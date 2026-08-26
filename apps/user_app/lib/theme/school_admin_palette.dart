import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class SchoolAdminPalette {
  const SchoolAdminPalette._();

  // สีหลักเดิม: น้ำตาล–ทอง–ครีม
  static const Color primary = Color(0xFFA66B1F);
  static const Color primaryDark = Color(0xFF6F4314);
  static const Color primaryLight = Color(0xFFE7C98F);
  static const Color primarySoft = Color(0xFFF8F6F3);

  // สีเสริม
  static const Color secondary = Color(0xFFD49A18);
  static const Color orange = Color(0xFFC78320);
  static const Color yellow = Color(0xFFE3B342);
  static const Color green = Color(0xFF5C8A63);
  static const Color blue = Color(0xFF6F7F98);
  static const Color red = Color(0xFFA74635);
  static const Color cyan = Color(0xFF8D9B86);

  // พื้นหลังหลักยังเป็นครีม
  static const Color background = Color(0xFFF7F1E7);

  // การ์ดและกรอบเป็นสีขาวล้วน
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSoft = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // เมนูด้านซ้ายคงสีเดิม
  static const Color sidebar = Color(0xFFF0E2C8);
  static const Color sidebarBg = sidebar;

  // เส้นขอบเข้มขึ้นเล็กน้อย เพื่อแบ่งการ์ดให้ชัด
  static const Color border = Color(0xFFD9C7A8);

  // สีข้อความ
  static const Color textPrimary = Color(0xFF35291E);
  static const Color textSecondary = Color(0xFF665544);
  static const Color textMuted = Color(0xFF8D7D6B);
  static const Color onPrimary = Colors.white;

  // สีอ่อนของป้ายและสัญลักษณ์
  // ปรับให้ใกล้สีขาวมากขึ้น แต่ยังแยกสถานะได้
  static const Color orangeSoft = Color(0xFFFFFAF5);
  static const Color yellowSoft = Color(0xFFFFFCF2);
  static const Color greenSoft = Color(0xFFF8FCF9);
  static const Color skySoft = Color(0xFFFAFCFA);
  static const Color blueSoft = Color(0xFFF8FAFC);
  static const Color redSoft = Color(0xFFFFF8F7);
  static const Color brownSoft = Color(0xFFFCF9F6);
  static const Color sandSoft = Color(0xFFFAF8F4);

  // ชื่อสำรองสำหรับหน้าที่มีอยู่เดิม
  static const Color success = green;
  static const Color successSoft = greenSoft;
  static const Color warning = yellow;
  static const Color warningSoft = yellowSoft;
  static const Color shadow = Color(0x00000000);

  // สีหัวข้อเดิม
  static const LinearGradient heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFB77A26),
      Color(0xFF6F4314),
    ],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD49A18),
      Color(0xFFA66B1F),
    ],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF80501D),
      Color(0xFF4E3014),
    ],
  );

  static const LinearGradient cyanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFE7D4A8),
      Color(0xFFC49A4D),
    ],
  );

  // การ์ดเป็นสีขาวล้วน ไม่มีไล่สีครีม
  static const LinearGradient softCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFFFFFF),
    ],
  );

  // ใช้เส้นขอบเป็นตัวแบ่งหลัก จึงไม่ใส่เงา
  static List<BoxShadow> get cardShadow => const [];

  static List<BoxShadow> get smallShadow => const [];

  // Design-system-unification (2026-08-26, ticket 01): the single place
  // that feeds School Admin's existing colors into the shared,
  // structure-only theme builder. Never add a new color value here —
  // this only re-packages the constants already defined above.
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
