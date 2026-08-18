import 'package:flutter/material.dart';
import '../theme/app_icons.dart';

class CategoryIconWidget extends StatelessWidget {
  final String iconKey;
  final Color color;
  final double size;
  final double iconSize;

  const CategoryIconWidget({
    super.key,
    required this.iconKey,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Center(
        child: Icon(
          AppIcons.getIcon(iconKey),
          color: color,
          size: iconSize,
        ),
      ),
    );
  }
}
