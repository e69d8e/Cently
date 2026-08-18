import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import '../../providers/category_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_format_helper.dart';
import '../../widgets/category_icon_widget.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/month_picker_dialog.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    final txProvider = Provider.of<TransactionProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () async {
            final picked = await MonthPickerDialog.show(context, txProvider.selectedMonth);
            if (picked != null) {
              await txProvider.setMonth(picked);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormatHelper.formatMonth(txProvider.selectedMonth),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              ],
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400, fontSize: 15),
          tabs: const [
            Tab(text: '支出分析'),
            Tab(text: '收入分析'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildStatsView(CategoryType.expense),
          _buildStatsView(CategoryType.income),
        ],
      ),
    );
  }

  Widget _buildStatsView(CategoryType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final txProvider = Provider.of<TransactionProvider>(context);
    final catProvider = Provider.of<CategoryProvider>(context);

    final stats = txProvider.getCategoryStats(type);
    final topItems = txProvider.getTopItemStats(type);
    final totalAmount = type == CategoryType.expense
        ? txProvider.totalExpense
        : txProvider.totalIncome;

    if (stats.isEmpty || totalAmount <= 0) {
      return EmptyState(
        title: '暂无${type.displayName}数据',
        subtitle: '本月还没有${type.displayName}记录',
        icon: Icons.pie_chart_outline_rounded,
      );
    }

    final daysInMonth = DateUtils.getDaysInMonth(
      txProvider.selectedMonth.year,
      txProvider.selectedMonth.month,
    );
    final dailyAvg = totalAmount / daysInMonth;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // Total summary banner
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本月总${type.displayName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormat.format(totalAmount),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: type == CategoryType.expense
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                          : AppColors.income,
                    ),
                  ),
                ],
              ),
              if (type == CategoryType.expense)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '日均支出',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyFormat.format(dailyAvg),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Category Breakdown Section
        Text(
          '分类占比排行',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Visual Proportion Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SizedBox(
                  height: 12,
                  child: Row(
                    children: stats.map((item) {
                      final cat = catProvider.getCategoryById(item.categoryId);
                      final color = cat?.color ?? AppColors.primary;
                      return Expanded(
                        flex: (item.percentage * 1000).toInt().clamp(1, 1000),
                        child: Container(color: color),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown List
              ...stats.map((item) {
                final cat = catProvider.getCategoryById(item.categoryId);
                final color = cat?.color ?? AppColors.primary;
                final percentStr = (item.percentage * 100).toStringAsFixed(1);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      CategoryIconWidget(
                        iconKey: cat?.iconKey ?? 'category',
                        color: color,
                        size: 32,
                        iconSize: 16,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  item.categoryName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  CurrencyFormat.format(item.amount),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item.count} 笔记录',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiary,
                                  ),
                                ),
                                Text(
                                  '$percentStr%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: color,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),

        if (topItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            '高频项目名称排行',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
                width: 1,
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topItems.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, idx) {
                final item = topItems[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: idx < 3
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: idx < 3 ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${item.categoryName} · 共 ${item.count} 次',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        CurrencyFormat.format(item.amount),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
