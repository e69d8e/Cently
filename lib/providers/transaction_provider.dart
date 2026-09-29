import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';
import '../utils/currency_format.dart';

class CategoryStat {
  final String categoryId;
  final String categoryName;
  final double amount;
  final double percentage; // 0.0 ~ 1.0
  final int count;
  final CategoryType type;

  CategoryStat({
    required this.categoryId,
    required this.categoryName,
    required this.amount,
    required this.percentage,
    required this.count,
    required this.type,
  });
}

class ItemStat {
  final String name;
  final String categoryName;
  final double amount;
  final int count;
  final CategoryType type;

  ItemStat({
    required this.name,
    required this.categoryName,
    required this.amount,
    required this.count,
    required this.type,
  });
}

class TransactionProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime? _selectedDay;
  List<TransactionRecord> _monthRecords = [];
  List<TransactionRecord> _deletedRecords = [];
  bool _isLoading = true;
  bool _isLoadingRecycleBin = false;

  String _searchQuery = '';
  String? _filterCategoryId;

  // Cached derived states
  Set<int> _recordedDaysInMonth = {};
  List<TransactionRecord> _filteredRecords = [];
  Map<DateTime, List<TransactionRecord>> _dailyGroupedRecords = {};
  List<DailyTransactionGroup> _sortedDailyGroups = [];
  double _currentViewExpense = 0.0;
  double _currentViewIncome = 0.0;
  double _currentViewBalance = 0.0;
  double _totalExpense = 0.0;
  double _totalIncome = 0.0;
  double _netBalance = 0.0;
  List<CategoryStat> _expenseCategoryStats = [];
  List<CategoryStat> _incomeCategoryStats = [];
  List<ItemStat> _expenseTopItemStats = [];
  List<ItemStat> _incomeTopItemStats = [];

  DateTime get selectedMonth => _selectedMonth;
  DateTime? get selectedDay => _selectedDay;
  bool get isDayMode => _selectedDay != null;
  List<TransactionRecord> get monthRecords => _monthRecords;
  List<TransactionRecord> get deletedRecords => _deletedRecords;
  int get deletedCount => _deletedRecords.length;
  bool get isLoading => _isLoading;
  bool get isLoadingRecycleBin => _isLoadingRecycleBin;
  String get searchQuery => _searchQuery;
  String? get filterCategoryId => _filterCategoryId;

  Set<int> get recordedDaysInMonth => _recordedDaysInMonth;
  List<TransactionRecord> get filteredRecords => _filteredRecords;
  double get currentViewExpense => _currentViewExpense;
  double get currentViewIncome => _currentViewIncome;
  double get currentViewBalance => _currentViewBalance;
  double get totalExpense => _totalExpense;
  double get totalIncome => _totalIncome;
  double get netBalance => _netBalance;
  Map<DateTime, List<TransactionRecord>> get dailyGroupedRecords => _dailyGroupedRecords;
  List<DailyTransactionGroup> get sortedDailyGroups => _sortedDailyGroups;

  @visibleForTesting
  void setMonthRecordsForTesting(List<TransactionRecord> records) {
    _monthRecords = records;
    _recomputeDerivedState();
    notifyListeners();
  }

  void _recomputeDerivedState() {
    double expSum = 0.0;
    double incSum = 0.0;
    final recordedDays = <int>{};

    final normalizedQuery = _searchQuery.trim().toLowerCase();
    final hasQuery = normalizedQuery.isNotEmpty;

    final filtered = <TransactionRecord>[];
    double viewExp = 0.0;
    double viewInc = 0.0;
    final Map<DateTime, List<TransactionRecord>> dailyMap = {};

    // Single-pass aggregators for categories and high-frequency item names
    final Map<String, (String name, double amount, int count)> expCatMap = {};
    final Map<String, (String name, double amount, int count)> incCatMap = {};
    final Map<String, (String catName, double amount, int count)> expItemMap = {};
    final Map<String, (String catName, double amount, int count)> incItemMap = {};

    for (final r in _monthRecords) {
      final isExp = r.type == CategoryType.expense;
      final amount = r.amount;

      // 1. Monthly totals & active recorded days
      recordedDays.add(r.dateTime.day);
      if (isExp) {
        expSum += amount;
        final existingCat = expCatMap[r.categoryId];
        if (existingCat == null) {
          expCatMap[r.categoryId] = (r.categoryName, amount, 1);
        } else {
          expCatMap[r.categoryId] = (existingCat.$1, existingCat.$2 + amount, existingCat.$3 + 1);
        }
        final existingItem = expItemMap[r.name];
        if (existingItem == null) {
          expItemMap[r.name] = (r.categoryName, amount, 1);
        } else {
          expItemMap[r.name] = (existingItem.$1, existingItem.$2 + amount, existingItem.$3 + 1);
        }
      } else {
        incSum += amount;
        final existingCat = incCatMap[r.categoryId];
        if (existingCat == null) {
          incCatMap[r.categoryId] = (r.categoryName, amount, 1);
        } else {
          incCatMap[r.categoryId] = (existingCat.$1, existingCat.$2 + amount, existingCat.$3 + 1);
        }
        final existingItem = incItemMap[r.name];
        if (existingItem == null) {
          incItemMap[r.name] = (r.categoryName, amount, 1);
        } else {
          incItemMap[r.name] = (existingItem.$1, existingItem.$2 + amount, existingItem.$3 + 1);
        }
      }

      // 2. Filtered view evaluation
      if (_selectedDay != null) {
        if (r.dateTime.year != _selectedDay!.year ||
            r.dateTime.month != _selectedDay!.month ||
            r.dateTime.day != _selectedDay!.day) {
          continue;
        }
      }
      if (_filterCategoryId != null && r.categoryId != _filterCategoryId) {
        continue;
      }
      if (hasQuery) {
        final nameMatch = r.name.toLowerCase().contains(normalizedQuery);
        final catMatch = r.categoryName.toLowerCase().contains(normalizedQuery);
        final remarkMatch = r.remark?.toLowerCase().contains(normalizedQuery) ?? false;
        // 金额匹配：同时覆盖千分位格式 (1,000.50) 与两位小数格式 (1000.50)
        final compactAmount = CurrencyFormat.formatCompact(r.amount, showSymbol: false);
        final fixedAmount = r.amount.toStringAsFixed(2);
        final amountMatch = compactAmount.contains(normalizedQuery) || fixedAmount.contains(normalizedQuery);
        if (!nameMatch && !catMatch && !remarkMatch && !amountMatch) {
          continue;
        }
      }

      filtered.add(r);
      if (isExp) {
        viewExp += amount;
      } else {
        viewInc += amount;
      }

      final dateKey = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      dailyMap.putIfAbsent(dateKey, () => []).add(r);
    }

    // 2.1 Build pre-sorted and pre-aggregated DailyTransactionGroup list
    final List<DailyTransactionGroup> sortedGroups = [];
    DateTime? currentGroupDate;
    List<TransactionRecord> currentDayRecords = [];
    double currentDayExp = 0.0;
    double currentDayInc = 0.0;

    for (final r in filtered) {
      final date = DateTime(r.dateTime.year, r.dateTime.month, r.dateTime.day);
      if (currentGroupDate == null || currentGroupDate != date) {
        if (currentGroupDate != null) {
          sortedGroups.add(DailyTransactionGroup(
            date: currentGroupDate,
            records: currentDayRecords,
            totalExpense: (currentDayExp * 100).round() / 100,
            totalIncome: (currentDayInc * 100).round() / 100,
          ));
        }
        currentGroupDate = date;
        currentDayRecords = [r];
        currentDayExp = (r.type == CategoryType.expense) ? r.amount : 0.0;
        currentDayInc = (r.type == CategoryType.income) ? r.amount : 0.0;
      } else {
        currentDayRecords.add(r);
        if (r.type == CategoryType.expense) {
          currentDayExp += r.amount;
        } else {
          currentDayInc += r.amount;
        }
      }
    }
    if (currentGroupDate != null) {
      sortedGroups.add(DailyTransactionGroup(
        date: currentGroupDate,
        records: currentDayRecords,
        totalExpense: (currentDayExp * 100).round() / 100,
        totalIncome: (currentDayInc * 100).round() / 100,
      ));
    }
    _sortedDailyGroups = sortedGroups;

    _totalExpense = (expSum * 100).round() / 100;
    _totalIncome = (incSum * 100).round() / 100;
    _netBalance = ((_totalIncome - _totalExpense) * 100).round() / 100;
    _recordedDaysInMonth = recordedDays;

    _filteredRecords = filtered;
    _currentViewExpense = (viewExp * 100).round() / 100;
    _currentViewIncome = (viewInc * 100).round() / 100;
    _currentViewBalance = ((_currentViewIncome - _currentViewExpense) * 100).round() / 100;
    _dailyGroupedRecords = dailyMap;

    // 3. Build Category Stats
    _expenseCategoryStats = _buildCategoryStatsList(expCatMap, _totalExpense, CategoryType.expense);
    _incomeCategoryStats = _buildCategoryStatsList(incCatMap, _totalIncome, CategoryType.income);
    _expenseTopItemStats = _buildTopItemList(expItemMap, CategoryType.expense);
    _incomeTopItemStats = _buildTopItemList(incItemMap, CategoryType.income);
  }

  // Initialize and load
  Future<void> loadCurrentMonth() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Auto cleanup deleted records older than 30 days
      await _db.cleanupExpiredDeletedTransactions(retentionDays: 30);

      // 2. Fetch current month active records
      _monthRecords = await _db.getTransactionsByMonth(_selectedMonth);
      _recomputeDerivedState();

      // 3. Fetch deleted records for recycle bin
      _deletedRecords = await _db.getDeletedTransactions();
    } catch (e) {
      debugPrint('Error loading current month transactions: $e');
      _monthRecords = [];
      _recomputeDerivedState();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<CategoryStat> _buildCategoryStatsList(
    Map<String, (String name, double amount, int count)> catMap,
    double totalAmount,
    CategoryType type,
  ) {
    if (totalAmount <= 0 || catMap.isEmpty) return const [];
    final List<CategoryStat> stats = catMap.entries.map((entry) {
      final amount = (entry.value.$2 * 100).round() / 100;
      return CategoryStat(
        categoryId: entry.key,
        categoryName: entry.value.$1,
        amount: amount,
        percentage: totalAmount > 0 ? (amount / totalAmount) : 0.0,
        count: entry.value.$3,
        type: type,
      );
    }).toList();
    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  List<ItemStat> _buildTopItemList(
    Map<String, (String catName, double amount, int count)> itemMap,
    CategoryType type,
  ) {
    if (itemMap.isEmpty) return const [];
    final List<ItemStat> stats = itemMap.entries.map((entry) {
      final amount = (entry.value.$2 * 100).round() / 100;
      return ItemStat(
        name: entry.key,
        categoryName: entry.value.$1,
        amount: amount,
        count: entry.value.$3,
        type: type,
      );
    }).toList();
    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  Future<void> loadRecycleBin() async {
    _isLoadingRecycleBin = true;
    notifyListeners();

    try {
      await _db.cleanupExpiredDeletedTransactions(retentionDays: 30);
      _deletedRecords = await _db.getDeletedTransactions();
    } catch (e) {
      debugPrint('Error loading recycle bin: $e');
      _deletedRecords = [];
    } finally {
      _isLoadingRecycleBin = false;
      notifyListeners();
    }
  }

  Future<void> setMonth(DateTime month) async {
    _selectedMonth = DateTime(month.year, month.month);
    _selectedDay = null; // Reset to whole month
    await loadCurrentMonth();
  }

  Future<void> selectDay(DateTime? day) async {
    if (day == null) {
      _selectedDay = null;
      _recomputeDerivedState();
      notifyListeners();
      return;
    }

    final normalizedDay = DateTime(day.year, day.month, day.day);
    _selectedDay = normalizedDay;

    // If day is outside current selected month, load that month
    if (day.year != _selectedMonth.year || day.month != _selectedMonth.month) {
      _selectedMonth = DateTime(day.year, day.month);
      await loadCurrentMonth();
    } else {
      _recomputeDerivedState();
      notifyListeners();
    }
  }

  void clearSelectedDay() {
    _selectedDay = null;
    _recomputeDerivedState();
    notifyListeners();
  }

  Future<void> previousPeriod() async {
    if (_selectedDay != null) {
      final prevDay = _selectedDay!.subtract(const Duration(days: 1));
      await selectDay(prevDay);
    } else {
      await previousMonth();
    }
  }

  Future<void> nextPeriod() async {
    if (_selectedDay != null) {
      final nextDay = _selectedDay!.add(const Duration(days: 1));
      await selectDay(nextDay);
    } else {
      await nextMonth();
    }
  }

  Future<void> previousMonth() async {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    _selectedDay = null;
    await loadCurrentMonth();
  }

  Future<void> nextMonth() async {
    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    _selectedDay = null;
    await loadCurrentMonth();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _recomputeDerivedState();
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    _recomputeDerivedState();
    notifyListeners();
  }

  // ================= CRUD =================

  /// 新增一笔账单；返回落库后的完整记录（含生成的唯一 ID），
  /// 便于调用方做保存反馈与撤销。
  Future<TransactionRecord> addTransaction({
    required double amount,
    required CategoryType type,
    required String categoryId,
    required String categoryName,
    required String name,
    required DateTime dateTime,
    String? remark,
  }) async {
    final record = TransactionRecord(
      id: 'tx_${_uuid.v4()}',
      amount: amount,
      type: type,
      categoryId: categoryId,
      categoryName: categoryName,
      name: name.trim().isEmpty ? categoryName : name.trim(),
      dateTime: dateTime,
      remark: (remark != null && remark.trim().isNotEmpty) ? remark.trim() : null,
      createdAt: DateTime.now(),
    );

    await _db.insertTransaction(record);

    // If added record is in currently viewed month, reload
    if (dateTime.year == _selectedMonth.year && dateTime.month == _selectedMonth.month) {
      await loadCurrentMonth();
    } else {
      // Switch view to record's month
      _selectedMonth = DateTime(dateTime.year, dateTime.month);
      await loadCurrentMonth();
    }
    return record;
  }

  Future<void> updateTransaction(TransactionRecord record) async {
    await _db.updateTransaction(record);
    if (record.dateTime.year != _selectedMonth.year || record.dateTime.month != _selectedMonth.month) {
      _selectedMonth = DateTime(record.dateTime.year, record.dateTime.month);
    }
    await loadCurrentMonth();
  }

  Future<void> deleteTransaction(String id) async {
    final now = DateTime.now();
    await _db.softDeleteTransaction(id, deletedAt: now);
    final index = _monthRecords.indexWhere((r) => r.id == id);
    if (index != -1) {
      final record = _monthRecords[index].copyWith(deletedAt: now);
      _monthRecords.removeAt(index);
      _deletedRecords.insert(0, record);
    } else {
      _deletedRecords = await _db.getDeletedTransactions();
    }
    _recomputeDerivedState();
    notifyListeners();
  }

  /// Restores a single deleted transaction back to active records
  Future<void> restoreTransaction(String id) async {
    await _db.restoreTransaction(id);
    _deletedRecords.removeWhere((r) => r.id == id);
    await loadCurrentMonth();
  }

  /// Restores all deleted transactions from recycle bin
  Future<void> restoreAll() async {
    await _db.restoreAllTransactions();
    _deletedRecords.clear();
    await loadCurrentMonth();
  }

  /// Permanently deletes a single transaction
  Future<void> permanentlyDeleteTransaction(String id) async {
    await _db.permanentlyDeleteTransaction(id);
    _deletedRecords.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  /// Empties the entire recycle bin permanently
  Future<void> emptyRecycleBin() async {
    await _db.clearRecycleBin();
    _deletedRecords.clear();
    notifyListeners();
  }

  // ================= STATISTICS =================

  List<CategoryStat> getCategoryStats(CategoryType type) {
    return type == CategoryType.expense ? _expenseCategoryStats : _incomeCategoryStats;
  }

  List<ItemStat> getTopItemStats(CategoryType type, {int limit = 10}) {
    final list = type == CategoryType.expense ? _expenseTopItemStats : _incomeTopItemStats;
    if (list.length > limit) {
      return list.sublist(0, limit);
    }
    return list;
  }

  // ================= DATA EXPORT =================

  /// Retrieves total count of active transactions in database across all time
  Future<int> getTotalTransactionsCount() async {
    return await _db.getTotalTransactionsCount();
  }

  /// Retrieves count of active transactions for a specific month
  Future<int> getTransactionsCountByMonth(DateTime month) async {
    return await _db.getTransactionsCountByMonth(month);
  }

  Future<String> exportAsJson({DateTime? month}) async {
    final records = month == null
        ? await _db.getAllTransactions()
        : await _db.getTransactionsByMonth(month);
    final categories = await _db.getAllCategories();
    final presets = await _db.getAllPresetItems();

    final data = {
      'app': 'Cently',
      'version': '1.0.4',
      'exportTime': DateTime.now().toIso8601String(),
      'exportScope': month == null ? 'all' : 'month',
      if (month != null) 'targetMonth': '${month.year}-${month.month.toString().padLeft(2, '0')}',
      'categories': categories.map((c) => c.toMap()).toList(),
      'presetItems': presets.map((p) => p.toMap()).toList(),
      'transactions': records.map((t) => t.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> exportAsCsv({DateTime? month}) async {
    final records = month == null
        ? await _db.getAllTransactions()
        : await _db.getTransactionsByMonth(month);
    final buffer = StringBuffer();
    buffer.writeln('日期时间,收支类型,分类,名称,金额,备注');

    for (final r in records) {
      final dateStr = CurrencyFormat.escapeCsvField(r.dateTime.toIso8601String());
      final typeStr = CurrencyFormat.escapeCsvField(r.type.displayName);
      final catStr = CurrencyFormat.escapeCsvField(r.categoryName);
      final nameStr = CurrencyFormat.escapeCsvField(r.name);
      final amountStr = r.amount.toStringAsFixed(2);
      final remarkStr = CurrencyFormat.escapeCsvField(r.remark ?? '');
      buffer.writeln('$dateStr,$typeStr,$catStr,$nameStr,$amountStr,$remarkStr');
    }

    return buffer.toString();
  }

  /// 生成规范的导出文件名，包含导出范围标识与精确到秒的时间戳后缀
  static String generateExportFileName({
    required String prefix,
    required String extension,
    DateTime? month,
    DateTime? now,
  }) {
    final dt = now ?? DateTime.now();
    final monthSuffix = month == null
        ? 'all'
        : '${month.year}${month.month.toString().padLeft(2, '0')}';
    final datePart =
        '${dt.year}${dt.month.toString().padLeft(2, '0')}${dt.day.toString().padLeft(2, '0')}';
    final timePart =
        '${dt.hour.toString().padLeft(2, '0')}${dt.minute.toString().padLeft(2, '0')}${dt.second.toString().padLeft(2, '0')}';
    final cleanExt = extension.startsWith('.') ? extension.substring(1) : extension;
    return '${prefix}_${monthSuffix}_${datePart}_$timePart.$cleanExt';
  }

  /// 使用系统原生文件保存选择器保存 JSON 备份文件（Android 调用 SAF 存储访问框架，不会弹出分享菜单）
  Future<Uri?> saveJsonFile({DateTime? month}) async {
    final jsonContent = await exportAsJson(month: month);
    final fileName = generateExportFileName(
      prefix: 'cently_backup',
      extension: 'json',
      month: month,
    );
    final bytes = Uint8List.fromList(utf8.encode(jsonContent));
    return await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['json'],
      mimeType: 'application/json',
    );
  }

  /// 使用系统原生文件保存选择器保存 CSV 文件（预置 UTF-8 BOM 确保 Excel 正常识别中文）
  Future<Uri?> saveCsvFile({DateTime? month}) async {
    final csvContent = await exportAsCsv(month: month);
    final fileName = generateExportFileName(
      prefix: 'cently_transactions',
      extension: 'csv',
      month: month,
    );
    final bom = [0xEF, 0xBB, 0xBF];
    final bytes = Uint8List.fromList([...bom, ...utf8.encode(csvContent)]);
    return await FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['csv'],
      mimeType: 'text/csv',
    );
  }

  /// 调用系统分享面板分享 JSON 备份文件（带精确时间戳后缀）
  Future<void> shareJsonFile({DateTime? month, Rect? sharePositionOrigin}) async {
    final jsonContent = await exportAsJson(month: month);
    final tempDir = await getTemporaryDirectory();
    final fileName = generateExportFileName(
      prefix: 'cently_backup',
      extension: 'json',
      month: month,
    );
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsString(jsonContent);

    final scopeLabel = month == null ? '全量' : '${month.year}年${month.month}月';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'application/json', name: fileName)],
        subject: 'Cently 记账数据备份 ($scopeLabel)',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// 调用系统分享面板分享 CSV 流水文件（带精确时间戳后缀）
  Future<void> shareCsvFile({DateTime? month, Rect? sharePositionOrigin}) async {
    final csvContent = await exportAsCsv(month: month);
    final tempDir = await getTemporaryDirectory();
    final fileName = generateExportFileName(
      prefix: 'cently_transactions',
      extension: 'csv',
      month: month,
    );
    final file = File('${tempDir.path}/$fileName');
    final bom = [0xEF, 0xBB, 0xBF];
    await file.writeAsBytes([...bom, ...utf8.encode(csvContent)]);

    final scopeLabel = month == null ? '全量' : '${month.year}年${month.month}月';
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv', name: fileName)],
        subject: 'Cently 记账流水明细 ($scopeLabel)',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }

  /// 导出并保存 JSON 备份文件（向下兼容别名）
  Future<void> exportJsonFile({DateTime? month, Rect? sharePositionOrigin}) async {
    await saveJsonFile(month: month);
  }

  /// 导出并保存 CSV 文件（向下兼容别名）
  Future<void> exportCsvFile({DateTime? month, Rect? sharePositionOrigin}) async {
    await saveCsvFile(month: month);
  }

  BackupPreview parseBackupPreview(String jsonStr) {
    try {
      final trimmed = jsonStr.trim();
      if (trimmed.isEmpty) {
        return BackupPreview(
          categoriesCount: 0,
          presetsCount: 0,
          transactionsCount: 0,
          isValid: false,
          errorMessage: '备份内容为空',
        );
      }

      final dynamic decoded = jsonDecode(trimmed);
      if (decoded is! Map<String, dynamic>) {
        return BackupPreview(
          categoriesCount: 0,
          presetsCount: 0,
          transactionsCount: 0,
          isValid: false,
          errorMessage: 'JSON 格式不正确（需为对象格式）',
        );
      }

      final categories = decoded['categories'] as List? ?? [];
      final presets = decoded['presetItems'] as List? ?? [];
      final transactions = decoded['transactions'] as List? ?? [];

      if (categories.isEmpty && presets.isEmpty && transactions.isEmpty) {
        return BackupPreview(
          categoriesCount: 0,
          presetsCount: 0,
          transactionsCount: 0,
          isValid: false,
          errorMessage: '未找到有效的分类或记账流水数据',
        );
      }

      String? exportScope = decoded['exportScope'] as String?;
      String? targetMonth = decoded['targetMonth'] as String?;

      // Auto-detect scope and targetMonth if not explicitly marked in metadata
      if (transactions.isNotEmpty && (exportScope == null || targetMonth == null)) {
        final Set<String> detectedMonths = {};
        for (final item in transactions) {
          if (item is Map) {
            final ts = item['timestamp'];
            if (ts is int) {
              final d = DateTime.fromMillisecondsSinceEpoch(ts);
              detectedMonths.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
            } else if (item['dateTime'] is String) {
              final d = DateTime.tryParse(item['dateTime'] as String);
              if (d != null) {
                detectedMonths.add('${d.year}-${d.month.toString().padLeft(2, '0')}');
              }
            }
          }
        }
        if (detectedMonths.length == 1) {
          exportScope ??= 'month';
          targetMonth ??= detectedMonths.first;
        } else if (detectedMonths.length > 1) {
          exportScope ??= 'all';
        }
      }

      return BackupPreview(
        app: decoded['app'] as String?,
        version: decoded['version'] as String?,
        exportTime: decoded['exportTime'] as String?,
        exportScope: exportScope,
        targetMonth: targetMonth,
        categoriesCount: categories.length,
        presetsCount: presets.length,
        transactionsCount: transactions.length,
        isValid: true,
        rawData: decoded,
      );
    } catch (e) {
      return BackupPreview(
        categoriesCount: 0,
        presetsCount: 0,
        transactionsCount: 0,
        isValid: false,
        errorMessage: 'JSON 解析失败: $e',
      );
    }
  }

  Future<ImportSummary> importFromJson(String jsonStr, {bool overwrite = false}) async {
    final preview = parseBackupPreview(jsonStr);
    if (!preview.isValid || preview.rawData == null) {
      return ImportSummary(
        categoriesCount: 0,
        presetsCount: 0,
        transactionsCount: 0,
        isSuccess: false,
        message: preview.errorMessage ?? '解析数据失败',
      );
    }

    DateTime? targetMonthDate;
    if (preview.isSingleMonth && preview.targetMonth != null) {
      final parts = preview.targetMonth!.split('-');
      if (parts.length == 2) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        if (year != null && month != null) {
          targetMonthDate = DateTime(year, month);
        }
      }
    }

    final result = await _db.importBackupData(
      preview.rawData!,
      overwrite: overwrite,
      targetMonth: targetMonthDate,
    );
    if (result.isSuccess) {
      await loadCurrentMonth();
    }
    return result;
  }

  Future<void> clearAll() async {
    await _db.clearAllTransactions();
    await loadCurrentMonth();
  }
}

class BackupPreview {
  final String? app;
  final String? version;
  final String? exportTime;
  final String? exportScope; // 'all' or 'month'
  final String? targetMonth; // e.g. '2026-08'
  final int categoriesCount;
  final int presetsCount;
  final int transactionsCount;
  final bool isValid;
  final String? errorMessage;
  final Map<String, dynamic>? rawData;

  BackupPreview({
    this.app,
    this.version,
    this.exportTime,
    this.exportScope,
    this.targetMonth,
    required this.categoriesCount,
    required this.presetsCount,
    required this.transactionsCount,
    required this.isValid,
    this.errorMessage,
    this.rawData,
  });

  bool get isSingleMonth => exportScope == 'month' && targetMonth != null;
}

