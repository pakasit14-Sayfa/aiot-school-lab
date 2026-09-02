import 'package:flutter/material.dart';

import '../models/director_models.dart';
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

class DirectorListCard extends StatelessWidget {
  final ListItemData item;
  final VoidCallback? onTap;

  const DirectorListCard({super.key, required this.item, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: directorWhiteCard(),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppPalette.tint(item.color, 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(item.subtitle, style: const TextStyle(fontSize: 10.5, color: AppPalette.textMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.tint(item.color, 0.10),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  item.status,
                  style: TextStyle(fontSize: 9.8, fontWeight: FontWeight.w700, color: item.color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
