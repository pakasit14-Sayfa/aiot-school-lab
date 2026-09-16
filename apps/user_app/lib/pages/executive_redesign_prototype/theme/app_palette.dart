import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class AppPalette {
  // Executive lane recolor (2026-09-14): brand tone moved from pink to
  // navy/slate, matching the hero banner already used on
  // director_meetings_page.dart (was a locally-defined _slate/_slateDark
  // pair on that one page — now the canonical primary/primaryDark here).
  // The warm-pink-tinted neutrals (page background, border, muted/dark
  // text) moved to cool slate-tinted neutrals too, so the page doesn't end
  // up with a cool navy accent sitting on a warm pink-white background.
  // Functional colors (danger/warning/success) and the generic categorical
  // "soft" backgrounds (softCream/softBlue/softMint/softPink2) are
  // untouched — this only moves the brand/primary tone and its neutrals.
  static const Color pageBg = Color(0xFFF8F8FB);
  static const Color primaryPink = Color(0xFF4A5578);
  static const Color primaryPinkDark = Color(0xFF363F5C);
  static const Color primaryPinkSoft = Color(0xFFEEF0F6);
  static const Color sidebarSurface = Color(0xFFF7F8FB);
  static const Color sidebarIconBg = Color(0xFFEBEDF3);
  static const Color sidebarIcon = Color(0xFF6B7280);
  static const Color heroPink = Color(0xFF5B6690);
  static const Color heroPinkDark = Color(0xFF424C6E);
  static const Color heroTag = Color(0xFFFFE082);
  static const Color textDark = Color(0xFF262A38);
  static const Color textMuted = Color(0xFF6E7385);
  static const Color border = Color(0xFFE7E9F0);
  static const Color softPink = Color(0xFFEDEFF5);
  static const Color softPink2 = Color(0xFFFBE3E1);
  static const Color softCream = Color(0xFFF9F2DD);
  static const Color softBlue = Color(0xFFEAF0FB);
  static const Color softMint = Color(0xFFEAF6F1);
  static const Color softTag = Color(0xFFF4EDF0);
  static const Color chartPink = Color(0xFF4A5578);
  static const Color chartPink2 = Color(0xFF7B87AC);
  static const Color chartPink3 = Color(0xFFC4CADC);
  static const Color chartCream = Color(0xFFE8C89B);
  static const Color chartBlue = Color(0xFF8DB3DD);
  static const Color behaviorYellow = Color(0xFFE8C56F);
  static const Color learningBlue = Color(0xFF7FA9D8);
  // Darker sibling of learningBlue, same naming pattern as
  // primaryPink/primaryPinkDark — used where a structural accent (status
  // dots, active filter chips, table headers) needs to read as blue rather
  // than the lane's primary pink, which is reserved for brand/header
  // moments so it doesn't get diluted by repeating on every list row.
  static const Color learningBlueDark = Color(0xFF4C7AB0);
  static const Color environmentGreen = Color(0xFF8FC7A5);
  static const Color danger = Color(0xFFD94141);
  static const Color warning = Color(0xFFE69A35);
  static const Color success = Color(0xFF3C9A6A);

  static Color tint(Color color, double alpha) =>
      color.withAlpha((255 * alpha).round());

  // Design-system-unification (2026-08-26, ticket 01): the single place
  // that feeds Executive's existing colors into the shared,
  // structure-only theme builder. Never add a new color value here —
  // this only re-packages the constants already defined above.
  static const RoleColors roleColors = RoleColors(
    primary: primaryPink,
    onPrimary: Colors.white,
    secondary: primaryPinkDark,
    background: pageBg,
    surface: Colors.white,
    border: border,
    textPrimary: textDark,
    textSecondary: textMuted,
    error: danger,
    success: success,
  );

  static ThemeData get roleTheme => buildRoleTheme(roleColors);
}
