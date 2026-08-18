import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

class IconPickerWidget extends StatelessWidget {
  final String selectedIconKey;
  final ValueChanged<String> onSelected;

  const IconPickerWidget({
    super.key,
    required this.selectedIconKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final icons = AppIcons.getAllIconKeys();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 220,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 6,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: icons.length,
        itemBuilder: (context, index) {
          final iconKey = icons[index];
          final isSelected = iconKey == selectedIconKey;
          return InkWell(
            onTap: () => onSelected(iconKey),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                AppIcons.getIcon(iconKey),
                size: 22,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
              ),
            ),
          );
        },
      ),
    );
  }
}
