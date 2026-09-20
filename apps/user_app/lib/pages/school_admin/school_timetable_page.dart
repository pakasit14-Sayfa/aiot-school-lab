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
          _showError('เกิดข้อผิดพลาดในการลบคาบ: $e');
        }
      } else if (result['action'] == 'save') {
        final String subjectName = result['subject_name'];
        final String? teacherId = result['teacher_id'];
        if (subjectName.isEmpty) {
          _showError('กรุณาระบุชื่อวิชา');
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
          _showError('เกิดข้อผิดพลาดในการบันทึกคาบ: $e');
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
        child: Text(
          'ข้อผิดพลาด: ${state.message}',
          style: const TextStyle(color: SchoolAdminPalette.red),
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
      ),
      body: bodyWidget,
    );
  }

  Widget _buildContent() {
    if (_controller.periods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ยังไม่ได้ตั้งค่าคาบเวลาเรียน'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Link to settings or just show a message since we don't have a settings page route right here
                Navigator.of(context).pushNamed('/school_admin/settings');
              },
              child: const Text('ไปตั้งค่าคาบเวลา'),
            ),
          ],
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
              decoration: const InputDecoration(labelText: 'เทอม'),
              items: _controller.terms.map((t) {
                return DropdownMenuItem(
                  value: t.termId,
                  child: Text('${t.termName} (${t.academicYearName})'),
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
              decoration: const InputDecoration(labelText: 'ห้องเรียน'),
              items: _controller.rooms.map((r) {
                return DropdownMenuItem(value: r, child: Text(r.displayName));
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
                            '${p.startTime.substring(0, 5)}-${p.endTime.substring(0, 5)}',
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
                                              color: SchoolAdminPalette.textMuted,
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
                                                  color: SchoolAdminPalette.textMuted,
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
              decoration: const InputDecoration(
                labelText: 'ครูผู้สอน (ไม่บังคับ)',
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('ไม่มี')),
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
                  onPressed: currentSubject.isEmpty
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
