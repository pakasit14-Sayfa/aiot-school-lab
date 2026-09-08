import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/models/meeting_model.dart';
import 'package:shared_core/services/meeting_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../utils/web_download.dart';
import '../controllers/meeting_detail_controller.dart';
import '../controllers/director_meetings_controller.dart';
import '../widgets/director_common_widgets.dart';
import '../widgets/meeting_actions.dart';
import '../widgets/meeting_attendance_dialog.dart';
import '../widgets/meeting_attachment_dialog.dart';
import '../widgets/meeting_document.dart';

class MeetingDetailPage extends StatefulWidget {
  const MeetingDetailPage({
    super.key,
    required this.service,
    required this.meetingId,
  });
  final MeetingService service;
  final String meetingId;
  @override
  State<MeetingDetailPage> createState() => _MeetingDetailPageState();
}

class _MeetingDetailPageState extends State<MeetingDetailPage> {
  late final controller = MeetingDetailController(
    widget.service,
    widget.meetingId,
  );
  String? actionError;
  bool exporting = false;
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

  Future<void> action(Widget dialog) async {
    setState(() => actionError = null);
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกและตรวจสอบข้อมูลแล้ว')),
      );
    }
  }

  Widget button(String label, VoidCallback onPressed, {IconData? icon}) =>
      OutlinedButton.icon(
        onPressed: controller.busy ? null : onPressed,
        icon: Icon(icon ?? Icons.edit_outlined, size: 18),
        label: Text(label),
      );
  Widget section(
    String title,
    List<Widget> children, {
    List<Widget> actions = const [],
  }) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(20),
    decoration: directorWhiteCard(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...children,
        if (actions.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ],
    ),
  );
  Map<String, String> peopleOptions(MeetingDetail d) => {
    '': 'ยังไม่ระบุ',
    for (final p in d.people) p.id: p.name,
  };
  void agenda(MeetingDetail d, [MeetingAgenda? item]) => action(
    MeetingActionDialog(
      title: item == null ? 'เพิ่มวาระประชุม' : 'แก้ไขวาระ',
      fields: [
        MeetingField(
          'title',
          'ชื่อวาระ',
          initial: item?.title ?? '',
          required: true,
        ),
        MeetingField(
          'order',
          'ลำดับ',
          initial:
              (item?.order ??
                      (d.agenda.isEmpty
                          ? 1
                          : d.agenda
                                    .map((a) => a.order)
                                    .reduce((a, b) => a > b ? a : b) +
                                1))
                  .toString(),
          required: true,
          validate: (v) => int.tryParse(v) == null ? 'กรอกเลขจำนวนเต็ม' : null,
        ),
        MeetingField(
          'presenter',
          'ผู้นำเสนอ',
          initial: item?.presenterId ?? '',
          options: peopleOptions(d),
        ),
        MeetingField(
          'detail',
          'รายละเอียด',
          initial: item?.detail ?? '',
          lines: 4,
        ),
      ],
      submit: (v) => controller.agenda(
        v['title']!,
        v['detail']!,
        v['presenter']!.isEmpty ? null : v['presenter'],
        int.parse(v['order']!),
        itemId: item?.id,
      ),
    ),
  );
  Future<void> export() async {
    setState(() {
      exporting = true;
      actionError = null;
    });
    try {
      final fresh = await controller.forDocument();
      if (!mounted) return;
      downloadBytes(
        filename: 'meeting-${fresh.meeting.id}.html',
        bytes: utf8.encode(meetingDocument(fresh)),
        mimeType: 'text/html;charset=utf-8',
      );
    } catch (e) {
      if (mounted) setState(() => actionError = meetingError(e));
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  Future<void> download(MeetingAttachment attachment) async {
    try {
      final uri = await controller.download(attachment.id);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw StateError('download_failed');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => actionError =
              'เปิดไฟล์แนบไม่ได้ กรุณาตรวจสอบสิทธิ์และการเชื่อมต่อ',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF5F6FA),
    appBar: AppBar(
      title: const Text('รายละเอียดประชุม'),
      actions: [
        IconButton(
          onPressed: controller.busy ? null : controller.load,
          tooltip: 'โหลดข้อมูลใหม่',
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const Center(child: Text('กำลังโหลดรายละเอียดประชุม'));
        }
        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(controller.error!),
                TextButton(
                  onPressed: controller.load,
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            ),
          );
        }
        final d = controller.data!;
        final m = d.meeting;
        final manage = m.canManage && m.status != 'cancelled';
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (actionError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        actionError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  section(
                    m.title,
                    [
                      Text(
                        '${m.numberLabel} · ${meetingStatus(m.status)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'เริ่ม ${meetingDate(m.startAt)}${m.endAt == null ? '' : ' ถึง ${meetingDate(m.endAt!)}'}',
                      ),
                      Text(
                        'สถานที่: ${m.location?.isNotEmpty == true ? m.location : 'ยังไม่ระบุ'} · ผู้จัด: ${m.organizer ?? 'ยังไม่ระบุ'}',
                      ),
                      if (m.description?.isNotEmpty == true)
                        Text(m.description!),
                      if (m.isPrivate)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'ข้อมูลลับ: เฉพาะคู่สนทนาและผู้ดูแลโรงเรียน · การเปิดอ่านรายงานมีประวัติการเข้าถึง',
                          ),
                        ),
                    ],
                    actions: [
                      OutlinedButton.icon(
                        onPressed: kIsWeb && !exporting && !controller.busy
                            ? export
                            : null,
                        icon: const Icon(Icons.print_outlined),
                        label: Text(
                          exporting
                              ? 'กำลังเตรียมเอกสาร'
                              : 'ส่งออกเอกสารประชุม',
                        ),
                      ),
                      if (!kIsWeb) const Text('ส่งออกเอกสารได้บนเว็บ'),
                      if (manage && m.status == 'scheduled') ...[
                        button(
                          'ประชุมเสร็จสิ้น',
                          () => action(
                            MeetingActionDialog(
                              title: 'ยืนยันประชุมเสร็จสิ้น',
                              description:
                                  'เปลี่ยนสถานะการประชุมเป็นเสร็จสิ้น โดยรายงานประชุมยังแยกบันทึกได้',
                              submit: (_) => controller.complete(),
                            ),
                          ),
                          icon: Icons.check_circle_outline,
                        ),
                        button(
                          'ยกเลิกประชุม',
                          () => action(
                            MeetingActionDialog(
                              title: 'ยกเลิกประชุม',
                              fields: const [
                                MeetingField(
                                  'reason',
                                  'เหตุผลที่ยกเลิก',
                                  required: true,
                                  lines: 3,
                                ),
                              ],
                              submit: (v) => controller.cancel(v['reason']!),
                            ),
                          ),
                          icon: Icons.cancel_outlined,
                        ),
                      ],
                    ],
                  ),
                  if (m.myResponse != null &&
                      !d.people.any((p) => p.id == d.myUserId && p.organizer) &&
                      m.status == 'scheduled')
                    section(
                      'การตอบรับของฉัน',
                      [Text(meetingStatus(m.myResponse!))],
                      actions: [
                        button(
                          'ตอบรับ',
                          () => action(
                            MeetingActionDialog(
                              title: 'ตอบรับเข้าร่วม',
                              submit: (_) =>
                                  controller.respond('accepted', null),
                            ),
                          ),
                        ),
                        button(
                          'ขอเลื่อน',
                          () => action(
                            MeetingActionDialog(
                              title: 'ขอเลื่อนนัดหมาย',
                              description:
                                  'ส่งคำขอให้ผู้จัดพิจารณา วันและเวลานัดยังไม่เปลี่ยนจนกว่าผู้จัดจะดำเนินการ',
                              fields: const [
                                MeetingField(
                                  'reason',
                                  'เหตุผล / เวลาที่สะดวก',
                                  required: true,
                                  lines: 3,
                                ),
                              ],
                              submit: (v) => controller.respond(
                                'postpone_requested',
                                v['reason'],
                              ),
                            ),
                          ),
                        ),
                        if (!m.isPrivate)
                          button(
                            'ปฏิเสธ',
                            () => action(
                              MeetingActionDialog(
                                title: 'ปฏิเสธเข้าร่วม',
                                fields: const [
                                  MeetingField('reason', 'หมายเหตุ', lines: 2),
                                ],
                                submit: (v) =>
                                    controller.respond('declined', v['reason']),
                              ),
                            ),
                          ),
                      ],
                    ),
                  section(
                    'ผู้เข้าร่วม (${d.people.length} คน) / ภายนอก (${d.guests.length} คน)',
                    [
                      Text(
                        m.attendanceTakenAt == null
                            ? 'ยังไม่ได้เช็คชื่อ'
                            : 'เช็คชื่อแล้ว ${meetingDate(m.attendanceTakenAt!.toLocal())}',
                      ),
                      for (final p in d.people)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            '${p.name}${p.organizer ? ' · ผู้จัด' : ''}',
                          ),
                          subtitle: Text(
                            '${meetingStatus(p.response ?? 'pending')} · ${attendanceLabel(p.attended)}${p.note?.isNotEmpty == true ? '\n${p.note}' : ''}',
                          ),
                        ),
                      for (final p in d.guests)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${p.name} · ภายนอก'),
                          subtitle: Text(
                            '${p.organization ?? 'ไม่ระบุต้นสังกัด'} · ${attendanceLabel(p.attended)}',
                          ),
                          trailing: manage
                              ? IconButton(
                                  tooltip: 'นำผู้เข้าร่วมภายนอกออก',
                                  icon: const Icon(
                                    Icons.person_remove_outlined,
                                  ),
                                  onPressed: controller.busy
                                      ? null
                                      : () => action(
                                          MeetingActionDialog(
                                            title: 'นำผู้เข้าร่วมภายนอกออก',
                                            description: p.name,
                                            submit: (_) =>
                                                controller.removeGuest(p.id),
                                          ),
                                        ),
                                )
                              : null,
                        ),
                    ],
                    actions: manage
                        ? [
                            button(
                              'เช็คชื่อ',
                              () => action(
                                MeetingAttendanceDialog(
                                  controller: controller,
                                  data: d,
                                ),
                              ),
                              icon: Icons.checklist,
                            ),
                            if (!m.isPrivate)
                              button(
                                'เพิ่มผู้เข้าร่วมภายนอก',
                                () => action(
                                  MeetingActionDialog(
                                    title: 'เพิ่มผู้เข้าร่วมภายนอก',
                                    description:
                                        'บุคคลภายนอกไม่มีบัญชีและไม่ใช้ระบบตอบรับ',
                                    fields: const [
                                      MeetingField(
                                        'name',
                                        'ชื่อ–นามสกุล',
                                        required: true,
                                      ),
                                      MeetingField('organization', 'ต้นสังกัด'),
                                    ],
                                    submit: (v) => controller.guest(
                                      v['name']!,
                                      v['organization']!,
                                    ),
                                  ),
                                ),
                                icon: Icons.person_add_alt,
                              ),
                          ]
                        : [],
                  ),
                  section(
                    'วาระประชุม',
                    [
                      if (d.agenda.isEmpty) const Text('ยังไม่มีวาระประชุม'),
                      for (final a in d.agenda)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a.order}. ${a.title}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (a.presenter != null)
                                Text('ผู้นำเสนอ: ${a.presenter}'),
                              if (a.detail?.isNotEmpty == true) Text(a.detail!),
                              if (manage)
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    button('แก้วาระ', () => agenda(d, a)),
                                    button(
                                      'ลบวาระ',
                                      () => action(
                                        MeetingActionDialog(
                                          title: 'ลบวาระประชุม',
                                          description: a.title,
                                          submit: (_) =>
                                              controller.deleteAgenda(a.id),
                                        ),
                                      ),
                                      icon: Icons.delete_outline,
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                    actions: manage
                        ? [
                            button(
                              'เพิ่มวาระ',
                              () => agenda(d),
                              icon: Icons.add,
                            ),
                          ]
                        : [],
                  ),
                  section(
                    'รายงานประชุม — ${m.minutesLabel}',
                    [
                      if (!m.minutesExpected)
                        const Text('ผู้จัดกำหนดว่าไม่ต้องมีบันทึก')
                      else if (d.minutes == null)
                        Text(
                          m.minutesStatus == 'draft'
                              ? 'ฉบับร่างอ่านได้เฉพาะผู้จัดและผู้ดูแลโรงเรียน'
                              : 'ยังไม่มีรายงานประชุม',
                        ),
                      if (d.minutes != null) ...[
                        SelectableText(d.minutes!.body),
                        if (d.minutes!.status == 'final')
                          const Text(
                            'ปิดบันทึกแล้ว แก้ข้อความเดิมไม่ได้ ใช้บันทึกเพิ่มเติมเพื่อแก้ไขหรือชี้แจง',
                          ),
                        if (d.minutes!.cancelledAt != null)
                          Text('เอกสารถูกยกเลิก: ${d.minutes!.cancelReason}'),
                      ],
                      for (final a in d.addenda)
                        Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${a.kind == 'subject' ? 'คำชี้แจงผู้เข้าร่วม' : 'บันทึกเพิ่มเติม'} · ${a.author ?? 'ไม่ระบุ'} · ${meetingDate(a.createdAt)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SelectableText(a.body),
                            ],
                          ),
                        ),
                    ],
                    actions: [
                      if (manage &&
                          m.minutesExpected &&
                          d.minutes?.status != 'final')
                        button(
                          'บันทึกฉบับร่าง',
                          () => action(
                            MeetingActionDialog(
                              title: 'บันทึกรายงานประชุมฉบับร่าง',
                              fields: [
                                MeetingField(
                                  'body',
                                  'รายงานประชุม',
                                  initial: d.minutes?.body ?? '',
                                  required: true,
                                  lines: 10,
                                ),
                              ],
                              submit: (v) => controller.minutes(v['body']!),
                            ),
                          ),
                        ),
                      if (manage && d.minutes?.status == 'draft')
                        button(
                          'ปิดบันทึก',
                          () => action(
                            MeetingActionDialog(
                              title: 'ยืนยันปิดบันทึก',
                              description:
                                  'หลังปิดบันทึกจะเปลี่ยนข้อความเดิมไม่ได้ ผู้เข้าร่วมจะอ่านรายงานได้ การแก้ไขต้องเขียนบันทึกเพิ่มเติม',
                              button: 'ยืนยันปิดบันทึก',
                              submit: (_) =>
                                  controller.finalize(d.minutes!.body),
                            ),
                          ),
                          icon: Icons.lock_outline,
                        ),
                      if (d.minutes?.status == 'final' && d.minutes!.canAppend)
                        button(
                          'เพิ่มคำชี้แจง / บันทึกเพิ่มเติม',
                          () => action(
                            MeetingActionDialog(
                              title: 'บันทึกเพิ่มเติม',
                              description:
                                  'ข้อความนี้จะถูกเก็บพร้อมผู้เขียนและเวลา โดยไม่แก้รายงานต้นฉบับ',
                              fields: const [
                                MeetingField(
                                  'body',
                                  'ข้อความเพิ่มเติม',
                                  required: true,
                                  lines: 6,
                                ),
                              ],
                              submit: (v) => controller.addendum(v['body']!),
                            ),
                          ),
                          icon: Icons.note_add_outlined,
                        ),
                    ],
                  ),
                  section(
                    'มติและงานที่มอบหมาย',
                    [
                      if (d.resolutions.isEmpty)
                        const Text('ยังไม่มีมติหรืองานที่มอบหมาย'),
                      for (final r in d.resolutions)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.body,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'ผู้รับผิดชอบ: ${r.assignee ?? 'ยังไม่ระบุ'} · กำหนด: ${r.dueDate?.toIso8601String().substring(0, 10) ?? 'ยังไม่ระบุ'}',
                              ),
                              Text(meetingStatus(r.status)),
                              if (m.status != 'cancelled' &&
                                  (m.canManage || r.assigneeId == d.myUserId))
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    for (final status in [
                                      'open',
                                      'done',
                                      'cancelled',
                                    ].where((s) => s != r.status))
                                      button(
                                        'เปลี่ยนเป็น${meetingStatus(status)}',
                                        () => action(
                                          MeetingActionDialog(
                                            title:
                                                'เปลี่ยนสถานะงานเป็น${meetingStatus(status)}',
                                            description: r.body,
                                            submit: (_) => controller
                                                .resolutionStatus(r.id, status),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                    ],
                    actions: manage
                        ? [
                            button(
                              'เพิ่มมติ / มอบหมายงาน',
                              () => action(
                                MeetingActionDialog(
                                  title: 'เพิ่มมติและงานที่มอบหมาย',
                                  fields: [
                                    const MeetingField(
                                      'body',
                                      'มติ / งานที่มอบหมาย',
                                      required: true,
                                      lines: 4,
                                    ),
                                    MeetingField(
                                      'assignee',
                                      'ผู้รับผิดชอบ',
                                      options: peopleOptions(d),
                                    ),
                                    const MeetingField(
                                      'due',
                                      'วันครบกำหนด (ค.ศ. YYYY-MM-DD)',
                                      validate: meetingDueDateValidator,
                                    ),
                                  ],
                                  submit: (v) => controller.resolution(
                                    v['body']!,
                                    v['assignee']!.isEmpty
                                        ? null
                                        : v['assignee'],
                                    v['due']!.isEmpty ? null : v['due'],
                                  ),
                                ),
                              ),
                              icon: Icons.add,
                            ),
                          ]
                        : [],
                  ),
                  section(
                    'ไฟล์แนบ',
                    [
                      if (d.attachments.isEmpty) const Text('ยังไม่มีไฟล์แนบ'),
                      for (final a in d.attachments)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.insert_drive_file_outlined),
                          title: Text(a.name),
                          subtitle: Text('${a.size} bytes'),
                          trailing: IconButton(
                            tooltip: 'ดาวน์โหลดไฟล์',
                            icon: const Icon(Icons.download),
                            onPressed: () => download(a),
                          ),
                        ),
                    ],
                    actions: d.canUpload && m.status != 'cancelled'
                        ? [
                            button(
                              'แนบไฟล์',
                              () => action(
                                MeetingAttachmentDialog(controller: controller),
                              ),
                              icon: Icons.attach_file,
                            ),
                          ]
                        : [],
                  ),
                  section('การเตือนนัดหมาย', [
                    const Text(
                      'การแจ้งเชิญและการเปลี่ยนสถานะส่งผ่านระบบแจ้งเตือนแล้ว ส่วนการเตือนล่วงหน้ายังไม่มีงานตั้งเวลา',
                    ),
                    const OutlinedButton(
                      onPressed: null,
                      child: Text('ตั้งเตือนล่วงหน้า — ยังไม่รองรับ'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}
