import 'package:flutter/material.dart';
import '../controllers/meeting_requests_controller.dart';
import '../theme/app_palette.dart';
import 'meeting_actions.dart';
import 'timeline_feed.dart';

String requestStatus(String status) => switch (status) {
  'pending_head' => 'รอหัวหน้าฝ่าย',
  'pending_executive' => 'รอผู้บริหาร',
  'approved' => 'อนุมัติคำขอแล้ว',
  'rejected' => 'ไม่อนุมัติ',
  'cancelled' => 'ถอนคำขอ',
  _ => status,
};

Color _requestStatusColor(String status) => switch (status) {
  'approved' => AppPalette.success,
  'rejected' => AppPalette.danger,
  'cancelled' => AppPalette.textMuted,
  _ => const Color(0xFF956419),
};

class MeetingRequestsDialog extends StatefulWidget {
  const MeetingRequestsDialog({super.key});
  @override
  State<MeetingRequestsDialog> createState() => _MeetingRequestsDialogState();
}

class _MeetingRequestsDialogState extends State<MeetingRequestsDialog> {
  final controller = MeetingRequestsController();
  bool pendingOnly = true;
  @override
  void initState() {
    super.initState();
    controller.load();
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
      // Content-sized instead of a fixed height — an empty or short list
      // no longer leaves a large blank gap below it, and a long list still
      // gets a cap plus its own scroll instead of pushing the dialog off
      // screen.
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
                    Icons.mark_email_read_outlined,
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
                        'คำขอเข้าพบ / ขอจัดประชุม',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'อนุมัติคำขอก่อน แล้วผู้จัดจึงสร้างนัดหมายในทะเบียนประชุม',
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
                      child: Center(child: Text('กำลังโหลดคำขอ')),
                    );
                  }
                  if (controller.error != null) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(controller.error!),
                        TextButton(
                          onPressed: controller.load,
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    );
                  }
                  final records = controller.records
                      .where(
                        (r) =>
                            !pendingOnly ||
                            controller.actionable.contains(r.id),
                      )
                      .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: AppPalette.pageBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'เฉพาะที่รอฉันพิจารณา',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Switch(
                              value: pendingOnly,
                              activeColor: AppPalette.primaryPink,
                              onChanged: (v) => setState(() => pendingOnly = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (records.isEmpty)
                        const TimelineEmptyState(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'ยังไม่มีคำขอในรายการนี้',
                          message:
                              'เมื่อมีคนขอเข้าพบหรือขอจัดประชุม รายการจะปรากฏบนเส้นเวลานี้',
                        )
                      else
                        TimelineFeed(
                          items: [
                            for (final r in records)
                              TimelineItem(
                                dotColor: _requestStatusColor(r.status),
                                title: r.subject,
                                trailing: requestStatus(r.status),
                                meta:
                                    '${r.type == 'meet_request' ? 'ขอเข้าพบ' : 'ขอจัดประชุม'} · ${r.requester} · ${r.department ?? 'ไม่ระบุฝ่าย'}',
                                detail:
                                    'วันที่ ${r.date.toIso8601String().substring(0, 10)} · ${r.location ?? 'ยังไม่ระบุสถานที่'}${r.detail != null ? '\n${r.detail}' : ''}',
                                subLines: [
                                  if (r.headDecision != null)
                                    'หัวหน้าฝ่าย: ${requestStatus(r.headDecision!)} · ${r.headName ?? ''} ${r.headNote ?? ''}',
                                  if (r.execDecision != null)
                                    'ผู้บริหาร: ${requestStatus(r.execDecision!)} · ${r.execName ?? ''} ${r.execNote ?? ''}',
                                  if (r.status == 'approved')
                                    'ขั้นต่อไป: ผู้จัดสร้างนัดหมายจากปุ่ม “สร้างประชุม / เรียกพบ”',
                                ],
                                actions: controller.actionable.contains(r.id)
                                    ? [
                                        for (final approve in [true, false])
                                          OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: approve
                                                  ? AppPalette.success
                                                  : AppPalette.danger,
                                              side: BorderSide(
                                                color: approve
                                                    ? AppPalette.success
                                                    : AppPalette.danger,
                                              ),
                                            ),
                                            onPressed: () => showDialog<bool>(
                                              context: context,
                                              barrierDismissible: false,
                                              builder: (_) => MeetingActionDialog(
                                                title: approve
                                                    ? 'อนุมัติคำขอ'
                                                    : 'ไม่อนุมัติคำขอ',
                                                description:
                                                    '${r.subject}\n${r.status == 'pending_head' && approve ? 'ส่งต่อให้ผู้บริหารพิจารณา' : 'ยืนยันผลพิจารณาและแจ้งผู้ขอ'}',
                                                fields: [
                                                  MeetingField(
                                                    'note',
                                                    'เหตุผล / หมายเหตุ',
                                                    required: !approve,
                                                    lines: 3,
                                                  ),
                                                ],
                                                submit: (v) =>
                                                    controller.review(
                                                      r,
                                                      approve,
                                                      v['note']!,
                                                    ),
                                              ),
                                            ),
                                            child: Text(
                                              approve
                                                  ? 'อนุมัติ'
                                                  : 'ไม่อนุมัติ',
                                            ),
                                          ),
                                      ]
                                    : [],
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
                TextButton(
                  onPressed: controller.load,
                  child: const Text('โหลดใหม่'),
                ),
                const SizedBox(width: 8),
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
