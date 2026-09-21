// เชื่อมกับ GradeService จริงแล้ว (2026-08-16) — เดิมเป็น mock ล้วน
// (weighted-contribution breakdown ที่ไม่มีสคีมารองรับจริง) ตัดส่วนที่ไม่มี
// ข้อมูลจริงรองรับออก (สัดส่วนคะแนนตามงาน/G-Score เฉลี่ย ไม่มี RPC ให้ดึง)
// เหลือแค่สิ่งที่ GradeService รองรับจริง: คะแนนเฉลี่ยต่อรายวิชา (จาก
// listCourseGrades) + รายการรอยืนยัน (confirmedAt == null) ที่ครูกดยืนยันได้
// จริงผ่าน GradeService.confirmGrade — ตรงตามหลักการ "ครูยืนยันขั้นสุดท้าย
// เสมอ" ที่ล็อกไว้ในวอลต์
import 'dart:convert';

import 'package:excel/excel.dart' as xls;
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../../utils/web_download.dart';
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

typedef GradesDownloadBytes =
    void Function({
      required String filename,
      required List<int> bytes,
      required String mimeType,
    });

class TeacherGradesPage extends StatefulWidget {
  const TeacherGradesPage({
    super.key,
    this.downloadBytesOverride,
    this.loadCourses,
    this.loadCourseGrades,
    this.confirmGrade,
  });

  // Seam for tests: lets a test prove the export button actually calls a
  // download instead of the old always-"generating..." SnackBar with no file.
  final GradesDownloadBytes? downloadBytesOverride;

  /// Read/write seams threaded to the corresponding CourseService/
  /// GradeService static calls in production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<GradeRecord>> Function(String courseId)? loadCourseGrades;
  final Future<void> Function(String recordId)? confirmGrade;

  @override
  State<TeacherGradesPage> createState() => _TeacherGradesPageState();
}

class _CourseGradeSummary {
  _CourseGradeSummary({
    required this.courseId,
    required this.subjectName,
    required this.records,
  });

  final String courseId;
  final String subjectName;
  final List<GradeRecord> records;

  double get average {
    final confirmed = records.where((r) => r.confirmedAt != null).toList();
    if (confirmed.isEmpty) return 0;
    final total = confirmed.fold<double>(
      0,
      (sum, r) => sum + (r.score / r.maxScore),
    );
    return total / confirmed.length;
  }

  List<GradeRecord> get pending =>
      records.where((r) => r.confirmedAt == null).toList();
}

class _TeacherGradesPageState extends State<TeacherGradesPage> {
  bool _loading = true;
  String? _error;
  List<_CourseGradeSummary> _summaries = [];
  final Set<String> _confirming = {};

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
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadGrades =
          widget.loadCourseGrades ?? GradeService.listCourseGrades;
      final courses = await loadCourses();
      // One RPC per course, none of them dependent on another. Awaited in the
      // loop this was N+1 sequential round trips before the page could paint.
      final gradesPerCourse = await Future.wait(
        courses.map((c) async {
          try {
            return await loadGrades(c.id);
          } catch (_) {
            return const <GradeRecord>[];
          }
        }),
      );
      final summaries = <_CourseGradeSummary>[];
      for (var i = 0; i < courses.length; i++) {
        final c = courses[i];
        final records = gradesPerCourse[i];
        summaries.add(
          _CourseGradeSummary(
            courseId: c.id,
            subjectName: c.subjectName,
            records: records,
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _summaries = summaries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลคะแนนไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  Future<void> _confirm(GradeRecord record) async {
    setState(() => _confirming.add(record.id));
    try {
      final confirm = widget.confirmGrade ?? GradeService.confirmGrade;
      await confirm(record.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'ยืนยันคะแนน ${record.studentFirstName} ${record.studentLastName} แล้ว',
          ),
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยืนยันคะแนนไม่สำเร็จ')));
    } finally {
      if (mounted) setState(() => _confirming.remove(record.id));
    }
  }

  String _csvField(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// ใช้ร่วมกันทั้ง CSV และ Excel กันข้อมูลสองฟอร์แมตเพี้ยนไม่ตรงกัน
  List<List<String>>? _buildReportRows() {
    if (_summaries.every((s) => s.records.isEmpty)) return null;
    final rows = <List<String>>[
      ['subject', 'student', 'score', 'max_score', 'status', 'confirmed_at'],
    ];
    for (final s in _summaries) {
      for (final r in s.records) {
        rows.add([
          s.subjectName,
          '${r.studentFirstName} ${r.studentLastName}',
          '${r.score}',
          '${r.maxScore}',
          r.status,
          r.confirmedAt?.toIso8601String() ?? '',
        ]);
      }
    }
    return rows;
  }

  void _exportCsv() {
    final rows = _buildReportRows();
    if (rows == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยังไม่มีข้อมูลคะแนนให้ส่งออก')));
      return;
    }
    final csv = rows.map((row) => row.map(_csvField).join(',')).join('\r\n');
    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'grades_report_${DateTime.now().toIso8601String().split('T').first}.csv',
      bytes: utf8.encode('﻿$csv'),
      mimeType: 'text/csv',
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ส่งออกรายงานคะแนนแล้ว (CSV)')));
  }

  void _exportExcel() {
    final rows = _buildReportRows();
    if (rows == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('ยังไม่มีข้อมูลคะแนนให้ส่งออก')));
      return;
    }
    final workbook = xls.Excel.createExcel();
    final sheet = workbook[workbook.getDefaultSheet() ?? 'Sheet1'];
    for (final row in rows) {
      sheet.appendRow(row.map(xls.TextCellValue.new).toList());
    }
    final bytes = workbook.encode();
    if (bytes == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('สร้างไฟล์ Excel ไม่สำเร็จ')));
      return;
    }
    final doDownload = widget.downloadBytesOverride ?? downloadBytes;
    doDownload(
      filename:
          'grades_report_${DateTime.now().toIso8601String().split('T').first}.xlsx',
      bytes: bytes,
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ส่งออกรายงานคะแนนแล้ว (Excel)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allPending = _summaries.expand((s) => s.pending).length;
    final overallAverage = () {
      final withData = _summaries.where((s) => s.average > 0).toList();
      if (withData.isEmpty) return 0.0;
      return withData.fold<double>(0, (sum, s) => sum + s.average) /
          withData.length;
    }();

    return TeacherMockPageShell(
      title: 'คะแนน',
      activeMenuLabel: 'คะแนน',
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Export รายงาน',
          icon: const Icon(Icons.file_download_outlined),
          onSelected: (format) =>
              format == 'csv' ? _exportCsv() : _exportExcel(),
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'csv', child: Text('ส่งออกเป็น CSV')),
            PopupMenuItem(value: 'excel', child: Text('ส่งออกเป็น Excel')),
          ],
        ),
      ],
      builder: (context, isDesktop) {
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: TeacherPalette.primary),
            ),
          );
        }
        if (_error != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('ลองใหม่')),
              ],
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = isDesktop ? 3 : 2;
                return GridView.count(
                  crossAxisCount: columns,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: isDesktop ? 1.6 : 1.3,
                  children: [
                    TeacherStatCard(
                      label: 'คะแนนเฉลี่ยทุกวิชา',
                      value: overallAverage > 0
                          ? '${(overallAverage * 100).round()}%'
                          : '-',
                      icon: Icons.bar_chart_rounded,
                      color: TeacherPalette.skyDeep,
                    ),
                    TeacherStatCard(
                      label: 'รายวิชาที่มีคะแนน',
                      value: '${_summaries.length} วิชา',
                      icon: Icons.menu_book_rounded,
                      color: TeacherPalette.primary,
                    ),
                    TeacherStatCard(
                      label: 'รอยืนยันคะแนน',
                      value: '$allPending รายการ',
                      icon: Icons.pending_actions_rounded,
                      color: allPending > 0
                          ? TeacherPalette.orange
                          : TeacherPalette.green,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            if (allPending > 0)
              TeacherSectionCard(
                title: 'รอครูยืนยันคะแนน',
                icon: Icons.verified_rounded,
                child: Column(
                  children: [
                    for (final s in _summaries)
                      for (final r in s.pending) ...[
                        _PendingGradeRow(
                          courseName: s.subjectName,
                          record: r,
                          isConfirming: _confirming.contains(r.id),
                          onConfirm: () => _confirm(r),
                        ),
                        const Divider(height: 18, color: Color(0xFFE8EEF3)),
                      ],
                  ],
                ),
              ),
            if (allPending > 0) const SizedBox(height: 16),
            TeacherSectionCard(
              title: 'ภาพรวมรายวิชา',
              icon: Icons.groups_2_rounded,
              child: _summaries.isEmpty
                  ? const Text(
                      'ยังไม่มีรายวิชาที่มีคะแนน',
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < _summaries.length; i++) ...[
                          _CourseGradeRow(summary: _summaries[i]),
                          if (i != _summaries.length - 1)
                            const Divider(height: 18, color: Color(0xFFE8EEF3)),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _PendingGradeRow extends StatelessWidget {
  const _PendingGradeRow({
    required this.courseName,
    required this.record,
    required this.isConfirming,
    required this.onConfirm,
  });

  final String courseName;
  final GradeRecord record;
  final bool isConfirming;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${record.studentFirstName} ${record.studentLastName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$courseName · ${record.score}/${record.maxScore}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        FilledButton(
          onPressed: isConfirming ? null : onConfirm,
          style: FilledButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          ),
          child: isConfirming
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('ยืนยัน', style: TextStyle(fontSize: 12.5)),
        ),
      ],
    );
  }
}

class _CourseGradeRow extends StatelessWidget {
  const _CourseGradeRow({required this.summary});

  final _CourseGradeSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${summary.records.length} รายการ · ยืนยันแล้ว '
                '${summary.records.length - summary.pending.length}',
                style: const TextStyle(
                  color: TeacherPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Text(
          summary.average > 0 ? '${(summary.average * 100).round()}%' : '-',
          style: const TextStyle(
            color: TeacherPalette.primary,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
