import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class AppPalette {
  // ชุดสีหลักจากภาพอ้างอิง
  static const Color carnivalRed = Color(0xFFB0232B);
  static const Color circusYellow = Color(0xFFECC412);
  static const Color deepBlue = Color(0xFF0D5C9D);
  static const Color gardenGreen = Color(0xFF1C7F46);
  static const Color softBeige = Color(0xFFE5D5C1);

  // ชื่อสีเดิมที่หน้าอื่นในโปรเจกต์เรียกใช้อยู่
  static const Color blueDark = Color(0xFF073E69);
  static const Color bluePrimary = deepBlue;
  static const Color blueAccent = Color(0xFF1977B8);
  static const Color blueSoft = Color(0xFFDDECF7);
  static const Color orange = carnivalRed;
  static const Color yellow = circusYellow;
  static const Color cream = softBeige;

  static const Color background = Color(0xFFF8F4EE);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF17324A);
  static const Color textSecondary = Color(0xFF6B7782);

  static const Color success = gardenGreen;
  static const Color warning = circusYellow;
  static const Color danger = carnivalRed;
  static const Color info = deepBlue;

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: blueDark.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  static ThemeData get theme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: deepBlue,
      brightness: Brightness.light,
      primary: deepBlue,
      secondary: carnivalRed,
      tertiary: gardenGreen,
      surface: surface,
      error: carnivalRed,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      // Arial has no Thai glyphs — every Thai character here was silently
      // substituted by whatever font each OS/browser falls back to.
      // Referenced by name, not `GoogleFonts.notoSansThaiLooped().fontFamily` —
      // the actual dynamic load that registers 'NotoSansThaiLooped' happens once
      // in the app's root `AppTheme.lightTheme`, which always builds first.
      fontFamily: 'NotoSansThaiLooped',
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: textPrimary,
      ),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 14, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 13, color: textSecondary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: const TextStyle(color: textSecondary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: softBeige.withValues(alpha: 0.9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: softBeige.withValues(alpha: 0.9)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: deepBlue, width: 1.5),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: IconThemeData(color: deepBlue),
        selectedLabelTextStyle: TextStyle(
          color: deepBlue,
          fontWeight: FontWeight.w700,
        ),
        unselectedIconTheme: IconThemeData(color: textSecondary),
        unselectedLabelTextStyle: TextStyle(color: textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: softBeige.withValues(alpha: 0.55),
        selectedColor: circusYellow.withValues(alpha: 0.25),
        labelStyle: const TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: deepBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBlue,
          side: const BorderSide(color: deepBlue),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  // Design-system-unification (2026-08-26, ticket 01): the single place
  // that feeds Super Admin's existing colors into the shared,
  // structure-only theme builder. Never add a new color value here —
  // this only re-packages the constants already defined above. Use
  // [roleTheme] (not the pre-existing [theme] getter above, which is
  // Super Admin's own hand-written theme) once Super Admin migrates to
  // the shared component system.
  static const RoleColors roleColors = RoleColors(
    primary: deepBlue,
    onPrimary: Colors.white,
    secondary: carnivalRed,
    background: background,
    surface: surface,
    border: softBeige,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    error: carnivalRed,
    success: gardenGreen,
  );

  static ThemeData get roleTheme => buildRoleTheme(roleColors);
}
