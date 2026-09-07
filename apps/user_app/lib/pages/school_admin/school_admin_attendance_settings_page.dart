import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'theme/school_admin_palette.dart';

/// ตั้งเวลาปฏิบัติงาน — sets the school's `staff_work_hours` row, the basis
/// `staff_check_in` judges lateness against. Until this exists, every staff
/// check-in throws `work_hours_not_configured` — nobody in the school can
/// log their own attendance at all.
class SchoolAdminAttendanceSettingsPage extends StatefulWidget {
  const SchoolAdminAttendanceSettingsPage({
    super.key,
    this.loadWorkHours,
    this.loadSummary,
    this.saveWorkHours,
  });

  /// Injectable read/write seams, same pattern as the rest of School Admin.
  /// Production passes nothing and the real service is used; tests supply
  /// these to drive loading/data/empty/error without a live Supabase client.
  final Future<StaffWorkHours?> Function()? loadWorkHours;
  final Future<StaffAttendanceSummary?> Function()? loadSummary;
  final Future<void> Function({
    required String workStartTime,
    required String workEndTime,
    required int lateGraceMinutes,
  })?
  saveWorkHours;

  @override
  State<SchoolAdminAttendanceSettingsPage> createState() =>
      _SchoolAdminAttendanceSettingsPageState();
}

class _SchoolAdminAttendanceSettingsPageState
    extends State<SchoolAdminAttendanceSettingsPage> {
  bool _isLoading = true;
  String? _loadError;
  bool _isSaving = false;

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 16, minute: 30);
  int _graceMinutes = 15;
  bool _hadExistingHours = false;

  StaffAttendanceSummary? _summary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    try {
      final hours =
          await (widget.loadWorkHours ?? StaffAttendanceService.getWorkHours)();
      final summary =
          await (widget.loadSummary ?? StaffAttendanceService.getSummary)();
      if (!mounted) return;
      setState(() {
        if (hours != null) {
          _startTime = _parseTime(hours.startLabel) ?? _startTime;
          _endTime = _parseTime(hours.endLabel) ?? _endTime;
          _graceMinutes = hours.lateGraceMinutes;
          _hadExistingHours = true;
        } else {
          _hadExistingHours = false;
        }
        _summary = summary;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('SchoolAdminAttendanceSettingsPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'โหลดข้อมูลไม่สำเร็จ กรุณาลองใหม่';
      });
    }
  }

  static TimeOfDay? _parseTime(String hm) {
    final parts = hm.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00';

  bool get _isValidRange =>
      _endTime.hour * 60 + _endTime.minute > _startTime.hour * 60 + _startTime.minute;

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_isValidRange) {
      _message('เวลาเลิกงานต้องอยู่หลังเวลาเข้างาน', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final save = widget.saveWorkHours ??
          ({
            required workStartTime,
            required workEndTime,
            required lateGraceMinutes,
          }) =>
              StaffAttendanceService.setWorkHours(
                workStartTime: workStartTime,
                workEndTime: workEndTime,
                lateGraceMinutes: lateGraceMinutes,
              );
      await save(
        workStartTime: _fmt(_startTime),
        workEndTime: _fmt(_endTime),
        lateGraceMinutes: _graceMinutes,
      );
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _hadExistingHours = true;
      });
      _message('บันทึกเวลาปฏิบัติงานแล้ว');
      await _load();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _message('บันทึกไม่สำเร็จ กรุณาลองใหม่', isError: true);
    }
  }

  void _message(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: isError ? SchoolAdminPalette.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SchoolAdminPalette.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'ตั้งเวลาปฏิบัติงาน',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: SchoolAdminPalette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'กำหนดเวลาเข้า-เลิกงาน เพื่อให้ระบบตัดสินสถานะ "มาสาย" ได้ '
                      'หากยังไม่ได้ตั้งค่า บุคลากรจะลงเวลาเข้างานไม่ได้เลย',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: SchoolAdminPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_loadError != null)
                      _errorBanner(_loadError!)
                    else if (!_hadExistingHours)
                      _noticeBanner(
                        'ยังไม่มีการตั้งเวลาปฏิบัติงานสำหรับโรงเรียนนี้ — '
                        'บุคลากรลงเวลาเข้างานไม่ได้จนกว่าจะบันทึกค่าด้านล่าง',
                      ),
                    const SizedBox(height: 12),
                    _card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _timeRow(
                            label: 'เวลาเข้างาน',
                            time: _startTime,
                            onTap: () => _pickTime(isStart: true),
                          ),
                          const Divider(height: 24),
                          _timeRow(
                            label: 'เวลาเลิกงาน',
                            time: _endTime,
                            onTap: () => _pickTime(isStart: false),
                          ),
                          const Divider(height: 24),
                          Text(
                            'ผ่อนผันมาสาย (นาที)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: SchoolAdminPalette.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: _graceMinutes.toDouble(),
                                  min: 0,
                                  max: 60,
                                  divisions: 12,
                                  label: '$_graceMinutes นาที',
                                  activeColor: SchoolAdminPalette.primary,
                                  onChanged: (v) =>
                                      setState(() => _graceMinutes = v.round()),
                                ),
                              ),
                              SizedBox(
                                width: 56,
                                child: Text(
                                  '$_graceMinutes นาที',
                                  textAlign: TextAlign.end,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: SchoolAdminPalette.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: Size.zero,
                          backgroundColor: SchoolAdminPalette.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'กำลังบันทึก...' : 'บันทึกเวลาปฏิบัติงาน',
                        ),
                      ),
                    ),
                    if (_summary != null) ...[
                      const SizedBox(height: 24),
                      Text(
                        'สรุปการเข้างานวันนี้',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: SchoolAdminPalette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _card(child: _summaryGrid(_summary!)),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  Widget _timeRow({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: SchoolAdminPalette.textPrimary,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(minimumSize: Size.zero),
          icon: const Icon(Icons.schedule_rounded, size: 18),
          label: Text(time.format(context)),
        ),
      ],
    );
  }

  Widget _summaryGrid(StaffAttendanceSummary s) {
    final items = [
      ('มาปฏิบัติงาน', s.presentCount, SchoolAdminPalette.green),
      (
        'มาสาย',
        s.lateCount,
        s.workHoursConfigured ? SchoolAdminPalette.orange : SchoolAdminPalette.textMuted,
      ),
      ('ลา', s.leaveCount, SchoolAdminPalette.blue),
      ('ไปราชการ', s.officialDutyCount, SchoolAdminPalette.cyan),
      ('ขาดงาน', s.absentCount, SchoolAdminPalette.red),
      ('ยังไม่ลงเวลา', s.noRecordCount, SchoolAdminPalette.textMuted),
    ];
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        for (final item in items)
          SizedBox(
            width: 96,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.$2}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: item.$3,
                  ),
                ),
                Text(
                  item.$1,
                  style: TextStyle(
                    fontSize: 11,
                    color: SchoolAdminPalette.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        if (!s.workHoursConfigured)
          SizedBox(
            width: double.infinity,
            child: Text(
              'ยังไม่ได้ตั้งเวลาปฏิบัติงาน — ตัวเลข "มาสาย" ยังไม่มีความหมายจนกว่าจะบันทึกด้านบน',
              style: TextStyle(fontSize: 11, color: SchoolAdminPalette.textMuted),
            ),
          ),
      ],
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SchoolAdminPalette.border),
        boxShadow: SchoolAdminPalette.smallShadow,
      ),
      child: child,
    );
  }

  Widget _errorBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.redSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: SchoolAdminPalette.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _noticeBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SchoolAdminPalette.yellowSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: SchoolAdminPalette.orange),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: SchoolAdminPalette.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
