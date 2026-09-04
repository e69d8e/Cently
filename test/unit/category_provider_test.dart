import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:cently/data/database_helper.dart';
import 'package:cently/models/category.dart';
import 'package:cently/providers/category_provider.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('CategoryProvider Unit & Integration Tests', () {
    late Database db;
    late CategoryProvider provider;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 5,
        onCreate: (db, version) async {
          await DatabaseHelper.instance.createDBForTesting(db);
        },
      );
      DatabaseHelper.setDatabaseForTesting(db);
      provider = CategoryProvider();
      await provider.loadData();
    });

    tearDown(() async {
      DatabaseHelper.setDatabaseForTesting(null);
      await db.close();
    });

    test('Initial loading populates categories and typed caches', () {
      expect(provider.categories.isNotEmpty, true);
      expect(provider.expenseCategories.isNotEmpty, true);
      expect(provider.incomeCategories.isNotEmpty, true);

      // Verify category lookup by id
      final firstCat = provider.categories.first;
      expect(provider.getCategoryById(firstCat.id), isNotNull);
      expect(provider.getCategoryById(firstCat.id)?.name, firstCat.name);
      expect(provider.getCategoryById('non_existent_id'), isNull);
    });

    test('addCategory adds category with initial presets and updates caches', () async {
      final initialCount = provider.categories.length;
      await provider.addCategory(
        name: '数字科技',
        type: CategoryType.expense,
        iconKey: 'devices',
        colorValue: 0xFF0284C7,
        initialPresetNames: ['云服务器', '电子书', '外设键盘'],
      );

      expect(provider.categories.length, initialCount + 1);

      final added = provider.categories.firstWhere((c) => c.name == '数字科技');
      expect(added.type, CategoryType.expense);
      expect(added.iconKey, 'devices');

      // Verify O(1) map cache is updated
      expect(provider.getCategoryById(added.id), isNotNull);
      expect(provider.expenseCategories.any((c) => c.id == added.id), true);

      // Verify presets were created and mapped
      final presets = provider.getPresetsForCategory(added.id);
      expect(presets.length, 3);
      expect(presets.map((p) => p.name).toList(), ['云服务器', '电子书', '外设键盘']);
    });

    test('updateCategory updates in-memory and mapped state', () async {
      final firstCat = provider.categories.first;
      final updated = firstCat.copyWith(name: '修改后的名称', colorValue: 0xFF10B981);

      await provider.updateCategory(updated);

      expect(provider.getCategoryById(firstCat.id)?.name, '修改后的名称');
      expect(provider.getCategoryById(firstCat.id)?.colorValue, 0xFF10B981);
    });

    test('deleteCategory deletes category and cascades presets removal', () async {
      await provider.addCategory(
        name: '待删分类',
        type: CategoryType.expense,
        iconKey: 'delete',
        colorValue: 0xFF999999,
        initialPresetNames: ['测试预设1', '测试预设2'],
      );

      final toDelete = provider.categories.firstWhere((c) => c.name == '待删分类');
      expect(provider.getPresetsForCategory(toDelete.id).length, 2);

      final success = await provider.deleteCategory(toDelete.id);
      expect(success, true);
      expect(provider.getCategoryById(toDelete.id), isNull);
      expect(provider.getPresetsForCategory(toDelete.id), isEmpty);
    });

    test('PresetItem operations: add, update, delete, reorder', () async {
      final cat = provider.expenseCategories.first;
      final initialPresets = provider.getPresetsForCategory(cat.id);
      final initialCount = initialPresets.length;

      // 1. Add preset
      await provider.addPresetItem(categoryId: cat.id, name: '新增预设A');
      var presets = provider.getPresetsForCategory(cat.id);
      expect(presets.length, initialCount + 1);
      final addedItem = presets.firstWhere((p) => p.name == '新增预设A');

      // 2. Update preset
      await provider.updatePresetItem(addedItem.copyWith(name: '更新预设A+'));
      presets = provider.getPresetsForCategory(cat.id);
      expect(presets.any((p) => p.name == '更新预设A+'), true);

      // 3. Delete preset
      await provider.deletePresetItem(cat.id, addedItem.id);
      presets = provider.getPresetsForCategory(cat.id);
      expect(presets.length, initialCount);
    });

    test('reorderCategories updates order properly', () async {
      final initialExpense = List<Category>.from(provider.expenseCategories);
      if (initialExpense.length >= 2) {
        final first = initialExpense[0];
        final second = initialExpense[1];

        // Move first item to index 1
        await provider.reorderCategories(CategoryType.expense, 0, 2);

        final newExpense = provider.expenseCategories;
        expect(newExpense[0].id, second.id);
        expect(newExpense[1].id, first.id);
      }
    });

    test('resetToDefault restores original state', () async {
      // Add custom category
      await provider.addCategory(
        name: '临时分类',
        type: CategoryType.income,
        iconKey: 'wallet',
        colorValue: 0xFF123456,
      );
      expect(provider.categories.any((c) => c.name == '临时分类'), true);

      // Reset to defaults
      await provider.resetToDefault();
      expect(provider.categories.any((c) => c.name == '临时分类'), false);
      expect(provider.categories.isNotEmpty, true);
    });
  });
}
