import 'package:flutter/material.dart';
import '../theme/app_palette.dart';

/// One entry on a [TimelineFeed] — a dot on a connecting vertical line,
/// with a title line, optional trailing text next to it (status/time),
/// optional meta/detail lines, optional nested sub-lines, and optional
/// trailing actions (e.g. approve/reject buttons).
class TimelineItem {
  const TimelineItem({
    required this.dotColor,
    required this.title,
    this.trailing,
    this.meta,
    this.detail,
    this.subLines = const [],
    this.actions = const [],
    this.dimmed = false,
  });

  final Color dotColor;
  final String title;
  final String? trailing;
  final String? meta;
  final String? detail;
  final List<String> subLines;
  final List<Widget> actions;

  /// Read/settled items read as quieter than unread/pending ones.
  final bool dimmed;
}

/// Vertical timeline feed — a connecting line with a colored dot per
/// [TimelineItem], used where the content is naturally a sequence of
/// events (a request's approval steps, a chronological notice feed)
/// rather than independent cards to compare side by side.
class TimelineFeed extends StatelessWidget {
  const TimelineFeed({super.key, required this.items});
  final List<TimelineItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          _TimelineRow(item: items[i], isLast: i == items.length - 1),
      ],
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});
  final TimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final titleColor = item.dimmed ? AppPalette.textMuted : AppPalette.textDark;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 26,
            child: Column(
              children: [
                const SizedBox(height: 3),
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.dotColor,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: item.dotColor,
                        blurRadius: 0,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(width: 1.5, color: AppPalette.border),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: item.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: titleColor,
                          ),
                        ),
                        if (item.trailing != null)
                          TextSpan(
                            text: ' · ${item.trailing}',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: item.dotColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (item.meta != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.meta!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                  if (item.detail != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      item.detail!,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textDark,
                        height: 1.6,
                      ),
                    ),
                  ],
                  if (item.subLines.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.only(left: 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(color: AppPalette.border, width: 2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final line in item.subLines)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                line,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  color: AppPalette.textMuted,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  if (item.actions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(spacing: 8, runSpacing: 8, children: item.actions),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Centered icon + heading + explanation, sized to fill the space it's
/// given intentionally — used instead of a single line of "ยังไม่มี..."
/// text floating above an otherwise-empty scroll area.
class TimelineEmptyState extends StatelessWidget {
  const TimelineEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });
  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppPalette.pageBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 24, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppPalette.textMuted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
