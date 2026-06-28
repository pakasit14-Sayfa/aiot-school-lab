import 'package:flutter/material.dart';

// ไฟล์นี้ใช้กำหนดธีมหลักของแอปทั้งหมด
class AppTheme {
  // สีหลักของแอป
  static const Color primaryColor = Color(0xFF4F46E5);

  // สีพื้นหลังของแอป
  static const Color backgroundColor = Color(0xFFF8FAFC);

  // สีแดงสำหรับปุ่มอันตราย เช่น Logout / Delete
  static const Color dangerColor = Color(0xFFDC2626);

  // ธีมหลักของแอป
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,

    // โทนสีหลักของแอป
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
    ),

    // สีพื้นหลังหลัก
    scaffoldBackgroundColor: backgroundColor,

    // ธีม AppBar
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      centerTitle: true,
      elevation: 0,
    ),

    // ธีมปุ่ม ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),

    // ธีมช่องกรอกข้อมูล
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      labelStyle: const TextStyle(color: Colors.black87),
      hintStyle: const TextStyle(color: Colors.grey),
    ),

    // ธีมข้อความ
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
    ),
  );
}
