import 'package:flutter/foundation.dart' hide Category;
import 'package:uuid/uuid.dart';

import '../data/database_helper.dart';
import '../models/category.dart';
import '../models/preset_item.dart';

class CategoryProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  List<Category> _categories = [];
  Map<String, List<PresetItem>> _presetItemsMap = {};
  bool _isLoading = true;

  List<Category> get categories => _categories;
  Map<String, List<PresetItem>> get presetItemsMap => _presetItemsMap;
  bool get isLoading => _isLoading;

  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == CategoryType.expense).toList();

  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == CategoryType.income).toList();

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _categories = await _db.getAllCategories();
      final allPresets = await _db.getAllPresetItems();

      _presetItemsMap = {};
      for (final item in allPresets) {
        if (!_presetItemsMap.containsKey(item.categoryId)) {
          _presetItemsMap[item.categoryId] = [];
        }
        _presetItemsMap[item.categoryId]!.add(item);
      }
    } catch (e) {
      debugPrint('Error loading category data: $e');
      _categories = [];
      _presetItemsMap = {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<PresetItem> getPresetsForCategory(String categoryId) {
    return _presetItemsMap[categoryId] ?? [];
  }

  Category? getCategoryById(String categoryId) {
    for (final c in _categories) {
      if (c.id == categoryId) return c;
    }
    return null;
  }

  // ================= CATEGORY OPERATIONS =================

  Future<void> addCategory({
    required String name,
    required CategoryType type,
    required String iconKey,
    required int colorValue,
    List<String>? initialPresetNames,
  }) async {
    final newId = 'cat_${_uuid.v4()}';
    final existingInType = _categories.where((c) => c.type == type).length;

    final category = Category(
      id: newId,
      name: name,
      type: type,
      iconKey: iconKey,
      colorValue: colorValue,
      sortOrder: existingInType,
      isDefault: false,
    );

    await _db.insertCategory(category);
    _categories.add(category);

    _presetItemsMap[newId] = [];
    if (initialPresetNames != null && initialPresetNames.isNotEmpty) {
      final presetsToAdd = <PresetItem>[];
      for (int i = 0; i < initialPresetNames.length; i++) {
        presetsToAdd.add(PresetItem(
          id: '${newId}_preset_${_uuid.v4()}',
          categoryId: newId,
          name: initialPresetNames[i],
          sortOrder: i,
          isDefault: false,
        ));
      }
      await _db.insertPresetItemsBatch(presetsToAdd);
      _presetItemsMap[newId]!.addAll(presetsToAdd);
    }

    notifyListeners();
  }

  Future<void> updateCategory(Category category) async {
    await _db.updateCategory(category);
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index != -1) {
      _categories[index] = category;
      notifyListeners();
    }
  }

  Future<bool> deleteCategory(String categoryId) async {
    await _db.deleteCategory(categoryId);
    _categories.removeWhere((c) => c.id == categoryId);
    _presetItemsMap.remove(categoryId);
    notifyListeners();
    return true;
  }

  Future<void> reorderCategories(CategoryType type, int oldIndex, int newIndex) async {
    final list = _categories.where((c) => c.type == type).toList();
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    final updatedList = <Category>[];
    for (int i = 0; i < list.length; i++) {
      updatedList.add(list[i].copyWith(sortOrder: i));
    }

    // Persist batch order update to database
    await _db.updateCategoriesOrder(updatedList);

    // Update in-memory state without needing an extra round-trip select query
    final otherTypeCategories = _categories.where((c) => c.type != type).toList();
    _categories = [...otherTypeCategories, ...updatedList]
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    notifyListeners();
  }

  // ================= PRESET ITEM OPERATIONS =================

  Future<void> addPresetItem({
    required String categoryId,
    required String name,
  }) async {
    final currentList = _presetItemsMap[categoryId] ?? [];
    final newId = '${categoryId}_preset_${_uuid.v4()}';
    final preset = PresetItem(
      id: newId,
      categoryId: categoryId,
      name: name.trim(),
      sortOrder: currentList.length,
      isDefault: false,
    );

    await _db.insertPresetItem(preset);
    if (!_presetItemsMap.containsKey(categoryId)) {
      _presetItemsMap[categoryId] = [];
    }
    _presetItemsMap[categoryId]!.add(preset);
    notifyListeners();
  }

  Future<void> updatePresetItem(PresetItem item) async {
    await _db.updatePresetItem(item);
    final list = _presetItemsMap[item.categoryId];
    if (list != null) {
      final index = list.indexWhere((p) => p.id == item.id);
      if (index != -1) {
        list[index] = item;
        notifyListeners();
      }
    }
  }

  Future<void> deletePresetItem(String categoryId, String presetId) async {
    await _db.deletePresetItem(presetId);
    _presetItemsMap[categoryId]?.removeWhere((p) => p.id == presetId);
    notifyListeners();
  }

  Future<void> reorderPresetItems(String categoryId, int oldIndex, int newIndex) async {
    final list = _presetItemsMap[categoryId];
    if (list == null) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);

    await _db.updatePresetItemsOrder(list);
    notifyListeners();
  }

  Future<void> resetToDefault() async {
    _isLoading = true;
    notifyListeners();

    await _db.resetCategoriesAndPresetsToDefault();
    await loadData();
  }
}
