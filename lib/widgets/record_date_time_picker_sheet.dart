import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/date_format_helper.dart';

class RecordDateTimePickerSheet extends StatefulWidget {
  final DateTime initialDateTime;
  final ValueChanged<DateTime> onConfirmed;

  const RecordDateTimePickerSheet({
    super.key,
    required this.initialDateTime,
    required this.onConfirmed,
  });

  static Future<DateTime?> show(BuildContext context, DateTime initialDateTime) {
    return showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RecordDateTimePickerSheet(
        initialDateTime: initialDateTime,
        onConfirmed: (dateTime) => Navigator.pop(context, dateTime),
      ),
    );
  }

  @override
  State<RecordDateTimePickerSheet> createState() => _RecordDateTimePickerSheetState();
}

class _RecordDateTimePickerSheetState extends State<RecordDateTimePickerSheet> {
  late DateTime _selectedDate;
  late int _selectedHour;
  late int _selectedMinute;

  late int _calendarYear;
  late int _calendarMonth;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDateTime.year,
      widget.initialDateTime.month,
      widget.initialDateTime.day,
    );
    _selectedHour = widget.initialDateTime.hour;
    _selectedMinute = widget.initialDateTime.minute;

    _calendarYear = widget.initialDateTime.year;
    _calendarMonth = widget.initialDateTime.month;
  }

  DateTime get _currentCombinedDateTime => DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedHour,
        _selectedMinute,
      );

  void _setToNow() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedHour = now.hour;
      _selectedMinute = now.minute;
      _calendarYear = now.year;
      _calendarMonth = now.month;
    });
  }

  void _setToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _calendarYear = now.year;
      _calendarMonth = now.month;
    });
  }

  void _setToYesterday() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    setState(() {
      _selectedDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
      _calendarYear = yesterday.year;
      _calendarMonth = yesterday.month;
    });
  }

  void _setToDayBeforeYesterday() {
    final now = DateTime.now();
    final dayBefore = now.subtract(const Duration(days: 2));
    setState(() {
      _selectedDate = DateTime(dayBefore.year, dayBefore.month, dayBefore.day);
      _calendarYear = dayBefore.year;
      _calendarMonth = dayBefore.month;
    });
  }

  void _previousMonth() {
    setState(() {
      if (_calendarMonth == 1) {
        _calendarYear -= 1;
        _calendarMonth = 12;
      } else {
        _calendarMonth -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_calendarMonth == 12) {
        _calendarYear += 1;
        _calendarMonth = 1;
      } else {
        _calendarMonth += 1;
      }
    });
  }

  Future<void> _pickExactTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _selectedHour, minute: _selectedMinute),
      helpText: '选择记账具体时间',
      cancelText: '取消',
      confirmText: '确定',
      hourLabelText: '小时',
      minuteLabelText: '分钟',
      errorInvalidText: '请输入有效时间',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Localizations.override(
          context: context,
          locale: const Locale('zh', 'CN'),
          child: child!,
        ),
      ),
    );
    if (picked != null && mounted) {
      setState(() {
        _selectedHour = picked.hour;
        _selectedMinute = picked.minute;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final daysInMonth = DateUtils.getDaysInMonth(_calendarYear, _calendarMonth);
    final firstWeekday = DateTime(_calendarYear, _calendarMonth, 1).weekday;
    final leadingEmptyCount = firstWeekday - 1;

    final timeStr = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}';
    final dateHeader = DateFormatHelper.formatDayHeader(_selectedDate, showYear: true);

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
            crossAxisAlignment: CrossAxisAlignment.start,
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

              // Title and current selection preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '设置记账日期与时间',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateHeader $timeStr',
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: _setToNow,
                    icon: const Icon(Icons.restore_rounded, size: 15),
                    label: const Text('设为当前时间', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Quick Day Shortcuts
              Row(
                children: [
                  _buildQuickDayChip('今天', _selectedDate == today, _setToToday, isDark),
                  const SizedBox(width: 8),
                  _buildQuickDayChip(
                    '昨天',
                    _selectedDate == today.subtract(const Duration(days: 1)),
                    _setToYesterday,
                    isDark,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickDayChip(
                    '前天',
                    _selectedDate == today.subtract(const Duration(days: 2)),
                    _setToDayBeforeYesterday,
                    isDark,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Calendar Month Switcher
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _previousMonth,
                      icon: const Icon(Icons.chevron_left_rounded, size: 20),
                    ),
                    Text(
                      '$_calendarYear年 $_calendarMonth月',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // Weekday Headers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const ['一', '二', '三', '四', '五', '六', '日'].map((w) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        w,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 6),

              // Calendar Days Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                  childAspectRatio: 1.25,
                ),
                itemCount: leadingEmptyCount + daysInMonth,
                itemBuilder: (context, index) {
                  if (index < leadingEmptyCount) {
                    return const SizedBox();
                  }

                  final day = index - leadingEmptyCount + 1;
                  final isSelected = _selectedDate.year == _calendarYear &&
                      _selectedDate.month == _calendarMonth &&
                      _selectedDate.day == day;

                  final isToday = today.year == _calendarYear &&
                      today.month == _calendarMonth &&
                      today.day == day;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedDate = DateTime(_calendarYear, _calendarMonth, day);
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : (isToday
                                ? (isDark ? Colors.white10 : Colors.black12)
                                : Colors.transparent),
                        borderRadius: BorderRadius.circular(8),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.primary, width: 1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // Time Setting Section
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 8),
                        Text(
                          '具体时间',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: _pickExactTime,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.edit_rounded, size: 13, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Confirm CTA
              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => widget.onConfirmed(_currentCombinedDateTime),
                  child: const Text('确认设置时间', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickDayChip(String label, bool isSelected, VoidCallback onTap, bool isDark) {
    return Expanded(
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 6),
          side: BorderSide(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 1.5 : 1,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onTap,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.primary : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
