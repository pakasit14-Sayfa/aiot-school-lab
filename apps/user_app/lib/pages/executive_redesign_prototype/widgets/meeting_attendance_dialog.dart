import 'package:flutter/material.dart';
import 'package:shared_core/models/meeting_model.dart';
import '../controllers/meeting_detail_controller.dart';
import '../controllers/director_meetings_controller.dart';
import 'meeting_actions.dart';

class MeetingAttendanceDialog extends StatefulWidget {
  const MeetingAttendanceDialog({
    super.key,
    required this.controller,
    required this.data,
  });
  final MeetingDetailController controller;
  final MeetingDetail data;
  @override
  State<MeetingAttendanceDialog> createState() =>
      _MeetingAttendanceDialogState();
}

class _MeetingAttendanceDialogState extends State<MeetingAttendanceDialog> {
  late final users = widget.data.people
      .where((p) => p.attended == true)
      .map((p) => p.id)
      .toSet();
  late final guests = widget.data.guests
      .where((p) => p.attended == true)
      .map((p) => p.id)
      .toSet();
  bool busy = false;
  String? error;
  Future<void> save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.controller.attendance(users.toList(), guests.toList());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          busy = false;
          error = meetingError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: AlertDialog(
      title: const Text('เช็คชื่อผู้เข้าร่วม'),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'เลือกเฉพาะผู้ที่มา ผู้ที่ไม่เลือกจะถูกบันทึกว่าขาดเมื่อกดยืนยัน',
              ),
              for (final p in [...widget.data.people, ...widget.data.guests])
                CheckboxListTile(
                  title: Text(p.name),
                  subtitle: Text(
                    '${p.external ? 'บุคคลภายนอก · ' : ''}เดิม: ${attendanceLabel(p.attended)}',
                  ),
                  value: (p.external ? guests : users).contains(p.id),
                  onChanged: busy
                      ? null
                      : (v) => setState(() {
                          final selection = p.external ? guests : users;
                          v == true
                              ? selection.add(p.id)
                              : selection.remove(p.id);
                        }),
                ),
              Text(
                'จะบันทึก: มา ${users.length + guests.length} คน / ขาด ${widget.data.people.length + widget.data.guests.length - users.length - guests.length} คน',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (error != null)
                Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              if (busy) const LinearProgressIndicator(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        FilledButton(
          onPressed: busy ? null : save,
          child: const Text('ยืนยันผลเช็คชื่อ'),
        ),
      ],
    ),
  );
}
