import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';

import 'controllers/school_timetable_controller.dart';
import 'controllers/school_admin_async_state.dart';

import 'theme/school_admin_palette.dart';

class SchoolTimetablePage extends StatefulWidget {
  const SchoolTimetablePage({super.key, this.controller});
  final SchoolTimetableController? controller;

  @override
  State<SchoolTimetablePage> createState() => _SchoolTimetablePageState();
}

class _SchoolTimetablePageState extends State<SchoolTimetablePage> {
  late final SchoolTimetableController _controller;
  late final bool _ownsController;

  final ScrollController _horizontalHeaderController = ScrollController();
  final ScrollController _horizontalGridController = ScrollController();

  static const List<String> _days = [
    'จันทร์',
    'อังคาร',
    'พุธ',
    'พฤหัสบดี',
    'ศุกร์',
  ];

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        SchoolTimetableController(
          loadTerms: TimetableService.listTerms,
          loadRooms: TimetableService.listSchoolRooms,
          loadPeriods: TimetableService.listSchoolPeriods,
          loadSchedules: TimetableService.listRoomTimetable,
          loadTeacherSubjects: TimetableService.listTeacherSubjects,
          loadStaff: StaffOrgService.listStaffDirectory,
          setSlot: TimetableService.adminSetRoomTimetableSlot,
          clearSlot: TimetableService.adminClearRoomTimetableSlot,
          savePeriods: TimetableService.setSchoolPeriods,
        );

    _controller.addListener(_onControllerChanged);
    _controller.load();

    _horizontalGridController.addListener(() {
      if (_horizontalHeaderController.hasClients &&
          _horizontalGridController.offset !=
              _horizontalHeaderController.offset) {
        _horizontalHeaderController.jumpTo(_horizontalGridController.offset);
      }
    });
    _horizontalHeaderController.addListener(() {
      if (_horizontalGridController.hasClients &&
          _horizontalHeaderController.offset !=
              _horizontalGridController.offset) {
        _horizontalGridController.jumpTo(_horizontalHeaderController.offset);
      }
    });
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    _horizontalHeaderController.dispose();
    _horizontalGridController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: SchoolAdminPalette.red),
    );
  }

  /// RPC error codes → what the admin should read. Raw exception text never
  /// reaches the screen (same rule as d8dcf6e on the teacher lane).
  static String thaiError(Object e, {required String fallback}) {
    final t = e.toString();
    if (t.contains('period_not_found')) {
      return 'ยังไม่ได้ตั้งค่าคาบเวลานี้ ตั้งค่าคาบเวลาก่อน';
    }
    if (t.contains('teacher_required')) return 'ต้องระบุครูผู้สอน';
    if (t.contains('teacher_not_found')) {
      return 'ไม่พบครูคนนี้ในโรงเรียน (ต้องมีบทบาทครู)';
    }
    if (t.contains('subject_name_required')) return 'กรุณาระบุชื่อวิชา';
    if (t.contains('term_not_found')) return 'ไม่พบภาคเรียนที่เลือก';
    if (t.contains('room_required')) return 'ต้องระบุชั้นและห้อง';
    if (t.contains('invalid_period_time')) {
      return 'เวลาสิ้นสุดของคาบต้องอยู่หลังเวลาเริ่ม';
    }
    if (t.contains('forbidden')) return 'บัญชีนี้ไม่มีสิทธิ์จัดตารางเรียน';
    if (t.contains('invalid_session') || t.contains('not_signed_in')) {
      return 'หมดเวลาเข้าสู่ระบบ กรุณาเข้าสู่ระบบใหม่';
    }
    return fallback;
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
    } catch (e) {
      if (!mounted) return;
      _showError(thaiError(e, fallback: 'บันทึกคาบเวลาไม่สำเร็จ กรุณาลองใหม่'));
    }
  }

  Future<void> _openSlotSheet(int periodNo, int dayOfWeek) async {
    final schedule = _controller.schedules
        .where((s) => s.periodNo == periodNo && s.dayOfWeek == dayOfWeek)
        .firstOrNull;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return _SlotEditSheet(
          initialSubject: schedule?.subjectName,
          initialTeacherId: schedule?.teacherId,
          teacherSubjects: _controller.teacherSubjects,
          staff: _controller.staff,
        );
      },
    );

    if (result != null) {
      if (result['action'] == 'clear') {
        try {
          await _controller.clearSlotAt(
            periodNo: periodNo,
            dayOfWeek: dayOfWeek,
          );
        } catch (e) {
          _showError(thaiError(e, fallback: 'ลบคาบไม่สำเร็จ กรุณาลองใหม่'));
        }
      } else if (result['action'] == 'save') {
        final String subjectName = result['subject_name'];
        final String? teacherId = result['teacher_id'];
        if (subjectName.isEmpty) {
          _showError('กรุณาระบุชื่อวิชา');
          return;
        }
        if (teacherId == null) {
          _showError('ต้องระบุครูผู้สอน');
          return;
        }
        try {
          await _controller.assignSlot(
            periodNo: periodNo,
            dayOfWeek: dayOfWeek,
            subjectName: subjectName,
            teacherId: teacherId,
          );
        } catch (e) {
          _showError(thaiError(e, fallback: 'บันทึกคาบไม่สำเร็จ กรุณาลองใหม่'));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;
    final state = _controller.state;
    if (state is SchoolAdminLoading) {
      bodyWidget = const Center(child: CircularProgressIndicator());
    } else if (state is SchoolAdminError) {
      bodyWidget = Center(
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
    } else if (state is SchoolAdminEmpty) {
      bodyWidget = Center(child: Text(state.label));
    } else {
      bodyWidget = _buildContent();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('จัดตารางเรียน'),
        backgroundColor: SchoolAdminPalette.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'ตั้งค่าคาบเวลา',
            onPressed: state is SchoolAdminLoading ? null : _openPeriodsSheet,
            icon: const Icon(Icons.schedule_rounded),
          ),
        ],
      ),
      body: bodyWidget,
    );
  }

  Widget _buildContent() {
    if (_controller.periods.isEmpty) {
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
                'กำหนดว่าคาบ 1, 2, 3 … เริ่ม-จบกี่โมง ครั้งเดียวทั้งโรงเรียน แล้วค่อยจัดวิชาลงช่อง',
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

    return Column(
      children: [
        _buildFilters(),
        const Divider(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: _buildGrid(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: _controller.selectedTermId,
              // isExpanded: the two dropdowns share a 360-pt phone row; without
              // it the inner Row overflowed by 1.2 px (iphone_layout_test).
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'เทอม'),
              items: _controller.terms.map((t) {
                return DropdownMenuItem(
                  value: t.termId,
                  child: Text(
                    '${t.termName} (${t.academicYearName})',
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _controller.selectTerm(val);
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<SchoolRoom>(
              initialValue: _controller.selectedRoom,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'ห้องเรียน'),
              items: _controller.rooms.map((r) {
                return DropdownMenuItem(
                  value: r,
                  child: Text(r.displayName, overflow: TextOverflow.ellipsis),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) _controller.selectRoom(val);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final periods = _controller.periods;

    return Column(
      children: [
        // Header Row (Empty corner + Days)
        Row(
          children: [
            const SizedBox(width: 80, height: 40),
            Expanded(
              child: SingleChildScrollView(
                controller: _horizontalHeaderController,
                scrollDirection: Axis.horizontal,
                physics: const ClampingScrollPhysics(),
                child: Row(
                  children: _days.map((day) {
                    return SizedBox(
                      width: 120,
                      height: 40,
                      child: Center(
                        child: Text(
                          day,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        // Grid Body
        Expanded(
          child: SingleChildScrollView(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fixed row headers (Periods)
                Column(
                  children: periods.map((p) {
                    return SizedBox(
                      width: 80,
                      height: 100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'คาบ ${p.periodNo}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${p.startHm}-${p.endHm}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                // Grid Cells
                Expanded(
                  child: SingleChildScrollView(
                    controller: _horizontalGridController,
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: periods.map((p) {
                        return Row(
                          children: List.generate(5, (dayIndex) {
                            final dayOfWeek = dayIndex + 1; // 1 = Monday
                            final schedule = _controller.schedules
                                .where(
                                  (s) =>
                                      s.periodNo == p.periodNo &&
                                      s.dayOfWeek == dayOfWeek,
                                )
                                .firstOrNull;

                            return SizedBox(
                              width: 120,
                              height: 100,
                              child: Card(
                                margin: const EdgeInsets.all(4),
                                clipBehavior: Clip.antiAlias,
                                child: InkWell(
                                  onTap: () =>
                                      _openSlotSheet(p.periodNo, dayOfWeek),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: schedule == null
                                        ? const Center(
                                            child: Icon(
                                              Icons.add,
                                              color:
                                                  SchoolAdminPalette.textMuted,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                schedule.subjectName,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                schedule.teacherName ?? '-',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: SchoolAdminPalette
                                                      .textMuted,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SlotEditSheet extends StatefulWidget {
  final String? initialSubject;
  final String? initialTeacherId;
  final List<TeacherSubject> teacherSubjects;
  final List<StaffDirectoryEntry> staff;

  const _SlotEditSheet({
    required this.initialSubject,
    required this.initialTeacherId,
    required this.teacherSubjects,
    required this.staff,
  });

  @override
  State<_SlotEditSheet> createState() => _SlotEditSheetState();
}

class _SlotEditSheetState extends State<_SlotEditSheet> {
  late final TextEditingController _subjectController;
  String? _selectedTeacherId;
  bool _showAllTeachers = false;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController(
      text: widget.initialSubject ?? '',
    );
    _selectedTeacherId = widget.initialTeacherId;
    _subjectController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final currentSubject = _subjectController.text.trim();
    final subjectTeachers = widget.teacherSubjects
        .where((t) => t.subjectName == currentSubject)
        .toList();

    final hasTeachersForSubject = subjectTeachers.isNotEmpty;
    if (!hasTeachersForSubject && currentSubject.isNotEmpty) {
      _showAllTeachers = true;
    }

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
            'ตั้งค่าคาบเรียน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: _subjectController,
            label: 'วิชา',
            hint: 'เช่น ภาษาไทย',
          ),
          const SizedBox(height: 16),
          if (currentSubject.isNotEmpty) ...[
            if (!hasTeachersForSubject)
              Container(
                padding: const EdgeInsets.all(8),
                color: SchoolAdminPalette.warningSoft,
                child: const Text(
                  'ยังไม่มีครูที่ลงสอนวิชานี้ คุณสามารถเลือกครูจากรายชื่อทั้งหมดได้',
                  style: TextStyle(color: SchoolAdminPalette.warning),
                ),
              ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _selectedTeacherId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'ครูผู้สอน *'),
              items: [
                if (!_showAllTeachers)
                  ...subjectTeachers.map(
                    (t) => DropdownMenuItem(
                      value: t.teacherId,
                      child: Text(t.fullName),
                    ),
                  ),
                if (_showAllTeachers)
                  ...widget.staff.map(
                    (s) => DropdownMenuItem(
                      value: s.userId,
                      child: Text(s.fullName),
                    ),
                  ),
              ],
              onChanged: (val) {
                setState(() {
                  _selectedTeacherId = val;
                });
              },
            ),
            const SizedBox(height: 24),
          ],
          Row(
            children: [
              if (widget.initialSubject != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        Navigator.of(context).pop({'action': 'clear'}),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: SchoolAdminPalette.red,
                    ),
                    child: const Text('ลบคาบ'),
                  ),
                ),
              if (widget.initialSubject != null) const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      currentSubject.isEmpty || _selectedTeacherId == null
                      ? null
                      : () => Navigator.of(context).pop({
                          'action': 'save',
                          'subject_name': currentSubject,
                          'teacher_id': _selectedTeacherId,
                        }),
                  child: const Text('บันทึก'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Edits the school's period table in place: one row per period with
/// start/end pickers. Saved as a whole (set_school_periods replaces the set).
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
                (p) => _EditablePeriod(_parse(p.startTime), _parse(p.endTime)),
              )
              .toList();
  }

  /// 8 periods of 50 minutes from 08:30 — a starting point the admin edits,
  /// shown only until saved (nothing is written until they press บันทึก).
  static List<_EditablePeriod> _defaultRows() {
    final rows = <_EditablePeriod>[];
    var start = const TimeOfDay(hour: 8, minute: 30);
    for (var i = 0; i < 8; i++) {
      final end = _add(start, 50);
      rows.add(_EditablePeriod(start, end));
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
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
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
    Navigator.of(context).pop([
      for (var i = 0; i < _rows.length; i++)
        SchoolPeriod(
          periodNo: i + 1,
          startTime: _fmt(_rows[i].start),
          endTime: _fmt(_rows[i].end),
          label: 'คาบ ${i + 1}',
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
            'ใช้ร่วมกันทั้งโรงเรียน · ตารางของทุกห้องอิงเวลาชุดนี้',
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
                    SizedBox(
                      width: 56,
                      child: Text(
                        'คาบ ${i + 1}',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pick(i, true),
                        child: Text(_fmt(r.start)),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6),
                      child: Text('–'),
                    ),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pick(i, false),
                        child: Text(_fmt(r.end)),
                      ),
                    ),
                    IconButton(
                      tooltip: 'ลบคาบนี้',
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
                child: ElevatedButton(
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
  _EditablePeriod(this.start, this.end);
  TimeOfDay start;
  TimeOfDay end;
}
