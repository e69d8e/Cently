import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cently/data/database_helper.dart';
import 'package:cently/models/category.dart';
import 'package:cently/models/transaction_record.dart';
import 'package:cently/providers/transaction_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('TransactionProvider Unit Tests', () {
    late Database db;
    late TransactionProvider provider;
    late List<TransactionRecord> sampleRecords;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createDBForTesting(db);
        },
      );
      DatabaseHelper.setDatabaseForTesting(db);

      provider = TransactionProvider();
      final month = provider.selectedMonth;
      final day15 = DateTime(month.year, month.month, 15, 12, 0);
      final day16 = DateTime(month.year, month.month, 16, 18, 30);

      sampleRecords = [
        TransactionRecord(
          id: 'tx_1',
          amount: 35.0,
          type: CategoryType.expense,
          categoryId: 'cat_dining',
          categoryName: '餐饮美食',
          name: '星巴克咖啡',
          remark: '冰美式大杯',
          dateTime: day16,
        ),
        TransactionRecord(
          id: 'tx_2',
          amount: 68.0,
          type: CategoryType.expense,
          categoryId: 'cat_dining',
          categoryName: '餐饮美食',
          name: '日料定食',
          remark: '三文鱼套餐',
          dateTime: day16.subtract(const Duration(hours: 5)),
        ),
        TransactionRecord(
          id: 'tx_3',
          amount: 5000.0,
          type: CategoryType.income,
          categoryId: 'cat_salary',
          categoryName: '工资收入',
          name: '月度基本薪资',
          dateTime: day15,
        ),
        TransactionRecord(
          id: 'tx_4',
          amount: 15.0,
          type: CategoryType.expense,
          categoryId: 'cat_transport',
          categoryName: '交通出行',
          name: '地铁出行',
          dateTime: day15.subtract(const Duration(hours: 3)),
        ),
      ];

      provider.setMonthRecordsForTesting(sampleRecords);
    });

    tearDown(() async {
      DatabaseHelper.setDatabaseForTesting(null);
      await db.close();
    });

    test('Initial aggregation and totals match records', () {
      expect(provider.totalExpense, 118.0); // 35 + 68 + 15
      expect(provider.totalIncome, 5000.0);
      expect(provider.netBalance, 4882.0); // 5000 - 118
      expect(provider.filteredRecords.length, 4);
      expect(provider.recordedDaysInMonth, {15, 16});
      expect(provider.currentViewExpense, 118.0);
      expect(provider.currentViewIncome, 5000.0);
      expect(provider.currentViewBalance, 4882.0);
    });

    test('selectDay filters records and updates view totals', () {
      final month = provider.selectedMonth;
      final day16 = DateTime(month.year, month.month, 16);
      final day15 = DateTime(month.year, month.month, 15);

      // Select day 16
      provider.selectDay(day16);
      expect(provider.isDayMode, true);
      expect(provider.selectedDay, day16);
      expect(provider.filteredRecords.length, 2);
      expect(provider.currentViewExpense, 103.0); // 35 + 68
      expect(provider.currentViewIncome, 0.0);
      expect(provider.currentViewBalance, -103.0);

      // Select day 15
      provider.selectDay(day15);
      expect(provider.isDayMode, true);
      expect(provider.selectedDay, day15);
      expect(provider.filteredRecords.length, 2);
      expect(provider.currentViewExpense, 15.0);
      expect(provider.currentViewIncome, 5000.0);
      expect(provider.currentViewBalance, 4985.0);

      // Monthly totals should remain unaffected by day view
      expect(provider.totalExpense, 118.0);
      expect(provider.totalIncome, 5000.0);

      // Clear day selection back to whole month
      provider.clearSelectedDay();
      expect(provider.isDayMode, false);
      expect(provider.selectedDay, isNull);
      expect(provider.filteredRecords.length, 4);
      expect(provider.currentViewExpense, 118.0);
    });

    test('Multi-field search query matches name, categoryName, and remark case-insensitively', () {
      // 1. Match by name
      provider.setSearchQuery('咖啡');
      expect(provider.filteredRecords.length, 1);
      expect(provider.filteredRecords.first.id, 'tx_1');

      // 2. Match by categoryName
      provider.setSearchQuery('餐饮');
      expect(provider.filteredRecords.length, 2);

      // 3. Match by remark
      provider.setSearchQuery('三文鱼');
      expect(provider.filteredRecords.length, 1);
      expect(provider.filteredRecords.first.id, 'tx_2');

      // 4. Non-matching query
      provider.setSearchQuery('不存在的项目');
      expect(provider.filteredRecords, isEmpty);
      expect(provider.currentViewExpense, 0.0);
      expect(provider.currentViewIncome, 0.0);

      // 5. Reset query
      provider.setSearchQuery('');
      expect(provider.filteredRecords.length, 4);
    });

    test('Category filtering and combination with day filter', () {
      final month = provider.selectedMonth;
      final day15 = DateTime(month.year, month.month, 15);
      final day16 = DateTime(month.year, month.month, 16);

      // Filter by category
      provider.setFilterCategory('cat_dining');
      expect(provider.filteredRecords.length, 2);
      expect(provider.currentViewExpense, 103.0);

      // Combine with day filter (day 15: dining has 0 records)
      provider.selectDay(day15);
      expect(provider.filteredRecords, isEmpty);

      // Switch day to day 16
      provider.selectDay(day16);
      expect(provider.filteredRecords.length, 2);

      // Clear category filter
      provider.setFilterCategory(null);
      expect(provider.filteredRecords.length, 2); // all records on day 16
    });

    test('Stats calculation and ranking by amount', () {
      final expStats = provider.getCategoryStats(CategoryType.expense);
      expect(expStats.length, 2);
      expect(expStats[0].categoryId, 'cat_dining');
      expect(expStats[0].amount, 103.0);
      expect(expStats[0].count, 2);
      expect(expStats[1].categoryId, 'cat_transport');
      expect(expStats[1].amount, 15.0);
      expect(expStats[1].count, 1);

      // Percentages sum to 1.0 (100%)
      final totalPercent = expStats.fold<double>(0.0, (acc, s) => acc + s.percentage);
      expect((totalPercent - 1.0).abs() < 0.001, true);

      final incStats = provider.getCategoryStats(CategoryType.income);
      expect(incStats.length, 1);
      expect(incStats.first.categoryId, 'cat_salary');
      expect(incStats.first.amount, 5000.0);
      expect(incStats.first.percentage, 1.0);

      // Top items limit
      final topItems = provider.getTopItemStats(CategoryType.expense, limit: 2);
      expect(topItems.length, 2);
      expect(topItems[0].name, '日料定食'); // 68 > 35
      expect(topItems[1].name, '星巴克咖啡');
    });

    test('BackupPreview parsing edge cases', () {
      // 1. Empty string
      final emptyPreview = provider.parseBackupPreview('');
      expect(emptyPreview.isValid, false);
      expect(emptyPreview.errorMessage?.contains('为空'), true);

      // 2. Malformed JSON
      final malformedPreview = provider.parseBackupPreview('{invalid json}');
      expect(malformedPreview.isValid, false);
      expect(malformedPreview.errorMessage?.contains('解析失败'), true);

      // 3. Array instead of object
      final arrayPreview = provider.parseBackupPreview('[1, 2, 3]');
      expect(arrayPreview.isValid, false);

      // 4. Valid payload
      final validJson = '''
      {
        "app": "Cently",
        "version": "1.0.1",
        "exportTime": "2026-08-16T12:00:00.000",
        "categories": [{"id": "c1"}],
        "presetItems": [{"id": "p1"}],
        "transactions": [{"id": "t1"}, {"id": "t2"}]
      }
      ''';
      final validPreview = provider.parseBackupPreview(validJson);
      expect(validPreview.isValid, true);
      expect(validPreview.categoriesCount, 1);
      expect(validPreview.presetsCount, 1);
      expect(validPreview.transactionsCount, 2);
    });

    test('getTotalTransactionsCount returns integer count from database', () async {
      final count = await provider.getTotalTransactionsCount();
      expect(count, isA<int>());
      expect(count >= 0, true);
    });

    test('exportAsJson and exportAsCsv for specific month filter correctly', () async {
      final augDate = DateTime(2026, 8, 15, 10, 0);
      final sepDate = DateTime(2026, 9, 5, 12, 0);

      final txAug = TransactionRecord(
        id: 'tx_aug',
        amount: 50.0,
        type: CategoryType.expense,
        categoryId: 'cat_dining',
        categoryName: '餐饮',
        name: '八月聚餐',
        dateTime: augDate,
      );
      final txSep = TransactionRecord(
        id: 'tx_sep',
        amount: 80.0,
        type: CategoryType.expense,
        categoryId: 'cat_dining',
        categoryName: '餐饮',
        name: '九月购物',
        dateTime: sepDate,
      );

      await db.insert('transactions', txAug.toMap());
      await db.insert('transactions', txSep.toMap());

      // 1. Single month export (August)
      final jsonAugStr = await provider.exportAsJson(month: DateTime(2026, 8));
      final jsonAug = jsonDecode(jsonAugStr);
      expect(jsonAug['exportScope'], 'month');
      expect(jsonAug['targetMonth'], '2026-08');
      final txListAug = jsonAug['transactions'] as List;
      expect(txListAug.any((t) => t['id'] == 'tx_aug'), true);
      expect(txListAug.any((t) => t['id'] == 'tx_sep'), false);

      // 2. All months export
      final jsonAllStr = await provider.exportAsJson();
      final jsonAll = jsonDecode(jsonAllStr);
      expect(jsonAll['exportScope'], 'all');
      expect(jsonAll['targetMonth'], isNull);
      final txListAll = jsonAll['transactions'] as List;
      expect(txListAll.any((t) => t['id'] == 'tx_aug'), true);
      expect(txListAll.any((t) => t['id'] == 'tx_sep'), true);

      // 3. Single month CSV export
      final csvAug = await provider.exportAsCsv(month: DateTime(2026, 8));
      expect(csvAug.contains('八月聚餐'), true);
      expect(csvAug.contains('九月购物'), false);

      // 4. Month count
      final countAug = await provider.getTransactionsCountByMonth(DateTime(2026, 8));
      expect(countAug, 1);
      final countSep = await provider.getTransactionsCountByMonth(DateTime(2026, 9));
      expect(countSep, 1);
    });

    test('parseBackupPreview detects single-month metadata and transaction dates', () {
      // With explicit metadata
      final singleMonthJson = jsonEncode({
        'app': 'Cently',
        'exportScope': 'month',
        'targetMonth': '2026-08',
        'categories': [{'id': 'c1'}],
        'presetItems': [],
        'transactions': [{'id': 't1', 'timestamp': DateTime(2026, 8, 10).millisecondsSinceEpoch}],
      });
      final preview = provider.parseBackupPreview(singleMonthJson);
      expect(preview.isValid, true);
      expect(preview.isSingleMonth, true);
      expect(preview.targetMonth, '2026-08');

      // Without explicit metadata, auto-detected from uniform timestamps
      final autoDetectJson = jsonEncode({
        'app': 'Cently',
        'categories': [{'id': 'c1'}],
        'presetItems': [],
        'transactions': [
          {'id': 't1', 'timestamp': DateTime(2026, 7, 5).millisecondsSinceEpoch},
          {'id': 't2', 'timestamp': DateTime(2026, 7, 20).millisecondsSinceEpoch},
        ],
      });
      final autoPreview = provider.parseBackupPreview(autoDetectJson);
      expect(autoPreview.isValid, true);
      expect(autoPreview.isSingleMonth, true);
      expect(autoPreview.targetMonth, '2026-07');

      // Multiple months detected as all
      final multiMonthJson = jsonEncode({
        'app': 'Cently',
        'categories': [{'id': 'c1'}],
        'presetItems': [],
        'transactions': [
          {'id': 't1', 'timestamp': DateTime(2026, 6, 5).millisecondsSinceEpoch},
          {'id': 't2', 'timestamp': DateTime(2026, 7, 20).millisecondsSinceEpoch},
        ],
      });
      final multiPreview = provider.parseBackupPreview(multiMonthJson);
      expect(multiPreview.isSingleMonth, false);
      expect(multiPreview.exportScope, 'all');
    });

    test('Single-month overwrite import preserves transactions of other months', () async {
      final augTx = TransactionRecord(
        id: 'existing_aug',
        amount: 100.0,
        type: CategoryType.expense,
        categoryId: 'c1',
        categoryName: '餐饮',
        name: '已有八月账单',
        dateTime: DateTime(2026, 8, 1),
      );
      final sepTx = TransactionRecord(
        id: 'existing_sep',
        amount: 200.0,
        type: CategoryType.expense,
        categoryId: 'c1',
        categoryName: '餐饮',
        name: '已有九月账单',
        dateTime: DateTime(2026, 9, 1),
      );
      await db.insert('transactions', augTx.toMap());
      await db.insert('transactions', sepTx.toMap());

      // Prepare backup for August only
      final backupAug = jsonEncode({
        'app': 'Cently',
        'exportScope': 'month',
        'targetMonth': '2026-08',
        'categories': [],
        'presetItems': [],
        'transactions': [
          TransactionRecord(
            id: 'new_aug_tx',
            amount: 88.0,
            type: CategoryType.expense,
            categoryId: 'c1',
            categoryName: '餐饮',
            name: '新恢复的八月账单',
            dateTime: DateTime(2026, 8, 18),
          ).toMap(),
        ],
      });

      // Import in overwrite mode
      final result = await provider.importFromJson(backupAug, overwrite: true);
      expect(result.isSuccess, true);

      // Verify August existing record was overwritten
      final augRecords = await db.query('transactions', where: 'id = ?', whereArgs: ['existing_aug']);
      expect(augRecords.isEmpty, true);

      // Verify new August record exists
      final newAugRecords = await db.query('transactions', where: 'id = ?', whereArgs: ['new_aug_tx']);
      expect(newAugRecords.length, 1);

      // Verify September existing record is PRESERVED!
      final sepRecords = await db.query('transactions', where: 'id = ?', whereArgs: ['existing_sep']);
      expect(sepRecords.length, 1);
    });

    test('generateExportFileName includes scope and exact timestamp suffix without illegal characters', () {
      final fixedTime = DateTime(2026, 9, 4, 16, 35, 8);

      // 1. Month scope JSON
      final jsonMonthName = TransactionProvider.generateExportFileName(
        prefix: 'cently_backup',
        extension: 'json',
        month: DateTime(2026, 9),
        now: fixedTime,
      );
      expect(jsonMonthName, 'cently_backup_202609_20260904_163508.json');

      // 2. All scope CSV
      final csvAllName = TransactionProvider.generateExportFileName(
        prefix: 'cently_transactions',
        extension: '.csv',
        month: null,
        now: DateTime(2026, 1, 5, 8, 9, 2),
      );
      expect(csvAllName, 'cently_transactions_all_20260105_080902.csv');

      // Check no illegal characters like :, /, \, space exist in filename
      expect(jsonMonthName.contains(':'), false);
      expect(jsonMonthName.contains('/'), false);
      expect(jsonMonthName.contains(' '), false);
    });
  });
}
