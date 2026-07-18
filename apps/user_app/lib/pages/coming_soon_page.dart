import 'package:flutter/material.dart';

class ComingSoonPage extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const ComingSoonPage({
    super.key,
    required this.title,
    required this.icon,
    this.color = const Color(0xFF2E7D32),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 72, color: color.withValues(alpha: 0.4)),
              const SizedBox(height: 20),
              Text(
                '$title กำลังจะมาเร็วๆ นี้',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'ฟีเจอร์นี้อยู่ระหว่างการพัฒนา',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
