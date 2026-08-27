import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class SchoolAdminPalette {
  const SchoolAdminPalette._();

  // สีหลัก: Warm Coffee Palette (IMG_2118.JPG: #A45C23, #4C2113, #B38B60, #DCB485, #FFFFFF, #F1DEBC)
  // Roasted Coffee (#A45C23) - สีหลักโทนกาแฟคั่วอบอุ่น พรีเมียม มีชีวิตชีวา
  static const Color primary = Color(0xFFA45C23);
  // Deep Espresso (#4C2113) - สีเข้มเอสเพรสโซ่เข้มข้น ลุ่มลึก
  static const Color primaryDark = Color(0xFF4C2113);
  // Soft Crema (#DCB485) - สีครีมาฟองกาแฟนุ่มละมุน
  static const Color primaryLight = Color(0xFFDCB485);
  // Biscuit Cream (#F1DEBC) - สีครีมบิสกิตอบอุ่น
  static const Color primarySoft = Color(0xFFF1DEBC);

  // สีเสริม
  // Caramel Latte (#B38B60) - สีคาราเมลลาเต้
  static const Color secondary = Color(0xFFB38B60);
  static const Color orange = Color(0xFFC76D2B);
  static const Color yellow = Color(0xFFD49B45);
  static const Color green = Color(0xFF4A7C59);
  static const Color blue = Color(0xFF56728E);
  static const Color red = Color(0xFFB84236);
  static const Color cyan = Color(0xFF688E83);

  // พื้นหลังหลัก: สีขาวล้วน (#FFFFFF) คลีน คมชัด ทันสมัย
  static const Color background = Color(0xFFFFFFFF);

  // การ์ดและกรอบเป็นสีขาวล้วน (#FFFFFF)
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // เมนูด้านซ้าย: สีขาวล้วน (#FFFFFF)
  static const Color sidebar = Color(0xFFFFFFFF);
  static const Color sidebarBg = sidebar;

  // เส้นขอบ Neutral Slate Hairline (#E2E8F0)
  static const Color border = Color(0xFFE2E8F0);

  // สีข้อความ: Deep Espresso (#4C2113) คมชัด อ่านง่าย หรูหรา
  static const Color textPrimary = Color(0xFF4C2113);
  static const Color textSecondary = Color(0xFF7A4A28);
  static const Color textMuted = Color(0xFF9E7E5E);
  static const Color onPrimary = Colors.white;

  // สีอ่อนของป้ายและสัญลักษณ์ (Glass Tint Soft)
  static const Color orangeSoft = Color(0xFFFDF5EE);
  static const Color yellowSoft = Color(0xFFFDF8EE);
  static const Color greenSoft = Color(0xFFEFF7F2);
  static const Color skySoft = Color(0xFFF0F5FA);
  static const Color blueSoft = Color(0xFFF0F5FA);
  static const Color redSoft = Color(0xFFFAF0EE);
  static const Color brownSoft = Color(0xFFF7EFE3);
  static const Color sandSoft = Color(0xFFFAF6F0);

  // ชื่อสำรองสำหรับหน้าที่มีอยู่เดิม
  static const Color success = green;
  static const Color successSoft = greenSoft;
  static const Color warning = yellow;
  static const Color warningSoft = yellowSoft;
  static const Color shadow = Color(0x00000000);

  // ไล่เฉดสี Roasted Coffee & Deep Espresso Gradient
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFA45C23),
      Color(0xFF4C2113),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB38B60),
      Color(0xFFA45C23),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF4C2113),
      Color(0xFF2E130B),
    ],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFDCB485),
      Color(0xFFA45C23),
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

  // เงาลอยสไตล์โมเดิร์นพร้อม Ambient Warm Roasted Glow
  static List<BoxShadow> get cardShadow => const [
    BoxShadow(
      color: Color(0x064C2113),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x0E4C2113),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0DA45C23),
      blurRadius: 24,
      offset: Offset(0, 10),
    ),
  ];

  static List<BoxShadow> get smallShadow => const [
    BoxShadow(
      color: Color(0x064C2113),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x084C2113),
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
