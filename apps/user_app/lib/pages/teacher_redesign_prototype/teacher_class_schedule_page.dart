import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'teacher_redesign_prototype_page.dart';
import 'teacher_shared_widgets.dart';

class TeacherClassSchedulePage extends StatefulWidget {
  const TeacherClassSchedulePage({super.key});

  @override
  State<TeacherClassSchedulePage> createState() =>
      _TeacherClassSchedulePageState();
}

class _TeacherClassSchedulePageState extends State<TeacherClassSchedulePage> {
  static const _allCoursesId = 'all';

  bool _loading = true;
  String? _error;
  List<CourseSummary> _courses = [];
  List<ClassScheduleSlot> _schedules = [];
  String _selectedCourseId = _allCoursesId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final courses = await CourseService.listMyCourses();
      final schedules = await CalendarService.listTeacherSchedules();
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _schedules = schedules;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error loading class schedule: $e');
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลตารางสอนไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  List<ClassScheduleSlot> get _filteredSchedules {
    if (_selectedCourseId == _allCoursesId) return _schedules;
    return _schedules.where((s) => s.courseId == _selectedCourseId).toList();
  }

  Map<int, List<ClassScheduleSlot>> get _schedulesByDay {
    final grouped = <int, List<ClassScheduleSlot>>{};
    for (int day = 0; day < 7; day++) {
      grouped[day] = [];
    }
    for (final s in _filteredSchedules) {
      final day = s.dayOfWeek.clamp(0, 6);
      grouped[day]!.add(s);
    }
    for (final day in grouped.keys) {
      grouped[day]!.sort((a, b) => a.startTime.compareTo(b.startTime));
    }
    return grouped;
  }

  Future<void> _openAddScheduleDialog() async {
    if (_courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('คุณยังไม่มีรายวิชาที่สอน กรุณาสร้างวิชาก่อน')),
      );
      return;
    }

    String selectedCourse = _selectedCourseId != _allCoursesId
        ? _selectedCourseId
        : _courses.first.id;
    int selectedDay = 0; // Monday
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 30);
    TimeOfDay endTime = const TimeOfDay(hour: 10, minute: 0);
    final roomController = TextEditingController();

    // Default room from course if available
    final initialCourse = _courses.firstWhere((c) => c.id == selectedCourse);
    if (initialCourse.room != null) {
      roomController.text = initialCourse.room!;
    }

    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            String formatTime(TimeOfDay t) =>
                '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_circle_outline_rounded, color: TeacherPalette.primary),
                  SizedBox(width: 8),
                  Text('เพิ่มคาบเรียนในตาราง', style: TextStyle(fontWeight: FontWeight.w800)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('รายวิชา:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedCourse,
                      isExpanded: true,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _courses.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.subjectName} (${c.gradeLevel ?? "ไม่ระบุชั้น"})'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedCourse = val;
                            final course = _courses.firstWhere((c) => c.id == val);
                            if (course.room != null && roomController.text.isEmpty) {
                              roomController.text = course.room!;
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    const Text('วันในสัปดาห์:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      value: selectedDay,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      items: List.generate(7, (idx) {
                        return DropdownMenuItem(
                          value: idx,
                          child: Text(ClassScheduleSlot.dayLabels[idx]),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedDay = val);
                      },
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('เวลาเริ่ม:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: startTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() => startTime = picked);
                                  }
                                },
                                icon: const Icon(Icons.access_time_rounded, size: 16),
                                label: Text(formatTime(startTime)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('เวลาสิ้นสุด:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(height: 6),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: endTime,
                                  );
                                  if (picked != null) {
                                    setDialogState(() => endTime = picked);
                                  }
                                },
                                icon: const Icon(Icons.access_time_rounded, size: 16),
                                label: Text(formatTime(endTime)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    const Text('ห้องเรียน / อาคาร:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: roomController,
                      decoration: InputDecoration(
                        hintText: 'เช่น ห้อง 302, Lab หุ่นยนต์',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final startStr = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}:00';
                    final endStr = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}:00';

                    if (startTime.hour > endTime.hour ||
                        (startTime.hour == endTime.hour && startTime.minute >= endTime.minute)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('เวลาสิ้นสุดต้องอยู่หลังเวลาเริ่ม')),
                      );
                      return;
                    }

                    Navigator.pop(dialogCtx);
                    try {
                      await CalendarService.setClassSchedule(
                        courseId: selectedCourse,
                        dayOfWeek: selectedDay,
                        startTime: startStr,
                        endTime: endStr,
                        room: roomController.text.trim().isNotEmpty ? roomController.text.trim() : null,
                      );
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('บันทึกคาบเรียนลงตารางเรียบร้อยแล้ว 🗓️'),
                          backgroundColor: TeacherPalette.primary,
                        ),
                      );
                      _load();
                    } catch (e) {
                      debugPrint('Error saving class schedule slot: $e');
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('บันทึกคาบเรียนไม่สำเร็จ')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('บันทึก'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSchedule(ClassScheduleSlot slot) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('ลบคาบเรียน'),
        content: Text('ยืนยันลบคาบเรียน "${slot.subjectName}" (วัน${slot.dayLabel} ${slot.timeRangeLabel}) หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('ลบคาบเรียน'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await CalendarService.removeClassSchedule(slot.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบคาบเรียนเรียบร้อยแล้ว')),
      );
      _load();
    } catch (e) {
      debugPrint('Error removing class schedule slot: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบไม่สำเร็จ')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ตารางสอน / จัดการเวลาเรียน',
      activeMenuLabel: 'ตารางสอน',
      actions: [
        IconButton(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'รีเฟรช',
        ),
      ],
      builder: (context, isDesktop) {
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (_error != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('ลองใหม่')),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroBanner(isDesktop),
            const SizedBox(height: 18),
            _buildStatSummary(),
            const SizedBox(height: 18),
            _buildCourseFilterBar(),
            const SizedBox(height: 18),
            _buildWeeklyScheduleList(),
          ],
        );
      },
    );
  }

  Widget _buildHeroBanner(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [TeacherPalette.primary, Color(0xFF4C1D95)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: TeacherPalette.primary.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'จัดการตารางสอนและเวลาเรียน',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'กำหนดวัน เวลา และห้องเรียนจริงสำหรับแต่ละรายวิชาที่สอน (ซิงค์ไปปฏิทินนักเรียนอัตโนมัติ)',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _openAddScheduleDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('เพิ่มคาบเรียน'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: TeacherPalette.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatSummary() {
    final totalSlots = _filteredSchedules.length;
    final distinctCourses = {for (final s in _filteredSchedules) s.courseId}.length;
    final today = DateTime.now().weekday - 1; // 0=Mon..6=Sun
    final todaySlots = _filteredSchedules.where((s) => s.dayOfWeek == today).length;

    return Row(
      children: [
        Expanded(
          child: TeacherStatCard(
            label: 'คาบเรียนทั้งหมด',
            value: '$totalSlots คาบ',
            icon: Icons.schedule_rounded,
            color: TeacherPalette.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TeacherStatCard(
            label: 'วิชาที่มีตาราง',
            value: '$distinctCourses วิชา',
            icon: Icons.menu_book_rounded,
            color: TeacherPalette.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TeacherStatCard(
            label: 'คาบสอนวันนี้',
            value: '$todaySlots คาบ',
            icon: Icons.today_rounded,
            color: TeacherPalette.green,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Row(
        children: [
          const Text(
            'กรองตามรายวิชา:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCourseId,
                isDense: true,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCourseId = val);
                },
                items: [
                  const DropdownMenuItem(
                    value: _allCoursesId,
                    child: Text('ทั้งหมด (ทุกวิชาที่สอน)'),
                  ),
                  ..._courses.map((c) {
                    return DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.subjectName} (${c.gradeLevel ?? "ไม่ระบุชั้น"})'),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyScheduleList() {
    final grouped = _schedulesByDay;

    return Column(
      children: List.generate(7, (dayIdx) {
        final slots = grouped[dayIdx] ?? [];
        final dayLabel = ClassScheduleSlot.dayLabels[dayIdx];
        final isToday = (DateTime.now().weekday - 1) == dayIdx;

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isToday ? TeacherPalette.primary.withValues(alpha: 0.5) : TeacherPalette.border,
              width: isToday ? 1.5 : 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isToday ? TeacherPalette.primary : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'วัน$dayLabel ${isToday ? "(วันนี้)" : ""}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isToday ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${slots.length} คาบ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (slots.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'ไม่มีคาบเรียนในวัน$dayLabel',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
                else
                  Column(
                    children: slots.map((slot) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: TeacherPalette.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.school_rounded,
                                color: TeacherPalette.primary,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    slot.subjectName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'เวลา: ${slot.timeRangeLabel} น. · ห้อง: ${slot.room ?? "ไม่ระบุ"}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              onPressed: () => _deleteSchedule(slot),
                              tooltip: 'ลบคาบเรียน',
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
