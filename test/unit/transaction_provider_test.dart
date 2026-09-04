import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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
    late TransactionProvider provider;
    late List<TransactionRecord> sampleRecords;

    setUp(() {
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
  });
}
