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

  Widget card(
    String title,
    List<Widget> children, {
    Color accent = AppPalette.primaryPinkDark,
    Color surface = Colors.white,
    IconData icon = Icons.school_outlined,
  }) => DirectorWorkspaceCard(
    title: title,
    icon: icon,
    accent: accent,
    surface: surface,
    children: children,
  );
  // ก็อบโครงสร้าง header จากเวอร์ชัน 7 ก.ย. มาตรง ๆ (การ์ดขาวเฉพาะหน้านี้
  // ไม่ใช่ DirectorWorkspaceHero กลางที่ใช้ร่วมกับอีก 5 หน้า) ต่างแค่ตัวเลข
  // ในป้ายเขียวเป็นจำนวนนักเรียนจริงจาก overview แทน "1,248" ที่แต่งขึ้น
  Widget _hero() {
    final count = controller.overview?.activeStudentCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final titleContent = Row(
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: Color(0xFF0284C7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ศูนย์ภาพรวมและพัฒนานักเรียน',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -.4,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ข้อมูลนักเรียน การมาเรียน และการดูแลช่วยเหลือของโรงเรียน',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
          final badgeContent = Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7ED),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF059669).withValues(alpha: .25),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        count == null
                            ? 'ยังไม่มีข้อมูลนักเรียน'
                            : 'นักเรียนที่ใช้งานอยู่ $count คน',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: const Color(0xFFF8FAFC),
                ),
                onPressed: controller.loading ? null : () => controller.load(),
                icon: const Icon(Icons.refresh_rounded, size: 14, color: Color(0xFF0F172A)),
                label: const Text(
                  'รีเฟรช',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          );
          if (box.maxWidth < 700) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [titleContent, const SizedBox(height: 14), badgeContent],
            );
          }
          return Row(
            children: [
              Expanded(child: titleContent),
              const SizedBox(width: 16),
              badgeContent,
            ],
          );
        },
      ),
    );
  }

  // การ์ดสรุปแบบเดียวกับ _StudentExecutiveSummary ของวันที่ 7 แต่คำนวณจาก
  // ข้อมูลจริง: การ์ดแรกใช้ overview.activeStudentCount ตรง ๆ การ์ดสองรวม
  // present/recorded ของทุกห้องที่ยังไม่กรอง (ไม่ใช้ตัวเลขแต่งขึ้น 1,248/94.2%)
  Widget _summaryCards() {
    final rows = controller.filteredAttendance(null, null);
    final present = rows.fold<int>(0, (n, r) => n + r.present);
    final recorded = rows.fold<int>(
      0,
      (n, r) => n + r.present + r.late + r.absent + r.excused,
    );
    final pct = recorded == 0 ? null : present * 100 / recorded;
    final count = controller.overview?.activeStudentCount;
    final cards = [
      _SummaryCardData(
        title: 'นักเรียนทั้งหมด',
        value: count?.toString() ?? '—',
        unit: 'คน',
        sub: '${controller.overview?.roomCount ?? 0} ห้องเรียน • ${controller.grades.length} ระดับชั้น',
        icon: Icons.groups_rounded,
        color: const Color(0xFF0284C7),
      ),
      _SummaryCardData(
        title: 'มาเรียนวันนี้',
        value: pct?.toStringAsFixed(1) ?? '—',
        unit: pct == null ? '' : '%',
        sub: pct == null
            ? 'ยังไม่มีการเช็คชื่อของวันนี้'
            : 'มา $present จาก $recorded คนที่เช็คชื่อแล้ว',
        icon: Icons.how_to_reg_rounded,
        color: const Color(0xFF16A34A),
      ),
    ];
    return LayoutBuilder(
      builder: (_, box) {
        final columns = box.maxWidth < 560 ? 1 : 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            for (final c in cards)
              SizedBox(
                width: columns == 1 ? box.maxWidth : (box.maxWidth - 14) / 2,
                child: _summaryCard(c),
              ),
          ],
        );
      },
    );
  }

  Widget _summaryCard(_SummaryCardData d) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE2E8F0)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .02),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: d.color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(d.icon, color: d.color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                d.title,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              d.value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                color: d.color,
                letterSpacing: -.6,
              ),
            ),
            if (d.unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                d.unit,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          d.sub,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
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
              _hero(),
              const SizedBox(height: 14),
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
                _summaryCards(),
                const SizedBox(height: 16),
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
                DirectorWorkspaceGrid(
                  children: [
                    card(
                      'สายการเรียนและคะแนน',
                      [
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
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
                      ],
                      accent: const Color(0xFF356A9A),
                      icon: Icons.auto_stories_outlined,
                    ),
                    card(
                      'ระบบดูแลช่วยเหลือนักเรียน',
                      [
                        const Text(
                          'รายการที่ครูบันทึกในระบบ ทั้งหมดของโรงเรียน',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ChoiceChip(
                              label: const Text('ทุกสถานะ'),
                              selected: selectedStatus == null,
                              onSelected: (_) =>
                                  setState(() => caseStatus = null),
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text('${c.categoryLabel} · ${c.statusLabel}'),
                                if (c.notes?.isNotEmpty == true) Text(c.notes!),
                                TextButton(
                                  onPressed: () => showHistory(c),
                                  child: Text(
                                    'ดูประวัติ (${c.interventionCount})',
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      accent: const Color(0xFF467A65),
                      icon: Icons.volunteer_activism_outlined,
                    ),
                  ],
                ),
              ],
              card(
                'งานติดตามที่ยังไม่รองรับ',
                [
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
                ],
                accent: AppPalette.textMuted,
                surface: AppPalette.softTag,
                icon: Icons.lock_outline,
              ),
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

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.unit,
    required this.sub,
    required this.icon,
    required this.color,
  });
  final String title, value, unit, sub;
  final IconData icon;
  final Color color;
}
