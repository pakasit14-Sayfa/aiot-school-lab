import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'controllers/school_admin_async_state.dart';
import 'controllers/school_timetable_controller.dart';
import 'theme/school_admin_palette.dart';

/// D6 timetable, v2 (owner review 2026-09-20: "ทั้งโรงเรียน → ม.ต้น/ม.ปลาย →
/// ห้อง"). Two levels inside one page, no routes:
///   * overview — every room of the year grouped by level, with how much of
///     its week is filled, plus teacher clashes for the whole school
///   * room — one day at a time (day chips), periods as coloured cards,
///     breaks as a grey band, empty lessons as a dashed "tap to add"
/// Embedded in the school-admin dashboard, which already draws the title
/// bar — so no AppBar of its own.
class SchoolTimetablePage extends StatefulWidget {
  const SchoolTimetablePage({super.key, this.controller});
  final SchoolTimetableController? controller;

  @override
  State<SchoolTimetablePage> createState() => _SchoolTimetablePageState();
}

class _SchoolTimetablePageState extends State<SchoolTimetablePage> {
  late final SchoolTimetableController _controller;
  late final bool _ownsController;

  static const _dayShort = ['จ.', 'อ.', 'พ.', 'พฤ.', 'ศ.'];
  static const _dayLong = ['จันทร์', 'อังคาร', 'พุธ', 'พฤหัสบดี', 'ศุกร์'];

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SchoolTimetableController(
          loadTerms: TimetableService.listTerms,
          loadPeriods: TimetableService.listSchoolPeriods,
          loadOverview: TimetableService.listTimetableOverview,
          loadSchedules: TimetableService.listRoomTimetable,
          loadTeacherSubjects: TimetableService.listTeacherSubjects,
          loadStaff: StaffOrgService.listStaffDirectory,
          loadTeacherWeek: TimetableService.listTeacherWeek,
          loadConflicts: TimetableService.listTeacherConflicts,
          setSlot: TimetableService.adminSetRoomTimetableSlot,
          clearSlot: TimetableService.adminClearRoomTimetableSlot,
          savePeriods: TimetableService.setSchoolPeriods,
          copyRoom: TimetableService.adminCopyRoomTimetable,
          clearRoom: TimetableService.adminClearRoomTimetable,
        );
    _controller.addListener(_onChanged);
    _controller.load();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  // ── messages ──────────────────────────────────────────────────────────

  void _snack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? SchoolAdminPalette.red : null,
      ),
    );
  }

  /// RPC error codes → what the admin should read. Raw exception text never
  /// reaches the screen (same rule as d8dcf6e on the teacher lane).
  static String thaiError(Object e, {required String fallback}) {
    final t = e.toString();
    if (t.contains('period_not_found')) {
      return 'ยังไม่ได้ตั้งค่าคาบเวลานี้ ตั้งค่าคาบเวลาก่อน';
    }
    if (t.contains('period_is_break')) return 'คาบนี้เป็นเวลาพัก ใส่วิชาไม่ได้';
    if (t.contains('period_overlap')) return 'มีคาบที่เวลาทับกัน';
    if (t.contains('invalid_period_time')) {
      return 'เวลาสิ้นสุดของคาบต้องอยู่หลังเวลาเริ่ม';
    }
    if (t.contains('teacher_required')) return 'ต้องระบุครูผู้สอน';
    if (t.contains('teacher_not_found')) {
      return 'ไม่พบครูคนนี้ในโรงเรียน (ต้องมีบทบาทครู)';
    }
    if (t.contains('subject_name_required')) return 'กรุณาระบุชื่อวิชา';
    if (t.contains('term_not_found')) return 'ไม่พบภาคเรียนที่เลือก';
    if (t.contains('room_required')) return 'ต้องระบุชั้นและห้อง';
    if (t.contains('same_room')) return 'ต้นทางกับปลายทางเป็นห้องเดียวกัน';
    if (t.contains('forbidden')) return 'บัญชีนี้ไม่มีสิทธิ์จัดตารางเรียน';
    if (t.contains('invalid_session') || t.contains('not_signed_in')) {
      return 'หมดเวลาเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่';
    }
    return fallback;
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    if (state is SchoolAdminLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is SchoolAdminError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                thaiError(
                  state.message,
                  fallback: 'โหลดตารางเรียนไม่สำเร็จ กรุณาลองใหม่',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(color: SchoolAdminPalette.red),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _controller.load,
                child: const Text('ลองใหม่'),
              ),
            ],
          ),
        ),
      );
    }
    if (_controller.periods.isEmpty) return _buildNoPeriods();
    if (_controller.selectedRoom == null) return _buildOverview();
    return _buildRoom();
  }

  // ── overview ──────────────────────────────────────────────────────────

  Widget _buildNoPeriods() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 40,
              color: SchoolAdminPalette.textMuted,
            ),
            const SizedBox(height: 12),
            const Text(
              'ยังไม่ได้ตั้งค่าคาบเวลาเรียน',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'กำหนดว่าคาบ 1, 2, 3 … เริ่ม-จบกี่โมง และพักกลางวันคาบไหน ครั้งเดียวทั้งโรงเรียน',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: SchoolAdminPalette.textMuted,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _openPeriodsSheet,
              icon: const Icon(Icons.add_rounded),
              label: const Text('ตั้งค่าคาบเวลา'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverview() {
    final rooms = _controller.rooms;
    final done = rooms
        .where((r) => r.lessonSlots > 0 && r.filledSlots >= r.lessonSlots)
        .length;
    final lower = rooms.where((r) => r.level == 'lower').toList();
    final upper = rooms.where((r) => r.level == 'upper').toList();
    final other = rooms.where((r) => r.level == 'other').toList();
    final conflicts = _controller.conflicts;
    final term = _controller.terms
        .where((t) => t.termId == _controller.selectedTermId)
        .firstOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    term == null
                        ? 'ตารางเรียน'
                        : 'ตารางเรียน ${term.termName} (${term.academicYearName})',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: SchoolAdminPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'จัดแล้ว $done จาก ${rooms.length} ห้อง · คาบเวลา ${_controller.lessonPeriods.length} คาบ',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: SchoolAdminPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'ตัวเลือก',
              icon: const Icon(Icons.more_horiz_rounded),
              onSelected: (v) {
                if (v == 'periods') _openPeriodsSheet();
                if (v == 'term') _openTermPicker();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'term',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.calendar_today_outlined),
                    title: Text('เปลี่ยนภาคเรียน'),
                  ),
                ),
                PopupMenuItem(
                  value: 'periods',
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.schedule_rounded),
                    title: Text('คาบเวลา / พักกลางวัน'),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: 'ครูที่มีในระบบ',
                value: '${_controller.teachers.length}',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                label: 'ครูชนกัน',
                value: '${conflicts.length}',
                warn: conflicts.isNotEmpty,
                onTap: conflicts.isEmpty ? null : _openConflictsSheet,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (rooms.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Text(
              'ยังไม่มีห้องเรียนในปีการศึกษานี้ — ห้องมาจากการตั้งชั้น/ห้องให้นักเรียนที่เมนู "นักเรียน"',
              textAlign: TextAlign.center,
              style: TextStyle(color: SchoolAdminPalette.textMuted),
            ),
          ),
        if (lower.isNotEmpty)
          _LevelSection(
            title: 'มัธยมต้น',
            rooms: lower,
            onTap: _controller.openRoom,
          ),
        if (upper.isNotEmpty)
          _LevelSection(
            title: 'มัธยมปลาย',
            rooms: upper,
            onTap: _controller.openRoom,
          ),
        if (other.isNotEmpty)
          _LevelSection(
            title: 'ชั้นอื่น ๆ',
            rooms: other,
            onTap: _controller.openRoom,
          ),
      ],
    );
  }

  // ── room / day view ───────────────────────────────────────────────────

  Widget _buildRoom() {
    final room = _controller.selectedRoom!;
    final day = _controller.selectedDay;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
          child: Row(
            children: [
              IconButton(
                tooltip: 'กลับ',
                onPressed: _controller.closeRoom,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตารางเรียน ${room.roomKey}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    Text(
                      'นักเรียน ${room.studentCount} คน · จัดแล้ว ${room.filledSlots}/${room.lessonSlots} คาบ',
                      style: const TextStyle(
                        fontSize: 12,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'ตัวเลือกห้อง',
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (v) {
                  if (v == 'copy') _openCopySheet(fromOtherTerm: false);
                  if (v == 'lastterm') _openCopySheet(fromOtherTerm: true);
                  if (v == 'clear') _confirmClearRoom();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'copy',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.copy_rounded),
                      title: Text('คัดลอกตารางจากห้องอื่น'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'lastterm',
                    child: ListTile(
                      dense: true,
                      leading: Icon(Icons.history_rounded),
                      title: Text('ใช้ตารางจากภาคเรียนอื่น'),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'clear',
                    child: ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.delete_outline_rounded,
                        color: SchoolAdminPalette.red,
                      ),
                      title: Text(
                        'ล้างตารางห้องนี้',
                        style: TextStyle(color: SchoolAdminPalette.red),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              for (var i = 1; i <= 5; i++) ...[
                Expanded(
                  child: _DayChip(
                    label: _dayShort[i - 1],
                    selected: day == i,
                    filled: _controller.schedules.any((s) => s.dayOfWeek == i),
                    onTap: () => _controller.selectDay(i),
                  ),
                ),
                if (i < 5) const SizedBox(width: 6),
              ],
            ],
          ),
        ),
        Expanded(
          child: _controller.roomLoading
              ? const Center(child: CircularProgressIndicator())
              : GestureDetector(
                  onHorizontalDragEnd: (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v < -200) _controller.selectDay(day + 1);
                    if (v > 200) _controller.selectDay(day - 1);
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'วัน${_dayLong[day - 1]}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: SchoolAdminPalette.textSecondary,
                          ),
                        ),
                      ),
                      for (final p in _controller.periods)
                        _PeriodRow(
                          period: p,
                          slot: p.isBreak
                              ? null
                              : _controller.slotAt(day, p.periodNo),
                          onTap: p.isBreak
                              ? null
                              : () => _openSlotSheet(p, day),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  // ── sheets ────────────────────────────────────────────────────────────

  Future<void> _openTermPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'ภาคเรียน',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
            for (final t in _controller.terms)
              ListTile(
                title: Text('${t.termName} (${t.academicYearName})'),
                trailing: t.termId == _controller.selectedTermId
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(t.termId),
              ),
          ],
        ),
      ),
    );
    if (picked != null) await _controller.selectTerm(picked);
  }

  Future<void> _openConflictsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (_) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            const Text(
              'ครูถูกจัดชนกัน',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            const Text(
              'ครูคนเดียวมีสอนมากกว่า 1 ห้องในคาบเดียวกัน แก้โดยเปิดห้องใดห้องหนึ่งแล้วเปลี่ยนครูหรือย้ายคาบ',
              style: TextStyle(
                fontSize: 12,
                color: SchoolAdminPalette.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            for (final c in _controller.conflicts)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.warning_amber_rounded,
                  color: SchoolAdminPalette.warning,
                ),
                title: Text(c.teacherName),
                subtitle: Text(
                  'วัน${_dayLong[(c.dayOfWeek - 1).clamp(0, 4)]} คาบ ${c.periodNo} · ${c.rooms.join(' และ ')}',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPeriodsSheet() async {
    final result = await showModalBottomSheet<List<SchoolPeriod>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PeriodsSheet(initial: _controller.periods),
    );
    if (result == null) return;
    try {
      await _controller.replacePeriods(result);
      if (mounted) _snack('บันทึกคาบเวลาแล้ว');
    } catch (e) {
      if (!mounted) return;
      _snack(
        thaiError(e, fallback: 'บันทึกคาบเวลาไม่สำเร็จ กรุณาลองใหม่'),
        error: true,
      );
    }
  }

  Future<void> _openSlotSheet(SchoolPeriod period, int dayOfWeek) async {
    final existing = _controller.slotAt(dayOfWeek, period.periodNo);
    final room = _controller.selectedRoom!;
    final result = await showModalBottomSheet<_SlotResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SlotSheet(
        title:
            'วัน${_dayLong[dayOfWeek - 1]} · คาบ ${period.periodNo} · ${period.startHm}–${period.endHm}',
        roomKey: room.roomKey,
        existing: existing,
        roomSubjects: _controller.roomSubjects,
        teachers: _controller.teachers,
        teachersFor: _controller.teachersFor,
        clashFor: (teacherId) => _controller.teacherClash(
          teacherId: teacherId,
          dayOfWeek: dayOfWeek,
          periodNo: period.periodNo,
        ),
      ),
    );
    if (result == null) return;
    try {
      if (result.clear) {
        await _controller.clearSlotAt(
          periodNo: period.periodNo,
          dayOfWeek: dayOfWeek,
        );
      } else {
        await _controller.assignSlot(
          periodNo: period.periodNo,
          dayOfWeek: dayOfWeek,
          subjectName: result.subjectName!,
          teacherId: result.teacherId!,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _snack(
        thaiError(
          e,
          fallback: result.clear
              ? 'ลบคาบไม่สำเร็จ กรุณาลองใหม่'
              : 'บันทึกคาบไม่สำเร็จ กรุณาลองใหม่',
        ),
        error: true,
      );
    }
  }

  Future<void> _openCopySheet({required bool fromOtherTerm}) async {
    final room = _controller.selectedRoom!;
    String fromTermId = _controller.selectedTermId!;
    TimetableRoomOverview? fromRoom;
    List<TimetableRoomOverview> candidates = _controller.rooms
        .where((r) => r.roomKey != room.roomKey)
        .toList();
    if (fromOtherTerm) {
      final t = await showModalBottomSheet<String>(
        context: context,
        builder: (_) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'ใช้ตารางของห้องนี้จากภาคเรียน…',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              for (final t in _controller.terms.where(
                (t) => t.termId != _controller.selectedTermId,
              ))
                ListTile(
                  title: Text('${t.termName} (${t.academicYearName})'),
                  onTap: () => Navigator.of(context).pop(t.termId),
                ),
            ],
          ),
        ),
      );
      if (t == null) return;
      fromTermId = t;
      fromRoom = room;
    } else {
      fromRoom = await showModalBottomSheet<TimetableRoomOverview>(
        context: context,
        builder: (_) => SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'คัดลอกตารางจากห้อง…',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
              for (final r in candidates)
                ListTile(
                  title: Text(r.roomKey),
                  subtitle: Text(
                    'จัดแล้ว ${r.filledSlots}/${r.lessonSlots} คาบ',
                  ),
                  enabled: r.filledSlots > 0,
                  onTap: () => Navigator.of(context).pop(r),
                ),
            ],
          ),
        ),
      );
      if (fromRoom == null) return;
    }
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('คัดลอกตาราง'),
        content: Text(
          'ตารางเดิมของ ${room.roomKey} ในภาคเรียนนี้จะถูกแทนทั้งหมด ดำเนินการต่อ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('คัดลอก'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = await _controller.copyIntoSelectedRoom(
        fromTermId: fromTermId,
        fromGradeLevel: fromRoom.gradeLevel,
        fromRoom: fromRoom.room,
      );
      if (mounted) _snack('คัดลอกแล้ว $n คาบ');
    } catch (e) {
      if (!mounted) return;
      _snack(
        thaiError(e, fallback: 'คัดลอกไม่สำเร็จ กรุณาลองใหม่'),
        error: true,
      );
    }
  }

  Future<void> _confirmClearRoom() async {
    final room = _controller.selectedRoom!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ล้างตารางห้องนี้'),
        content: Text(
          'ลบทุกคาบของ ${room.roomKey} ในภาคเรียนนี้ (${room.filledSlots} คาบ) — นักเรียนยังอยู่ในวิชาเดิม แค่ตารางว่าง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: SchoolAdminPalette.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('ล้าง'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final n = await _controller.clearSelectedRoom();
      if (mounted) _snack('ล้างแล้ว $n คาบ');
    } catch (e) {
      if (!mounted) return;
      _snack(thaiError(e, fallback: 'ล้างไม่สำเร็จ กรุณาลองใหม่'), error: true);
    }
  }
}

// ── subject colours ─────────────────────────────────────────────────────

/// Stable pastel per subject name (hash → one of 8 pairs), like a calendar
/// app: same subject, same colour, in every room. Text uses the dark stop
/// of the same family.
class SubjectColor {
  const SubjectColor(this.bg, this.fg, this.bar);
  final Color bg;
  final Color fg;
  final Color bar;

  static const _pairs = [
    SubjectColor(Color(0xFFE6F1FB), Color(0xFF0C447C), Color(0xFF378ADD)),
    SubjectColor(Color(0xFFE1F5EE), Color(0xFF085041), Color(0xFF1D9E75)),
    SubjectColor(Color(0xFFFAEEDA), Color(0xFF633806), Color(0xFFEF9F27)),
    SubjectColor(Color(0xFFEEEDFE), Color(0xFF3C3489), Color(0xFF7F77DD)),
    SubjectColor(Color(0xFFFBEAF0), Color(0xFF72243E), Color(0xFFD4537E)),
    SubjectColor(Color(0xFFFAECE7), Color(0xFF712B13), Color(0xFFD85A30)),
    SubjectColor(Color(0xFFEAF3DE), Color(0xFF27500A), Color(0xFF639922)),
    SubjectColor(Color(0xFFF1EFE8), Color(0xFF444441), Color(0xFF888780)),
  ];

  static SubjectColor of(String subjectName) {
    var h = 0;
    for (final c in subjectName.trim().codeUnits) {
      h = (h * 31 + c) & 0x7fffffff;
    }
    return _pairs[h % _pairs.length];
  }
}

// ── small widgets ───────────────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    this.warn = false,
    this.onTap,
  });
  final String label;
  final String value;
  final bool warn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = warn
        ? SchoolAdminPalette.warningSoft
        : SchoolAdminPalette.surfaceSoft;
    final fg = warn
        ? SchoolAdminPalette.warning
        : SchoolAdminPalette.textPrimary;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: SchoolAdminPalette.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: warn ? fg : SchoolAdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: fg,
                    ),
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    Icon(Icons.chevron_right_rounded, size: 18, color: fg),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({
    required this.title,
    required this.rooms,
    required this.onTap,
  });
  final String title;
  final List<TimetableRoomOverview> rooms;
  final ValueChanged<TimetableRoomOverview> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 6),
          child: Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: SchoolAdminPalette.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${rooms.length} ห้อง',
                style: const TextStyle(
                  fontSize: 12,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
            ],
          ),
        ),
        for (final r in rooms) _RoomRow(room: r, onTap: () => onTap(r)),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onTap});
  final TimetableRoomOverview room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final complete =
        room.lessonSlots > 0 && room.filledSlots >= room.lessonSlots;
    final started = room.filledSlots > 0;
    final barColor = complete
        ? SchoolAdminPalette.success
        : SchoolAdminPalette.yellow;
    final label = !started
        ? 'ยังไม่จัด'
        : '${room.filledSlots}/${room.lessonSlots}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: SchoolAdminPalette.surface,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: SchoolAdminPalette.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            room.roomKey,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${room.studentCount} คน',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: SchoolAdminPalette.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: room.progress.clamp(0, 1),
                          minHeight: 4,
                          backgroundColor: SchoolAdminPalette.surfaceSoft,
                          color: barColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: !started
                        ? SchoolAdminPalette.textMuted
                        : complete
                        ? SchoolAdminPalette.success
                        : SchoolAdminPalette.warning,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SchoolAdminPalette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.label,
    required this.selected,
    required this.filled,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? SchoolAdminPalette.primary
          : SchoolAdminPalette.surfaceSoft,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? SchoolAdminPalette.primary
                  : SchoolAdminPalette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? SchoolAdminPalette.onPrimary
                      : SchoolAdminPalette.textPrimary,
                ),
              ),
              if (filled && !selected) ...[
                const SizedBox(width: 4),
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: SchoolAdminPalette.success,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodRow extends StatelessWidget {
  const _PeriodRow({required this.period, required this.slot, this.onTap});
  final SchoolPeriod period;
  final ClassSchedule? slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final time = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          period.startHm,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: SchoolAdminPalette.textSecondary,
          ),
        ),
        Text(
          period.endHm,
          style: const TextStyle(
            fontSize: 11,
            color: SchoolAdminPalette.textMuted,
          ),
        ),
      ],
    );

    Widget body;
    if (period.isBreak) {
      body = Container(
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: SchoolAdminPalette.surfaceSoft,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          period.label ?? 'พัก',
          style: const TextStyle(
            fontSize: 12.5,
            color: SchoolAdminPalette.textSecondary,
          ),
        ),
      );
    } else if (slot == null) {
      body = Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: SchoolAdminPalette.border, width: 1.2),
        ),
        child: const Row(
          children: [
            Icon(
              Icons.add_rounded,
              size: 18,
              color: SchoolAdminPalette.textMuted,
            ),
            SizedBox(width: 6),
            Expanded(
              child: Text(
                'ว่าง — แตะเพื่อใส่วิชา',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.5,
                  color: SchoolAdminPalette.textMuted,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      final c = SubjectColor.of(slot!.subjectName);
      body = Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: const BorderRadius.horizontal(
            right: Radius.circular(10),
          ),
          border: Border(left: BorderSide(color: c.bar, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              slot!.subjectName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: c.fg,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              slot!.teacherName ?? 'ยังไม่ระบุครู',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: c.fg.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(width: 46, child: time),
          const SizedBox(width: 6),
          Expanded(
            child: onTap == null
                ? body
                : Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onTap,
                      borderRadius: BorderRadius.circular(10),
                      child: body,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── slot sheet ──────────────────────────────────────────────────────────

class _SlotResult {
  const _SlotResult.save(this.subjectName, this.teacherId) : clear = false;
  const _SlotResult.clear()
    : subjectName = null,
      teacherId = null,
      clear = true;
  final String? subjectName;
  final String? teacherId;
  final bool clear;
}

class _SlotSheet extends StatefulWidget {
  const _SlotSheet({
    required this.title,
    required this.roomKey,
    required this.existing,
    required this.roomSubjects,
    required this.teachers,
    required this.teachersFor,
    required this.clashFor,
  });
  final String title;
  final String roomKey;
  final ClassSchedule? existing;
  final List<RoomSubject> roomSubjects;
  final List<StaffDirectoryEntry> teachers;
  final List<TeacherSubject> Function(String subject) teachersFor;
  final Future<TeacherWeekSlot?> Function(String teacherId) clashFor;

  @override
  State<_SlotSheet> createState() => _SlotSheetState();
}

class _SlotSheetState extends State<_SlotSheet> {
  late final TextEditingController _subject;
  String? _teacherId;
  bool _newSubject = false;
  TeacherWeekSlot? _clash;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _subject = TextEditingController(text: widget.existing?.subjectName ?? '');
    _teacherId = widget.existing?.teacherId;
    _newSubject = widget.existing != null;
    _subject.addListener(() => setState(() {}));
    if (_teacherId != null) _checkClash(_teacherId!);
  }

  @override
  void dispose() {
    _subject.dispose();
    super.dispose();
  }

  Future<void> _checkClash(String teacherId) async {
    setState(() {
      _checking = true;
      _clash = null;
    });
    try {
      final c = await widget.clashFor(teacherId);
      if (!mounted) return;
      setState(() => _clash = c);
    } catch (_) {
      // a failed clash lookup must not block saving
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _pickRoomSubject(RoomSubject rs) {
    setState(() {
      _subject.text = rs.subjectName;
      _newSubject = true;
      _teacherId = rs.teacherId;
    });
    if (rs.teacherId != null) _checkClash(rs.teacherId!);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final subject = _subject.text.trim();
    final known = widget.teachersFor(subject);
    final knownIds = known.map((t) => t.teacherId).toSet();
    final options = subject.isEmpty || known.isEmpty
        ? widget.teachers
        : widget.teachers.where((t) => knownIds.contains(t.userId)).toList();
    final canSave = subject.isNotEmpty && _teacherId != null;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'ห้อง ${widget.roomKey}',
                style: const TextStyle(
                  fontSize: 12,
                  color: SchoolAdminPalette.textSecondary,
                ),
              ),
              const SizedBox(height: 14),
              if (!_newSubject) ...[
                if (widget.roomSubjects.isNotEmpty) ...[
                  const Text(
                    'วิชาที่ห้องนี้เรียนอยู่',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: SchoolAdminPalette.textMuted,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final rs in widget.roomSubjects)
                    _RoomSubjectTile(rs: rs, onTap: () => _pickRoomSubject(rs)),
                  const SizedBox(height: 4),
                ],
                OutlinedButton.icon(
                  onPressed: () => setState(() {
                    _newSubject = true;
                    _teacherId = null;
                    _clash = null;
                  }),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(
                    widget.roomSubjects.isEmpty
                        ? 'ใส่วิชาแรกของห้องนี้'
                        : 'วิชาใหม่ให้ห้องนี้',
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _subject,
                  autofocus: widget.existing == null && _subject.text.isEmpty,
                  decoration: const InputDecoration(
                    labelText: 'วิชา',
                    hintText: 'เช่น ภาษาไทย',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: options.any((t) => t.userId == _teacherId)
                      ? _teacherId
                      : null,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'ครูผู้สอน *',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final t in options)
                      DropdownMenuItem(
                        value: t.userId,
                        child: Text(
                          t.fullName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() => _teacherId = v);
                    if (v != null) _checkClash(v);
                  },
                ),
                if (subject.isNotEmpty && known.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text(
                      'ยังไม่มีครูที่เคยสอนวิชานี้ในระบบ — เลือกจากครูทั้งหมดได้ ระบบจะจำให้ครั้งถัดไป',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: SchoolAdminPalette.textMuted,
                      ),
                    ),
                  ),
                if (_checking)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: SizedBox(
                      height: 14,
                      width: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                if (_clash != null)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: SchoolAdminPalette.warningSoft,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 18,
                          color: SchoolAdminPalette.warning,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'ครูคนนี้สอน ${_clash!.roomKey} (${_clash!.subjectName}) อยู่แล้วในคาบนี้ — บันทึกได้ แต่จะถูกนับว่าชนกัน',
                            style: const TextStyle(
                              fontSize: 12,
                              color: SchoolAdminPalette.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (widget.existing != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(const _SlotResult.clear()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SchoolAdminPalette.red,
                          ),
                          child: const Text('ลบคาบ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: FilledButton(
                        onPressed: canSave
                            ? () => Navigator.of(
                                context,
                              ).pop(_SlotResult.save(subject, _teacherId!))
                            : null,
                        child: const Text('บันทึก'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomSubjectTile extends StatelessWidget {
  const _RoomSubjectTile({required this.rs, required this.onTap});
  final RoomSubject rs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = SubjectColor.of(rs.subjectName);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: SchoolAdminPalette.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              border: Border.all(color: SchoolAdminPalette.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: c.bar,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rs.subjectName,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                      Text(
                        '${rs.teacherName ?? 'ยังไม่ระบุครู'} · ${rs.slotsPerWeek} คาบ/สัปดาห์',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: SchoolAdminPalette.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: SchoolAdminPalette.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── periods sheet ───────────────────────────────────────────────────────

/// Edits the school's period table in place: one row per period with
/// start/end pickers and a lesson/break toggle. Saved as a whole
/// (set_school_periods replaces the set).
class _PeriodsSheet extends StatefulWidget {
  const _PeriodsSheet({required this.initial});
  final List<SchoolPeriod> initial;

  @override
  State<_PeriodsSheet> createState() => _PeriodsSheetState();
}

class _PeriodsSheetState extends State<_PeriodsSheet> {
  late List<_EditablePeriod> _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _rows = widget.initial.isEmpty
        ? _defaultRows()
        : widget.initial
              .map(
                (p) => _EditablePeriod(
                  _parse(p.startTime),
                  _parse(p.endTime),
                  isBreak: p.isBreak,
                ),
              )
              .toList();
  }

  /// 4 lessons, lunch, 4 lessons from 08:30 in 50-minute steps — a starting
  /// point the admin edits; nothing is written until they press บันทึก.
  static List<_EditablePeriod> _defaultRows() {
    final rows = <_EditablePeriod>[];
    var start = const TimeOfDay(hour: 8, minute: 30);
    for (var i = 0; i < 9; i++) {
      final isBreak = i == 4;
      final end = _add(start, isBreak ? 60 : 50);
      rows.add(_EditablePeriod(start, end, isBreak: isBreak));
      start = end;
    }
    return rows;
  }

  static TimeOfDay _add(TimeOfDay t, int minutes) {
    final total = t.hour * 60 + t.minute + minutes;
    return TimeOfDay(hour: (total ~/ 60) % 24, minute: total % 60);
  }

  static TimeOfDay _parse(String hms) {
    final parts = hms.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
    );
  }

  static String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static int _mins(TimeOfDay t) => t.hour * 60 + t.minute;

  Future<void> _pick(int index, bool isStart) async {
    final row = _rows[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? row.start : row.end,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        row.start = picked;
      } else {
        row.end = picked;
      }
      _error = null;
    });
  }

  void _save() {
    var lessons = 0;
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      if (!r.isBreak) lessons++;
      if (_mins(r.end) <= _mins(r.start)) {
        setState(
          () => _error = 'คาบ ${i + 1}: เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม',
        );
        return;
      }
      if (i > 0 && _mins(r.start) < _mins(_rows[i - 1].end)) {
        setState(() => _error = 'คาบ ${i + 1} เริ่มก่อนคาบ $i จบ');
        return;
      }
    }
    if (lessons == 0) {
      setState(() => _error = 'ต้องมีคาบเรียนอย่างน้อย 1 คาบ');
      return;
    }
    Navigator.of(context).pop([
      for (var i = 0; i < _rows.length; i++)
        SchoolPeriod(
          periodNo: i + 1,
          startTime: _fmt(_rows[i].start),
          endTime: _fmt(_rows[i].end),
          kind: _rows[i].isBreak ? 'break' : 'lesson',
          label: _rows[i].isBreak ? 'พักกลางวัน' : 'คาบ ${i + 1}',
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottomInset,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'คาบเวลาเรียน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'ใช้ร่วมกันทั้งโรงเรียน · แตะไอคอนซ้ายเพื่อสลับ คาบเรียน / พัก',
            style: TextStyle(fontSize: 12, color: SchoolAdminPalette.textMuted),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _rows.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) {
                final r = _rows[i];
                return Row(
                  children: [
                    IconButton(
                      tooltip: r.isBreak ? 'พัก → คาบเรียน' : 'คาบเรียน → พัก',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => setState(() {
                        r.isBreak = !r.isBreak;
                        _error = null;
                      }),
                      icon: Icon(
                        r.isBreak
                            ? Icons.restaurant_rounded
                            : Icons.menu_book_rounded,
                        size: 18,
                        color: r.isBreak
                            ? SchoolAdminPalette.orange
                            : SchoolAdminPalette.primary,
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        r.isBreak ? 'พัก' : 'คาบ ${i + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                          color: r.isBreak
                              ? SchoolAdminPalette.textSecondary
                              : SchoolAdminPalette.textPrimary,
                        ),
                      ),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pick(i, true),
                        child: Text(_fmt(r.start)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4),
                      child: Text('–'),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pick(i, false),
                        child: Text(_fmt(r.end)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'ลบ',
                      visualDensity: VisualDensity.compact,
                      onPressed: _rows.length <= 1
                          ? null
                          : () => setState(() => _rows.removeAt(i)),
                      icon: const Icon(Icons.remove_circle_outline, size: 18),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => setState(() {
                final last = _rows.last;
                _rows.add(_EditablePeriod(last.end, _add(last.end, 50)));
              }),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('เพิ่มคาบ'),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                _error!,
                style: const TextStyle(
                  color: SchoolAdminPalette.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('บันทึกคาบเวลา'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _EditablePeriod {
  _EditablePeriod(this.start, this.end, {this.isBreak = false});
  TimeOfDay start;
  TimeOfDay end;
  bool isBreak;
}
