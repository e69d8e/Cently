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
import '../../widgets/date_or_month_picker_sheet.dart';
import '../../widgets/empty_state.dart';
import '../record/add_record_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool?> _showDeleteConfirmDialog(BuildContext context, TransactionRecord record) {
    return showDialog<bool>(
      context: context,
      builder: (confirmCtx) => AlertDialog(
        title: const Text('删除此笔记录？'),
        content: Text('确认删除「${record.name}」¥${CurrencyFormat.format(record.amount, showSymbol: false)} 的记账记录？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(confirmCtx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.expense),
            onPressed: () => Navigator.pop(confirmCtx, true),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(BuildContext context, TransactionRecord record) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catProvider = Provider.of<CategoryProvider>(context, listen: false);
    final txProvider = Provider.of<TransactionProvider>(context, listen: false);
    final category = catProvider.getCategoryById(record.categoryId);
    final isExpense = record.type == CategoryType.expense;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                CategoryIconWidget(
                  iconKey: category?.iconKey ?? 'category',
                  color: category?.color ?? (isExpense ? AppColors.expense : AppColors.income),
                  size: 52,
                  iconSize: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.name,
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${record.type.displayName} · ${record.categoryName}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  '${isExpense ? '-' : '+'}${CurrencyFormat.format(record.amount)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isExpense ? AppColors.expense : AppColors.income,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 14),

            _buildDetailRow('记录时间', '${DateFormatHelper.formatDayHeader(record.dateTime)} ${DateFormatHelper.formatTime(record.dateTime)}', isDark),
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('删除'),
                    onPressed: () async {
                      final confirmed = await _showDeleteConfirmDialog(context, record);

                      if (confirmed == true && context.mounted) {
                        Navigator.pop(ctx);
                        await txProvider.deleteTransaction(record.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('已删除该笔记录'),
                              duration: Duration(milliseconds: 1500),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('编辑'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      AddRecordScreen.show(context, initialRecord: record);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
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

    final dailyGroups = txProvider.dailyGroupedRecords;
    final sortedDates = dailyGroups.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final result = await DateOrMonthPickerSheet.show(
              context,
              initialMonth: txProvider.selectedMonth,
              initialDay: txProvider.selectedDay,
              recordedDays: txProvider.recordedDaysInMonth,
            );
            if (result != null) {
              if (result.isDayMode) {
                await txProvider.selectDay(result.selectedDate);
              } else {
                await txProvider.setMonth(result.selectedDate);
              }
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    txProvider.isDayMode
                        ? DateFormatHelper.formatDayHeader(txProvider.selectedDay!, showYear: true)
                        : DateFormatHelper.formatMonth(txProvider.selectedMonth),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            tooltip: '搜索记录',
            icon: Icon(_isSearching ? Icons.close : Icons.search_rounded),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  txProvider.setSearchQuery('');
                }
              });
            },
          ),
          IconButton(
            tooltip: txProvider.isDayMode ? '前一天' : '上个月',
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => txProvider.previousPeriod(),
          ),
          IconButton(
            tooltip: txProvider.isDayMode ? '后一天' : '下个月',
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: () => txProvider.nextPeriod(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Input Bar (if open)
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: (val) => txProvider.setSearchQuery(val),
                decoration: InputDecoration(
                  hintText: '搜索分类、名称或备注...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

          // Day Mode Filter Banner (if filtered to specific day)
          if (txProvider.isDayMode)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_note_rounded, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '当前单日视图：${DateFormatHelper.formatDayHeader(txProvider.selectedDay!, showYear: true)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => txProvider.clearSelectedDay(),
                    borderRadius: BorderRadius.circular(8),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            '查看整月',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.close_rounded, size: 14, color: AppColors.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Monthly / Daily Summary Card
          _buildMonthlySummaryCard(txProvider, isDark),

          // Category Quick Filter Bar (if filtered)
          if (txProvider.filterCategoryId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceMutedLight,
              child: Row(
                children: [
                  const Text('已筛选分类', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      catProvider.getCategoryById(txProvider.filterCategoryId!)?.name ?? '分类',
                      style: const TextStyle(fontSize: 11),
                    ),
                    onDeleted: () => txProvider.setFilterCategory(null),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

          // Daily Grouped Transaction Records
          Expanded(
            child: txProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : sortedDates.isEmpty
                    ? EmptyState(
                        title: txProvider.isDayMode
                            ? '${DateFormatHelper.formatDayHeader(txProvider.selectedDay!, showYear: true)} 暂无记账'
                            : '${DateFormatHelper.formatMonth(txProvider.selectedMonth)} 暂无记账记录',
                        subtitle: '点击下方「记一笔」开启极简记账',
                        icon: Icons.receipt_long_outlined,
                        action: FilledButton.icon(
                          onPressed: () => AddRecordScreen.show(context),
                          icon: const Icon(Icons.add),
                          label: const Text('记一笔'),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: sortedDates.length,
                        itemBuilder: (context, dateIndex) {
                          final date = sortedDates[dateIndex];
                          final dayRecords = dailyGroups[date] ?? [];

                          final dayExpense = dayRecords
                              .where((r) => r.type == CategoryType.expense)
                              .fold(0.0, (sum, r) => sum + r.amount);
                          final dayIncome = dayRecords
                              .where((r) => r.type == CategoryType.income)
                              .fold(0.0, (sum, r) => sum + r.amount);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day Header
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormatHelper.formatDayHeader(date),
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          if (dayExpense > 0) ...[
                                            Text(
                                              '支 ${CurrencyFormat.formatCompact(dayExpense, showSymbol: false)}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isDark
                                                    ? AppColors.textSecondaryDark
                                                    : AppColors.textSecondary,
                                              ),
                                            ),
                                            if (dayIncome > 0) const SizedBox(width: 8),
                                          ],
                                          if (dayIncome > 0)
                                            Text(
                                              '收 ${CurrencyFormat.formatCompact(dayIncome, showSymbol: false)}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: AppColors.income,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(),

                                // List of records for this day
                                ...dayRecords.map((record) {
                                  final cat = catProvider.getCategoryById(record.categoryId);
                                  final isExpense = record.type == CategoryType.expense;

                                  return Dismissible(
                                    key: ValueKey(record.id),
                                    direction: DismissDirection.endToStart,
                                    background: Container(
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.only(right: 20),
                                      color: AppColors.expense,
                                      child: const Icon(Icons.delete_rounded, color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      final confirmed = await _showDeleteConfirmDialog(context, record);
                                      return confirmed == true;
                                    },
                                    onDismissed: (_) {
                                      txProvider.deleteTransaction(record.id);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('已删除该笔记录'),
                                          duration: Duration(milliseconds: 1500),
                                        ),
                                      );
                                    },
                                    child: InkWell(
                                      onTap: () => _showTransactionDetails(context, record),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        child: Row(
                                          children: [
                                            CategoryIconWidget(
                                              iconKey: cat?.iconKey ?? 'category',
                                              color: cat?.color ?? (isExpense ? AppColors.expense : AppColors.income),
                                              size: 38,
                                              iconSize: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                    children: [
                                                      Text(
                                                        record.name,
                                                        style: const TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 6),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                        decoration: BoxDecoration(
                                                          color: isDark
                                                              ? AppColors.surfaceMutedDark
                                                              : AppColors.surfaceMutedLight,
                                                          borderRadius: BorderRadius.circular(4),
                                                        ),
                                                        child: Text(
                                                          record.categoryName,
                                                          style: TextStyle(
                                                            fontSize: 10,
                                                            color: isDark
                                                                ? AppColors.textSecondaryDark
                                                                : AppColors.textSecondary,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  if (record.remark != null && record.remark!.isNotEmpty) ...[
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      record.remark!,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: isDark
                                                            ? AppColors.textTertiaryDark
                                                            : AppColors.textTertiary,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                Text(
                                                  '${isExpense ? '-' : '+'}${CurrencyFormat.format(record.amount)}',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: isExpense
                                                        ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                                                        : AppColors.income,
                                                  ),
                                                ),
                                                Text(
                                                  DateFormatHelper.formatTime(record.dateTime),
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark
                                                        ? AppColors.textTertiaryDark
                                                        : AppColors.textTertiary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlySummaryCard(TransactionProvider txProvider, bool isDark) {
    final isDay = txProvider.isDayMode;
    final expense = txProvider.currentViewExpense;
    final income = txProvider.currentViewIncome;
    final balance = txProvider.currentViewBalance;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Total Expense
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDay ? '当日支出 (元)' : '总支出 (元)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormat.format(expense, showSymbol: false),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Total Income
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDay ? '当日收入 (元)' : '总收入 (元)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormat.format(income, showSymbol: false),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.income,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Net Balance
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDay ? '当日结余 (元)' : '收支结余 (元)',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    CurrencyFormat.format(balance, showSymbol: false),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: balance >= 0
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                          : AppColors.expense,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
