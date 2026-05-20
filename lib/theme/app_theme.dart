import 'package:flutter/material.dart';

class AppColors {
  static const violet   = Color(0xFF7C3AED);
  static const fuchsia  = Color(0xFFD946EF);
  static const orange   = Color(0xFFF97316);
  static const pink     = Color(0xFFEC4899);
  static const cyan     = Color(0xFF06B6D4);
  static const blue     = Color(0xFF2563EB);
  static const emerald  = Color(0xFF10B981);
  static const teal     = Color(0xFF0D9488);
  static const purple   = Color(0xFF9333EA);
  static const rose     = Color(0xFFF43F5E);
  static const background   = Color(0xFFF8F7FF);
  static const textPrimary  = Color(0xFF1F2937);
  static const textSecondary= Color(0xFF6B7280);
  static const border       = Color(0xFFEDE9FE);
}

class AppGradients {
  static const primary = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF7C3AED), Color(0xFFD946EF), Color(0xFFF97316)],
  );
  static const violet = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
  );
  static const orange = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF97316), Color(0xFFEC4899)],
  );
  static const cyan = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
  );
  static const emerald = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF0D9488)],
  );
  static const purple = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFA855F7), Color(0xFF9333EA)],
  );
  static const red = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFF87171), Color(0xFFF43F5E)],
  );
  static const fuchsia = LinearGradient(
    begin: Alignment.topLeft, end: Alignment.bottomRight,
    colors: [Color(0xFFE879F9), Color(0xFFD946EF)],
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
