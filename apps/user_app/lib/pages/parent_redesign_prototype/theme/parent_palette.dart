import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Parent had no centralized palette before this — every page just wrote
/// the same handful of hex values inline (confirmed via grep: `0xFF2867B2`
/// alone appears 26+ times across the redesign). This file changes
/// nothing visually; it only names the colors Parent's pages already use
/// so ticket 01 has a single place to build [roleColors]/[roleTheme]
/// from, same as every other role.
class ParentPalette {
  const ParentPalette._();

  static const Color primary = Color(0xFF2867B2);
  static const Color primaryDark = Color(0xFF1C5790);
  static const Color primarySoft = Color(0xFFEAF3FF);
  static const Color background = Color(0xFFF5F7FB);
  static const Color surface = Colors.white;
  static const Color border = Color(0xFFE7EAF0);
  static const Color textPrimary = Color(0xFF1B2536);
  static const Color textSecondary = Color(0xFF7F899B);
  static const Color onPrimary = Colors.white;
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF18A06F);

  // Design-system-unification (2026-08-26, ticket 01): the single place
  // that feeds Parent's existing colors into the shared, structure-only
  // theme builder. Never add a new color value here — this only
  // re-packages the constants already defined above.
  static const RoleColors roleColors = RoleColors(
    primary: primary,
    onPrimary: onPrimary,
    secondary: primaryDark,
    background: background,
    surface: surface,
    border: border,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    error: error,
    success: success,
  );

  static ThemeData get roleTheme => buildRoleTheme(roleColors);
}
