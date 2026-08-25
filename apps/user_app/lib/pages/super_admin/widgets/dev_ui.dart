import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

class AppPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? trailing;

  const AppPanel({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class PageIntroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badgeText;
  final String? mascotAsset;

  const PageIntroCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.badgeText,
    this.mascotAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: AppPalette.cardShadow,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;

          final textSide = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badgeText != null && badgeText!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.blueSoft,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badgeText!,
                    style: const TextStyle(
                      color: AppPalette.bluePrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (badgeText != null && badgeText!.isNotEmpty)
                const SizedBox(height: 14),
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 10),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppPalette.textSecondary,
                  height: 1.45,
                ),
              ),
            ],
          );

          final imageSide = SizedBox(
            height: wide ? 260 : 200,
            child: Image.asset(
              mascotAsset ?? 'assets/images/dev_mascot.png',
              fit: BoxFit.contain,
              errorBuilder:
                  (context, error, stackTrace) => Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      color: AppPalette.cream,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      size: 54,
                      color: AppPalette.bluePrimary,
                    ),
                  ),
            ),
          );

          if (wide) {
            return Row(
              children: [
                Expanded(flex: 3, child: textSide),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: imageSide,
                  ),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              textSide,
              const SizedBox(height: 18),
              Center(child: imageSide),
            ],
          );
        },
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String footnote;
  final Color accent;

  const StatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.footnote,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppPalette.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: accent.withValues(alpha: 0.12),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(footnote, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({super.key, required this.label, this.color});

  Color resolveColor() {
    if (color != null) return color!;
    final lower = label.toLowerCase();

    if (lower.contains('online') ||
        lower.contains('active') ||
        lower.contains('passed') ||
        lower.contains('ผ่าน') ||
        lower.contains('normal') ||
        lower.contains('healthy') ||
        lower.contains('success') ||
        lower.contains('resolved')) {
      return AppPalette.success;
    }

    if (lower.contains('warning') ||
        lower.contains('เตือน') ||
        lower.contains('pending') ||
        lower.contains('expiring') ||
        lower.contains('investigating') ||
        lower.contains('open')) {
      return AppPalette.warning;
    }

    if (lower.contains('offline') ||
        lower.contains('critical') ||
        lower.contains('danger') ||
        lower.contains('ไม่ผ่าน') ||
        lower.contains('suspended')) {
      return AppPalette.danger;
    }

    return AppPalette.bluePrimary;
  }

  @override
  Widget build(BuildContext context) {
    final badgeColor = resolveColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final int desktopColumns;
  final int tabletColumns;
  final double spacing;

  const ResponsiveWrap({
    super.key,
    required this.children,
    this.desktopColumns = 4,
    this.tabletColumns = 2,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 1;
        if (constraints.maxWidth >= 1200) {
          columns = desktopColumns;
        } else if (constraints.maxWidth >= 720) {
          columns = tabletColumns;
        }

        final itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children:
              children
                  .map(
                    (child) => SizedBox(
                      width: columns == 1 ? constraints.maxWidth : itemWidth,
                      child: child,
                    ),
                  )
                  .toList(),
        );
      },
    );
  }
}

class HorizontalTable extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;
  final int? statusColumn;
  final List<int> statusColumns;

  const HorizontalTable({
    super.key,
    required this.columns,
    required this.rows,
    this.statusColumn,
    this.statusColumns = const [],
  });

  @override
  Widget build(BuildContext context) {
    final highlighted = <int>{...statusColumns};
    if (statusColumn != null) highlighted.add(statusColumn!);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns:
            columns.map((column) => DataColumn(label: Text(column))).toList(),
        rows:
            rows
                .map(
                  (row) => DataRow(
                    cells: List.generate(
                      row.length,
                      (index) => DataCell(
                        highlighted.contains(index)
                            ? StatusBadge(label: row[index])
                            : Text(row[index]),
                      ),
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

class ActionInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const ActionInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppPalette.bluePrimary),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }
}

class MiniInfoGrid extends StatelessWidget {
  final Map<String, String> items;

  const MiniInfoGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 24,
      runSpacing: 20,
      children:
          items.entries
              .map(
                (entry) => SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(
                          color: AppPalette.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        entry.value,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class DeviceTypeTile extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;

  const DeviceTypeTile(this.title, this.amount, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.memory_rounded, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: Text(
        amount,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          color: AppPalette.textPrimary,
        ),
      ),
    );
  }
}

class ControlSwitchTile extends StatelessWidget {
  final bool value;
  final String title;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  const ControlSwitchTile({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class RoleTile extends StatelessWidget {
  final String role;
  final String description;
  final Color color;

  const RoleTile({
    super.key,
    required this.role,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(Icons.verified_user_rounded, color: color),
      ),
      title: Text(role, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(description),
    );
  }
}

class SensorTestCard extends StatelessWidget {
  final String title;
  final String status;
  final String description;
  final Color color;
  final List<String> checks;

  const SensorTestCard({
    super.key,
    required this.title,
    required this.status,
    required this.description,
    required this.color,
    required this.checks,
  });

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      title: title,
      trailing: StatusBadge(label: status, color: color),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            description,
            style: const TextStyle(color: AppPalette.textSecondary),
          ),
          const SizedBox(height: 12),
          ...checks.map(
            (check) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, color: color, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(check)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('เริ่มทดสอบ'),
          ),
        ],
      ),
    );
  }
}

class PathStep extends StatelessWidget {
  final String label;
  final Color color;

  const PathStep(this.label, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class SettingValueTile extends StatelessWidget {
  final String title;
  final String value;

  const SettingValueTile(this.title, this.value, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(value),
      trailing: const Icon(Icons.edit_rounded),
    );
  }
}

class IntegrationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String status;

  const IntegrationTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppPalette.bluePrimary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: StatusBadge(label: status),
    );
  }
}
