import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/color_picker_widget.dart';
import '../../widgets/icon_picker_widget.dart';

class EditCategoryDialog extends StatefulWidget {
  final CategoryType defaultType;
  final Category? category; // If editing

  const EditCategoryDialog({
    super.key,
    required this.defaultType,
    this.category,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CategoryType defaultType,
    Category? category,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditCategoryDialog(
        defaultType: defaultType,
        category: category,
      ),
    );
  }

  @override
  State<EditCategoryDialog> createState() => _EditCategoryDialogState();
}

class _EditCategoryDialogState extends State<EditCategoryDialog> {
  late TextEditingController _nameController;
  late TextEditingController _presetsController;
  late String _selectedIconKey;
  late int _selectedColorValue;
  late CategoryType _type;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    if (cat != null) {
      _nameController = TextEditingController(text: cat.name);
      _presetsController = TextEditingController();
      _selectedIconKey = cat.iconKey;
      _selectedColorValue = cat.colorValue;
      _type = cat.type;
    } else {
      _nameController = TextEditingController();
      _presetsController = TextEditingController();
      _selectedIconKey = 'category';
      _selectedColorValue = AppColors.categoryPalette.first.toARGB32();
      _type = widget.defaultType;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _presetsController.dispose();
    super.dispose();
  }

  void _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入分类名称')),
      );
      return;
    }

    final catProvider = Provider.of<CategoryProvider>(context, listen: false);

    if (widget.category != null) {
      final updated = widget.category!.copyWith(
        name: name,
        iconKey: _selectedIconKey,
        colorValue: _selectedColorValue,
        type: _type,
      );
      await catProvider.updateCategory(updated);
    } else {
      List<String>? initialPresets;
      final presetsText = _presetsController.text.trim();
      if (presetsText.isNotEmpty) {
        initialPresets = presetsText
            .split(RegExp(r'[,，\s]+'))
            .where((s) => s.trim().isNotEmpty)
            .toList();
      }

      await catProvider.addCategory(
        name: name,
        type: _type,
        iconKey: _selectedIconKey,
        colorValue: _selectedColorValue,
        initialPresetNames: initialPresets,
      );
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEditing = widget.category != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEditing ? '编辑分类' : '新建${_type.displayName}分类',
                  style: theme.textTheme.titleLarge,
                ),
                TextButton(
                  onPressed: _save,
                  child: const Text('保存', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category Name Input
            TextField(
              controller: _nameController,
              autofocus: !isEditing,
              decoration: InputDecoration(
                labelText: '分类名称',
                hintText: '如：餐饮、交通、数码',
                filled: true,
                fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            if (!isEditing) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _presetsController,
                decoration: InputDecoration(
                  labelText: '初始预设名称 (选填，空格或逗号分隔)',
                  hintText: '如：早餐 午餐 晚餐 咖啡',
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              '选择颜色',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            ColorPickerWidget(
              selectedColorValue: _selectedColorValue,
              onSelected: (colorVal) {
                setState(() {
                  _selectedColorValue = colorVal;
                });
              },
            ),

            const SizedBox(height: 16),
            Text(
              '选择图标',
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            IconPickerWidget(
              selectedIconKey: _selectedIconKey,
              onSelected: (iconKey) {
                setState(() {
                  _selectedIconKey = iconKey;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
