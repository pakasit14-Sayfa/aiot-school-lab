import 'package:flutter/material.dart';
import 'package:shared_core/models/meeting_model.dart';
import 'package:shared_core/services/meeting_service.dart';
import '../controllers/director_meetings_controller.dart';
import '../widgets/director_common_widgets.dart';
import '../widgets/director_workspace_widgets.dart';
import '../theme/app_palette.dart';
import '../widgets/meeting_actions.dart';
import '../widgets/meeting_create_dialog.dart';
import '../widgets/meeting_requests_dialog.dart';
import '../widgets/meeting_notices_dialog.dart';
import 'meeting_detail_page.dart';

class DirectorMeetingsPage extends StatefulWidget {
  const DirectorMeetingsPage({
    super.key,
    this.service,
    this.allowOrganize = true,
  });
  final MeetingService? service;
  final bool allowOrganize;
  @override
  State<DirectorMeetingsPage> createState() => _DirectorMeetingsPageState();
}

class _DirectorMeetingsPageState extends State<DirectorMeetingsPage> {
  late final controller = DirectorMeetingsController(
    widget.service ?? MeetingService(),
  );
  String query = '';
  String? type;
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

  Future<void> open(String id) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            MeetingDetailPage(service: controller.service, meetingId: id),
      ),
    );
    if (mounted) await controller.load();
  }

  Future<void> create() async {
    final result = await showDialog<MeetingDetail>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MeetingCreateDialog(controller: controller),
    );
    if (result == null || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สร้างประชุมและตรวจสอบข้อมูลแล้ว')),
    );
    await open(result.meeting.id);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final selectedType = controller.types.contains(type) ? type : null;
      final records = controller.filtered(query, selectedType);
      return DirectorWorkspace(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DirectorWorkspaceHero(
                icon: Icons.calendar_month_outlined,
                title: 'ประชุม / ขอพบ',
                subtitle: 'ทะเบียนประชุม นัดหมาย และรายงานของโรงเรียน',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (widget.allowOrganize)
                    OutlinedButton.icon(
                      onPressed: () => showDialog<void>(
                        context: context,
                        builder: (_) => const MeetingRequestsDialog(),
                      ),
                      icon: const Icon(Icons.inbox_outlined),
                      label: const Text('คำขอเข้าพบ / จัดประชุม'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const MeetingNoticesDialog(),
                    ),
                    icon: const Icon(Icons.notifications_none),
                    label: const Text('การแจ้งเตือน'),
                  ),
                  if (widget.allowOrganize)
                    FilledButton.icon(
                      onPressed: controller.loading || controller.error != null
                          ? null
                          : create,
                      icon: const Icon(Icons.add),
                      label: const Text('สร้างประชุม / เรียกพบ'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _StaffCalendarDialog(controller: controller),
                    ),
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: const Text('ปฏิทินบุคลากร'),
                  ),
                  IconButton(
                    onPressed: controller.loading ? null : controller.load,
                    tooltip: 'โหลดข้อมูลใหม่',
                    icon: const Icon(Icons.refresh),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (controller.loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('กำลังโหลดข้อมูลประชุม'),
                )
              else if (controller.error != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: directorWhiteCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(controller.error!),
                      TextButton(
                        onPressed: controller.load,
                        child: const Text('ลองอีกครั้ง'),
                      ),
                    ],
                  ),
                )
              else if (controller.meetings.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: directorWhiteCard(),
                  child: const Text('ยังไม่มีข้อมูลประชุม'),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: directorWhiteCard(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ทั้งหมด ${controller.meetings.length} รายการ · รอตอบรับของฉัน ${controller.meetings.where((m) => m.status == 'scheduled' && m.myResponse == 'pending').length} รายการ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'ค้นหาเรื่องประชุม ผู้จัด หรือสถานที่',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          ChoiceChip(
                            label: const Text('ทุกประเภท'),
                            selected: selectedType == null,
                            onSelected: (_) => setState(() => type = null),
                          ),
                          for (final t in controller.types)
                            ChoiceChip(
                              label: Text(meetingType(t)),
                              selected: selectedType == t,
                              onSelected: (_) => setState(() => type = t),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (records.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('ไม่พบประชุมที่ตรงกับตัวกรอง'),
                  ),
                for (final m in records)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => open(m.id),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: directorWhiteCard(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    m.isPrivate
                                        ? Icons.lock_outline
                                        : Icons.groups_outlined,
                                    size: 22,
                                    color: AppPalette.primaryPinkDark,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      m.title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${m.numberLabel} · ${meetingStatus(m.status)}',
                              ),
                              Text(
                                '${meetingDate(m.startAt)} · ${m.location?.isNotEmpty == true ? m.location : 'ยังไม่ระบุสถานที่'}',
                              ),
                              Text(
                                'ผู้เข้าร่วม ${m.attendeeCount} คน · ตอบรับ ${m.acceptedCount} · รอตอบรับ ${m.pendingCount}',
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppPalette.primaryPinkSoft,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  m.minutesLabel,
                                  style: const TextStyle(
                                    color: AppPalette.primaryPinkDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      );
    },
  );
}

class _StaffCalendarDialog extends StatefulWidget {
  const _StaffCalendarDialog({required this.controller});
  final DirectorMeetingsController controller;
  @override
  State<_StaffCalendarDialog> createState() => _StaffCalendarDialogState();
}

class _StaffCalendarDialogState extends State<_StaffCalendarDialog> {
  late Future<List<MeetingCalendarEntry>> result = widget.controller.calendar();
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('ปฏิทินบุคลากร'),
    content: SizedBox(
      width: 650,
      height: 440,
      child: FutureBuilder<List<MeetingCalendarEntry>>(
        future: result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('กำลังโหลดปฏิทิน'));
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                const Text('ไม่สามารถโหลดปฏิทินได้'),
                TextButton(
                  onPressed: () =>
                      setState(() => result = widget.controller.calendar()),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            );
          }
          final items = [...snapshot.data!]
            ..sort((a, b) => a.startAt.compareTo(b.startAt));
          if (items.isEmpty) return const Text('ยังไม่มีนัดหมายหรือกิจกรรม');
          return ListView(
            children: [
              for (final item in items)
                ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    '${meetingDate(item.startAt)} · ${meetingStatus(item.status)}',
                  ),
                  leading: Icon(
                    item.kind == 'summons'
                        ? Icons.lock_outline
                        : Icons.event_outlined,
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
