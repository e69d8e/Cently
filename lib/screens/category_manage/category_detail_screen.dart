import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/preset_item.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/category_icon_widget.dart';
import 'edit_category_dialog.dart';

class CategoryDetailScreen extends StatefulWidget {
  final Category category;

  const CategoryDetailScreen({super.key, required this.category});

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  final TextEditingController _newPresetController = TextEditingController();

  @override
  void dispose() {
    _newPresetController.dispose();
    super.dispose();
  }

  void _showAddPresetDialog(BuildContext context, CategoryProvider provider) {
    _newPresetController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加预设名称'),
        content: TextField(
          controller: _newPresetController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '如：下午茶、加油费、房租',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = _newPresetController.text.trim();
              if (name.isNotEmpty) {
                await provider.addPresetItem(
                  categoryId: widget.category.id,
                  name: name,
                );
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  void _showEditPresetDialog(
    BuildContext context,
    CategoryProvider provider,
    PresetItem item,
  ) {
    final controller = TextEditingController(text: item.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改预设名称'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                await provider.updatePresetItem(item.copyWith(name: name));
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CategoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除分类 "${widget.category.name}"？'),
        content: const Text('删除该分类将同时移除其下的所有预设名称。历史记账数据仍会保留原分类文字。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              await provider.deleteCategory(widget.category.id);
              if (ctx.mounted) {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Close detail screen
              }
            },
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catProvider = Provider.of<CategoryProvider>(context);
    final currentCat = catProvider.getCategoryById(widget.category.id) ?? widget.category;
    final presets = catProvider.getPresetsForCategory(currentCat.id);

    return Scaffold(
      appBar: AppBar(
        title: Text(currentCat.name),
        actions: [
          IconButton(
            tooltip: '编辑分类属性',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              EditCategoryDialog.show(
                context,
                defaultType: currentCat.type,
                category: currentCat,
              );
            },
          ),
          IconButton(
            tooltip: '删除分类',
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
            onPressed: () => _confirmDeleteCategory(context, catProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category Banner Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                CategoryIconWidget(
                  iconKey: currentCat.iconKey,
                  color: currentCat.color,
                  size: 48,
                  iconSize: 24,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentCat.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${currentCat.type.displayName} · ${presets.length} 个预设名称',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _showAddPresetDialog(context, catProvider),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('加名称'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '预设名称列表 (可拖拽排序)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                Text(
                  '长按可拖动排序',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Reorderable Preset List
          Expanded(
            child: presets.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.label_off_outlined, size: 40, color: AppColors.textTertiary),
                        const SizedBox(height: 12),
                        const Text('暂无预设名称'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => _showAddPresetDialog(context, catProvider),
                          child: const Text('立即添加'),
                        ),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    itemCount: presets.length,
                    onReorderItem: (oldIndex, newIndex) {
                      catProvider.reorderPresetItems(
                        currentCat.id,
                        oldIndex,
                        newIndex,
                      );
                    },
                    itemBuilder: (context, index) {
                      final item = presets[index];
                      return Container(
                        key: ValueKey(item.id),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? AppColors.borderDark : AppColors.borderLight,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: currentCat.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: currentCat.color,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showEditPresetDialog(context, catProvider, item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.expense),
                                  onPressed: () {
                                    catProvider.deletePresetItem(currentCat.id, item.id);
                                  },
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.drag_handle_rounded, size: 20, color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
