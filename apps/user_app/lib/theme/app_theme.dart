import 'package:flutter/material.dart';

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
