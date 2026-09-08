import 'package:flutter/material.dart';
import '../controllers/meeting_requests_controller.dart';
import 'meeting_actions.dart';

String requestStatus(String status) => switch (status) {
  'pending_head' => 'รอหัวหน้าฝ่าย',
  'pending_executive' => 'รอผู้บริหาร',
  'approved' => 'อนุมัติคำขอแล้ว',
  'rejected' => 'ไม่อนุมัติ',
  'cancelled' => 'ถอนคำขอ',
  _ => status,
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
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('คำขอเข้าพบ / ขอจัดประชุม'),
    content: SizedBox(
      width: 760,
      height: 520,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          if (controller.loading) {
            return const Center(child: Text('กำลังโหลดคำขอ'));
          }
          if (controller.error != null) {
            return Column(
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
                (r) => !pendingOnly || controller.actionable.contains(r.id),
              )
              .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'อนุมัติคำขอก่อน แล้วผู้จัดจึงสร้างนัดหมายและระบุเวลาในทะเบียนประชุม',
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('เฉพาะที่รอฉันพิจารณา'),
                value: pendingOnly,
                onChanged: (v) => setState(() => pendingOnly = v),
              ),
              if (records.isEmpty) const Text('ยังไม่มีคำขอในรายการนี้'),
              Expanded(
                child: ListView(
                  children: [
                    for (final r in records)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.subject,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${r.type == 'meet_request' ? 'ขอเข้าพบ' : 'ขอจัดประชุม'} · ${r.requester} · ${r.department ?? 'ไม่ระบุฝ่าย'}',
                              ),
                              Text(
                                'วันที่ ${r.date.toIso8601String().substring(0, 10)} · ${r.location ?? 'ยังไม่ระบุสถานที่'}',
                              ),
                              if (r.detail != null) Text(r.detail!),
                              Text(requestStatus(r.status)),
                              if (r.headDecision != null)
                                Text(
                                  'หัวหน้าฝ่าย: ${requestStatus(r.headDecision!)} · ${r.headName ?? ''} ${r.headNote ?? ''}',
                                ),
                              if (r.execDecision != null)
                                Text(
                                  'ผู้บริหาร: ${requestStatus(r.execDecision!)} · ${r.execName ?? ''} ${r.execNote ?? ''}',
                                ),
                              if (r.status == 'approved')
                                const Text(
                                  'ขั้นต่อไป: ผู้จัดสร้างนัดหมายจากปุ่ม “สร้างประชุม / เรียกพบ”',
                                ),
                              if (controller.actionable.contains(r.id))
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final approve in [true, false])
                                      TextButton(
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
                                            submit: (v) => controller.review(
                                              r,
                                              approve,
                                              v['note']!,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          approve ? 'อนุมัติ' : 'ไม่อนุมัติ',
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
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
      TextButton(onPressed: controller.load, child: const Text('โหลดใหม่')),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('ปิด'),
      ),
    ],
  );
}
