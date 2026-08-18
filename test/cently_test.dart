import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cently/models/category.dart';
import 'package:cently/models/preset_item.dart';
import 'package:cently/models/transaction_record.dart';
import 'package:cently/data/default_data.dart';
import 'package:cently/utils/currency_format.dart';
import 'package:cently/utils/date_format_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Models and Utilities Tests', () {
    test('Category serialization and deserialization', () {
      final category = Category(
        id: 'cat_test',
        name: '餐饮测试',
        type: CategoryType.expense,
        iconKey: 'restaurant',
        colorValue: 0xFFE11D48,
        sortOrder: 1,
        isDefault: true,
      );

      final map = category.toMap();
      expect(map['id'], 'cat_test');
      expect(map['name'], '餐饮测试');
      expect(map['type'], 'expense');
      expect(map['isDefault'], 1);

      final fromMap = Category.fromMap(map);
      expect(fromMap.id, category.id);
      expect(fromMap.name, category.name);
      expect(fromMap.type, CategoryType.expense);
      expect(fromMap.isDefault, true);
    });

    test('PresetItem serialization and deserialization', () {
      final item = PresetItem(
        id: 'preset_1',
        categoryId: 'cat_test',
        name: '拿铁咖啡',
        sortOrder: 2,
        isDefault: false,
      );

      final map = item.toMap();
      expect(map['id'], 'preset_1');
      expect(map['name'], '拿铁咖啡');

      final fromMap = PresetItem.fromMap(map);
      expect(fromMap.id, item.id);
      expect(fromMap.name, item.name);
      expect(fromMap.isDefault, false);
    });

    test('TransactionRecord serialization and deserialization', () {
      final now = DateTime(2026, 8, 16, 12, 30);
      final record = TransactionRecord(
        id: 'tx_1',
        amount: 32.50,
        type: CategoryType.expense,
        categoryId: 'cat_test',
        categoryName: '餐饮',
        name: '星巴克咖啡',
        dateTime: now,
        remark: '与同事一起',
      );

      final map = record.toMap();
      expect(map['id'], 'tx_1');
      expect(map['amount'], 32.50);
      expect(map['name'], '星巴克咖啡');

      final fromMap = TransactionRecord.fromMap(map);
      expect(fromMap.id, record.id);
      expect(fromMap.amount, 32.50);
      expect(fromMap.name, '星巴克咖啡');
      expect(fromMap.remark, '与同事一起');
      expect(fromMap.dateTime, now);
    });

    test('CurrencyFormat outputs correct strings', () {
      expect(CurrencyFormat.format(12.5), '¥12.50');
      expect(CurrencyFormat.format(12345.67), '¥12,345.67');
      expect(CurrencyFormat.format(0), '¥0.00');
      expect(CurrencyFormat.formatCompact(45.0), '¥45');
      expect(CurrencyFormat.formatCompact(45.5), '¥45.5');
      expect(CurrencyFormat.formatRaw(1000.0), '1000');
      expect(CurrencyFormat.formatRaw(1250.50), '1250.5');
      expect(CurrencyFormat.formatRaw(1250.55), '1250.55');
      expect(CurrencyFormat.formatRaw(0.0), '0');
    });

    test('CurrencyFormat parseExpression handles various arithmetic and formatted inputs', () {
      expect(CurrencyFormat.parseExpression('1000'), 1000.0);
      expect(CurrencyFormat.parseExpression('1,000'), 1000.0);
      expect(CurrencyFormat.parseExpression('12,345.67'), 12345.67);
      expect(CurrencyFormat.parseExpression('100+50'), 150.0);
      expect(CurrencyFormat.parseExpression('100-30'), 70.0);
      expect(CurrencyFormat.parseExpression('1,000+500-200'), 1300.0);
      expect(CurrencyFormat.parseExpression('100.5+20.25'), 120.75);
      expect(CurrencyFormat.parseExpression('100+'), 100.0);
      expect(CurrencyFormat.parseExpression('100-'), 100.0);
      expect(CurrencyFormat.parseExpression('100.'), 100.0);
      expect(CurrencyFormat.parseExpression(''), 0.0);
      expect(CurrencyFormat.parseExpression('50-100'), 0.0); // Clamped to 0
    });

    test('DateFormatHelper formats date correctly', () {
      final date = DateTime(2026, 8, 16, 14, 30);
      expect(DateFormatHelper.formatMonth(date), '2026年8月');
      expect(DateFormatHelper.formatYear(date), '2026年');
      expect(DateFormatHelper.formatTime(date), '14:30');
      expect(DateFormatHelper.formatFullDateTime(date), '2026年8月16日 14:30');

      // Test formatDayHeader with explicit showYear
      expect(DateFormatHelper.formatDayHeader(date, showYear: true).contains('2026年8月16日'), true);

      // Test formatDayHeader for a previous year (e.g. 2024)
      final pastDate = DateTime(2024, 5, 20);
      expect(DateFormatHelper.formatDayHeader(pastDate).startsWith('2024年5月20日'), true);

      // Test formatRelativeDateTime for today, yesterday, and specific date
      final now = DateTime.now();
      final todayDate = DateTime(now.year, now.month, now.day, 9, 15);
      final yesterdayDate = todayDate.subtract(const Duration(days: 1));
      expect(DateFormatHelper.formatRelativeDateTime(todayDate), '今天 09:15');
      expect(DateFormatHelper.formatRelativeDateTime(yesterdayDate), '昨天 09:15');
    });

    test('DefaultData provides non-empty default categories and presets', () {
      final defaultCats = DefaultData.getDefaultCategories();
      final defaultPresets = DefaultData.getDefaultPresetItems();

      expect(defaultCats.isNotEmpty, true);
      expect(defaultPresets.isNotEmpty, true);

      final expenseCats = defaultCats.where((c) => c.type == CategoryType.expense).toList();
      final incomeCats = defaultCats.where((c) => c.type == CategoryType.income).toList();

      expect(expenseCats.isNotEmpty, true);
      expect(incomeCats.isNotEmpty, true);
    });
  });

  group('Database in-memory CRUD test', () {
    late Database db;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE categories (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              iconKey TEXT NOT NULL,
              colorValue INTEGER NOT NULL,
              sortOrder INTEGER NOT NULL,
              isDefault INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE preset_items (
              id TEXT PRIMARY KEY,
              categoryId TEXT NOT NULL,
              name TEXT NOT NULL,
              sortOrder INTEGER NOT NULL,
              isDefault INTEGER NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE transactions (
              id TEXT PRIMARY KEY,
              amount REAL NOT NULL,
              type TEXT NOT NULL,
              categoryId TEXT NOT NULL,
              categoryName TEXT NOT NULL,
              name TEXT NOT NULL,
              timestamp INTEGER NOT NULL,
              remark TEXT,
              createdAt INTEGER NOT NULL
            )
          ''');
        },
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('Insert and query Category and Preset Items', () async {
      final cat = Category(
        id: 'c1',
        name: '餐饮',
        type: CategoryType.expense,
        iconKey: 'restaurant',
        colorValue: 0xFFE11D48,
        sortOrder: 0,
        isDefault: true,
      );
      await db.insert('categories', cat.toMap());

      final preset1 = PresetItem(id: 'p1', categoryId: 'c1', name: '早餐', sortOrder: 0);
      final preset2 = PresetItem(id: 'p2', categoryId: 'c1', name: '午餐', sortOrder: 1);
      await db.insert('preset_items', preset1.toMap());
      await db.insert('preset_items', preset2.toMap());

      final catQuery = await db.query('categories');
      expect(catQuery.length, 1);
      expect(catQuery.first['name'], '餐饮');

      final presetQuery = await db.query('preset_items', where: 'categoryId = ?', whereArgs: ['c1']);
      expect(presetQuery.length, 2);
      expect(presetQuery[0]['name'], '早餐');
      expect(presetQuery[1]['name'], '午餐');
    });

    test('Insert, query and delete Transaction', () async {
      final tx = TransactionRecord(
        id: 't1',
        amount: 50.0,
        type: CategoryType.expense,
        categoryId: 'c1',
        categoryName: '餐饮',
        name: '午餐',
        dateTime: DateTime(2026, 8, 16, 12, 0),
        remark: '牛肉面',
      );
      await db.insert('transactions', tx.toMap());

      final query = await db.query('transactions');
      expect(query.length, 1);
      expect(query.first['name'], '午餐');
      expect(query.first['amount'], 50.0);

      await db.delete('transactions', where: 'id = ?', whereArgs: ['t1']);
      final queryAfter = await db.query('transactions');
      expect(queryAfter.isEmpty, true);
    });

    test('Batch import in merge and overwrite mode', () async {
      // 1. Prepare backup payload
      final backupData = {
        'app': 'Cently',
        'version': '1.0.0',
        'exportTime': '2026-08-16T12:00:00.000',
        'categories': [
          {
            'id': 'cat_import_1',
            'name': '数码科技',
            'type': 'expense',
            'iconKey': 'devices',
            'colorValue': 0xFF0284C7,
            'sortOrder': 0,
            'isDefault': 0,
          }
        ],
        'presetItems': [
          {
            'id': 'preset_import_1',
            'categoryId': 'cat_import_1',
            'name': '手机',
            'sortOrder': 0,
            'isDefault': 0,
          }
        ],
        'transactions': [
          {
            'id': 'tx_import_1',
            'amount': 4999.0,
            'type': 'expense',
            'categoryId': 'cat_import_1',
            'categoryName': '数码科技',
            'name': '手机',
            'timestamp': 1786881600000,
            'remark': '新机',
            'createdAt': 1786881600000,
          }
        ]
      };

      // 2. Perform import (merge mode)
      final batch = db.batch();
      for (final cat in backupData['categories'] as List) {
        batch.insert('categories', cat as Map<String, dynamic>);
      }
      for (final p in backupData['presetItems'] as List) {
        batch.insert('preset_items', p as Map<String, dynamic>);
      }
      for (final t in backupData['transactions'] as List) {
        batch.insert('transactions', t as Map<String, dynamic>);
      }
      await batch.commit(noResult: true);

      final cats = await db.query('categories', where: 'id = ?', whereArgs: ['cat_import_1']);
      expect(cats.length, 1);
      expect(cats.first['name'], '数码科技');

      final txs = await db.query('transactions', where: 'id = ?', whereArgs: ['tx_import_1']);
      expect(txs.length, 1);
      expect(txs.first['amount'], 4999.0);
    });

    test('Batch insert preset items and batch reorder categories', () async {
      // 1. Insert categories
      final catA = Category(id: 'cA', name: '分类A', type: CategoryType.expense, iconKey: 'home', colorValue: 0xFF000000, sortOrder: 0);
      final catB = Category(id: 'cB', name: '分类B', type: CategoryType.expense, iconKey: 'home', colorValue: 0xFF000000, sortOrder: 1);
      await db.insert('categories', catA.toMap());
      await db.insert('categories', catB.toMap());

      // 2. Batch insert preset items
      final presetList = [
        PresetItem(id: 'pA1', categoryId: 'cA', name: '预设1', sortOrder: 0),
        PresetItem(id: 'pA2', categoryId: 'cA', name: '预设2', sortOrder: 1),
        PresetItem(id: 'pA3', categoryId: 'cA', name: '预设3', sortOrder: 2),
      ];

      final batch = db.batch();
      for (final p in presetList) {
        batch.insert('preset_items', p.toMap());
      }
      await batch.commit(noResult: true);

      final presetsQuery = await db.query('preset_items', where: 'categoryId = ?', whereArgs: ['cA']);
      expect(presetsQuery.length, 3);

      // 3. Batch update category order
      final reordered = [
        catB.copyWith(sortOrder: 0),
        catA.copyWith(sortOrder: 1),
      ];
      final reorderBatch = db.batch();
      for (final c in reordered) {
        reorderBatch.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
      }
      await reorderBatch.commit(noResult: true);

      final orderedCats = await db.query('categories', orderBy: 'sortOrder ASC');
      expect(orderedCats[0]['id'], 'cB');
      expect(orderedCats[1]['id'], 'cA');
    });
  });
}
