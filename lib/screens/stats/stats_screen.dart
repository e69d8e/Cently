import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../main_navigation_screen.dart';
import '../record/add_record_screen.dart';

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '上个月',
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: () {
                HapticFeedback.selectionClick();
                txProvider.previousMonth();
              },
            ),
            InkWell(
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
            IconButton(
              tooltip: '下个月',
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: () {
                HapticFeedback.selectionClick();
                txProvider.nextMonth();
              },
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: (_) => HapticFeedback.selectionClick(),
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
        action: FilledButton.icon(
          onPressed: () => AddRecordScreen.show(context),
          icon: const Icon(Icons.add),
          label: const Text('记一笔'),
        ),
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
        _StatsSummaryBanner(
          type: type,
          totalAmount: totalAmount,
          dailyAvg: dailyAvg,
          isDark: isDark,
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

        _CategoryBreakdownCard(
          stats: stats,
          catProvider: catProvider,
          totalAmount: totalAmount,
          type: type,
          isDark: isDark,
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

          _TopItemsCard(
            topItems: topItems,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

class _StatsSummaryBanner extends StatelessWidget {
  final CategoryType type;
  final double totalAmount;
  final double dailyAvg;
  final bool isDark;

  const _StatsSummaryBanner({
    required this.type,
    required this.totalAmount,
    required this.dailyAvg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
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
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: type == CategoryType.expense
                      ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                      : AppColors.income,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '日均${type.displayName}',
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
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}

class _CategoryBreakdownCard extends StatefulWidget {
  final List<CategoryStat> stats;
  final CategoryProvider catProvider;
  final double totalAmount;
  final CategoryType type;
  final bool isDark;

  const _CategoryBreakdownCard({
    required this.stats,
    required this.catProvider,
    required this.totalAmount,
    required this.type,
    required this.isDark,
  });

  @override
  State<_CategoryBreakdownCard> createState() => _CategoryBreakdownCardState();
}

class _CategoryBreakdownCardState extends State<_CategoryBreakdownCard> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (_touchedIndex >= widget.stats.length) {
      _touchedIndex = -1;
    }

    final isDark = widget.isDark;

    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          // Donut Pie Chart with center badge
          SizedBox(
            height: 190,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          return;
                        }
                        final index = pieTouchResponse
                            .touchedSection!.touchedSectionIndex;
                        if (index < 0 || index >= widget.stats.length) return;
                        if (event is FlTapUpEvent) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (_touchedIndex == index) {
                              _touchedIndex = -1;
                            } else {
                              _touchedIndex = index;
                            }
                          });
                        }
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: widget.stats.length > 1 ? 2.5 : 0,
                    centerSpaceRadius: 52,
                    sections: _buildPieSections(),
                  ),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                ),
                // Center Data Badge
                _buildCenterBadge(),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 8),

          // Breakdown List
          ...List.generate(widget.stats.length, (idx) {
            final item = widget.stats[idx];
            final cat = widget.catProvider.getCategoryById(item.categoryId);
            final color = cat?.color ?? AppColors.primary;
            final percentStr = (item.percentage * 100).toStringAsFixed(1);
            final isSelected = idx == _touchedIndex;

            final rankColor = idx == 0
                ? const Color(0xFFEAB308) // Gold
                : (idx == 1
                    ? const Color(0xFF94A3B8) // Silver
                    : (idx == 2 ? const Color(0xFFD97706) : Colors.transparent));
            final isTopThree = idx < 3;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Material(
                color: isSelected
                    ? color.withValues(alpha: isDark ? 0.18 : 0.08)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _touchedIndex = (_touchedIndex == idx ? -1 : idx);
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Rank Indicator
                        Container(
                          width: 24,
                          alignment: Alignment.center,
                          child: Text(
                            '#${idx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isTopThree ? FontWeight.w700 : FontWeight.w500,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: isTopThree
                                  ? rankColor
                                  : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        CategoryIconWidget(
                          iconKey: cat?.iconKey ?? 'category',
                          color: color,
                          size: 36,
                          iconSize: 18,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.categoryName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    CurrencyFormat.format(item.amount),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                      color: isSelected ? color : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${item.count} 笔记录',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                      color: isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiary,
                                    ),
                                  ),
                                  Text(
                                    '$percentStr%',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                      color: color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: item.percentage.clamp(0.0, 1.0),
                                  backgroundColor: isDark
                                      ? AppColors.surfaceMutedDark
                                      : AppColors.surfaceMutedLight,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    color,
                                  ),
                                  minHeight: 5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 13,
                            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                          ),
                          tooltip: '查看该分类明细',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            final txProvider = Provider.of<TransactionProvider>(context, listen: false);
                            txProvider.setFilterCategory(item.categoryId);
                            MainNavigationScreen.switchToTab(context, 0);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    ));
  }

  Widget _buildCenterBadge() {
    final isDark = widget.isDark;
    Widget content;

    if (_touchedIndex >= 0 && _touchedIndex < widget.stats.length) {
      final selected = widget.stats[_touchedIndex];
      final cat = widget.catProvider.getCategoryById(selected.categoryId);
      final color = cat?.color ?? AppColors.primary;
      final percentStr = (selected.percentage * 100).toStringAsFixed(1);

      content = Column(
        key: ValueKey('selected_${selected.categoryId}'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selected.categoryName,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            CurrencyFormat.format(selected.amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            '$percentStr%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ),
        ],
      );
    } else {
      content = Column(
        key: const ValueKey('total_badge'),
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '总${widget.type.displayName}',
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              CurrencyFormat.format(widget.totalAmount),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${widget.stats.length} 个分类',
            style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.textTertiaryDark
                  : AppColors.textTertiary,
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () {
        if (_touchedIndex != -1) {
          HapticFeedback.selectionClick();
          setState(() {
            _touchedIndex = -1;
          });
        }
      },
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: content,
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections() {
    return List.generate(widget.stats.length, (i) {
      final item = widget.stats[i];
      final isTouched = i == _touchedIndex;
      final cat = widget.catProvider.getCategoryById(item.categoryId);
      final color = cat?.color ?? AppColors.primary;

      final radius = isTouched ? 34.0 : 26.0;

      return PieChartSectionData(
        color: color,
        value: item.amount,
        title: '',
        showTitle: false,
        radius: radius,
      );
    });
  }
}

class _TopItemsCard extends StatelessWidget {
  final List<ItemStat> topItems;
  final bool isDark;

  const _TopItemsCard({
    required this.topItems,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            for (int idx = 0; idx < topItems.length; idx++) ...[
              if (idx > 0) const Divider(),
              _buildTopItemRow(context, topItems[idx], idx),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopItemRow(BuildContext context, ItemStat item, int idx) {
    final rankBg = idx == 0
        ? const Color(0xFFEAB308)
        : (idx == 1
            ? const Color(0xFF94A3B8)
            : (idx == 2 ? const Color(0xFFD97706) : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight)));
    final rankTextCol = idx < 3 ? Colors.white : AppColors.textSecondary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        // 跳转到「明细」Tab 并以项目名称发起搜索，快速回看该项目的每一笔记录
        final txProvider = Provider.of<TransactionProvider>(context, listen: false);
        txProvider.setFilterCategory(null);
        txProvider.setSearchQuery(item.name);
        MainNavigationScreen.switchToTab(context, 0);
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: rankBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${idx + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: rankTextCol,
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
                      fontFeatures: const [FontFeature.tabularFigures()],
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
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
