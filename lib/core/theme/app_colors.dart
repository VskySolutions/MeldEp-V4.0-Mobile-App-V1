import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary / Theme
  static const Color PRIMARY = Color(0xFF1B75AB); // Original blue
  static const Color PRIMARY_VARIANT = Color(0xFF1565C0); // Deeper blue for contrast
  static const Color LOGIN_PRIMARY = Color(0xFF1976D2); // Slightly modern blue

  // Secondary / Neutral
  static const Color SECONDARY = Color(0xFF6B7280); // Neutral gray (improved contrast)
  static const Color SECONDARY_VARIANT = Color(0xFF4B5563); // Darker neutral for text/icons

  // Accent
  static const Color ACCENT = Color(0xFF9333EA); // Vibrant purple (M3 / Tailwind violet-600)
  static const Color ACCENT_VARIANT = Color(0xFF7E22CE); // Darker purple shade

  // Backgrounds
  static const Color SCAFFOLD_BG = Color(0xFFF9FAFB); // Soft gray background
  static const Color SURFACE = Color(0xFFFFFFFF);

  // Text
  static const Color TEXT_PRIMARY = Color(0xFF111827); // Dark neutral (almost black)
  static const Color TEXT_SECONDARY = Color(0xFF6B7280); // Medium gray

  // Dark Mode
  static const Color DARK = Color(0xFF1E1E1E); // Elevated dark gray
  static const Color DARK_PAGE = Color(0xFF121212); // True dark bg

  // Accent / Semantic
  static const Color SUCCESS = Color(0xFF16A34A); // Tailwind green-600
  static const Color WARNING = Color(0xFFF59E0B); // Tailwind amber-500
  static const Color INFO = Color(0xFF0284C7); // Tailwind sky-600
  static const Color ERROR = Color(0xFFDC2626); // Tailwind red-600

  // Dividers / Muted
  static const Color DIVIDER = Color(0xFFE5E7EB);

  // Shadows (if needed)
  static const Color SHADOW = Color(0x1A000000); // 10% black
}
