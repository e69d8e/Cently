import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../models/transaction_record.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_format_helper.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/empty_state.dart';

class RecycleBinScreen extends StatefulWidget {
  const RecycleBinScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RecycleBinScreen(),
      ),
    );
  }

  @override
  State<RecycleBinScreen> createState() => _RecycleBinScreenState();
}

class _RecycleBinScreenState extends State<RecycleBinScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<TransactionProvider>(context, listen: false).loadRecycleBin();
    });
  }

  void _confirmRestoreAll(BuildContext context, TransactionProvider txProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore_from_trash_rounded, color: AppColors.income),
            SizedBox(width: 8),
            Text('找回所有账单？'),
          ],
        ),
        content: Text(
          '确认找回回收站中的全部 ${txProvider.deletedCount} 笔账单记录？找回后将重新计入您的收支明细中。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.income),
            onPressed: () async {
              Navigator.pop(ctx);
              await txProvider.restoreAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已找回所有账单记录'),
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            },
            child: const Text('全部找回'),
          ),
        ],
      ),
    );
  }

  void _confirmEmptyBin(BuildContext context, TransactionProvider txProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: AppColors.expense),
            SizedBox(width: 8),
            Text('清空回收站？'),
          ],
        ),
        content: Text(
          '此操作将永久彻底删除回收站内的全部 ${txProvider.deletedCount} 笔账单。此操作不可撤销，数据将无法找回！',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(ctx);
              await txProvider.emptyRecycleBin();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('回收站已清空'),
                    duration: Duration(milliseconds: 1500),
                  ),
                );
              }
            },
            child: const Text('彻底清空'),
          ),
        ],
      ),
    );
  }

  void _confirmPermanentlyDelete(
    BuildContext context,
    TransactionProvider txProvider,
    TransactionRecord record,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('彻底删除此笔记录？'),
        content: Text(
          '确认永久删除「${record.name}」¥${CurrencyFormat.format(record.amount, showSymbol: false)} 的账单？永久删除后将无法找回。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () async {
              Navigator.pop(ctx);
              await txProvider.permanentlyDeleteTransaction(record.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已彻底删除「${record.name}」'),
                    duration: const Duration(milliseconds: 1500),
                  ),
                );
              }
            },
            child: const Text('彻底删除'),
          ),
        ],
      ),
    );
  }

  void _showRecordDetails(
    BuildContext context,
    TransactionRecord record,
    Category? cat,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpense = record.type == CategoryType.expense;
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final remaining = record.remainingDays;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header with Category Icon & Name
              Row(
                children: [
                  CategoryIconWidget(
                    iconKey: cat?.iconKey ?? 'category',
                    color: cat?.color ?? (isExpense ? AppColors.expense : AppColors.income),
                    size: 48,
                    iconSize: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${record.type.displayName} · ${record.categoryName}',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isExpense ? '-' : '+'}${CurrencyFormat.format(record.amount)}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isExpense ? AppColors.expense : AppColors.income,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),

              // Retention Tag Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: remaining <= 3
                      ? AppColors.expense.withValues(alpha: 0.1)
                      : AppColors.income.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      remaining <= 3 ? Icons.alarm_rounded : Icons.auto_delete_outlined,
                      size: 18,
                      color: remaining <= 3 ? AppColors.expense : AppColors.income,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        remaining == 0
                            ? '保留期今日到期，即将自动彻底清除'
                            : '回收站将保留此记录，剩余 $remaining 天',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: remaining <= 3 ? AppColors.expense : AppColors.income,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Details
              _buildDetailRow(
                '记录时间',
                '${DateFormatHelper.formatDayHeader(record.dateTime)} ${DateFormatHelper.formatTime(record.dateTime)}',
                isDark,
              ),
              if (record.deletedAt != null) ...[
                const SizedBox(height: 10),
                _buildDetailRow(
                  '删除时间',
                  '${DateFormatHelper.formatDayHeader(record.deletedAt!)} ${DateFormatHelper.formatTime(record.deletedAt!)}',
                  isDark,
                ),
              ],
              if (record.remark != null && record.remark!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildDetailRow('备注信息', record.remark!, isDark),
              ],

              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.expense,
                        side: const BorderSide(color: AppColors.expense),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.delete_forever_rounded, size: 18),
                      label: const Text('彻底删除'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _confirmPermanentlyDelete(context, txProvider, record);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.income,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.restore_from_trash_rounded, size: 18),
                      label: const Text('找回账单'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await txProvider.restoreTransaction(record.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('已找回「${record.name}」'),
                              duration: const Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);
    final deletedRecords = txProvider.deletedRecords;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          deletedRecords.isEmpty ? '账单回收站' : '账单回收站 (${deletedRecords.length})',
        ),
        actions: [
          if (deletedRecords.isNotEmpty) ...[
            TextButton.icon(
              icon: const Icon(Icons.restore_from_trash_rounded, size: 16),
              label: const Text('全部找回'),
              style: TextButton.styleFrom(foregroundColor: AppColors.income),
              onPressed: () => _confirmRestoreAll(context, txProvider),
            ),
            IconButton(
              tooltip: '清空回收站',
              icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.expense),
              onPressed: () => _confirmEmptyBin(context, txProvider),
            ),
          ],
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => txProvider.loadRecycleBin(),
        child: deletedRecords.isEmpty
            ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: const EmptyState(
                    icon: Icons.delete_outline_rounded,
                    title: '回收站为空',
                    subtitle: '删除的记账记录将在此处保留 30 天\n随时可以找回或彻底删除',
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                children: [
                  // Top policy info banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.surfaceMutedLight,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.borderLight,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '已删除账单在回收站中保留 30 天，超期将自动彻底清理。',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // List of Deleted Records
                  ...deletedRecords.map((record) {
                    final cat = catProvider.getCategoryById(record.categoryId);
                    final isExpense = record.type == CategoryType.expense;
                    final remaining = record.remainingDays;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _showRecordDetails(context, record, cat),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              CategoryIconWidget(
                                iconKey: cat?.iconKey ?? 'category',
                                color: cat?.color ?? (isExpense ? AppColors.expense : AppColors.income),
                                size: 40,
                                iconSize: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            record.name,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: remaining <= 3
                                                ? AppColors.expense.withValues(alpha: 0.12)
                                                : isDark
                                                    ? AppColors.surfaceMutedDark
                                                    : AppColors.surfaceMutedLight,
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            remaining == 0 ? '今日到期' : '剩 $remaining 天',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: remaining <= 3
                                                  ? AppColors.expense
                                                  : (isDark
                                                      ? AppColors.textSecondaryDark
                                                      : AppColors.textSecondary),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${DateFormatHelper.formatRelativeDateTime(record.dateTime)} · ${record.categoryName}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textTertiaryDark
                                            : AppColors.textTertiary,
                                      ),
                                    ),
                                    if (record.remark != null && record.remark!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        record.remark!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isExpense ? '-' : '+'}${CurrencyFormat.format(record.amount)}',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isExpense ? AppColors.expense : AppColors.income,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Restore button
                                      IconButton(
                                        tooltip: '找回账单',
                                        icon: const Icon(
                                          Icons.restore_from_trash_rounded,
                                          size: 18,
                                          color: AppColors.income,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onPressed: () async {
                                          await txProvider.restoreTransaction(record.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('已找回「${record.name}」'),
                                                duration: const Duration(milliseconds: 1500),
                                              ),
                                            );
                                          }
                                        },
                                      ),
                                      const SizedBox(width: 4),
                                      // Permanent delete button
                                      IconButton(
                                        tooltip: '彻底删除',
                                        icon: const Icon(
                                          Icons.delete_forever_rounded,
                                          size: 18,
                                          color: AppColors.expense,
                                        ),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                        onPressed: () => _confirmPermanentlyDelete(
                                          context,
                                          txProvider,
                                          record,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}
