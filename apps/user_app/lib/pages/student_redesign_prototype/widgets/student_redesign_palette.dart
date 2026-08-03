import 'package:flutter/material.dart';

class SchoolPalette {
  static const green = Color(0xFF43AC60);
  static const yellow = Color(0xFFFFC939);
  static const orange = Color(0xFFDB6D24);
  static const blue = Color(0xFF4CA4F1);
  static const cream = Color(0xFFFBEAA8);
  static const sky = Color(0xFFAADBF9);
  static const lime = Color(0xFFA9CD30);
  static const lavender = Color(0xFFC8BADD);
  static const ink = Color(0xFF263238);
  static const muted = Color(0xFF607D8B);
  static const page = Colors.white;
}

class SoftCard extends StatelessWidget {
  const SoftCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = Colors.white,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
