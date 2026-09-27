import 'package:flutter/material.dart';

class LDColors {
  static const navy = Color(0xFF0F172A);
  static const navyLight = Color(0xFF1E293B);
  static const deepNavy = Color(0xFF0B1220);

  static const blue = Color(0xFF2563EB);
  static const cyan = Color(0xFF06B6D4);

  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceSoft = Color(0xFFF1F5F9);

  static const border = Color(0xFFE2E8F0);

  static const text = Color(0xFF0F172A);
  static const secondary = Color(0xFF64748B);
  static const muted = Color(0xFF94A3B8);
  static const subtle = Color(0xFF94A3B8);

  static const blueSoft = Color(0xFFEFF6FF);
  static const cyanSoft = Color(0xFFECFEFF);
  static const greenSoft = Color(0xFFF0FDF4);
  static const amberSoft = Color(0xFFFFFBEB);
  static const redSoft = Color(0xFFFEF2F2);
}

class LDTheme {
  static ThemeData light() {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: LDColors.blue,
          brightness: Brightness.light,
        ).copyWith(
          primary: LDColors.blue,
          secondary: LDColors.cyan,
          surface: LDColors.surface,
          error: LDColors.danger,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LDColors.background,
      fontFamily: 'Inter',
      visualDensity: VisualDensity.standard,
      appBarTheme: const AppBarTheme(
        backgroundColor: LDColors.surface,
        foregroundColor: LDColors.text,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: LDColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: LDColors.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: LDColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LDColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LDColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: LDColors.blue, width: 1.5),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: LDColors.border,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
