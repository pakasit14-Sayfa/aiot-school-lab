import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class SchoolAdminPalette {
  const SchoolAdminPalette._();

  // สีหลัก: Modern Royal Amber & Honey Gold (อบอุ่น สว่าง พรีเมียม ไม่อมโคลน)
  static const Color primary = Color(0xFFD97706);
  static const Color primaryDark = Color(0xFFB45309);
  static const Color primaryLight = Color(0xFFFDE68A);
  static const Color primarySoft = Color(0xFFFEF3C7);

  // สีเสริม
  static const Color secondary = Color(0xFFF59E0B);
  static const Color orange = Color(0xFFEA580C);
  static const Color yellow = Color(0xFFEAB308);
  static const Color green = Color(0xFF10B981);
  static const Color blue = Color(0xFF0284C7);
  static const Color red = Color(0xFFEF4444);
  static const Color cyan = Color(0xFF06B6D4);

  // พื้นหลังหลัก: Warm Off-White สว่าง คมชัด
  static const Color background = Color(0xFFFAF9F6);

  // การ์ดและกรอบเป็นสีขาวล้วน
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFAF9F6);
  static const Color card = Color(0xFFFFFFFF);

  // เมนูด้านซ้าย: Warm Neutral Clean
  static const Color sidebar = Color(0xFFFBF8F2);
  static const Color sidebarBg = sidebar;

  // เส้นขอบบางเฉียบ คมชัดสไตล์หินอ่อน
  static const Color border = Color(0xFFE7E5E4);

  // สีข้อความ: Deep Stone Charcoal อ่านง่าย คมชัด
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF78716C);
  static const Color textMuted = Color(0xFFA8A29E);
  static const Color onPrimary = Colors.white;

  // สีอ่อนของป้ายและสัญลักษณ์ (Glass Tint Soft)
  static const Color orangeSoft = Color(0xFFFFF7ED);
  static const Color yellowSoft = Color(0xFFFEFCE8);
  static const Color greenSoft = Color(0xFFECFDF5);
  static const Color skySoft = Color(0xFFF0F9FF);
  static const Color blueSoft = Color(0xFFF0FDF4);
  static const Color redSoft = Color(0xFFFEF2F2);
  static const Color brownSoft = Color(0xFFFAF8F5);
  static const Color sandSoft = Color(0xFFFDFBF7);

  // ชื่อสำรองสำหรับหน้าที่มีอยู่เดิม
  static const Color success = green;
  static const Color successSoft = greenSoft;
  static const Color warning = yellow;
  static const Color warningSoft = yellowSoft;
  static const Color shadow = Color(0x00000000);

  // ไล่เฉดสี Modern Amber Gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD97706),
      Color(0xFFB45309),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFD97706),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF92400E),
      Color(0xFF78350F),
    ],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFDE68A),
      Color(0xFFD97706),
    ],
  );

  // การ์ดเป็นสีขาวล้วน
  static const LinearGradient softCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
    ],
  );

  // เงาลอยสไตล์โมเดิร์นพร้อม Ambient Warm Glow
  static List<BoxShadow> get cardShadow => const [
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0C0F172A),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0DB45309),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get smallShadow => const [
    BoxShadow(
      color: Color(0x060F172A),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x080F172A),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static const RoleColors roleColors = RoleColors(
    primary: primary,
    onPrimary: onPrimary,
    secondary: secondary,
    background: background,
    surface: surface,
    border: border,
    textPrimary: textPrimary,
    textSecondary: textSecondary,
    error: red,
    success: green,
  );

  static ThemeData get theme => buildRoleTheme(roleColors);
}
