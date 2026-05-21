import 'package:flutter/material.dart';

class AppColors {
  static const violet   = Color(0xFF1E40AF); // Blue
  static const fuchsia  = Color(0xFF3B82F6); // Light Blue
  static const orange   = Color(0xFF0F172A); // Slate
  static const pink     = Color(0xFF1E1B4B); // Dark Indigo
  static const cyan     = Color(0xFF0EA5E9); // Sky Blue
  static const blue     = Color(0xFF2563EB); // Standard Blue
  static const emerald  = Color(0xFF0284C7); // Dark Sky Blue
  static const teal     = Color(0xFF312E81); // Indigo
  static const purple   = Color(0xFF111827); // Dark Gray
  static const rose     = Color(0xFF374151); // Gray
  static const background   = Color(0xFFF8F9FA); // Very light grey/blue
  static const textPrimary  = Color(0xFF1F2937);
  static const textSecondary= Color(0xFF6B7280);
  static const border       = Color(0xFFE2E8F0); // Slate border
}

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF2563EB), Color(0xFF1E1B4B)],
  );
  static const violet = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF1E1B4B)],
  );
  static const orange = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
  );
  static const cyan = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
  );
  static const emerald = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
  );
  static const purple = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF312E81), Color(0xFF4338CA)],
  );
  static const red = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF111827), Color(0xFF374151)],
  );
  static const fuchsia = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
  );
  static const darkBlue = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF1E1B4B)],
  );

  static final courseGradients = [cyan, emerald, purple, orange];
  static final cardGradients   = [cyan, emerald, purple, orange, red, fuchsia];
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: 'Roboto',
    cardTheme: CardThemeData(
      elevation: 4,
      shadowColor: AppColors.violet.withOpacity(0.15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0),
  );
}
