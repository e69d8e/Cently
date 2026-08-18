import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MonthPickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onSelected;

  const MonthPickerDialog({
    super.key,
    required this.initialDate,
    required this.onSelected,
  });

  static Future<DateTime?> show(BuildContext context, DateTime initialDate) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => MonthPickerDialog(
        initialDate: initialDate,
        onSelected: (date) => Navigator.pop(context, date),
      ),
    );
  }

  @override
  State<MonthPickerDialog> createState() => _MonthPickerDialogState();
}

class _MonthPickerDialogState extends State<MonthPickerDialog> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Year switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedYear -= 1;
                  });
                },
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                '$_selectedYear 年',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedYear += 1;
                  });
                },
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 12 Months grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
            ),
            itemCount: 12,
            itemBuilder: (context, index) {
              final month = index + 1;
              final isSelected = _selectedYear == widget.initialDate.year &&
                  _selectedMonth == month;
              final isCurrentMonth = DateTime.now().year == _selectedYear &&
                  DateTime.now().month == month;

              return InkWell(
                onTap: () {
                  widget.onSelected(DateTime(_selectedYear, month));
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight),
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentMonth && !isSelected
                        ? Border.all(color: AppColors.primary, width: 1.5)
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$month 月',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
        ],
      ),
    );
  }
}
