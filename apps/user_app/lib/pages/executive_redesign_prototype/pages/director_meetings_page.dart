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
              // Used its own locally-reimplemented hero (not
              // DirectorWorkspaceHero) back when this page deliberately
              // diverged from the rest of the lane's color — now that the
              // whole lane shares the same navy tone (2026-09-14 recolor),
              // that divergence is gone, so this is just the shared hero.
              const DirectorWorkspaceHero(
                title: 'ประชุม / ขอพบ',
                subtitle: 'ทะเบียนประชุม นัดหมาย และรายงานของโรงเรียน',
                icon: Icons.calendar_month_outlined,
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
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppPalette.primaryPinkDark,
                        side: const BorderSide(color: AppPalette.primaryPink),
                      ),
                      icon: const Icon(Icons.inbox_outlined),
                      label: const Text('คำขอเข้าพบ / จัดประชุม'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => const MeetingNoticesDialog(),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.primaryPinkDark,
                      side: const BorderSide(color: AppPalette.primaryPink),
                    ),
                    icon: const Icon(Icons.notifications_none),
                    label: const Text('การแจ้งเตือน'),
                  ),
                  if (widget.allowOrganize)
                    FilledButton.icon(
                      onPressed: controller.loading || controller.error != null
                          ? null
                          : create,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppPalette.primaryPink,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add),
                      label: const Text('สร้างประชุม / เรียกพบ'),
                    ),
                  OutlinedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _StaffCalendarDialog(controller: controller),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppPalette.primaryPinkDark,
                      side: const BorderSide(color: AppPalette.primaryPink),
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
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'ค้นหาเรื่องประชุม ผู้จัด หรือสถานที่',
                          hintStyle: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: AppPalette.primaryPink,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppPalette.pageBg,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: AppPalette.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: AppPalette.border,
                            ),
                          ),
                          // Theme's own focusedBorder is a 12px-radius rect
                          // (buildRoleTheme) — without overriding it here
                          // too, focusing this field would snap its corners
                          // from the pill shape to that rect.
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: AppPalette.primaryPink,
                              width: 1.5,
                            ),
                          ),
                        ),
                        onChanged: (v) => setState(() => query = v),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _typeChip(
                            label: 'ทุกประเภท',
                            selected: selectedType == null,
                            onSelected: () => setState(() => type = null),
                          ),
                          for (final t in controller.types)
                            _typeChip(
                              label: meetingType(t),
                              selected: selectedType == t,
                              onSelected: () => setState(() => type = t),
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
                DirectorWorkspaceGrid(
                  children: [
                    for (final m in records)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _meetingCard(m),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    },
  );

  // Still a ChoiceChip under the hood (tests tap it by widget type via
  // `find.widgetWithText(ChoiceChip, ...)`) — just restyled as a pill with
  // the page's own slate accent instead of the theme's default chip look.
  Widget _typeChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      avatar: selected
          ? const Icon(
              Icons.check_rounded,
              size: 15,
              color: AppPalette.primaryPinkDark,
            )
          : null,
      labelStyle: TextStyle(
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        color: selected ? AppPalette.primaryPinkDark : AppPalette.textMuted,
      ),
      backgroundColor: Colors.white,
      selectedColor: AppPalette.tint(AppPalette.primaryPink, 0.12),
      side: BorderSide(
        color: selected ? AppPalette.primaryPink : AppPalette.border,
        width: selected ? 1.5 : 1,
      ),
      shape: const StadiumBorder(),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    );
  }

  // Draft/none/not-yet/final are the only 4 values minutesLabel can be
  // (see MeetingRecord.minutesLabel) — color follows which one, instead of
  // the old fixed blue for every value regardless of what it said.
  Color _minutesColor(String label) => switch (label) {
    'ปิดบันทึกแล้ว' => AppPalette.success,
    'บันทึกฉบับร่าง' => const Color(0xFFD97706),
    'ไม่ต้องมีบันทึก' => AppPalette.textMuted,
    _ => const Color(0xFF356A9A),
  };

  IconData _minutesIcon(String label) => switch (label) {
    'ปิดบันทึกแล้ว' => Icons.check_circle_rounded,
    'บันทึกฉบับร่าง' => Icons.edit_note_rounded,
    'ไม่ต้องมีบันทึก' => Icons.remove_circle_outline_rounded,
    _ => Icons.description_outlined,
  };

  // Icon-badge pill — same language as the icon-badge rows already shipped
  // on the teachers page ("สิ่งที่ควรติดตาม"), not a new visual language.
  Widget _meetingPill({
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 10, 4),
      decoration: BoxDecoration(
        color: AppPalette.tint(color, 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 11, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _meetingCard(MeetingRecord m) {
    return Material(
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
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppPalette.tint(AppPalette.primaryPink, 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      m.isPrivate ? Icons.lock_outline : Icons.groups_outlined,
                      size: 18,
                      color: AppPalette.primaryPinkDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      m.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppPalette.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${m.numberLabel} · ${meetingStatus(m.status)}',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 13,
                    color: Color(0xFF356A9A),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${meetingDate(m.startAt)} · ${m.location?.isNotEmpty == true ? m.location : 'ยังไม่ระบุสถานที่'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF356A9A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'ผู้เข้าร่วม ${m.attendeeCount} คน · ตอบรับ ${m.acceptedCount} · รอตอบรับ ${m.pendingCount}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _meetingPill(
                    label: m.minutesLabel,
                    icon: _minutesIcon(m.minutesLabel),
                    color: _minutesColor(m.minutesLabel),
                  ),
                  if (m.pendingCount > 0)
                    _meetingPill(
                      label: 'รอตอบรับ ${m.pendingCount} คน',
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFFD97706),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
