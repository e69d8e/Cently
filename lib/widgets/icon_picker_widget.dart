import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_icons.dart';

class IconPickerWidget extends StatefulWidget {
  final String selectedIconKey;
  final ValueChanged<String> onSelected;

  const IconPickerWidget({
    super.key,
    required this.selectedIconKey,
    required this.onSelected,
  });

  @override
  State<IconPickerWidget> createState() => _IconPickerWidgetState();
}

class _IconPickerWidgetState extends State<IconPickerWidget> {
  String _selectedCategory = '全部';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = AppIcons.iconCategories.keys.toList();
    final icons = _selectedCategory == '全部'
        ? AppIcons.getAllIconKeys()
        : (AppIcons.iconCategories[_selectedCategory] ?? AppIcons.getAllIconKeys());

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category filter chips
        SizedBox(
          height: 32,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isCatSelected = cat == _selectedCategory;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedCategory = cat;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isCatSelected
                        ? (isDark
                            ? AppColors.primary.withValues(alpha: 0.25)
                            : AppColors.primary.withValues(alpha: 0.12))
                        : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCatSelected
                          ? AppColors.primary.withValues(alpha: 0.8)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isCatSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isCatSelected
                            ? (isDark ? AppColors.primaryLight : AppColors.primary)
                            : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Icons grid
        SizedBox(
          height: 180,
          child: GridView.builder(
            key: ValueKey(_selectedCategory),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final iconKey = icons[index];
              final isSelected = iconKey == widget.selectedIconKey;
              return InkWell(
                onTap: () => widget.onSelected(iconKey),
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.surfaceMutedDark : AppColors.surfaceMutedLight),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: isDark ? Colors.white70 : AppColors.primary,
                            width: 1.5,
                          )
                        : null,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
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
        ),
      ],
    );
  }
}

