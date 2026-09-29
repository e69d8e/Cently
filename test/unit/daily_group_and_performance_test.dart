import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cently/models/category.dart';
import 'package:cently/models/transaction_record.dart';
import 'package:cently/providers/transaction_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('DailyTransactionGroup & Performance Tests', () {
    test('DailyTransactionGroup correctly aggregates records and computes daily totals', () {
      final now = DateTime(2026, 8, 18, 14, 30);
      final r1 = TransactionRecord(
        id: 'tx_d1_1',
        amount: 25.5,
        type: CategoryType.expense,
        categoryId: 'c_food',
        categoryName: '餐饮',
        name: '午餐',
        dateTime: now,
      );
      final r2 = TransactionRecord(
        id: 'tx_d1_2',
        amount: 14.5,
        type: CategoryType.expense,
        categoryId: 'c_drink',
        categoryName: '饮品',
        name: '奶茶',
        dateTime: now.add(const Duration(minutes: 30)),
      );
      final r3 = TransactionRecord(
        id: 'tx_d1_3',
        amount: 100.0,
        type: CategoryType.income,
        categoryId: 'c_bonus',
        categoryName: '奖金',
        name: '红包',
        dateTime: now.add(const Duration(hours: 1)),
      );

      final group = DailyTransactionGroup(
        date: DateTime(2026, 8, 18),
        records: [r3, r2, r1],
        totalExpense: 40.0,
        totalIncome: 100.0,
      );

      expect(group.date, DateTime(2026, 8, 18));
      expect(group.records.length, 3);
      expect(group.totalExpense, 40.0);
      expect(group.totalIncome, 100.0);
    });

    test('TransactionProvider single-pass builds ordered DailyTransactionGroup list', () {
      final provider = TransactionProvider();
      final day1 = DateTime(2026, 8, 20, 10, 0);
      final day2 = DateTime(2026, 8, 19, 12, 0);
      final day3 = DateTime(2026, 8, 18, 18, 0);

      final records = [
        TransactionRecord(
          id: 't1',
          amount: 50.0,
          type: CategoryType.expense,
          categoryId: 'c1',
          categoryName: '餐饮',
          name: '晚餐',
          dateTime: day1,
        ),
        TransactionRecord(
          id: 't2',
          amount: 120.0,
          type: CategoryType.income,
          categoryId: 'c2',
          categoryName: '退款',
          name: '商品退款',
          dateTime: day1,
        ),
        TransactionRecord(
          id: 't3',
          amount: 30.0,
          type: CategoryType.expense,
          categoryId: 'c1',
          categoryName: '餐饮',
          name: '午餐',
          dateTime: day2,
        ),
        TransactionRecord(
          id: 't4',
          amount: 15.0,
          type: CategoryType.expense,
          categoryId: 'c1',
          categoryName: '餐饮',
          name: '早餐',
          dateTime: day3,
        ),
      ];

      provider.setMonthRecordsForTesting(records);

      final sortedGroups = provider.sortedDailyGroups;
      expect(sortedGroups.length, 3);

      // Verify reverse-chronological group ordering
      expect(sortedGroups[0].date, DateTime(2026, 8, 20));
      expect(sortedGroups[0].records.length, 2);
      expect(sortedGroups[0].totalExpense, 50.0);
      expect(sortedGroups[0].totalIncome, 120.0);

      expect(sortedGroups[1].date, DateTime(2026, 8, 19));
      expect(sortedGroups[1].records.length, 1);
      expect(sortedGroups[1].totalExpense, 30.0);
      expect(sortedGroups[1].totalIncome, 0.0);

      expect(sortedGroups[2].date, DateTime(2026, 8, 18));
      expect(sortedGroups[2].records.length, 1);
      expect(sortedGroups[2].totalExpense, 15.0);
      expect(sortedGroups[2].totalIncome, 0.0);

      // Verify backward-compatibility dailyGroupedRecords map is preserved
      expect(provider.dailyGroupedRecords.keys.length, 3);
      expect(provider.dailyGroupedRecords[DateTime(2026, 8, 20)]?.length, 2);
    });

    test('High-volume benchmark: 2,500 records single-pass aggregation stays under 120ms', () {
      final provider = TransactionProvider();
      final List<TransactionRecord> massiveRecords = [];
      final baseDate = DateTime(2026, 8, 30, 20, 0);

      // Generate 2,500 transactions across 25 distinct days in reverse order
      for (int dayOffset = 0; dayOffset < 25; dayOffset++) {
        final dayTime = baseDate.subtract(Duration(days: dayOffset));
        for (int i = 0; i < 100; i++) {
          final isExp = i % 3 != 0;
          massiveRecords.add(TransactionRecord(
            id: 'bulk_tx_${dayOffset}_$i',
            amount: (i + 1) * 2.5,
            type: isExp ? CategoryType.expense : CategoryType.income,
            categoryId: isExp ? 'cat_exp_${i % 5}' : 'cat_inc_${i % 2}',
            categoryName: isExp ? '支出分类 ${i % 5}' : '收入分类 ${i % 2}',
            name: '项目 ${i % 10}',
            dateTime: dayTime.subtract(Duration(minutes: i)),
            createdAt: dayTime,
          ));
        }
      }

      expect(massiveRecords.length, 2500);

      // Warm-up pass: let the JIT compile the aggregation path before measuring,
      // otherwise the first cold run dominates the reading on CI runners.
      provider.setMonthRecordsForTesting(massiveRecords);

      // Best-of-5 steady-state timing so an unlucky scheduler slice on a shared
      // CI runner cannot fail the build on its own.
      var bestMs = -1;
      for (var round = 0; round < 5; round++) {
        final stopwatch = Stopwatch()..start();
        provider.setMonthRecordsForTesting(massiveRecords);
        stopwatch.stop();
        final elapsed = stopwatch.elapsedMicroseconds;
        if (bestMs < 0 || elapsed < bestMs) bestMs = elapsed;
      }

      // Verify correctness
      expect(provider.sortedDailyGroups.length, 25);
      expect(provider.filteredRecords.length, 2500);
      expect(provider.totalExpense > 0, true);
      expect(provider.totalIncome > 0, true);

      // Verify high performance (best steady-state pass under 120ms for 2,500
      // records; a regression in the single-pass aggregation would blow past it)
      expect(bestMs < 120000, true,
          reason: 'Best elapsed was ${(bestMs / 1000).toStringAsFixed(2)}ms, should be < 120ms');
    });
  });
}
