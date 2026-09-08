import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../controllers/director_learning_controller.dart';
import '../widgets/director_workspace_widgets.dart';
import '../theme/app_palette.dart';

class DirectorLearningPage extends StatefulWidget {
  const DirectorLearningPage({super.key, this.controller});
  final DirectorLearningController? controller;
  @override
  State<DirectorLearningPage> createState() => _DirectorLearningPageState();
}

class _DirectorLearningPageState extends State<DirectorLearningPage> {
  late final controller = widget.controller ?? DirectorLearningController();
  String? grade, track, caseStatus;
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    if (widget.controller == null) controller.dispose();
    super.dispose();
  }

  String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: controller.date,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
    );
    if (date != null && mounted) await controller.load(onDate: date);
  }

  Widget card(String title, List<Widget> children) => DirectorWorkspaceCard(
    title: title,
    icon: Icons.school_outlined,
    children: children,
  );
  Widget metric(String title, String value) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppPalette.primaryPinkSoft,
      borderRadius: BorderRadius.circular(18),
    ),
    width: 180,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        Text(
          value,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppPalette.primaryPinkDark,
          ),
        ),
      ],
    ),
  );
  Future<void> showHistory(StudentSupportCase item) => showDialog<void>(
    context: context,
    builder: (_) => _SupportHistoryDialog(
      item: item,
      load: () => controller.history(item.caseId),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final selectedGrade = controller.grades.contains(grade) ? grade : null;
      final selectedTrack = controller.tracks.any((t) => t.trackId == track)
          ? track
          : null;
      final rows = controller.filteredAttendance(selectedGrade, selectedTrack);
      final statuses = controller.cases.map((c) => c.status).toSet();
      final selectedStatus = statuses.contains(caseStatus) ? caseStatus : null;
      final cases = controller.cases.where(
        (c) => selectedStatus == null || c.status == selectedStatus,
      );
      return DirectorWorkspace(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DirectorWorkspaceHero(
                icon: Icons.school_outlined,
                title: 'ศูนย์ภาพรวมและพัฒนานักเรียน',
                subtitle:
                    'ข้อมูลนักเรียน การมาเรียน และการดูแลช่วยเหลือของโรงเรียน',
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: controller.loading ? null : () => controller.load(),
                icon: const Icon(Icons.refresh),
                label: const Text('โหลดข้อมูลใหม่'),
              ),
              const SizedBox(height: 12),
              if (controller.loading)
                card('กำลังโหลดข้อมูลนักเรียน', [
                  const LinearProgressIndicator(),
                ])
              else if (controller.error != null)
                card('โหลดข้อมูลไม่สำเร็จ', [
                  Text(controller.error!),
                  TextButton(
                    onPressed: () => controller.load(),
                    child: const Text('ลองอีกครั้ง'),
                  ),
                ])
              else if (controller.isEmpty)
                card('ยังไม่มีข้อมูลนักเรียนหรือการเรียน', [
                  const Text(
                    'เมื่อโรงเรียนเพิ่มข้อมูลแล้ว สามารถโหลดข้อมูลใหม่ได้',
                  ),
                ])
              else ...[
                card('ภาพรวมปัจจุบันของโรงเรียน', [
                  Wrap(
                    spacing: 20,
                    runSpacing: 16,
                    children: [
                      metric(
                        'นักเรียนที่ใช้งานอยู่',
                        '${controller.overview!.activeStudentCount} คน',
                      ),
                      metric(
                        'ห้องในทะเบียนสถานที่',
                        '${controller.overview!.roomCount} ห้อง',
                      ),
                      metric(
                        'รายวิชา',
                        '${controller.overview!.courseCount} วิชา',
                      ),
                      metric(
                        'งานครบกำหนดใน 7 วัน',
                        '${controller.overview!.assignmentsDueThisWeek} งาน',
                      ),
                    ],
                  ),
                ]),
                card('การมาเรียนรายวัน', [
                  const Text(
                    'นับนักเรียนที่ใช้งานอยู่ในปัจจุบัน แม้เลือกดูวันย้อนหลัง ข้อมูลนี้เป็นการเช็คชื่อประจำชั้น',
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text('วันที่ ${dateLabel(controller.date)}'),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('ทุกระดับชั้น'),
                        selected: selectedGrade == null,
                        onSelected: (_) => setState(() => grade = null),
                      ),
                      for (final g in controller.grades)
                        ChoiceChip(
                          label: Text(g.isEmpty ? 'ยังไม่ระบุชั้น' : g),
                          selected: selectedGrade == g,
                          onSelected: (_) => setState(() => grade = g),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('ทุกสายการเรียน'),
                        selected: selectedTrack == null,
                        onSelected: (_) => setState(() => track = null),
                      ),
                      for (final t in controller.tracks)
                        ChoiceChip(
                          label: Text(t.name),
                          selected: selectedTrack == t.trackId,
                          onSelected: (_) => setState(() => track = t.trackId),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (rows.isEmpty)
                    const Text('ยังไม่มีข้อมูลนักเรียนในตัวกรองนี้'),
                  for (final r in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${r.roomLabel} · ${r.studentCount} คน',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'มา ${r.present} · สาย ${r.late} · ขาด ${r.absent} · ลา ${r.excused} · ยังไม่เช็คชื่อ ${r.unknown}',
                          ),
                          Text(
                            r.attendancePercent == null
                                ? 'ยังไม่มีข้อมูลการเช็คชื่อ'
                                : 'มาเรียน ${r.attendancePercent!.toStringAsFixed(1)}% ของผู้ที่เช็คชื่อแล้ว ${r.recorded} คน',
                          ),
                        ],
                      ),
                    ),
                ]),
                card('สายการเรียนและคะแนน', [
                  const Text(
                    'จำนวนตามทะเบียนปีการศึกษาปัจจุบัน คะแนนเฉลี่ยคิดจากคะแนนที่ยืนยันแล้วของทั้งสายการเรียน',
                  ),
                  const SizedBox(height: 12),
                  if (controller.tracks.isEmpty)
                    const Text('ยังไม่มีข้อมูลสายการเรียน'),
                  for (final t in controller.tracks)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${t.studentCount} คน · ${t.roomCount} ห้องเรียน',
                          ),
                          Text(
                            t.avgGradePercent == null
                                ? 'ยังไม่มีคะแนนที่ยืนยันแล้ว'
                                : 'คะแนนเฉลี่ย ${t.avgGradePercent!.toStringAsFixed(1)}%',
                          ),
                        ],
                      ),
                    ),
                ]),
                card('ระบบดูแลช่วยเหลือนักเรียน', [
                  const Text('รายการที่ครูบันทึกในระบบ ทั้งหมดของโรงเรียน'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('ทุกสถานะ'),
                        selected: selectedStatus == null,
                        onSelected: (_) => setState(() => caseStatus = null),
                      ),
                      for (final status in statuses)
                        ChoiceChip(
                          label: Text(
                            controller.cases
                                .firstWhere((c) => c.status == status)
                                .statusLabel,
                          ),
                          selected: selectedStatus == status,
                          onSelected: (_) =>
                              setState(() => caseStatus = status),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (cases.isEmpty)
                    const Text('ยังไม่มีเคสดูแลช่วยเหลือในตัวกรองนี้'),
                  for (final c in cases)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${c.studentName} · ${c.title}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('${c.categoryLabel} · ${c.statusLabel}'),
                          if (c.notes?.isNotEmpty == true) Text(c.notes!),
                          TextButton(
                            onPressed: () => showHistory(c),
                            child: Text('ดูประวัติ (${c.interventionCount})'),
                          ),
                        ],
                      ),
                    ),
                ]),
              ],
              card('งานติดตามที่ยังไม่รองรับ', [
                const Text(
                  'ยังไม่มีข้อมูลสรุปเยี่ยมบ้าน ทุนการศึกษา SDQ หรือระบบสั่งการจากผู้บริหาร การประเมินความเสี่ยงอัตโนมัติยังไม่รองรับขอบเขตทั้งโรงเรียน',
                ),
                const SizedBox(height: 8),
                const Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: null,
                      child: Text('สั่งการติดตาม'),
                    ),
                    OutlinedButton(
                      onPressed: null,
                      child: Text('รายงานเยี่ยมบ้าน / SDQ'),
                    ),
                    OutlinedButton(
                      onPressed: null,
                      child: Text('ส่งออกรายงานการเรียน'),
                    ),
                  ],
                ),
                const Text('การส่งออกรายงานการเรียนยังไม่เปิดใช้งาน'),
              ]),
            ],
          ),
        ),
      );
    },
  );
}

class _SupportHistoryDialog extends StatefulWidget {
  const _SupportHistoryDialog({required this.item, required this.load});
  final StudentSupportCase item;
  final Future<List<StudentSupportIntervention>> Function() load;
  @override
  State<_SupportHistoryDialog> createState() => _SupportHistoryDialogState();
}

class _SupportHistoryDialogState extends State<_SupportHistoryDialog> {
  late Future<List<StudentSupportIntervention>> result = widget.load();
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('ประวัติการช่วยเหลือ: ${widget.item.studentName}'),
    content: SizedBox(
      width: 600,
      height: 400,
      child: FutureBuilder<List<StudentSupportIntervention>>(
        future: result,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: Text('กำลังโหลดประวัติ'));
          }
          if (snapshot.hasError) {
            return Column(
              children: [
                const Text('ไม่สามารถโหลดประวัติการช่วยเหลือได้'),
                TextButton(
                  onPressed: () => setState(() => result = widget.load()),
                  child: const Text('ลองอีกครั้ง'),
                ),
              ],
            );
          }
          if (snapshot.data!.isEmpty) {
            return const Text('ยังไม่มีบันทึกการช่วยเหลือ');
          }
          return ListView(
            children: [
              for (final entry in snapshot.data!)
                ListTile(
                  title: Text(entry.actionTypeLabel),
                  subtitle: Text(
                    '${entry.notes}\nผู้บันทึก: ${entry.recordedByName}\n${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
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
