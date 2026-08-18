import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/empty_state.dart';
import 'category_detail_screen.dart';
import 'edit_category_dialog.dart';

class CategoryManageScreen extends StatefulWidget {
  const CategoryManageScreen({super.key});

  @override
  State<CategoryManageScreen> createState() => _CategoryManageScreenState();
}

class _CategoryManageScreenState extends State<CategoryManageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _confirmResetDefaults(BuildContext context, CategoryProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('恢复默认分类与预设？'),
        content: const Text('这将重置所有分类与预设名称为初始状态，您自己添加的自定义分类和名称会被重置。已有记账记录不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.resetToDefault();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已恢复默认分类与预设')),
                );
              }
            },
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catProvider = Provider.of<CategoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('类型与名称管理'),
        actions: [
          IconButton(
            tooltip: '恢复默认预设',
            icon: const Icon(Icons.restart_alt_rounded),
            onPressed: () => _confirmResetDefaults(context, catProvider),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
          tabs: const [
            Tab(text: '支出分类'),
            Tab(text: '收入分类'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildCategoryList(
            context,
            catProvider,
            catProvider.expenseCategories,
            CategoryType.expense,
            isDark,
          ),
          _buildCategoryList(
            context,
            catProvider,
            catProvider.incomeCategories,
            CategoryType.income,
            isDark,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'category_manage_add_fab',
        onPressed: () {
          final currentType = _tabController.index == 0
              ? CategoryType.expense
              : CategoryType.income;
          EditCategoryDialog.show(context, defaultType: currentType);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('添加分类'),
      ),
    );
  }

  Widget _buildCategoryList(
    BuildContext context,
    CategoryProvider provider,
    List<Category> categories,
    CategoryType type,
    bool isDark,
  ) {
    if (categories.isEmpty) {
      return EmptyState(
        title: '暂无${type.displayName}分类',
        subtitle: '点击右下角按钮添加新分类',
        icon: Icons.category_outlined,
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: categories.length,
      onReorderItem: (oldIndex, newIndex) {
        provider.reorderCategories(type, oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final cat = categories[index];
        final presets = provider.getPresetsForCategory(cat.id);

        return Container(
          key: ValueKey(cat.id),
          margin: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CategoryIconWidget(
                iconKey: cat.iconKey,
                color: cat.color,
                size: 42,
                iconSize: 22,
              ),
              title: Text(
                cat.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              subtitle: Text(
                '${presets.length} 个预设名称：${presets.take(3).map((p) => p.name).join('、')}${presets.length > 3 ? '...' : ''}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  const Icon(Icons.drag_handle_rounded, size: 20, color: AppColors.textTertiary),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryDetailScreen(category: cat),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
