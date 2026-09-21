import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../controllers/meeting_detail_controller.dart';
import '../controllers/director_meetings_controller.dart';

class MeetingAttachmentDialog extends StatefulWidget {
  const MeetingAttachmentDialog({super.key, required this.controller});
  final MeetingDetailController controller;
  @override
  State<MeetingAttachmentDialog> createState() =>
      _MeetingAttachmentDialogState();
}

class _MeetingAttachmentDialogState extends State<MeetingAttachmentDialog> {
  PlatformFile? file;
  bool busy = false;
  String? error;
  Future<void> pick() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result != null && mounted) {
        setState(() {
          file = result.files.single;
          error = null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => error = 'ไม่สามารถเปิดไฟล์ได้');
    }
  }

  Future<void> save() async {
    if (file?.bytes == null) return;
    if (file!.size > 20 * 1024 * 1024 || file!.size == 0) {
      setState(() => error = 'เลือกไฟล์ที่ไม่ว่างและขนาดไม่เกิน 20 MB');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.controller.attach(file!.name, file!.bytes!);
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
      title: const Text('แนบไฟล์ประชุม'),
      content: SizedBox(
        width: 500,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ไฟล์ส่วนตัวของการประชุม ขนาดไม่เกิน 20 MB'),
            TextButton.icon(
              onPressed: busy ? null : pick,
              icon: const Icon(Icons.attach_file),
              label: const Text('เลือกไฟล์'),
            ),
            if (file != null) Text('${file!.name} (${file!.size} bytes)'),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            if (busy) const LinearProgressIndicator(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: busy ? null : () => Navigator.pop(context),
          child: const Text('ปิด'),
        ),
        FilledButton(
          onPressed: busy || file?.bytes == null ? null : save,
          child: const Text('อัปโหลดและบันทึก'),
        ),
      ],
    ),
  );
}
