import 'package:flutter/material.dart';

import 'student_redesign_palette.dart';

/// The one empty-state block for Student home sections.
///
/// Until 2026-09-18 each section rendered its "nothing here" as a SoftCard
/// that shrank to its text, so the home page ended in three pill shapes of
/// three different widths. This is full-width, has a fixed shape, and says
/// both what is missing and when something will appear. Sections keep their
/// existing layout once they have data — this is only the empty branch.
class StudentEmptyState extends StatelessWidget {
  const StudentEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
  });

  final IconData icon;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SchoolPalette.glassBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: SchoolPalette.softGreenBg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, size: 22, color: SchoolPalette.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.ink,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hint,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
