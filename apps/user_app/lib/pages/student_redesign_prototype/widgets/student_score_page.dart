import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_redesign_palette.dart';

/// เดิมหน้านี้โชว์ G-Score/GPA/แนวโน้มรายเดือน/แบดจ์ทั้งหมด — ตรวจสอบแล้วว่า
/// ไม่มี backend รองรับเลยสักอย่าง (ไม่มี GScoreService, ไม่มีสเกล GPA,
/// ไม่มีระบบเก็บ trend, ไม่มีระบบแบดจ์) เหลือแค่คะแนนรายวิชาจริงจาก
/// GradeService เท่านั้นที่มีข้อมูลจริงรองรับ จึงตัดส่วนที่เหลือออกทั้งหมด.
/// 2026-08-27: G-Score ได้ backend จริงแล้ว (GScoreService.listMyGScore,
/// migration 20260823030000_g_score.sql) — เพิ่มการ์ดคะแนนสะสมกลับเข้ามา
/// เฉพาะส่วนที่ครูยืนยันแล้วเท่านั้น (GPA/trend/badge ยังไม่มี backend จริง
/// ไม่เพิ่มกลับ)
class StudentScorePage extends StatefulWidget {
  const StudentScorePage({super.key, this.loadGrades, this.loadGScore});

  /// Read seams threaded to the corresponding GradeService/GScoreService
  /// static calls in production.
  final Future<List<CourseGrade>> Function()? loadGrades;
  final Future<List<MyGScoreEntry>> Function()? loadGScore;

  @override
  State<StudentScorePage> createState() => _StudentScorePageState();
}

class _StudentScorePageState extends State<StudentScorePage> {
  bool _loading = true;
  String? _error;
  List<CourseGrade> _grades = const [];
  List<MyGScoreEntry> _gScoreEntries = const [];

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
      final loadGrades = widget.loadGrades ?? GradeService.listMyGrades;
      final loadGScore = widget.loadGScore ?? GScoreService.listMyGScore;
      final results = await Future.wait([loadGrades(), loadGScore()]);
      if (!mounted) return;
      setState(() {
        _grades = results[0] as List<CourseGrade>;
        _gScoreEntries = results[1] as List<MyGScoreEntry>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final confirmed = _grades.where((g) => g.confirmedAt != null).toList();
    final pending = _grades.where((g) => g.confirmedAt == null).toList();
    final avgPercent = confirmed.isEmpty
        ? 0.0
        : confirmed.map((g) => g.percent).reduce((a, b) => a + b) /
              confirmed.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'คะแนนของฉัน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: Align(
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 900;
                return ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      isDesktop ? 24 : 18,
                      16,
                      isDesktop ? 24 : 18,
                      24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_error != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 16),
                        ],
                        _SummaryHeroCard(
                          avgPercent: avgPercent,
                          gradedCount: confirmed.length,
                        ),
                        const SizedBox(height: 16),
                        _GScoreCard(entries: _gScoreEntries, loading: _loading),
                        if (pending.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _PendingGradesCard(grades: pending),
                        ],
                        const SizedBox(height: 16),
                        _SubjectGradesCard(
                          grades: confirmed,
                          loading: _loading,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }
}

class _SummaryHeroCard extends StatelessWidget {
  const _SummaryHeroCard({required this.avgPercent, required this.gradedCount});

  final double avgPercent;
  final int gradedCount;

  @override
  Widget build(BuildContext context) {
    const accent = SchoolPalette.deepGreen;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 78,
                  height: 78,
                  child: CircularProgressIndicator(
                    value: avgPercent / 100,
                    strokeWidth: 7,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    valueColor: const AlwaysStoppedAnimation(accent),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                const Icon(Icons.grade_rounded, color: accent, size: 26),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'คะแนนเฉลี่ยทุกวิชา',
                  style: TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'เฉลี่ยจากคะแนนที่ครูยืนยันแล้วทุกวิชา',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: SchoolPalette.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      avgPercent.toStringAsFixed(0),
                      style: const TextStyle(
                        color: accent,
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '%',
                      style: TextStyle(
                        color: SchoolPalette.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$gradedCount วิชา',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: accent,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GScoreCard extends StatelessWidget {
  const _GScoreCard({required this.entries, required this.loading});

  final List<MyGScoreEntry> entries;
  final bool loading;

  static String _sourceLabel(String source) {
    switch (source) {
      case 'lesson_completed':
        return 'เรียนจบบทเรียน';
      case 'assignment_on_time':
        return 'ส่งงานตรงเวลา';
      default:
        return source;
    }
  }

  /// ตัวอย่างข้อมูลจำลอง — โชว์เฉพาะตอนบัญชีนี้ยังไม่มี G-Score จริงเลย
  /// (ให้เห็นว่าการ์ดนี้หน้าตาเป็นยังไงตอนมีข้อมูล) ต้องมี badge "ข้อมูลจำลอง"
  /// กำกับเสมอ ห้ามโชว์ปนกับข้อมูลจริงโดยไม่บอก
  static final List<MyGScoreEntry> _demoEntries = [
    MyGScoreEntry(
      id: 'demo-1',
      courseId: 'demo',
      subjectName: 'วิทยาศาสตร์ ม.5',
      source: 'lesson_completed',
      points: 5,
      confirmedAt: DateTime.now(),
    ),
    MyGScoreEntry(
      id: 'demo-2',
      courseId: 'demo',
      subjectName: 'การออกแบบเทคโนโลยี',
      source: 'assignment_on_time',
      points: 3,
      confirmedAt: DateTime.now(),
    ),
    MyGScoreEntry(
      id: 'demo-3',
      courseId: 'demo',
      subjectName: 'คณิตศาสตร์ ม.5',
      source: 'lesson_completed',
      points: 5,
      confirmedAt: DateTime.now(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFF59E0B);
    final isDemo = !loading && entries.isEmpty;
    final effectiveEntries = isDemo ? _demoEntries : entries;
    final total = effectiveEntries.fold<num>(0, (sum, e) => sum + e.points);
    final recent = effectiveEntries.take(5).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stars_rounded, size: 18, color: accent),
              const SizedBox(width: 6),
              const Text(
                'G-Score สะสม',
                style: TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                loading ? '...' : '$total คะแนน',
                style: const TextStyle(
                  color: accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'สะสมจากบทเรียนที่เรียนจบและงานที่ส่งตรงเวลา หลังครูยืนยันแล้ว',
            style: TextStyle(
              color: SchoolPalette.muted,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isDemo) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Text(
                'ตัวอย่าง — ข้อมูลจำลอง ยังไม่มี G-Score จริง',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (recent.isEmpty)
            // ไม่ควรเกิดขึ้นจริง เพราะเข้า demo fallback ไปแล้วตอน entries
            // ว่าง แต่กันไว้เผื่อ effectiveEntries ว่างจากสาเหตุอื่น
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Text(
                'ยังไม่มีคะแนน G-Score ที่ครูยืนยัน',
                style: TextStyle(color: SchoolPalette.muted, fontSize: 12.5),
              ),
            )
          else
            for (var i = 0; i < recent.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${recent[i].subjectName} · ${_sourceLabel(recent[i].source)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.navy,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '+${recent[i].points}',
                      style: const TextStyle(
                        color: accent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (i != recent.length - 1)
                const Divider(height: 14, color: Color(0xFFE8EEF3)),
            ],
        ],
      ),
    );
  }
}

class _PendingGradesCard extends StatelessWidget {
  const _PendingGradesCard({required this.grades});

  final List<CourseGrade> grades;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.hourglass_top_rounded,
                size: 16,
                color: Color(0xFFD97706),
              ),
              SizedBox(width: 6),
              Text(
                'รอครูยืนยันคะแนน',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final g in grades)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${g.subjectName} · ${g.score}/${g.maxScore}',
                style: const TextStyle(
                  color: Color(0xFF92400E),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SubjectGradesCard extends StatelessWidget {
  const _SubjectGradesCard({required this.grades, required this.loading});

  final List<CourseGrade> grades;
  final bool loading;

  static const _colors = [
    SchoolPalette.deepGreen,
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF59E0B),
    Color(0xFF06B6D4),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.menu_book_rounded,
                size: 16,
                color: Color(0xFF3B82F6),
              ),
              const SizedBox(width: 6),
              const Text(
                'คะแนนเรียนรายวิชา',
                style: TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '${grades.length} วิชา',
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (grades.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'ยังไม่มีคะแนนที่ยืนยันแล้ว',
                style: TextStyle(color: SchoolPalette.muted, fontSize: 12.5),
              ),
            )
          else
            for (var i = 0; i < grades.length; i++) ...[
              _SubjectGradeRow(
                grade: grades[i],
                color: _colors[i % _colors.length],
              ),
              if (i != grades.length - 1)
                const Divider(height: 20, color: Color(0xFFE8EEF3)),
            ],
        ],
      ),
    );
  }
}

class _SubjectGradeRow extends StatelessWidget {
  const _SubjectGradeRow({required this.grade, required this.color});

  final CourseGrade grade;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Text(
            grade.percent.toStringAsFixed(0),
            style: TextStyle(
              color: color,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                grade.subjectName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${grade.score}/${grade.maxScore} คะแนน',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  height: 5,
                  color: const Color(0xFFE8EEF5),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: (grade.percent / 100).clamp(0.0, 1.0),
                    child: Container(color: color),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
