import 'package:flutter/material.dart';
import 'package:shared_core/models/meeting_model.dart';
import 'package:shared_core/services/auth_service.dart';
import '../controllers/director_meetings_controller.dart';
import 'meeting_actions.dart';

class MeetingCreateDialog extends StatefulWidget {
  const MeetingCreateDialog({super.key, required this.controller});
  final DirectorMeetingsController controller;
  @override
  State<MeetingCreateDialog> createState() => _MeetingCreateDialogState();
}

class _MeetingCreateDialogState extends State<MeetingCreateDialog> {
  final directory = MeetingDirectoryController();
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      location = TextEditingController(),
      description = TextEditingController();
  final users = <String>{}, departments = <String>{};
  String type = 'group', visibility = 'attendees';
  DateTime? start, end;
  bool minutesExpected = true, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    directory.load();
  }

  @override
  void dispose() {
    directory.dispose();
    title.dispose();
    location.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pickDate(bool isStart) async {
    final now = DateTime.now();
    final initial = (isStart ? start : end) ?? start ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    final result = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isStart) {
        start = result;
      } else {
        end = result;
      }
    });
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (start == null || (end != null && !end!.isAfter(start!))) {
      setState(
        () => error = 'กรุณาระบุเวลาเริ่มและเวลาสิ้นสุดที่อยู่หลังเวลาเริ่ม',
      );
      return;
    }
    if ((type == 'one_on_one' && users.length != 1) ||
        (type == 'group' && users.isEmpty && departments.isEmpty)) {
      setState(
        () => error = type == 'one_on_one'
            ? 'เลือกผู้ถูกเรียกพบ 1 คน'
            : 'เลือกผู้เข้าร่วมหรือฝ่ายอย่างน้อย 1 รายการ',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final result = await widget.controller.create(
        MeetingDraft(
          title: title.text,
          type: type,
          startAt: start!,
          endAt: end,
          location: location.text,
          description: description.text,
          visibility: type == 'one_on_one' ? 'attendees' : visibility,
          minutesExpected: minutesExpected,
          userIds: type == 'school_wide' ? [] : users.toList(),
          departmentIds: type == 'group' ? departments.toList() : [],
        ),
      );
      if (mounted) Navigator.pop(context, result);
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
      title: const Text('สร้างประชุม / เรียกพบ'),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Form(
            key: form,
            child: ListenableBuilder(
              listenable: directory,
              builder: (context, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: title,
                    enabled: !busy,
                    decoration: const InputDecoration(
                      labelText: 'เรื่องประชุม',
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'กรุณาระบุเรื่องประชุม'
                        : null,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'ประเภท'),
                    items: ['group', 'school_wide', 'one_on_one']
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(meetingType(t)),
                          ),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (v) => setState(() {
                            type = v!;
                            users.clear();
                            departments.clear();
                          }),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: busy ? null : () => pickDate(true),
                        child: Text(
                          start == null
                              ? 'เลือกวันและเวลาเริ่ม'
                              : 'เริ่ม ${meetingDate(start!)}',
                        ),
                      ),
                      OutlinedButton(
                        onPressed: busy ? null : () => pickDate(false),
                        child: Text(
                          end == null
                              ? 'เวลาสิ้นสุด (ไม่บังคับ)'
                              : 'สิ้นสุด ${meetingDate(end!)}',
                        ),
                      ),
                      if (end != null)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() => end = null),
                          child: const Text('ล้างเวลาสิ้นสุด'),
                        ),
                    ],
                  ),
                  TextFormField(
                    controller: location,
                    enabled: !busy,
                    decoration: const InputDecoration(labelText: 'สถานที่'),
                  ),
                  TextFormField(
                    controller: description,
                    enabled: !busy,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'รายละเอียด'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('ต้องมีรายงานประชุม'),
                    value: minutesExpected,
                    onChanged: busy
                        ? null
                        : (v) => setState(() => minutesExpected = v),
                  ),
                  if (type == 'school_wide')
                    const Text('การมองเห็น: บุคลากรทั้งโรงเรียน')
                  else if (type == 'one_on_one')
                    const Text('การมองเห็น: คู่สนทนาและผู้ดูแลโรงเรียน')
                  else
                    DropdownButtonFormField<String>(
                      initialValue: visibility,
                      decoration: const InputDecoration(
                        labelText: 'การมองเห็น',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'attendees',
                          child: Text('ผู้เข้าร่วมและผู้บริหาร'),
                        ),
                        DropdownMenuItem(
                          value: 'school',
                          child: Text('บุคลากรทั้งโรงเรียน'),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() => visibility = v!),
                    ),
                  const SizedBox(height: 12),
                  if (type == 'school_wide')
                    const Text(
                      'ระบบจะเพิ่มบุคลากรของโรงเรียนเป็นผู้เข้าร่วมตอนสร้างประชุม',
                    )
                  else if (directory.loading)
                    const Text('กำลังโหลดรายชื่อบุคลากร')
                  else if (directory.error != null) ...[
                    Text(directory.error!),
                    TextButton(
                      onPressed: directory.load,
                      child: const Text('โหลดรายชื่อใหม่'),
                    ),
                  ] else ...[
                    Text(
                      type == 'one_on_one'
                          ? 'ผู้ถูกเรียกพบ (เลือก 1 คน)'
                          : 'เลือกผู้เข้าร่วม — รายบุคคล / ฝ่าย / กลุ่มสาระ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (directory.staff
                        .where((s) => s.userId != currentUserModel?.uid)
                        .isEmpty)
                      const Text('ยังไม่มีบุคลากรให้เลือก'),
                    for (final s in directory.staff.where(
                      (s) => s.userId != currentUserModel?.uid,
                    ))
                      CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.fullName),
                        value: users.contains(s.userId),
                        onChanged: busy
                            ? null
                            : (v) => setState(() {
                                if (v == true) {
                                  if (type == 'one_on_one') users.clear();
                                  users.add(s.userId);
                                } else {
                                  users.remove(s.userId);
                                }
                              }),
                      ),
                    if (type == 'group') ...[
                      const Divider(),
                      for (final d in directory.departments)
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('${d.name} (${d.memberCount} คน)'),
                          subtitle: Text(
                            d.isSubjectGroup ? 'กลุ่มสาระ' : 'ฝ่าย',
                          ),
                          value: departments.contains(d.departmentId),
                          onChanged: busy
                              ? null
                              : (v) => setState(
                                  () => v == true
                                      ? departments.add(d.departmentId)
                                      : departments.remove(d.departmentId),
                                ),
                        ),
                      const Text(
                        'สมาชิกของฝ่าย/กลุ่มสาระจะถูกบันทึกเป็นรายบุคคล ณ เวลาสร้างประชุม',
                      ),
                    ],
                  ],
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (busy) const LinearProgressIndicator(),
                ],
              ),
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
          onPressed:
              busy ||
                  (type != 'school_wide' &&
                      (directory.loading || directory.error != null))
              ? null
              : save,
          child: Text(busy ? 'กำลังสร้างและตรวจสอบ' : 'สร้างประชุม'),
        ),
      ],
    ),
  );
}
