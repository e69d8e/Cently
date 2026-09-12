import 'package:flutter/material.dart';

class AppColors {
  // Brand & Core
  static const Color primary = Color(0xFF1E293B); // Slate dark ink
  static const Color primaryLight = Color(0xFF334155);
  
  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC); // Clean paper off-white
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceMutedLight = Color(0xFFF1F5F9);
  static const Color borderLight = Color(0xFFE2E8F0);
  
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);
  static const Color surfaceMutedDark = Color(0xFF334155);
  static const Color borderDark = Color(0xFF334155);

  // Financial Accents (Refined & Muted)
  static const Color expense = Color(0xFFE11D48); // Rose / Terracotta (支出)
  static const Color expenseBg = Color(0xFFFFF1F2);
  static const Color expenseBgDark = Color(0xFF2E1318);
  static const Color income = Color(0xFF059669); // Emerald / Sage (收入)
  static const Color incomeBg = Color(0xFFECFDF5);
  static const Color incomeBgDark = Color(0xFF082B20);
  static const Color balance = Color(0xFF2563EB); // Royal Blue
  static const Color balanceBg = Color(0xFFEFF6FF);
  static const Color balanceBgDark = Color(0xFF0E223D);

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);

  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textTertiaryDark = Color(0xFF64748B);

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
