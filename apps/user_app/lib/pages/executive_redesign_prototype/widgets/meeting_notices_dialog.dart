import 'package:flutter/material.dart';
import '../controllers/meeting_notices_controller.dart';
import 'meeting_actions.dart';

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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('การแจ้งเตือนของฉัน'),
    content: SizedBox(
      width: 760,
      height: 520,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.loading) {
            return const Center(child: Text('กำลังโหลดการแจ้งเตือน'));
          }
          if (controller.error != null) {
            return Column(
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
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'ทั้งหมด ${controller.categories.fold(0, (n, c) => n + c.total)} รายการ · ยังไม่อ่าน ${controller.categories.fold(0, (n, c) => n + c.unread)} รายการ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('แสดง 50 รายการล่าสุดของหมวดที่เลือก'),
              ),
              if (controller.notices.isEmpty)
                const Text('ยังไม่มีการแจ้งเตือน'),
              Expanded(
                child: ListView(
                  children: [
                    for (final n in controller.notices)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          n.isUnread
                              ? Icons.mark_email_unread_outlined
                              : Icons.drafts_outlined,
                        ),
                        title: Text(n.title),
                        subtitle: Text(
                          '${n.body ?? ''}\n${meetingDate(n.createdAt.toLocal())}',
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ปิด'),
      ),
    ],
  );
}
