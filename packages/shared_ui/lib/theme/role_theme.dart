import 'package:flutter/material.dart';

import 'role_colors.dart';

/// Builds a [ThemeData] whose button/text-field/search-field *structure*
/// (corner radius, padding, border weight) is identical for every role —
/// modeled on the teacher and student redesigns' structural feel, the
/// two references the 2026-08-26 design-system-unification plan settled
/// on — while every *color* comes from the [RoleColors] passed in. Two
/// roles built with different [RoleColors] but the same structural
/// constants below will look unmistakably related in shape, while still
/// rendering in each role's own existing color scheme.
///
/// A role wraps its own subtree once — `Theme(data: buildRoleTheme(...),
/// child: ...)` at that role's root page — after which plain `FilledButton`,
/// `OutlinedButton`, and `TextField`/`TextFormField` calls with no
/// per-field `style`/`border` override automatically inherit this
/// structure. Migrating a page means *removing* the page's own inline
/// `InputDecoration(border: ...)` / `ButtonStyle(shape: ...)` overrides,
/// not swapping widget types.
ThemeData buildRoleTheme(RoleColors colors) {
  const double fieldRadius = 12;
  // Flutter's own Material 3 default for FilledButton/OutlinedButton is
  // already a 20px radius — an earlier version of this builder used 14,
  // which was *less* rounded than what Flutter renders with no theme at
  // all, so migrating a page produced an invisible (or backwards) change.
  // 24 is deliberately past the M3 default so the shift away from a
  // page's old ad-hoc styling is actually visible, matching the
  // noticeably-rounded feel of the teacher/student reference designs.
  const double buttonRadius = 24;
  const EdgeInsets fieldPadding = EdgeInsets.symmetric(
    horizontal: 14,
    vertical: 12,
  );
  const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: 20,
    vertical: 14,
  );

  final colorScheme = ColorScheme.fromSeed(
    seedColor: colors.primary,
    brightness: Brightness.light,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.secondary,
    surface: colors.surface,
    error: colors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: colors.background,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      backgroundColor: Colors.transparent,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colors.textPrimary,
    ),
    textTheme: TextTheme(
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: colors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      bodyLarge: TextStyle(fontSize: 14, color: colors.textPrimary),
      bodyMedium: TextStyle(fontSize: 13, color: colors.textSecondary),
      labelLarge: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      filled: true,
      fillColor: colors.surface,
      contentPadding: fieldPadding,
      hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
      labelStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(fieldRadius),
        borderSide: BorderSide(color: colors.error),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        padding: buttonPadding,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.primary,
        side: BorderSide(color: colors.primary),
        padding: buttonPadding,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.primary,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.border),
      ),
    ),
  );
}
