import 'package:flutter/material.dart';

// Widget ช่องกรอกข้อมูลแบบใช้ซ้ำได้
class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
    this.focusNode,
  });

  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  /// ทั้ง 4 ตัวนี้ใส่ทีหลัง (ค่าเริ่มต้น null = พฤติกรรมเดิมทุกหน้า) —
  /// หน้า login ต้องใช้เพื่อให้ตัวจัดการรหัสผ่านเติมให้ได้ และกด Enter
  /// จากคีย์บอร์ดแล้วส่งฟอร์มได้ ซึ่งสำคัญมากบนเว็บ/แท็บเล็ต
  final List<String>? autofillHints;
  final TextInputAction? textInputAction;
  final void Function(String)? onFieldSubmitted;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      obscureText: obscureText,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }
}
