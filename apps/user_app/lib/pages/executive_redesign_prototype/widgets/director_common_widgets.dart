import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

BoxDecoration directorWhiteCard() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: const Color(0xFFE5E5EA), width: 0.8),
    boxShadow: const [
      BoxShadow(
        color: Color(0x08000000),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
  );
}

class DirectorSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const DirectorSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: directorWhiteCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppPalette.textMuted)),
        ],
      ),
    );
  }
}

