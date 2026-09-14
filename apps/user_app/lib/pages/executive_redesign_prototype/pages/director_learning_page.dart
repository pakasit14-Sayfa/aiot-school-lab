import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../../utils/web_download.dart';
import '../controllers/director_learning_controller.dart';
import '../widgets/director_workspace_widgets.dart';
import '../theme/app_palette.dart';
import 'director_student_followup_page.dart';

// dataviz skill's fixed status palette (good/warning/critical) — kept
// separate from AppPalette on purpose: a status color must never double as
// the page's pink/blue brand accent, or "this bar means trouble" and "this
// is just decoration" become impossible to tell apart at a glance.
const _kStatusGood = Color(0xFF0CA30C);
const _kStatusWarning = Color(0xFFFAB219);
const _kStatusCritical = Color(0xFFD03B3B);
const _kStatusWarningSoft = Color(0xFFFEF3D6);
const _kStatusCriticalSoft = Color(0xFFFBE4E4);
const _kStatusWarningInk = Color(0xFF8A5A00);
const _kAttendanceTarget = 90.0;

enum _AttendanceStatus { none, good, warning, critical }

_AttendanceStatus _attendanceStatusFor(double? pct) {
  if (pct == null) return _AttendanceStatus.none;
  if (pct >= _kAttendanceTarget) return _AttendanceStatus.good;
  if (pct >= _kAttendanceTarget - 5) return _AttendanceStatus.warning;
  return _AttendanceStatus.critical;
}

Color _attendanceStatusColor(_AttendanceStatus status) => switch (status) {
  _AttendanceStatus.good => _kStatusGood,
  _AttendanceStatus.warning => _kStatusWarning,
  _AttendanceStatus.critical => _kStatusCritical,
  _AttendanceStatus.none => AppPalette.border,
};

class _GradeAttendanceStat {
  _GradeAttendanceStat(this.grade, List<SchoolHomeroomAttendance> rows)
    : present = rows.fold<int>(0, (n, r) => n + r.present),
      late = rows.fold<int>(0, (n, r) => n + r.late),
      absent = rows.fold<int>(0, (n, r) => n + r.absent),
      excused = rows.fold<int>(0, (n, r) => n + r.excused);
  final String grade;
  final int present, late, absent, excused;
  int get recorded => present + late + absent + excused;
  double? get pct => recorded == 0 ? null : present * 100 / recorded;
}

// เดิม "ไม่มีข้อมูล" วาดเป็นแท่งสูง 4px สี AppPalette.border แทบมองไม่เห็นบน
// พื้นขาว (บั๊กที่ทำให้การ์ดนี้ดูเหมือนพังในสกรีนช็อตที่ผู้ใช้ส่งมา) —
// เปลี่ยนเป็นกรอบเส้นประที่มองเห็นชัดว่า "ระบบทำงานอยู่ แค่ยังไม่มีใครเช็คชื่อ"
class _DashedTrack extends StatelessWidget {
  const _DashedTrack();
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 18,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(child: CustomPaint(painter: _DashedTrackPainter())),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 12,
              color: AppPalette.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              'ยังไม่เช็คชื่อ',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppPalette.textMuted,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _DashedTrackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size.height - 12) / 2, size.width, 12),
      const Radius.circular(3),
    );
    final paint = Paint()
      ..color = AppPalette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dashed = Path();
    for (final metric in (Path()..addRRect(rect)).computeMetrics()) {
      var distance = 0.0;
      const dashWidth = 4.0, gapWidth = 3.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        dashed.addPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          Offset.zero,
        );
        distance = next + gapWidth;
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

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

  // mockup "C — เซลล์สี่เหลี่ยมมุมมน + ปุ่มข้ามไปวันนี้" ที่เลือกไว้ — สี/มุม
  // โค้ง/ทรงเซลล์วันที่ปรับผ่าน DatePickerThemeData ได้ตรงๆ (ยังเป็น
  // showDatePicker ของ Flutter เดิม ไม่ได้สร้างปฏิทินใหม่) แต่ปุ่ม "วันนี้"
  // ที่วางไว้ในแถวปุ่มยกเลิก/ตกลงของมอคอัพทำไม่ได้จริง — แถวปุ่มของ
  // DatePickerDialog เป็นของภายใน Flutter ไม่มีช่องให้เสียบปุ่มที่ 3 เข้าไป
  // (ต้อง fork ทั้ง widget ถึงจะทำได้ ไม่ใช่แค่ปรับธีม) ย้ายปุ่ม "วันนี้" มา
  // ไว้ข้างช่องแทน ได้ผลลัพธ์เดียวกัน (กดแล้วข้ามไปวันนี้ทันทีโดยไม่ต้องเปิด
  // ปฏิทินเลยด้วยซ้ำ) แค่ตำแหน่งต่างจากมอคอัพ — เช็คแบบนี้ก่อนแตะโค้ดจริง
  // ดีกว่าไปเจอตอนใช้งานว่าทำตามที่อนุมัติไม่ได้ 100%
  //
  // อีกจุดที่ต่างจากมอคอัพ: หัวปฏิทิน ("กันยายน ค.ศ. 2026") มาจาก Thai
  // MaterialLocalizations ของ Flutter เอง ไม่ใช่ข้อความที่แอปเขียนเอง — เป็น
  // ค.ศ. จริง ไม่ใช่ พ.ศ. อย่างที่มอคอัพเขียนไว้ (ตอนทำมอคอัพเข้าใจผิดว่าทั้ง
  // แอปใช้ พ.ศ. หมด แต่ dateLabel ของหน้านี้เองก็ยังเป็น ค.ศ. เหมือนกัน) แก้
  // ให้เป็น พ.ศ. ได้จริงแต่ต้อง override MaterialLocalizations ทั้งแอป ไม่ใช่
  // แค่ปฏิทินตัวนี้ — นอกขอบเขตของงานนี้ ไม่แตะ
  Future<void> pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: controller.date,
      firstDate: DateTime(now.year - 10),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            headerBackgroundColor: AppPalette.primaryPinkSoft,
            headerForegroundColor: AppPalette.textDark,
            dayShape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            yearShape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
            ),
            todayBorder: const BorderSide(
              color: AppPalette.primaryPinkDark,
              width: 1.4,
            ),
            todayForegroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : AppPalette.primaryPinkDark,
            ),
            dayBackgroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppPalette.primaryPinkDark
                  : null,
            ),
            dayForegroundColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? Colors.white
                  : AppPalette.textDark,
            ),
            cancelButtonStyle: TextButton.styleFrom(
              foregroundColor: AppPalette.textMuted,
            ),
            confirmButtonStyle: TextButton.styleFrom(
              backgroundColor: AppPalette.primaryPinkDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        child: child!,
      ),
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
  Widget _hero(
    Iterable<StudentSupportCase> cases,
    List<SchoolHomeroomAttendance> attendance,
  ) {
    final count = controller.overview?.activeStudentCount;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppPalette.border),
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
                  color: AppPalette.primaryPinkDark.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_rounded,
                  color: AppPalette.primaryPinkDark,
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
                        color: AppPalette.textDark,
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
                        color: AppPalette.textMuted,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
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
              // รีเฟรช ลดเหลือแค่ไอคอนกลม ไม่มีกรอบ — ใช้บ่อยแต่ไม่ใช่แอ็กชัน
              // หลักของการ์ดนี้ ไม่ต้องแย่งน้ำหนักสายตากับ 2 ปุ่มขวามือ
              IconButton(
                tooltip: 'รีเฟรช',
                onPressed: controller.loading ? null : () => controller.load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                color: AppPalette.textMuted,
                visualDensity: VisualDensity.compact,
              ),
              // ปุ่มของการ์ด "งานติดตามนักเรียนรายบุคคล" ย้ายขึ้นมาไว้ตรงนี้
              // แทน — "เปิดระบบ" เป็นแอ็กชันหลักของการ์ดนี้เลยทำเป็นปุ่มทึบ
              // เด่นสุด "ส่งออก" เป็นแอ็กชันรองใช้กรอบบางแบบเดียวกับรีเฟรชเดิม
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  side: const BorderSide(color: AppPalette.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: AppPalette.pageBg,
                ),
                onPressed: () => _exportLearningReportCsv(cases, attendance),
                icon: const Icon(
                  Icons.download_rounded,
                  size: 14,
                  color: AppPalette.textDark,
                ),
                label: const Text(
                  'ส่งออกรายงานการเรียน',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppPalette.textDark,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppPalette.primaryPinkDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _openFollowup(0),
                icon: const Icon(Icons.open_in_new_rounded, size: 14),
                label: const Text(
                  'เปิดระบบติดตามนักเรียน',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          );
          // badgeContent grew from 2 items (pill + รีเฟรช) to 4 (+ เปิดระบบ +
          // ส่งออก) — as a bare non-flex Row sibling it got unbounded width
          // and overflowed by 115px instead of wrapping. Flexible forces a
          // real max-width so the Wrap inside can actually break lines.
          if (box.maxWidth < 980) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                titleContent,
                const SizedBox(height: 14),
                badgeContent,
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: titleContent),
              const SizedBox(width: 16),
              Flexible(child: badgeContent),
            ],
          );
        },
      ),
    );
  }

  // เวอร์ชันใหม่ (mockup "A — การ์ดเดียว คั่นเส้นบาง" ที่เลือกไว้): เดิม 3 ช่อง
  // เป็นกล่อง DropdownButtonFormField/InputDecorator แยกกัน 3 ใบ เส้นขอบซ้ำ
  // กันเยอะ และเมนู dropdown ตอนเปิดเป็นเมนูขาวเปล่า default ของ Flutter ไม่มี
  // การไฮไลต์ตัวที่เลือกอยู่ — เปลี่ยนมาเป็นการ์ดเดียว คั่นด้วยเส้นบาง (แนวตั้ง
  // ตอนจอกว้าง แนวนอนตอนจอแคบ) และแทน DropdownButtonFormField ด้วย
  // showMenu แบบกำหนดสไตล์เอง (มุมโค้ง เงานุ่ม ตัวที่เลือกอยู่มีตัวหนา+เครื่อง
  // หมายถูก) ให้ตรงกับที่อนุมัติไว้ — ยังผูกกับ state ตัวเดียวกับที่กรองรายการ
  // ห้องด้านล่างอยู่แล้ว ไม่ใช่ตัวกรองใหม่
  static const String _kAllSentinel = ' __all__';

  Future<void> _openFilterMenu(
    BuildContext context, {
    required String? selected,
    required List<MapEntry<String?, String>> options,
    required ValueChanged<String?> onSelected,
  }) async {
    final button = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomLeft(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );
    // showMenu<String> ไม่ใช่ <String?> — ปุ่ม "ทุกระดับชั้น/ทุกสายการเรียน"
    // ใน state จริงแทนด้วย null แต่ showMenu คืน null ทั้งตอน "กดเลือก item
    // ที่ value เป็น null จริงๆ" และตอน "ปิดเมนูโดยไม่เลือกอะไรเลย" กำกวมกัน
    // ใช้ sentinel string แทน null ภายในเมนูนี้เพื่อแยก 2 กรณีออกจากกัน
    final result = await showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black.withValues(alpha: .12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppPalette.border),
      ),
      constraints: const BoxConstraints(minWidth: 200),
      items: [
        for (final entry in options)
          PopupMenuItem<String>(
            value: entry.key ?? _kAllSentinel,
            height: 42,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: entry.key == selected
                        ? FontWeight.w800
                        : FontWeight.w600,
                    color: entry.key == selected
                        ? AppPalette.primaryPinkDark
                        : AppPalette.textDark,
                  ),
                ),
                if (entry.key == selected)
                  const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppPalette.primaryPinkDark,
                  ),
              ],
            ),
          ),
      ],
    );
    if (result == null) return; // ปิดเมนูโดยไม่ได้เลือก ไม่ต้องทำอะไร
    onSelected(result == _kAllSentinel ? null : result);
  }

  Widget _filterField({
    required String label,
    required IconData icon,
    required String value,
    required void Function(BuildContext context) onTap,
    Widget? trailing,
  }) {
    return Builder(
      builder: (context) => InkWell(
        onTap: () => onTap(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: .3,
                  color: AppPalette.textMuted,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(icon, size: 17, color: AppPalette.primaryPinkDark),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppPalette.textDark,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[trailing, const SizedBox(width: 4)],
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppPalette.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterBar(String? selectedGrade, String? selectedTrack) {
    final gradeLabel = selectedGrade == null
        ? 'ทุกระดับชั้น'
        : (selectedGrade.isEmpty ? 'ยังไม่ระบุชั้น' : selectedGrade);
    final trackLabel = selectedTrack == null
        ? 'ทุกสายการเรียน'
        : (controller.tracks
                  .where((t) => t.trackId == selectedTrack)
                  .firstOrNull
                  ?.name ??
              selectedTrack);

    // ของวันที่ 7 มี dropdown ตัวที่ 3 "ช่วงเวลาแสดงผล" (วันนี้/สัปดาห์นี้/
    // เดือนนี้/ภาคเรียนนี้) แต่เป็นแค่ state จำลอง กดแล้วไม่โหลดข้อมูลใหม่จริง
    // ของจริงมีแค่ "เลือกวันที่เดียว" ที่ยิง RPC จริงตามวันที่เลือก (pickDate)
    final now = DateTime.now();
    final isToday =
        controller.date.year == now.year &&
        controller.date.month == now.month &&
        controller.date.day == now.day;
    final dateField = _filterField(
      label: 'วันที่แสดงผล',
      icon: Icons.calendar_today_rounded,
      value: dateLabel(controller.date),
      onTap: (_) => pickDate(),
      // มอบหมายไว้ในมอคอัพว่าเป็นปุ่มในแถวยกเลิก/ตกลงของตัวปฏิทิน แต่แถวนั้น
      // เป็นโครงภายในของ Flutter เสียบปุ่มที่ 3 เข้าไปไม่ได้ (ดูคอมเมนต์ใน
      // pickDate) — ย้ายมาไว้ข้างช่องแทน กดแล้วข้ามไปวันนี้ได้เร็วเหมือนกัน
      // โดยไม่ต้องเปิดปฏิทินด้วยซ้ำ ซ่อนเมื่อวันที่แสดงผลเป็นวันนี้อยู่แล้ว
      trailing: isToday
          ? null
          : InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => controller.load(onDate: DateTime.now()),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                child: Text(
                  'วันนี้',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppPalette.primaryPinkDark,
                  ),
                ),
              ),
            ),
    );
    final gradeField = _filterField(
      label: 'ระดับชั้นเป้าหมาย',
      icon: Icons.school_rounded,
      value: gradeLabel,
      onTap: (context) => _openFilterMenu(
        context,
        selected: selectedGrade,
        options: [
          const MapEntry(null, 'ทุกระดับชั้น'),
          for (final g in controller.grades)
            MapEntry(g, g.isEmpty ? 'ยังไม่ระบุชั้น' : g),
        ],
        onSelected: (v) => setState(() => grade = v),
      ),
    );
    final trackField = _filterField(
      label: 'สายการเรียน',
      icon: Icons.category_rounded,
      value: trackLabel,
      onTap: (context) => _openFilterMenu(
        context,
        selected: selectedTrack,
        options: [
          const MapEntry(null, 'ทุกสายการเรียน'),
          for (final t in controller.tracks) MapEntry(t.trackId, t.name),
        ],
        onSelected: (v) => setState(() => track = v),
      ),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (_, box) => box.maxWidth < 760
            ? Column(
                children: [
                  dateField,
                  const Divider(height: 17, color: AppPalette.border),
                  gradeField,
                  const Divider(height: 17, color: AppPalette.border),
                  trackField,
                ],
              )
            : IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: dateField),
                    const VerticalDivider(width: 25, color: AppPalette.border),
                    Expanded(child: gradeField),
                    const VerticalDivider(width: 25, color: AppPalette.border),
                    Expanded(child: trackField),
                  ],
                ),
              ),
      ),
    );
  }

  // การ์ดสรุปแบบเดียวกับ _StudentExecutiveSummary ของวันที่ 7 แต่คำนวณจาก
  // ข้อมูลจริง: การ์ดแรกใช้ overview.activeStudentCount ตรง ๆ การ์ดสองรวม
  // present/recorded ของทุกห้องที่ยังไม่กรอง (ไม่ใช้ตัวเลขแต่งขึ้น 1,248/94.2%)
  Widget _summaryCards() {
    final rows = controller.filteredAttendance(null, null);
    final present = rows.fold<int>(0, (n, r) => n + r.present);
    final late = rows.fold<int>(0, (n, r) => n + r.late);
    final absent = rows.fold<int>(0, (n, r) => n + r.absent);
    final excused = rows.fold<int>(0, (n, r) => n + r.excused);
    final recorded = present + late + absent + excused;
    final pct = recorded == 0 ? null : present * 100 / recorded;
    final count = controller.overview?.activeStudentCount;
    final urgentCases = controller.cases
        .where((c) => c.riskLevel == 'high' || c.status == 'escalated')
        .length;
    final cards = [
      _SummaryCardData(
        title: 'นักเรียนทั้งหมด',
        value: count?.toString() ?? '—',
        unit: 'คน',
        sub:
            '${controller.overview?.roomCount ?? 0} ห้องเรียน • ${controller.grades.length} ระดับชั้น',
        icon: Icons.groups_rounded,
        bg: AppPalette.primaryPinkSoft,
        color: AppPalette.primaryPinkDark,
      ),
      _SummaryCardData(
        title: 'มาเรียนวันนี้',
        value: pct?.toStringAsFixed(1) ?? '—',
        unit: pct == null ? '' : '%',
        sub: pct == null
            ? 'ยังไม่มีการเช็คชื่อของวันนี้'
            : 'มา $present จาก $recorded คนที่เช็คชื่อแล้ว',
        icon: Icons.how_to_reg_rounded,
        bg: const Color(0xFFDCFCE7),
        color: const Color(0xFF16A34A),
        badge: pct == null
            ? null
            : (pct >= 90 ? '✓ ถึงเกณฑ์ 90%' : '⚠ ต่ำกว่าเกณฑ์'),
        badgeColor: pct == null
            ? null
            : (pct >= 90 ? const Color(0xFF15803D) : const Color(0xFFB91C1C)),
      ),
      _SummaryCardData(
        title: 'ขาดเรียน / ลา',
        value: recorded == 0 ? '—' : '${absent + excused}',
        unit: recorded == 0 ? '' : 'คน',
        sub: recorded == 0
            ? 'ยังไม่มีการเช็คชื่อของวันนี้'
            : 'ขาด $absent คน • ลา $excused คน วันนี้',
        icon: Icons.person_off_rounded,
        bg: const Color(0xFFFEE2E2),
        color: const Color(0xFFE11D48),
      ),
      _SummaryCardData(
        title: 'มาสายวันนี้',
        value: recorded == 0 ? '—' : '$late',
        unit: recorded == 0 ? '' : 'คน',
        sub: recorded == 0
            ? 'ยังไม่มีการเช็คชื่อของวันนี้'
            : 'นับจากการเช็คชื่อวันนี้ทุกห้อง',
        icon: Icons.schedule_rounded,
        bg: const Color(0xFFFEF3C7),
        color: const Color(0xFFD97706),
      ),
      _SummaryCardData(
        title: 'เคสดูแลช่วยเหลือด่วน',
        value: '$urgentCases',
        unit: 'เคส',
        sub: urgentCases == 0
            ? 'ไม่มีเคสความเสี่ยงสูงค้างอยู่'
            : 'ความเสี่ยงสูงหรือส่งต่อฝ่ายแนะแนวแล้ว',
        icon: Icons.health_and_safety_rounded,
        bg: const Color(0xFFF3E8FF),
        color: const Color(0xFF9333EA),
        badge: urgentCases == 0 ? '✓ ไม่มีเคสด่วน' : '⚠ ต้องติดตาม',
        badgeColor: urgentCases == 0
            ? const Color(0xFF15803D)
            : const Color(0xFFB91C1C),
      ),
    ];
    return LayoutBuilder(
      builder: (_, box) {
        final columns = box.maxWidth >= 1150
            ? 5
            : (box.maxWidth >= 700 ? 3 : 1);
        const spacing = 12.0;
        final width = columns == 1
            ? box.maxWidth
            : (box.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final c in cards)
              SizedBox(width: width, child: _summaryCard(c)),
          ],
        );
      },
    );
  }

  Widget _summaryCard(_SummaryCardData d) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppPalette.border, width: 1.1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: .03),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // แถบสีบนสุด — ไอคอน + ชื่อ ไม่มี "ดูข้อมูล >" แบบต้นฉบับเพราะหน้านี้
        // ไม่มีปลายทางจริงให้กดไป (ต้นฉบับกดแล้วก็แค่ขึ้น toast ข้อความลอย)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: d.bg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(d.icon, size: 14, color: d.color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  d.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: d.color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              d.value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppPalette.textDark,
                letterSpacing: -.5,
              ),
            ),
            if (d.unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                d.unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                d.sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 9.8,
                  color: AppPalette.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (d.badge != null) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (d.badgeColor ?? d.color).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  d.badge!,
                  style: TextStyle(
                    fontSize: 8.8,
                    fontWeight: FontWeight.w700,
                    color: d.badgeColor ?? d.color,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );

  // การ์ด "EXECUTIVE WATCHLIST" สีแดงของวันที่ 7 ใช้รายชื่อนักเรียนแต่งขึ้น 3
  // คนตายตัว (ไม่เคยเปลี่ยนไม่ว่าข้อมูลจริงจะเป็นอย่างไร) — ของจริงมี RPC
  // `listExecutiveAutoFlaggedStudents` ที่คำนวณสัญญาณเสี่ยงจริงอยู่แล้วแต่ไม่
  // เคยถูกเอามาแสดงบนหน้าจอเลยสักจุด (โหลดไว้ใน controller.flaggedStudents
  // เฉยๆ) เอามาต่อจริงให้ตรงนี้แทน ระดับชั้นและครูที่ปรึกษามาจาก migration
  // 20260910150000 ที่เพิ่ม join student_profiles/homeroom_assignments เข้าไปใน
  // RPC ของจริง — ของวันที่ 7 มี badge สถานะ 3 ระดับ (วิกฤต/เฝ้าระวัง/ดูแลพิเศษ)
  // แต่ severity จริงมีแค่ urgent/normal เลยแมปเหลือ 2 ระดับ ไม่ใส่ "ดูแลพิเศษ"
  // เพราะไม่มีสัญญาณด้านสุขภาพจิต/ความเครียดในระบบจริงเลย
  Widget _watchlist() {
    final flags = controller.flaggedStudents;
    if (flags.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFB91C1C),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 8, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'EXECUTIVE WATCHLIST • เคสนักเรียนที่ผู้อำนวยการควรติดตามด่วนวันนี้',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${flags.length} เคสต้องดำเนินการ',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'รายชื่อนักเรียนที่มีประเด็นเร่งด่วนด้านการมาเรียน วิชาการ หรือพฤติกรรม เพื่อให้ ผอ. สั่งการและช่วยเหลือทันท่วงที',
              style: TextStyle(
                fontSize: 11,
                color: Colors.black.withValues(alpha: .7),
              ),
            ),
          ),
          for (final f in flags) _watchlistRow(f),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _watchlistRow(AutoFlaggedStudent f) {
    final color = _severityColor(f.severity);
    final grade = f.gradeLevel == null
        ? null
        : (f.room == null || f.room == f.gradeLevel ? f.gradeLevel : f.room);
    final priorCase = controller.cases.cast<StudentSupportCase?>().firstWhere(
      (c) => c!.studentId == f.studentId,
      orElse: () => null,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: .25)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(_severityIcon(f.severity), size: 18, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        f.studentName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      if (grade != null)
                        _watchlistTag(grade, AppPalette.textMuted),
                      _watchlistTag(_severityLabel(f.severity), color),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    f.detail,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'คำแนะนำ: ${_recommendation(f.reason)}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                  Text(
                    f.advisorName == null || f.advisorName!.isEmpty
                        ? 'ครูที่ปรึกษา: ยังไม่มีข้อมูล'
                        : 'ครูที่ปรึกษา: ${f.advisorName}',
                    style: const TextStyle(
                      fontSize: 10.5,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // ปุ่มทั้งคู่กว้างเท่ากันเสมอ (เท่ากับปุ่มที่กว้างกว่า) แทนที่จะกว้าง
            // ตามความยาวข้อความของตัวเอง — เดิมข้อความปุ่มล่างเปลี่ยนตาม reason
            // จริงของนักเรียนแต่ละคน ("ดูงานค้าง"/"เช็คชื่อ"/"ดูคะแนน") ทำให้ปุ่ม
            // กว้างไม่เท่ากันในแต่ละแถว ดูไม่เป็นระเบียบ
            IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton(
                    onPressed: priorCase == null
                        ? null
                        : () => showHistory(priorCase),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      side: BorderSide(color: color.withValues(alpha: .4)),
                      foregroundColor: color,
                    ),
                    child: const Text(
                      'ดูประวัติ',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
                  const SizedBox(height: 6),
                  FilledButton(
                    onPressed: controller.loading
                        ? null
                        : () async {
                            try {
                              await controller.openCaseFromFlag(f);
                            } catch (_) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'สั่งการดูแลไม่สำเร็จ ลองอีกครั้ง',
                                  ),
                                ),
                              );
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                    ),
                    child: Text(
                      f.actionLabel.isEmpty ? 'สั่งการดูแล' : f.actionLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _watchlistTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );

  // มีแค่ 3 ค่า reason จริงจาก RPC (ค้างส่งงาน/คะแนนเฉลี่ยต่ำ/ขาดเรียนบ่อย) —
  // ข้อความนี้เป็นคำแนะนำมาตรฐานต่อประเภทสัญญาณ ไม่ใช่ข้อมูลต่อรายบุคคล
  // (ต่างจากตัวเลข/ชื่อ ที่ต้องมาจาก DB เท่านั้น)
  String _recommendation(String reason) => switch (reason) {
    'ค้างส่งงาน' => 'ติดตามงานที่ค้างส่งกับครูผู้สอนประจำวิชา',
    'คะแนนเฉลี่ยต่ำ' => 'จัดสอนเสริมคลินิกวิชาการ / วางแผนปรับผลการเรียน',
    _ => 'ประสานผู้ปกครองด่วน / ครูที่ปรึกษาลงพื้นที่ติดตาม',
  };

  IconData _severityIcon(String severity) => severity == 'urgent'
      ? Icons.priority_high_rounded
      : Icons.visibility_rounded;
  String _severityLabel(String severity) =>
      severity == 'urgent' ? 'วิกฤต' : 'เฝ้าระวัง';
  Color _severityColor(String severity) =>
      severity == 'urgent' ? const Color(0xFFB91C1C) : const Color(0xFFD97706);

  // กราฟอัตรามาเรียนแยกระดับชั้น — เดิมมี 2 บั๊ก: (1) ความสูงแท่งใช้ค่า %
  // ดิบเป็นพิกเซลตรงๆ ไม่ scale ตามพื้นที่จริง (2) "ไม่มีข้อมูล" วาดเป็นแท่ง
  // สูง 4px สีขอบอ่อนมาก แทบมองไม่เห็น ฉบับนี้เปลี่ยนเป็นแท่งแนวนอนเรียงจาก
  // แย่สุดขึ้นก่อน (เจอปัญหาได้ทันที ไม่ต้องกวาดตาหาเอง) สีสถานะใช้ status
  // palette ที่ผ่านการ validate ของ dataviz skill ตรงๆ ไม่ใช่เลือกเอง และ
  // ไม่ทาสีตัวเลข % (ตัวเลขใช้สีหมึกปกติเสมอ ความหมายมาจากแท่ง/ไอคอนข้างๆ
  // แทน) รายละเอียดมา/สาย/ขาด/ลา ย้ายไปอยู่ใน tooltip ต่อแถวแทนการยัดใส่แท่ง
  Widget _attendanceByGrade(List<SchoolHomeroomAttendance> filteredRows) {
    final byGrade = <String, List<SchoolHomeroomAttendance>>{};
    for (final r in controller.attendance) {
      byGrade.putIfAbsent(r.gradeLevel ?? 'ไม่ระบุชั้น', () => []).add(r);
    }
    if (byGrade.isEmpty) return const SizedBox.shrink();
    final stats =
        byGrade.entries
            .map((e) => _GradeAttendanceStat(e.key, e.value))
            .toList()
          ..sort((a, b) {
            if (a.pct == null && b.pct == null)
              return a.grade.compareTo(b.grade);
            if (a.pct == null) return 1;
            if (b.pct == null) return -1;
            return a.pct!.compareTo(b.pct!);
          });
    final totalPresent = stats.fold<int>(0, (n, s) => n + s.present);
    final totalRecorded = stats.fold<int>(0, (n, s) => n + s.recorded);
    final avgPct = totalRecorded == 0
        ? null
        : totalPresent * 100 / totalRecorded;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'การมาเรียนแยกตามระดับชั้น (Attendance Rate)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'คำนวณจากข้อมูลเช็คชื่อจริงของวันที่เลือก · ชี้ที่แถวเพื่อดูรายละเอียด',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    avgPct == null ? '—' : avgPct.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppPalette.textDark,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Text(
                    'ค่าเฉลี่ยรวม',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppPalette.textMuted,
                      letterSpacing: .3,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final s in stats) _gradeRow(s),
          const SizedBox(height: 6),
          _attendanceLegend(),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppPalette.border),
          const SizedBox(height: 12),
          Text(
            'รายละเอียดตามห้อง · วันที่ ${dateLabel(controller.date)}',
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (filteredRows.isEmpty)
            const Text(
              'ยังไม่มีข้อมูลนักเรียนในตัวกรองนี้',
              style: TextStyle(fontSize: 11.5, color: AppPalette.textMuted),
            )
          else
            // เดิมเรียงแนวตั้งทีละห้อง 3 บรรทัด (ชื่อห้อง, ตัวเลขราย
            // สถานะ, ข้อความซ้ำ "ยังไม่มีข้อมูลการเช็คชื่อ") ห้องเยอะแล้วยาว
            // มาก — ย่อเป็นตารางการ์ดกะทัดรัดแทน และตัดบรรทัดที่ 3 ทิ้งเมื่อ
            // ไม่มีอะไรใหม่กว่าบรรทัดที่ 2 อยู่แล้ว (unknown เท่ากับจำนวนคน
            // ทั้งห้อง = ยังไม่เช็คชื่อเลยสักคน) — ใช้ Wrap กว้างคงที่แทน
            // LayoutBuilder เพราะการ์ดนี้อยู่ใต้ IntrinsicHeight ของคู่การ์ด
            // ข้างบน (attendance/care) และ LayoutBuilder ไม่รองรับ intrinsic
            // dimensions ทำให้พังทันทีที่จอกว้าง ≥1050px (จับได้จากเทสต์)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final r in filteredRows)
                  SizedBox(width: 190, child: _roomDetailCard(r)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _roomDetailCard(SchoolHomeroomAttendance r) {
    final fullyUnchecked = r.recorded == 0;
    // บรรทัด 3 ต้องยังบอก "เหลือกี่คนที่ยังไม่เช็คชื่อ" ไว้เสมอเมื่อ unknown>0
    // แม้จะเช็คไปแล้วบางส่วน (ไม่ใช่แค่ตอนยังไม่เช็คเลยทั้งห้อง) ไม่งั้นจะดูเหมือน
    // ห้องเช็คชื่อครบแล้วทั้งที่ยังไม่ครบจริง
    final statusParts = <String>[
      if (!fullyUnchecked)
        'มาเรียน ${r.attendancePercent!.toStringAsFixed(1)}%',
      if (r.unknown > 0) 'ยังไม่เช็คชื่อ ${r.unknown} คน',
    ];
    final statusLine = statusParts.isEmpty
        ? 'เช็คชื่อครบแล้ว'
        : statusParts.join(' · ');
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.pageBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${r.roomLabel} · ${r.studentCount} คน',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
          ),
          const SizedBox(height: 3),
          Text(
            'มา ${r.present} · สาย ${r.late} · ขาด ${r.absent} · ลา ${r.excused}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 3),
          Text(
            statusLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fullyUnchecked
                  ? AppPalette.textMuted
                  : const Color(0xFF356A9A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gradeRow(_GradeAttendanceStat stat) {
    final pct = stat.pct;
    final status = _attendanceStatusFor(pct);
    // Positioned.fill รอบ Align/FractionallySizedBox ทุกชั้น (ไม่ใช้ Align
    // เปล่าๆ เป็นลูกตรงของ Stack) เพราะ Align ที่ไม่ได้อยู่ใต้ Positioned จะ
    // ได้ loose constraints จาก Stack ทำให้ Container ที่ไม่มี width ชัดเจน
    // (แถบพื้นหลัง) ยุบเหลือ 0 กว้าง — ต้องห่อด้วย Positioned.fill ก่อนเพื่อ
    // ให้ได้ tight constraints เท่าขนาด Stack จริงก่อนค่อยคำนวณสัดส่วน
    final track = pct == null
        ? const _DashedTrack()
        : SizedBox(
            height: 18,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 3,
                  bottom: 3,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppPalette.pageBg,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 3,
                  bottom: 3,
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (pct / 100).clamp(0.0, 1.0),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _attendanceStatusColor(status),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Align(
                    alignment: Alignment(2 * (_kAttendanceTarget / 100) - 1, 0),
                    child: Container(
                      width: 1.5,
                      color: AppPalette.textDark.withValues(alpha: .28),
                    ),
                  ),
                ),
              ],
            ),
          );
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              stat.grade,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: track),
          const SizedBox(width: 10),
          _gradeValueLabel(status, pct),
        ],
      ),
    );
    if (stat.recorded == 0) return row;
    return Tooltip(
      waitDuration: const Duration(milliseconds: 200),
      richMessage: _gradeTooltipMessage(stat),
      child: row,
    );
  }

  Widget _gradeValueLabel(_AttendanceStatus status, double? pct) {
    if (pct == null) {
      // ป้าย "ยังไม่เช็คชื่อ" ย้ายไปอยู่กลางกล่องเส้นประแล้ว (ดู _DashedTrack)
      // — ตรงนี้เหลือแค่ — กันคอลัมน์เลื่อน ไม่ต้องพูดซ้ำ
      return const Text(
        '—',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppPalette.textMuted,
        ),
      );
    }
    final valueText = Text(
      '${pct.toStringAsFixed(pct % 1 == 0 ? 0 : 1)}%',
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: AppPalette.textDark,
        fontFeatures: [FontFeature.tabularFigures()],
      ),
    );
    if (status == _AttendanceStatus.good) return valueText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [valueText, const SizedBox(width: 6), _statusChip(status)],
    );
  }

  Widget _statusChip(_AttendanceStatus status) {
    final critical = status == _AttendanceStatus.critical;
    final ink = critical ? _kStatusCritical : _kStatusWarningInk;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: critical ? _kStatusCriticalSoft : _kStatusWarningSoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            critical ? Icons.error_rounded : Icons.warning_amber_rounded,
            size: 10,
            color: ink,
          ),
          const SizedBox(width: 3),
          Text(
            critical ? 'ต่ำกว่ามาก' : 'ใกล้เกณฑ์',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }

  // เดิม V3 พยายามโชว์ present/late/absent/excused ด้วยแท่ง segmented ในแท่ง
  // เดียว แต่ส่วนแบ่งแคบ (3-5%) มองแทบไม่เห็น — ย้ายรายละเอียดนี้มาไว้ที่
  // tooltip แทน ใช้จำนวนคนจริง (ไม่ใช่ % ที่ปัดแล้ว) ให้ตรงกับ _roomDetailCard
  // ด้านล่างที่ใช้หน่วยเดียวกันอยู่แล้ว
  InlineSpan _gradeTooltipMessage(_GradeAttendanceStat stat) {
    Widget line(String label, int value, Color color) => Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 9, height: 2, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: Colors.white70),
          ),
          const SizedBox(width: 8),
          Text(
            '$value คน',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    return WidgetSpan(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            stat.grade,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (stat.present > 0) line('มาเรียน', stat.present, _kStatusGood),
          if (stat.late > 0) line('มาสาย', stat.late, _kStatusWarning),
          if (stat.absent > 0) line('ขาด', stat.absent, _kStatusCritical),
          if (stat.excused > 0)
            line('ลา', stat.excused, const Color(0xFF7FA9D8)),
        ],
      ),
    );
  }

  Widget _attendanceLegend() {
    final lowTarget = (_kAttendanceTarget - 5).toInt();
    final target = _kAttendanceTarget.toInt();
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _legendDot(_kStatusGood, 'ถึงเกณฑ์ (≥$target%)'),
        _legendDot(_kStatusWarning, 'ใกล้เกณฑ์ ($lowTarget–$target%)'),
        _legendDot(_kStatusCritical, 'ต่ำกว่าเกณฑ์มาก (<$lowTarget%)'),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 1.5,
              height: 11,
              color: AppPalette.textDark.withValues(alpha: .35),
            ),
            const SizedBox(width: 6),
            Text(
              'เส้นเกณฑ์ $target%',
              style: const TextStyle(
                fontSize: 9.5,
                color: AppPalette.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _legendDot(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(
        label,
        style: const TextStyle(
          fontSize: 9.5,
          color: AppPalette.textMuted,
          fontWeight: FontWeight.w600,
        ),
      ),
    ],
  );

  // "ข้อมูลเจาะลึกรายระดับชั้น" ของวันที่ 7 เป็นการ์ดตายตัว 6 ใบ (ม.1-ม.6) มี
  // % เยี่ยมบ้านและป้าย "ต้องดูแลด่วน" ที่ไม่มีข้อมูลจริงรองรับเลย — ฉบับนี้
  // สร้างการ์ดตามจำนวนระดับชั้นที่มีจริงในระบบ ใช้แค่ฟิลด์ที่มาจาก attendance
  // (จำนวนคน/ห้อง/% มาเรียน/ขาด-สาย) และจำนวนเคสดูแลช่วยเหลือจริงต่อชั้น
  // red-team: "เคสดูแล" เดิมนับจาก controller.cases ทั้งหมดเสมอ ไม่สนตัวกรอง
  // สถานะที่ผู้ใช้เลือกอยู่ (ทุกสถานะ/เปิดเคสใหม่/กำลังช่วยเหลือ/ปิดเคสสำเร็จ)
  // ทำให้ตัวเลขบนการ์ดนี้ไม่ตรงกับรายการเคสที่กรองแล้วด้านล่าง — รับ cases ที่
  // กรองแล้วจาก build() มาใช้แทน ให้ตัวเลขสอดคล้องกันทั้งหน้า
  Widget _gradeDeepDive(Iterable<StudentSupportCase> cases) {
    final byGrade = <String, List<SchoolHomeroomAttendance>>{};
    for (final r in controller.attendance) {
      byGrade.putIfAbsent(r.gradeLevel ?? 'ไม่ระบุชั้น', () => []).add(r);
    }
    if (byGrade.isEmpty) return const SizedBox.shrink();
    final grades = byGrade.keys.toList()..sort();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ข้อมูลเจาะลึกรายระดับชั้น (Grade-Level Deep Dive)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
          ),
          const Text(
            'จำนวนนักเรียน ห้องเรียน การมาเรียน และเคสดูแลช่วยเหลือตามตัวกรองสถานะที่เลือกไว้ ต่อระดับชั้น',
            style: TextStyle(fontSize: 10, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (_, box) {
              final columns = box.maxWidth < 620 ? 1 : 2;
              final width = columns == 1
                  ? box.maxWidth
                  : (box.maxWidth - 14) / 2;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  for (final g in grades)
                    SizedBox(
                      width: width,
                      child: _gradeCard(g, byGrade[g]!, cases),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _gradeCard(
    String grade,
    List<SchoolHomeroomAttendance> rows,
    Iterable<StudentSupportCase> cases,
  ) {
    final students = rows.fold<int>(0, (n, r) => n + r.studentCount);
    final roomCount = rows.map((r) => r.room).toSet().length;
    final present = rows.fold<int>(0, (n, r) => n + r.present);
    final late = rows.fold<int>(0, (n, r) => n + r.late);
    final absent = rows.fold<int>(0, (n, r) => n + r.absent);
    final recorded = rows.fold<int>(
      0,
      (n, r) => n + r.present + r.late + r.absent + r.excused,
    );
    final pct = recorded == 0 ? null : present * 100 / recorded;
    final caseCount = cases.where((c) => c.gradeLevel == grade).length;
    final needsAttention = pct != null && pct < 90;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: needsAttention ? const Color(0xFFFEF2F2) : AppPalette.pageBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsAttention ? const Color(0xFFFECACA) : AppPalette.border,
        ),
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
                  color: AppPalette.primaryPinkDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  grade,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$students คน • $roomCount ห้องเรียน',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (needsAttention)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'ต้องดูแลด่วน',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _gradeStat(
                  'มาเรียน',
                  pct == null ? '—' : '${pct.toStringAsFixed(1)}%',
                  needsAttention
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF2563EB),
                ),
              ),
              Expanded(
                child: _gradeStat(
                  'ขาด/สาย',
                  '$absent/$late',
                  const Color(0xFFD97706),
                ),
              ),
              Expanded(
                child: _gradeStat(
                  'เคสดูแล',
                  '$caseCount',
                  const Color(0xFF7C3AED),
                  key: ValueKey('grade_case_count_$grade'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // พอร์ตทรง _careDimensionTile ของเวอร์ชัน 7 ก.ย. มาตรง ๆ (bg tint 5%,
  // border tint 15%, กล่องไอคอนพื้นขาว, ชื่อ+% อยู่แถวเดียวกันในคอลัมน์เนื้อหา
  // ไม่ใช่ตัวเลขลอยใหญ่ขวาสุดทั้งการ์ดแบบที่เคยทำผิดไป) ใช้ 4 หมวดเคสจริงที่มี
  // อยู่แล้ว (category ของ StudentSupportCase) แทน 5 มิติที่ไม่มีจริง (SDQ/
  // เยี่ยมบ้าน/ทักษะชีวิต/ให้คำปรึกษา/ทุนการศึกษา) — % คือสัดส่วนเคสที่ปิดแล้ว
  // จริง ไม่ใช่ตัวเลขคุณภาพงานที่แต่งขึ้นแบบต้นฉบับ
  (IconData, Color) _categoryStyle(String category) => switch (category) {
    'academic' => (Icons.school_rounded, const Color(0xFF2563EB)),
    'behavioral' => (Icons.groups_rounded, const Color(0xFFD97706)),
    'emotional' => (Icons.favorite_rounded, const Color(0xFF9333EA)),
    'safety' => (Icons.shield_rounded, const Color(0xFFDC2626)),
    _ => (Icons.folder_rounded, AppPalette.textMuted),
  };

  Color _statusColor(String status) => switch (status) {
    'resolved' => const Color(0xFF15803D),
    'in_progress' => const Color(0xFFD97706),
    'escalated' => const Color(0xFFDC2626),
    _ => const Color(0xFF2563EB),
  };

  Widget _careDimensionRow(String category, List<StudentSupportCase> cases) {
    if (cases.isEmpty) return const SizedBox.shrink();
    final resolved = cases.where((c) => c.status == 'resolved').length;
    final pct = resolved * 100 / cases.length;
    final (icon, color) = _categoryStyle(category);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: .15)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        cases.first.categoryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppPalette.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  'ปิดแล้ว $resolved จาก ${cases.length} เคส',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // เดิมรายการเคสเป็นตัวหนังสือเปล่าเรียงต่อกัน ไม่มีการ์ด/เส้นขอบเลย ทำให้
  // ดูไม่เข้าชุดกับการ์ดหมวดด้านบนและแถวในการ์ดอื่นทั้งหน้า ปรับให้เป็นการ์ด
  // สไตล์เดียวกัน (ไอคอนตามหมวดจริง + badge หมวด/สถานะสี + ปุ่มแบบเดียวกับ
  // ที่ใช้ใน watchlist)
  Widget _caseListTile(StudentSupportCase c) {
    final (icon, color) = _categoryStyle(c.category);
    final statusColor = _statusColor(c.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${c.studentName} · ${c.title}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _badge(c.categoryLabel, color),
                    _badge(c.statusLabel, statusColor),
                  ],
                ),
                if (c.notes?.isNotEmpty == true) ...[
                  const SizedBox(height: 5),
                  Text(
                    c.notes!,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppPalette.textMuted,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => showHistory(c),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    side: BorderSide(color: color.withValues(alpha: .4)),
                    foregroundColor: color,
                  ),
                  child: Text(
                    'ดูประวัติ (${c.interventionCount})',
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 9.5,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );

  Widget _gradeStat(String label, String value, Color color, {Key? key}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 9.5, color: AppPalette.textMuted),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            key: key,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      );

  // "ข้อเสนอแนะเชิงบริหาร" ของวันที่ 7 อ้างอิงระบบที่ไม่มีจริง (สั่งการครูหัวหน้า
  // ระดับ, คลินิกวิชาการ, ฝ่ายปกครอง) — ฉบับนี้สร้างข้อสังเกตจากข้อมูลจริงที่
  // คำนวณได้อยู่แล้วเท่านั้น (ระดับชั้นที่มาเรียนต่ำกว่าเกณฑ์, เคสความเสี่ยงสูง
  // ค้างอยู่) ไม่มีปุ่ม "สั่งการ" ปลอมเพราะไม่มีระบบสั่งการจริงให้กด
  Widget _actionItems() {
    final byGrade = <String, List<SchoolHomeroomAttendance>>{};
    for (final r in controller.attendance) {
      byGrade.putIfAbsent(r.gradeLevel ?? 'ไม่ระบุชั้น', () => []).add(r);
    }
    final lowGrades = <String>[];
    for (final entry in byGrade.entries) {
      final present = entry.value.fold<int>(0, (n, r) => n + r.present);
      final recorded = entry.value.fold<int>(
        0,
        (n, r) => n + r.present + r.late + r.absent + r.excused,
      );
      if (recorded > 0 && present * 100 / recorded < 90)
        lowGrades.add(entry.key);
    }
    lowGrades.sort();
    final urgentCases = controller.cases
        .where((c) => c.riskLevel == 'high' || c.status == 'escalated')
        .toList();
    final items = <Widget>[
      if (lowGrades.isNotEmpty)
        _actionTile(
          icon: Icons.trending_down_rounded,
          color: const Color(0xFFDC2626),
          title: 'ระดับชั้นมาเรียนต่ำกว่าเกณฑ์ (90%)',
          badge: '${lowGrades.length} ระดับชั้น',
          detail:
              'พบใน ${lowGrades.join(", ")} — ดูรายละเอียดที่การ์ด "ข้อมูลเจาะลึกรายระดับชั้น" ด้านล่าง',
        ),
      if (urgentCases.isNotEmpty)
        _actionTile(
          icon: Icons.warning_rounded,
          color: const Color(0xFFB91C1C),
          title: 'เคสความเสี่ยงสูงรอดำเนินการ',
          badge: '${urgentCases.length} เคส',
          detail: 'ดูรายชื่อได้ที่การ์ด "ระบบดูแลช่วยเหลือนักเรียน" ด้านล่าง',
        ),
    ];
    // ก็อบ header ของเวอร์ชัน 7 ก.ย. มาตรง ๆ (กล่องไอคอน 36x36 สีเหลือง, ชื่อ
    // การ์ด fontSize 16, ซับไตเติล 10.5) แทนที่จะใช้ card() กลาง — ซับไตเติล
    // ของจริงบอกตรง ๆ ว่ายังไม่มีระบบสั่งการเชื่อมต่อจริง แทนคำอ้าง "สั่งการครู
    // หัวหน้าระดับ" ของต้นฉบับที่ไม่มีระบบรองรับ
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .02),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.flag_rounded,
                  size: 20,
                  color: Color(0xFFD97706),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ข้อเสนอแนะเชิงบริหารและงานติดตาม (Executive Action Items)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                        letterSpacing: -.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'คำนวณจากข้อมูลจริงเท่านั้น ไม่มีปุ่มสั่งการเพราะยังไม่มีระบบสั่งการเชื่อมต่อจริง',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            const Text(
              'ไม่มีข้อสังเกตเร่งด่วนจากข้อมูลวันนี้',
              style: TextStyle(fontSize: 12, color: AppPalette.textMuted),
            )
          else
            ...items,
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String badge,
    required String detail,
  }) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .2)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2.5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badge,
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: const TextStyle(
                  fontSize: 11,
                  height: 1.45,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
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
              _hero(cases, rows),
              const SizedBox(height: 14),
              _filterBar(selectedGrade, selectedTrack),
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
                _watchlist(),
                if (controller.flaggedStudents.isNotEmpty)
                  const SizedBox(height: 16),
                // red-team: หน้านี้มี 9+ ส่วนต่อกันยาวเป็นหน้าจอเดียวโดยไม่มี
                // ลำดับความสำคัญ — ย้าย "สิ่งที่ต้องดำเนินการ" ขึ้นมาไว้ต่อจาก
                // watchlist ทันที (เดิมอยู่ล่างสุดของหน้า) เพราะเป็นสรุปที่
                // ผอ.ควรเห็นก่อนไปดูรายละเอียดทีละการ์ดด้านล่าง
                _actionItems(),
                const SizedBox(height: 16),
                card(
                  'การวิเคราะห์ผลการเรียนและสายการเรียน (Academic Program Analytics)',
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
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (_, box) {
                    final attendanceCard = _attendanceByGrade(rows);
                    // การ์ดนี้ก็อบ header ของเวอร์ชัน 7 ก.ย. มาตรง ๆ (กล่อง
                    // ไอคอน 36x36, ชื่อการ์ด fontSize 15, ซับไตเติล 10.5,
                    // เงา/ขอบแบบเฉพาะการ์ดนี้) แทนที่จะใช้ card()/
                    // DirectorWorkspaceCard กลาง (fontSize 18, ไม่มีซับ
                    // ไตเติล, มีเส้นคั่น) ที่ให้หน้าตาต่างจากต้นฉบับชัดเจน
                    final careCard = Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppPalette.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: .02),
                            blurRadius: 14,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF059669,
                                  ).withValues(alpha: .12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 20,
                                  color: Color(0xFF059669),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ระบบดูแลช่วยเหลือนักเรียน (Student Care System)',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppPalette.textDark,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    // ของวันที่ 7 เขียน "5 มิติหลักตามเกณฑ์
                                    // สพฐ." แต่ของจริงมีแค่ 4 หมวดจาก category
                                    // จริงในระบบ ไม่ใช่ 5 มิติตามมาตรฐานที่อ้าง
                                    Text(
                                      'จำแนกเคสดูแลช่วยเหลือ 4 ด้านจากข้อมูลจริงในระบบ',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppPalette.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          for (final cat in const [
                            'academic',
                            'behavioral',
                            'emotional',
                            'safety',
                          ])
                            _careDimensionRow(
                              cat,
                              controller.cases
                                  .where((c) => c.category == cat)
                                  .toList(),
                            ),
                          const SizedBox(height: 12),
                          const Divider(height: 1, color: AppPalette.border),
                          const SizedBox(height: 12),
                          Text(
                            'รายการที่ครูบันทึกในระบบ ทั้งหมดของโรงเรียน',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppPalette.textMuted,
                            ),
                          ),
                          const SizedBox(height: 10),
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
                          for (final c in cases) _caseListTile(c),
                        ],
                      ),
                    );
                    if (box.maxWidth < 1050) {
                      return Column(
                        children: [
                          attendanceCard,
                          const SizedBox(height: 16),
                          careCard,
                        ],
                      );
                    }
                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 5, child: attendanceCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 4, child: careCard),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _gradeDeepDive(cases),
              ],
              const SizedBox(height: 16),
              _followUpSystemCard(controller.followupSummary),
            ],
          ),
        ),
      );
    },
  );
}

extension on _DirectorLearningPageState {
  // Real backend as of 20260911020000_student_followup_system.sql — was a
  // "not supported" placeholder with 3 onPressed:null buttons. Every button
  // below either opens the real 4-tab system (director_student_followup_page.dart)
  // or exports data this page already has loaded, nothing invented.
  Widget _followUpSystemCard(StudentFollowupSummary? summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppPalette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppPalette.primaryPinkDark.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.diversity_1_rounded,
                  size: 20,
                  color: AppPalette.primaryPinkDark,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'งานติดตามนักเรียนรายบุคคล',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppPalette.textDark,
                        letterSpacing: -.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'เยี่ยมบ้าน · SDQ · ทุนการศึกษา · สั่งการติดตาม',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppPalette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppPalette.border),
          const SizedBox(height: 14),
          if (summary == null)
            const Text(
              'ยังโหลดสรุปงานติดตามไม่สำเร็จ — เปิด "เปิดระบบติดตามนักเรียน" (ปุ่มบนหัวหน้า) แล้วลองใหม่',
              style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
            )
          else
            Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _followUpStat(
                  'เยี่ยมบ้านเดือนนี้',
                  '${summary.homeVisitsThisMonth}',
                ),
                _followUpStat('SDQ ทั้งหมด', '${summary.sdqAssessmentsTotal}'),
                _followUpStat('ทุนที่เปิดรับ', '${summary.scholarshipsActive}'),
                _followUpStat(
                  'คำสั่งติดตามค้าง',
                  '${summary.directivesOpen}',
                  accent: summary.directivesOverdue > 0
                      ? AppPalette.danger
                      : null,
                ),
              ],
            ),
          const SizedBox(height: 14),
          const Text(
            'การประเมินความเสี่ยงในการ์ด "รายชื่อที่ต้องติดตาม" ตอนนี้รวมสัญญาณจากคะแนน SDQ '
            'ล่าสุดด้วย ไม่ใช่แค่การขาดเรียน/คะแนน/งานค้างเหมือนเดิม',
            style: TextStyle(fontSize: 10.5, color: AppPalette.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _followUpStat(String label, String value, {Color? accent}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 10, color: AppPalette.textMuted),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: accent ?? AppPalette.textDark,
        ),
      ),
    ],
  );

  Future<void> _openFollowup(int tab) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DirectorStudentFollowupPage(initialTab: tab),
      ),
    );
    await controller.load(onDate: controller.date);
  }

  // Exports exactly what this page already loaded from real RPCs — no new
  // data source, just the room-attendance grid and the case list as CSV.
  void _exportLearningReportCsv(
    Iterable<StudentSupportCase> cases,
    List<SchoolHomeroomAttendance> attendance,
  ) {
    final rows = <List<dynamic>>[
      ['รายงานภาพรวมนักเรียน', dateLabel(controller.date)],
      [],
      ['การเข้าเรียนรายห้อง'],
      [
        'ระดับชั้น',
        'ห้อง',
        'จำนวนนักเรียน',
        'มาเรียน',
        'มาสาย',
        'ขาด',
        'ลา',
        'ยังไม่เช็กชื่อ',
      ],
      for (final r in attendance)
        [
          r.gradeLevel ?? '',
          r.room ?? '',
          r.studentCount,
          r.present,
          r.late,
          r.absent,
          r.excused,
          r.unknown,
        ],
      [],
      ['เคสดูแลช่วยเหลือนักเรียน'],
      [
        'นักเรียน',
        'หมวด',
        'สถานะ',
        'ความเสี่ยง',
        'หัวข้อ',
        'ผู้บันทึก',
        'จำนวนการติดตาม',
      ],
      for (final c in cases)
        [
          c.studentName,
          c.categoryLabel,
          c.statusLabel,
          c.riskLevel,
          c.title,
          c.createdByName,
          c.interventionCount,
        ],
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(csv)]);
    downloadBytes(
      filename:
          'รายงานภาพรวมนักเรียน_${dateLabel(controller.date).replaceAll('/', '-')}.csv',
      bytes: bytes,
      mimeType: 'text/csv',
    );
  }
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

  Color get _riskColor => switch (widget.item.riskLevel) {
    'high' => const Color(0xFFDC2626),
    'medium' => const Color(0xFFD97706),
    _ => AppPalette.textMuted,
  };

  // คำแนะนำมาตรฐานต่อ "หมวด" จริงของเคส (4 หมวดที่มีอยู่แล้วบน
  // StudentSupportCase.category) ไม่ใช่ข้อมูลเฉพาะรายเคสที่แต่งขึ้น
  static String _recommendation(String category) => switch (category) {
    'academic' => 'จัดสอนเสริม/ติดตามผลการเรียนร่วมกับครูผู้สอนประจำวิชา',
    'behavioral' => 'ประสานผู้ปกครองและครูประจำชั้นติดตามพฤติกรรมอย่างใกล้ชิด',
    'emotional' => 'นัดหมายพูดคุยกับครูแนะแนวหรือผู้เชี่ยวชาญด้านสุขภาพจิต',
    'safety' => 'แจ้งฝ่ายกิจการนักเรียน/ความปลอดภัยดำเนินการทันที',
    _ => 'ติดตามอาการอย่างต่อเนื่องร่วมกับครูที่ปรึกษา',
  };

  static String _relativeLabel(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'เมื่อสักครู่';
    if (diff.inMinutes < 60) return 'เมื่อ ${diff.inMinutes} นาทีที่แล้ว';
    if (diff.inHours < 24) return 'เมื่อ ${diff.inHours} ชม.ที่แล้ว';
    if (diff.inDays < 7) return 'เมื่อ ${diff.inDays} วันที่แล้ว';
    return 'เมื่อวันที่ ${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppPalette.primaryPinkSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppPalette.primaryPinkDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (item.gradeLevel != null)
                      'ห้อง ${item.gradeLevel}${item.room != null ? "/${item.room}" : ""}',
                    item.courseName,
                  ].join(' • '),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppPalette.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.tint(_riskColor, .08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppPalette.tint(_riskColor, .3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ประเด็นที่ต้องติดตาม: ${item.title}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _riskColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'หมวดหมู่: ${item.categoryLabel} • เปิดเคส ${_relativeLabel(item.createdAt)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppPalette.textMuted,
                      ),
                    ),
                    if (item.notes?.isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(item.notes!, style: const TextStyle(fontSize: 12)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'คำแนะนำเบื้องต้น',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
              ),
              const SizedBox(height: 4),
              Text(
                _recommendation(item.category),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppPalette.textDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'ประวัติการช่วยเหลือ (${item.interventionCount})',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<StudentSupportIntervention>>(
                future: result,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('กำลังโหลดประวัติ')),
                    );
                  }
                  if (snapshot.hasError) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ไม่สามารถโหลดประวัติการช่วยเหลือได้'),
                        TextButton(
                          onPressed: () =>
                              setState(() => result = widget.load()),
                          child: const Text('ลองอีกครั้ง'),
                        ),
                      ],
                    );
                  }
                  final entries = snapshot.data!;
                  if (entries.isEmpty) {
                    // ต้นฉบับวันที่ 7 แต่งไทม์ไลน์ 3 ขั้น (ตรวจพบอัตโนมัติ/
                    // แจ้งเตือนครู/ผอ.สั่งการ) พร้อมเวลาที่ไม่มีจริงในระบบเลย
                    // สักจุด — ของจริงต้องบอกตรงๆ ว่ายังไม่มีใครบันทึกการ
                    // ช่วยเหลือ ไม่ใช่โชว์ขั้นตอนที่ไม่ได้เกิดขึ้นจริง
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      decoration: BoxDecoration(
                        color: AppPalette.pageBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            color: AppPalette.textMuted,
                            size: 28,
                          ),
                          SizedBox(height: 6),
                          Text(
                            'ยังไม่มีบันทึกการช่วยเหลือ',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppPalette.textMuted,
                            ),
                          ),
                          SizedBox(height: 3),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'บันทึกจะปรากฏที่นี่เมื่อครูหรือผู้ดูแลโรงเรียนเพิ่มการช่วยเหลือให้เคสนี้',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 10.5,
                                color: AppPalette.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        _timelineTile(
                          i + 1,
                          entries[i],
                          isLast: i == entries.length - 1,
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 4),
            ],
          ),
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

  Widget _timelineTile(
    int index,
    StudentSupportIntervention entry, {
    required bool isLast,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFF356A9A),
                shape: BoxShape.circle,
              ),
              child: Text(
                '$index',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (!isLast)
              Container(width: 2, height: 30, color: AppPalette.border),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.actionTypeLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(entry.notes, style: const TextStyle(fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(
                '${entry.recordedByName} • ${_relativeLabel(entry.createdAt)}',
                style: const TextStyle(
                  fontSize: 10,
                  color: AppPalette.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.title,
    required this.value,
    required this.unit,
    required this.sub,
    required this.icon,
    required this.bg,
    required this.color,
    this.badge,
    this.badgeColor,
  });
  final String title, value, unit, sub;
  final IconData icon;
  final Color bg, color;
  final String? badge;
  final Color? badgeColor;
}
