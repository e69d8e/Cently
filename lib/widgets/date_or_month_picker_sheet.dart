import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class DatePickerResult {
  final DateTime selectedDate;
  final bool isDayMode; // true = specific day, false = whole month

  DatePickerResult({
    required this.selectedDate,
    required this.isDayMode,
  });
}

class DateOrMonthPickerSheet extends StatefulWidget {
  final DateTime initialMonth;
  final DateTime? initialDay;
  final Set<int> recordedDays;
  final ValueChanged<DatePickerResult> onSelected;

  const DateOrMonthPickerSheet({
    super.key,
    required this.initialMonth,
    this.initialDay,
    this.recordedDays = const {},
    required this.onSelected,
  });

  static Future<DatePickerResult?> show(
    BuildContext context, {
    required DateTime initialMonth,
    DateTime? initialDay,
    Set<int> recordedDays = const {},
  }) {
    return showModalBottomSheet<DatePickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DateOrMonthPickerSheet(
        initialMonth: initialMonth,
        initialDay: initialDay,
        recordedDays: recordedDays,
        onSelected: (result) => Navigator.pop(context, result),
      ),
    );
  }

  @override
  State<DateOrMonthPickerSheet> createState() => _DateOrMonthPickerSheetState();
}

class _DateOrMonthPickerSheetState extends State<DateOrMonthPickerSheet> {
  late int _displayYear;
  late int _displayMonth;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _displayYear = widget.initialMonth.year;
    _displayMonth = widget.initialMonth.month;
    _selectedDay = widget.initialDay;
  }

  void _previousMonth() {
    setState(() {
      if (_displayMonth == 1) {
        _displayYear -= 1;
        _displayMonth = 12;
      } else {
        _displayMonth -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_displayMonth == 12) {
        _displayYear += 1;
        _displayMonth = 1;
      } else {
        _displayMonth += 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final daysInMonth = DateUtils.getDaysInMonth(_displayYear, _displayMonth);
    final firstWeekday = DateTime(_displayYear, _displayMonth, 1).weekday; // 1 = Mon, 7 = Sun
    final leadingEmptyCount = firstWeekday - 1;

    final isViewingSameMonthAsInitial =
        _displayYear == widget.initialMonth.year && _displayMonth == widget.initialMonth.month;
    final activeRecordedDays = isViewingSameMonthAsInitial ? widget.recordedDays : <int>{};

    return SafeArea(
      child: Container(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 14,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

          // Month Switcher Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$_displayYear年 $_displayMonth月',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick Action Shortcuts Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    side: BorderSide(
                      color: widget.initialDay == null && isViewingSameMonthAsInitial
                          ? AppColors.primary
                          : (isDark ? AppColors.borderDark : AppColors.borderLight),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    widget.onSelected(DatePickerResult(
                      selectedDate: DateTime(_displayYear, _displayMonth),
                      isDayMode: false,
                    ));
                  },
                  child: Text(
                    _displayYear != now.year
                        ? '查看整月 ($_displayYear年$_displayMonth月)'
                        : '查看整月 ($_displayMonth月)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: widget.initialDay == null && isViewingSameMonthAsInitial
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  side: BorderSide(
                    color: _selectedDay != null &&
                            _selectedDay!.year == today.year &&
                            _selectedDay!.month == today.month &&
                            _selectedDay!.day == today.day
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  widget.onSelected(DatePickerResult(
                    selectedDate: today,
                    isDayMode: true,
                  ));
                },
                child: const Text('今天', style: TextStyle(fontSize: 12)),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  side: BorderSide(
                    color: _selectedDay != null &&
                            _selectedDay!.year == yesterday.year &&
                            _selectedDay!.month == yesterday.month &&
                            _selectedDay!.day == yesterday.day
                        ? AppColors.primary
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  widget.onSelected(DatePickerResult(
                    selectedDate: yesterday,
                    isDayMode: true,
                  ));
                },
                child: const Text('昨天', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Weekday header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['一', '二', '三', '四', '五', '六', '日'].map((w) {
              return Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 8),

          // Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.1,
            ),
            itemCount: leadingEmptyCount + daysInMonth,
            itemBuilder: (context, index) {
              if (index < leadingEmptyCount) {
                return const SizedBox();
              }

              final day = index - leadingEmptyCount + 1;
              final isSelectedDay = _selectedDay != null &&
                  _selectedDay!.year == _displayYear &&
                  _selectedDay!.month == _displayMonth &&
                  _selectedDay!.day == day;

              final isToday = today.year == _displayYear &&
                  today.month == _displayMonth &&
                  today.day == day;

              final hasRecord = activeRecordedDays.contains(day);

              return InkWell(
                onTap: () {
                  widget.onSelected(DatePickerResult(
                    selectedDate: DateTime(_displayYear, _displayMonth, day),
                    isDayMode: true,
                  ));
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelectedDay
                        ? AppColors.primary
                        : (isToday
                            ? (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight)
                            : Colors.transparent),
                    borderRadius: BorderRadius.circular(10),
                    border: isToday && !isSelectedDay
                        ? Border.all(color: AppColors.primary, width: 1.2)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$day',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelectedDay || isToday
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelectedDay
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary),
                        ),
                      ),
                      if (hasRecord)
                        Container(
                          width: 4,
                          height: 4,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: isSelectedDay ? Colors.white70 : AppColors.expense,
                            shape: BoxShape.circle,
                          ),
                        )
                      else
                        const SizedBox(height: 6),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    ),
    ),
    );
  }
}
