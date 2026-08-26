import 'package:flutter/material.dart';

/// The color values one role contributes to [buildRoleTheme]. Every field
/// here is a *color only* — never a radius, padding, or font size, since
/// those are the structural pieces shared across every role by
/// [buildRoleTheme] itself. A role's existing palette file should build
/// one `RoleColors` from its own already-defined color constants rather
/// than inventing new hex values, so the design-system-unification work
/// never changes what a role looks like — only how its buttons/fields are
/// structured.
class RoleColors {
  const RoleColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    this.error = const Color(0xFFB3261E),
    this.success = const Color(0xFF2E7D32),
  });

  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color error;
  final Color success;
}
