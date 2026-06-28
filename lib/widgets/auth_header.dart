import 'package:flutter/material.dart';

// Widget หัวหน้าฟอร์ม ใช้ซ้ำในหน้า Login / Register / Forgot Password
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Column(
      children: [
        CircleAvatar(
          radius: 46,
          backgroundColor: primaryColor.withOpacity(0.12),
          child: Icon(
            icon,
            size: 54,
            color: primaryColor,
          ),
        ),

        const SizedBox(height: 20),

        Text(
          title,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontSize: 28,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}