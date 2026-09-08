import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../controllers/director_meetings_controller.dart';

String meetingDate(DateTime date) =>
    DateFormat('dd/MM/yyyy HH:mm').format(date.toLocal());
String meetingType(String type) => switch (type) {
  'one_on_one' => 'เรียกพบรายบุคคล',
  'school_wide' => 'ประชุมทั้งโรงเรียน',
  'group' => 'ประชุมกลุ่ม',
  _ => type,
};
String meetingStatus(String status) => switch (status) {
  'scheduled' => 'นัดหมายแล้ว',
  'cancelled' => 'ยกเลิก',
  'completed' => 'เสร็จสิ้น',
  'accepted' => 'ตอบรับแล้ว',
  'pending' => 'รอตอบรับ',
  'declined' => 'ปฏิเสธ',
  'postpone_requested' => 'ขอเลื่อน',
  'open' => 'รอดำเนินการ',
  'done' => 'ทำเสร็จแล้ว',
  'draft' => 'ฉบับร่าง',
  'final' => 'ปิดบันทึกแล้ว',
  _ => status,
};
String attendanceLabel(bool? attended) => switch (attended) {
  true => 'มา',
  false => 'ขาด',
  null => 'ยังไม่ได้เช็คชื่อ',
};

class MeetingField {
  const MeetingField(
    this.key,
    this.label, {
    this.initial = '',
    this.required = false,
    this.lines = 1,
    this.options,
    this.validate,
  });
  final String key, label, initial;
  final bool required;
  final int lines;
  final Map<String, String>? options;
  final String? Function(String)? validate;
}

/// Keeps validation, pending state and errors above the modal barrier.
class MeetingActionDialog extends StatefulWidget {
  const MeetingActionDialog({
    super.key,
    required this.title,
    this.description,
    this.fields = const [],
    required this.submit,
    this.button = 'บันทึก',
  });
  final String title, button;
  final String? description;
  final List<MeetingField> fields;
  final Future<void> Function(Map<String, String>) submit;
  @override
  State<MeetingActionDialog> createState() => _MeetingActionDialogState();
}

class _MeetingActionDialogState extends State<MeetingActionDialog> {
  final form = GlobalKey<FormState>();
  late final inputs = {
    for (final f in widget.fields)
      f.key: TextEditingController(text: f.initial),
  };
  bool busy = false;
  String? error;
  @override
  void dispose() {
    for (final c in inputs.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.submit({
        for (final e in inputs.entries) e.key: e.value.text.trim(),
      });
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
      title: Text(widget.title),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.description != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(widget.description!),
                  ),
                for (final f in widget.fields)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: f.options == null
                        ? TextFormField(
                            controller: inputs[f.key],
                            enabled: !busy,
                            minLines: f.lines,
                            maxLines: f.lines,
                            decoration: InputDecoration(
                              labelText: f.label,
                              border: const OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                f.required && (value ?? '').trim().isEmpty
                                ? 'กรุณากรอก${f.label}'
                                : f.validate?.call((value ?? '').trim()),
                          )
                        : DropdownButtonFormField<String>(
                            initialValue: f.initial,
                            isExpanded: true,
                            decoration: InputDecoration(labelText: f.label),
                            items: f.options!.entries
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e.key,
                                    child: Text(
                                      e.value,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: busy
                                ? null
                                : (v) => inputs[f.key]!.text = v ?? '',
                            validator: (v) => f.required && (v ?? '').isEmpty
                                ? 'กรุณาเลือก${f.label}'
                                : null,
                          ),
                  ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (busy) const LinearProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        FilledButton(
          onPressed: busy ? null : submit,
          child: Text(busy ? 'กำลังบันทึกและตรวจสอบ' : widget.button),
        ),
      ],
    ),
  );
}

String? meetingDueDateValidator(String value) {
  if (value.isEmpty) return null;
  final parsed = DateTime.tryParse(value);
  return parsed != null && parsed.toIso8601String().substring(0, 10) == value
      ? null
      : 'ใช้รูปแบบ ค.ศ. YYYY-MM-DD เช่น 2027-03-10';
}
