import 'package:flutter/material.dart';
import '../controllers/meeting_notices_controller.dart';
import '../theme/app_palette.dart';
import 'meeting_actions.dart';
import 'timeline_feed.dart';

String noticeCategory(String category) => switch (category) {
  'meeting' => 'ประชุม',
  'request' => 'คำขอ',
  'incident' => 'เหตุการณ์',
  'learning' => 'การเรียน',
  'other' => 'อื่น ๆ',
  _ => category,
};

class MeetingNoticesDialog extends StatefulWidget {
  const MeetingNoticesDialog({super.key});
  @override
  State<MeetingNoticesDialog> createState() => _MeetingNoticesDialogState();
}

class _MeetingNoticesDialogState extends State<MeetingNoticesDialog> {
  final controller = MeetingNoticesController();
  @override
  void initState() {
    super.initState();
    controller.load(null);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Dialog(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: ConstrainedBox(
      // Content-sized instead of a fixed height — see the same fix in
      // MeetingRequestsDialog, which this dialog mirrors (both open from
      // director_meetings_page.dart's action row).
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 640),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppPalette.tint(AppPalette.primaryPinkDark, 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.notifications_none_rounded,
                    size: 18,
                    color: AppPalette.primaryPinkDark,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'การแจ้งเตือนของฉัน',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'แสดง 50 รายการล่าสุดของหมวดที่เลือก',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppPalette.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppPalette.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 16, 22, 4),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.loading) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('กำลังโหลดการแจ้งเตือน')),
                    );
                  }
                  if (controller.error != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(controller.error!),
                        TextButton(
                          onPressed: () => controller.load(controller.category),
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ทั้งหมด ${controller.categories.fold(0, (n, c) => n + c.total)} รายการ · ยังไม่อ่าน ${controller.categories.fold(0, (n, c) => n + c.unread)} รายการ',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('ทุกหมวด'),
                            selected: controller.category == null,
                            onSelected: (_) => controller.load(null),
                          ),
                          for (final c in controller.categories)
                            ChoiceChip(
                              label: Text(
                                '${noticeCategory(c.category)} · ${c.unread} ยังไม่อ่าน',
                              ),
                              selected: controller.category == c.category,
                              onSelected: (_) => controller.load(c.category),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (controller.notices.isEmpty)
                        const TimelineEmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: 'ยังไม่มีการแจ้งเตือน',
                          message:
                              'แจ้งเตือนเรื่องประชุม คำขอ และเหตุการณ์ในโรงเรียนจะปรากฏที่นี่',
                        )
                      else
                        TimelineFeed(
                          items: [
                            for (final n in controller.notices)
                              TimelineItem(
                                dotColor: n.isUnread
                                    ? AppPalette.primaryPinkDark
                                    : AppPalette.border,
                                dimmed: !n.isUnread,
                                title: n.title,
                                trailing: meetingDate(n.createdAt.toLocal()),
                                meta: n.body,
                              ),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          const Divider(height: 1, color: AppPalette.border),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ปิด'),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
