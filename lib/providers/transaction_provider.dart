import 'dart:convert';
import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/transaction_record.dart';

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
  bool _isLoading = true;

  String _searchQuery = '';
  String? _filterCategoryId;

  DateTime get selectedMonth => _selectedMonth;
  DateTime? get selectedDay => _selectedDay;
  bool get isDayMode => _selectedDay != null;
  List<TransactionRecord> get monthRecords => _monthRecords;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get filterCategoryId => _filterCategoryId;

  // Set of days (1..31) that have records in the currently loaded month
  Set<int> get recordedDaysInMonth {
    return _monthRecords.map((r) => r.dateTime.day).toSet();
  }

  // Filtered records (by selectedDay if set, by filterCategory, and by search query)
  List<TransactionRecord> get filteredRecords {
    return _monthRecords.where((record) {
      if (_selectedDay != null) {
        if (record.dateTime.year != _selectedDay!.year ||
            record.dateTime.month != _selectedDay!.month ||
            record.dateTime.day != _selectedDay!.day) {
          return false;
        }
      }
      if (_filterCategoryId != null && record.categoryId != _filterCategoryId) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty) {
        final query = _searchQuery.trim().toLowerCase();
        final nameMatch = record.name.toLowerCase().contains(query);
        final catMatch = record.categoryName.toLowerCase().contains(query);
        final remarkMatch = record.remark?.toLowerCase().contains(query) ?? false;
        return nameMatch || catMatch || remarkMatch;
      }
      return true;
    }).toList();
  }

  // Current view totals (for selectedDay if in day mode, else for whole month)
  double get currentViewExpense {
    final list = isDayMode
        ? _monthRecords.where((r) =>
            r.dateTime.year == _selectedDay!.year &&
            r.dateTime.month == _selectedDay!.month &&
            r.dateTime.day == _selectedDay!.day &&
            r.type == CategoryType.expense)
        : _monthRecords.where((r) => r.type == CategoryType.expense);
    return list.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get currentViewIncome {
    final list = isDayMode
        ? _monthRecords.where((r) =>
            r.dateTime.year == _selectedDay!.year &&
            r.dateTime.month == _selectedDay!.month &&
            r.dateTime.day == _selectedDay!.day &&
            r.type == CategoryType.income)
        : _monthRecords.where((r) => r.type == CategoryType.income);
    return list.fold(0.0, (sum, r) => sum + r.amount);
  }

  double get currentViewBalance => currentViewIncome - currentViewExpense;

  // Monthly totals
  double get totalExpense {
    return _monthRecords
        .where((r) => r.type == CategoryType.expense)
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  double get totalIncome {
    return _monthRecords
        .where((r) => r.type == CategoryType.income)
        .fold(0.0, (sum, r) => sum + r.amount);
  }

  double get netBalance => totalIncome - totalExpense;

  // Grouped by day (Key: DateTime normalized to midnight)
  Map<DateTime, List<TransactionRecord>> get dailyGroupedRecords {
    final Map<DateTime, List<TransactionRecord>> map = {};
    for (final record in filteredRecords) {
      final dateKey = DateTime(
        record.dateTime.year,
        record.dateTime.month,
        record.dateTime.day,
      );
      map.putIfAbsent(dateKey, () => []).add(record);
    }
    return map;
  }

  // Initialize and load
  Future<void> loadCurrentMonth() async {
    _isLoading = true;
    notifyListeners();

    try {
      _monthRecords = await _db.getTransactionsByMonth(_selectedMonth);
    } catch (e) {
      debugPrint('Error loading current month transactions: $e');
      _monthRecords = [];
    } finally {
      _isLoading = false;
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
      notifyListeners();
    }
  }

  void clearSelectedDay() {
    _selectedDay = null;
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
    notifyListeners();
  }

  void setFilterCategory(String? categoryId) {
    _filterCategoryId = categoryId;
    notifyListeners();
  }

  // ================= CRUD =================

  Future<void> addTransaction({
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
  }

  Future<void> updateTransaction(TransactionRecord record) async {
    await _db.updateTransaction(record);
    if (record.dateTime.year != _selectedMonth.year || record.dateTime.month != _selectedMonth.month) {
      _selectedMonth = DateTime(record.dateTime.year, record.dateTime.month);
    }
    await loadCurrentMonth();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    _monthRecords.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  // ================= STATISTICS =================

  List<CategoryStat> getCategoryStats(CategoryType type) {
    final recordsOfType = _monthRecords.where((r) => r.type == type).toList();
    final totalAmount = recordsOfType.fold(0.0, (sum, r) => sum + r.amount);

    if (totalAmount <= 0) return [];

    final Map<String, (String name, double amount, int count)> catMap = {};
    for (final r in recordsOfType) {
      if (!catMap.containsKey(r.categoryId)) {
        catMap[r.categoryId] = (r.categoryName, 0.0, 0);
      }
      final cur = catMap[r.categoryId]!;
      catMap[r.categoryId] = (cur.$1, cur.$2 + r.amount, cur.$3 + 1);
    }

    final List<CategoryStat> stats = catMap.entries.map((entry) {
      final amount = entry.value.$2;
      return CategoryStat(
        categoryId: entry.key,
        categoryName: entry.value.$1,
        amount: amount,
        percentage: totalAmount > 0 ? (amount / totalAmount) : 0.0,
        count: entry.value.$3,
        type: type,
      );
    }).toList();

    // Sort by amount descending
    stats.sort((a, b) => b.amount.compareTo(a.amount));
    return stats;
  }

  List<ItemStat> getTopItemStats(CategoryType type, {int limit = 10}) {
    final recordsOfType = _monthRecords.where((r) => r.type == type).toList();
    final Map<String, (String catName, double amount, int count)> itemMap = {};

    for (final r in recordsOfType) {
      if (!itemMap.containsKey(r.name)) {
        itemMap[r.name] = (r.categoryName, 0.0, 0);
      }
      final cur = itemMap[r.name]!;
      itemMap[r.name] = (cur.$1, cur.$2 + r.amount, cur.$3 + 1);
    }

    final List<ItemStat> stats = itemMap.entries.map((entry) {
      return ItemStat(
        name: entry.key,
        categoryName: entry.value.$1,
        amount: entry.value.$2,
        count: entry.value.$3,
        type: type,
      );
    }).toList();

    // Sort by total amount descending
    stats.sort((a, b) => b.amount.compareTo(a.amount));
    if (stats.length > limit) {
      return stats.sublist(0, limit);
    }
    return stats;
  }

  // ================= DATA EXPORT =================

  Future<String> exportAsJson() async {
    final allRecords = await _db.getAllTransactions();
    final categories = await _db.getAllCategories();
    final presets = await _db.getAllPresetItems();

    final data = {
      'app': 'Cently',
      'version': '1.0.0',
      'exportTime': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => c.toMap()).toList(),
      'presetItems': presets.map((p) => p.toMap()).toList(),
      'transactions': allRecords.map((t) => t.toMap()).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  Future<String> exportAsCsv() async {
    final allRecords = await _db.getAllTransactions();
    final buffer = StringBuffer();
    buffer.writeln('日期时间,收支类型,分类,名称,金额,备注');

    for (final r in allRecords) {
      final dateStr = r.dateTime.toIso8601String();
      final typeStr = r.type.displayName;
      final remarkStr = (r.remark ?? '').replaceAll('"', '""');
      buffer.writeln('"$dateStr","$typeStr","${r.categoryName}","${r.name}",${r.amount.toStringAsFixed(2)},"$remarkStr"');
    }

    return buffer.toString();
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

      return BackupPreview(
        app: decoded['app'] as String?,
        version: decoded['version'] as String?,
        exportTime: decoded['exportTime'] as String?,
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

    final result = await _db.importBackupData(preview.rawData!, overwrite: overwrite);
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
    required this.categoriesCount,
    required this.presetsCount,
    required this.transactionsCount,
    required this.isValid,
    this.errorMessage,
    this.rawData,
  });
}

