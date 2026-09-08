import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// Shared visual language for the three connected executive workspaces.
class DirectorWorkspace extends StatelessWidget {
  const DirectorWorkspace({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Theme(
    data: AppPalette.roleTheme,
    child: ColoredBox(
      color: AppPalette.pageBg,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: child,
        ),
      ),
    ),
  );
}

class DirectorWorkspaceHero extends StatelessWidget {
  const DirectorWorkspaceHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });
  final String title, subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppPalette.primaryPinkDark, AppPalette.heroPink],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(35),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
      ],
    ),
  );
}

class DirectorWorkspaceCard extends StatelessWidget {
  const DirectorWorkspaceCard({
    super.key,
    required this.title,
    required this.children,
    this.icon = Icons.dashboard_outlined,
  });
  final String title;
  final List<Widget> children;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppPalette.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppPalette.primaryPinkSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppPalette.primaryPinkDark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppPalette.textDark,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        ...children,
      ],
    ),
  );
}
