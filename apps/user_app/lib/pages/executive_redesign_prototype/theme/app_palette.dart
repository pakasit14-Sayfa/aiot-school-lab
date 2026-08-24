import 'package:flutter/material.dart';

class AppPalette {
  static const Color pageBg = Color(0xFFFBF7F9);
  static const Color primaryPink = Color(0xFFD85A8C);
  static const Color primaryPinkDark = Color(0xFFB63E70);
  static const Color primaryPinkSoft = Color(0xFFFBE6EF);
  static const Color sidebarSurface = Color(0xFFFFF8FB);
  static const Color sidebarIconBg = Color(0xFFF6EDF1);
  static const Color sidebarIcon = Color(0xFF8C7C84);
  static const Color heroPink = Color(0xFFE072A0);
  static const Color heroPinkDark = Color(0xFFC74F82);
  static const Color heroTag = Color(0xFFFFE082);
  static const Color textDark = Color(0xFF2B2430);
  static const Color textMuted = Color(0xFF8B7C86);
  static const Color border = Color(0xFFF0E5EA);
  static const Color softPink = Color(0xFFFCE8F0);
  static const Color softPink2 = Color(0xFFFBE3E1);
  static const Color softCream = Color(0xFFF9F2DD);
  static const Color softBlue = Color(0xFFEAF0FB);
  static const Color softMint = Color(0xFFEAF6F1);
  static const Color softTag = Color(0xFFF4EDF0);
  static const Color chartPink = Color(0xFFE35A8B);
  static const Color chartPink2 = Color(0xFFE796B3);
  static const Color chartPink3 = Color(0xFFECC1D1);
  static const Color chartCream = Color(0xFFE8C89B);
  static const Color chartBlue = Color(0xFF8DB3DD);
  static const Color behaviorYellow = Color(0xFFE8C56F);
  static const Color learningBlue = Color(0xFF7FA9D8);
  static const Color environmentGreen = Color(0xFF8FC7A5);
  static const Color danger = Color(0xFFD94141);
  static const Color warning = Color(0xFFE69A35);
  static const Color success = Color(0xFF3C9A6A);

  static Color tint(Color color, double alpha) =>
      color.withAlpha((255 * alpha).round());
}
