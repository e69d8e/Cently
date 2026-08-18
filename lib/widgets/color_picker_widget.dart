import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ColorPickerWidget extends StatelessWidget {
  final int selectedColorValue;
  final ValueChanged<int> onSelected;

  const ColorPickerWidget({
    super.key,
    required this.selectedColorValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppColors.categoryPalette.map((color) {
        final isSelected = color.toARGB32() == selectedColorValue;
        return GestureDetector(
          onTap: () => onSelected(color.toARGB32()),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.white, width: 3)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
