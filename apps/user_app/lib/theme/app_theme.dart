import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ไฟล์นี้ใช้กำหนดธีมหลักของแอปทั้งหมด
class AppTheme {
  // สีหลักของแอป (Ocean Blue สำหรับความสดใสและการเรียนรู้)
  static const Color primaryColor = Color(0xFF0284C7);

  // สีรอง (Soft Mint Green สำหรับ Green School & ปลอดภัย)
  static const Color secondaryColor = Color(0xFF10B981);

  // สีเน้น (Energy Gold สำหรับรางวัล & แจ้งเตือนสำคัญ)
  static const Color accentColor = Color(0xFFF59E0B);

  // สีพื้นหลังของแอป (Soft Cloud White สบายตา)
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // สีการ์ด (Pure White)
  static const Color cardColor = Colors.white;

  // สีแดงสำหรับปุ่มอันตราย เช่น Logout / Delete
  static const Color dangerColor = Color(0xFFEF4444);

  // ธีมหลักของแอป
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // Flutter default (Roboto) มีตัวอักษรไทยไม่ครบ — ข้อความไทยที่ไม่ได้
    // กำหนด fontFamily ไว้เอง จึงถูกเบราว์เซอร์/OS แต่ละเครื่อง fallback
    // ไปคนละฟอนต์กันเงียบ ๆ (ไม่เคยมีใครเลือกฟอนต์นี้จริงจัง) กำหนดไว้ตรงนี้
    // ที่เดียวให้ทุกหน้าที่ไม่ได้ห่อ Theme ของตัวเอง (student/parent/teacher/
    // executive/super_admin) เรนเดอร์เหมือนกันทุกเครื่อง
    // ฟอนต์ไทย 'มีหัว' (looped) — อ่านง่ายกว่าในขนาดเล็กและเป็นแบบที่
    // คนไทยคุ้นตาในเอกสาร เปลี่ยนจาก Noto Sans Thai (ไม่มีหัว)
    // เมื่อ 2026-09-22 ทั้งสองตัวเป็นตระกูลเดียวกัน ความกว้างใกล้เคียง
    // มาก เลย์เอาต์จึงแทบไม่ขยับ
    fontFamily: GoogleFonts.notoSansThaiLooped().fontFamily,

    // โทนสีหลักของแอป
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      surface: backgroundColor,
      brightness: Brightness.light,
    ),

    // สีพื้นหลังหลัก
    scaffoldBackgroundColor: backgroundColor,

    // ธีม Card
    cardTheme: CardThemeData(
      color: cardColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFF1F5F9), width: 1),
      ),
    ),

    // ธีม AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),

    // ธีมปุ่ม ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 52),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // ธีมช่องกรอกข้อมูล
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Colors.grey),
    ),

    // ธีมข้อความ
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
      titleLarge: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
      bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF334155)),
    ),
  );
}
