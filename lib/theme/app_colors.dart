import 'package:flutter/material.dart';

class AppColors {
  // Brand & Core
  static const Color primary = Color(0xFF1E293B); // Slate dark ink
  static const Color primaryLight = Color(0xFF334155);

  /// 深色模式下的主按钮/主色：浅色底 + 深色文字，保证在深色 surface 上可见。
  static const Color primaryOnDark = Color(0xFFE2E8F0);

  // Backgrounds
  static const Color backgroundLight = Color(
    0xFFF8FAFC,
  ); // Clean paper off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);

  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceMutedDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);

  // Financial Accents (Refined & Muted)
  static const Color expense = Color(0xFFE11D48); // Rose / Terracotta (支出)

  /// 作为前景文字/金额时的红色。
  static const Color expenseText = Color(0xFFBE123C);
  static const Color expenseTextDark = Color(0xFFFB7185);
  static const Color expenseBg = Color(0xFFFFF1F2);
  static const Color expenseBgDark = Color(0xFF2E1318);
  static const Color income = Color(0xFF059669); // Emerald / Sage (收入)

  /// 作为前景文字/金额时的绿色（浅色底与深色底各自满足 WCAG AA）。
  static const Color incomeText = Color(0xFF047857);
  static const Color incomeTextDark = Color(0xFF34D399);
  static const Color incomeBg = Color(0xFFECFDF5);
  static const Color incomeBgDark = Color(0xFF082B20);
  static const Color balance = Color(0xFF2563EB); // Royal Blue
  static const Color balanceBg = Color(0xFFEFF6FF);
  static const Color balanceBgDark = Color(0xFF0E223D);
  static const Color balanceTextDark = Color(0xFF60A5FA);

  // Ranking accents (AA-safe on light/dark surfaces)
  static const Color rankGold = Color(0xFFB45309);
  static const Color rankGoldDark = Color(0xFFFBBF24);
  static const Color rankSilver = Color(0xFF64748B);
  static const Color rankSilverDark = Color(0xFFCBD5E1);
  static const Color rankBronze = Color(0xFF9A3412);
  static const Color rankBronzeDark = Color(0xFFFB923C);

  // Search keyword highlight (applied to matched text in result lists)
  static const Color searchHighlight = Color(0xFF2563EB); // Royal Blue
  static const Color searchHighlightDark = Color(
    0xFF7CB0FF,
  ); // Softer blue for dark surfaces

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textTertiary = Color(0xFF5B6B80);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFFA8B5C6);

  // Preset Colors for Categories
  static const List<Color> categoryPalette = [
    Color(0xFFE11D48), // Rose
    Color(0xFFEA580C), // Orange
    Color(0xFFD97706), // Amber
    Color(0xFF059669), // Emerald
    Color(0xFF0D9488), // Teal
    Color(0xFF0284C7), // Sky
    Color(0xFF2563EB), // Blue
    Color(0xFF7C3AED), // Violet
    Color(0xFFDB2777), // Pink
    Color(0xFF475569), // Slate
  ];
}
