import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/category_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../category_manage/category_manage_screen.dart';
import 'data_backup_screen.dart';
import 'recycle_bin_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _confirmClearData(BuildContext context, TransactionProvider txProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空所有记账记录？'),
        content: const Text('此操作将永久清空本地所有已记录的账单流水。分类和预设名称不会被删除。此操作不可恢复！'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(ctx);
              await txProvider.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('已清空所有记账记录')),
                );
              }
            },
            child: const Text('确认清空'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.spa_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('关于 分厘'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '「分厘」取意自“差之毫厘，失之千里”与“积少成多”。\n\n'
              '分厘 是一款专注于极简、纯粹与高效的无后端本地记账应用。\n\n'
              '• 100% 本地安全：数据纯本地离线保存，零云端上传，零隐私泄露。\n'
              '• 预设与自由并存：内置丰富的日常分类与项目预设，支持一键点选与自由输入。\n'
              '• 极速计算键盘：让每一笔记录都轻快自然。',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('好的'),
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
    final txProvider = Provider.of<TransactionProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置与管理'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // App Logo / Philosophy Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      '厘',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cently · 分厘',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '无后端 · 纯本地 · 极简记账',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.income.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '离线安全',
                    style: TextStyle(fontSize: 11, color: AppColors.income, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Core Management Section
          _buildSectionHeader('管理配置', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.category_outlined),
                title: const Text('类型与名称管理'),
                subtitle: Text('共 ${catProvider.categories.length} 个分类，管理分类与专属预设名称'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CategoryManageScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Appearance Section
          _buildSectionHeader('外观', isDark),
          _buildCard(
            isDark,
            children: [
              _buildThemeModeTile(
                context,
                title: '跟随系统',
                subtitle: '自动适配系统的深浅色模式',
                icon: Icons.brightness_auto_outlined,
                mode: ThemeMode.system,
                current: settingsProvider.themeMode,
                isDark: isDark,
              ),
              const Divider(),
              _buildThemeModeTile(
                context,
                title: '浅色模式',
                subtitle: '始终使用浅色主题',
                icon: Icons.light_mode_outlined,
                mode: ThemeMode.light,
                current: settingsProvider.themeMode,
                isDark: isDark,
              ),
              const Divider(),
              _buildThemeModeTile(
                context,
                title: '深色模式',
                subtitle: '始终使用深色主题',
                icon: Icons.dark_mode_outlined,
                mode: ThemeMode.dark,
                current: settingsProvider.themeMode,
                isDark: isDark,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Data Management Section
          _buildSectionHeader('数据管理与备份', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.auto_delete_outlined),
                title: const Text('账单回收站'),
                subtitle: Text(
                  txProvider.deletedCount > 0
                      ? '共 ${txProvider.deletedCount} 笔已删除账单 · 30天内可找回'
                      : '30天内已删除记录可找回',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (txProvider.deletedCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: AppColors.income.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${txProvider.deletedCount}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.income,
                          ),
                        ),
                      ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
                onTap: () => RecycleBinScreen.show(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_upload_outlined),
                title: const Text('数据导出与备份'),
                subtitle: const Text('导出完整 JSON 备份或 Excel CSV 明细'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => DataBackupScreen.show(context, initialTabIndex: 0),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cloud_download_outlined),
                title: const Text('数据导入与恢复'),
                subtitle: const Text('支持合并导入或覆盖还原数据'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => DataBackupScreen.show(context, initialTabIndex: 1),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.expense),
                title: const Text('清空所有记账记录', style: TextStyle(color: AppColors.expense)),
                subtitle: const Text('重置账单流水，保留分类与预设配置'),
                onTap: () => _confirmClearData(context, txProvider),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // About Section
          _buildSectionHeader('关于应用', isDark),
          _buildCard(
            isDark,
            children: [
              ListTile(
                leading: const Icon(Icons.info_outline_rounded),
                title: const Text('关于 分厘'),
                subtitle: const Text('版本 1.0.4 · 本地安全存储'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showAboutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildThemeModeTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required ThemeMode mode,
    required ThemeMode current,
    required bool isDark,
  }) {
    final isSelected = current == mode;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check_circle_rounded,
              size: 20,
              color: isDark ? AppColors.textPrimaryDark : AppColors.primary,
            )
          : null,
      onTap: () {
        Provider.of<SettingsProvider>(context, listen: false).setThemeMode(mode);
      },
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCard(bool isDark, {required List<Widget> children}) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }
}
