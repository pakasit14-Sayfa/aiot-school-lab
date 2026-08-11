import 'dart:async';
import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_lesson_quiz_page.dart';
import 'student_assignments_page.dart' show AssignmentCardItem;

/// UI-only mock of the "actual lesson content" screen — what
/// "เข้าสู่บทเรียน" opens into. No real video/file rendering is wired up;
/// this is purely the prototype visual.
///
/// Structured as 3 phases — ก่อนเรียน (before) → ระหว่างเรียน (during) →
/// หลังเรียน (after) — instead of dropping the student straight into content
/// and letting them mark it done immediately. During playback, a simulated
/// watch-progress bar has to reach ~90% before moving on, so leaving a video
/// playing unattended isn't the only signal, but opening it and waiting
/// through it is required.
class StudentLessonContentPage extends StatefulWidget {
  const StudentLessonContentPage({
    super.key,
    required this.chapterNumber,
    required this.title,
    required this.typeTag,
    required this.contentType,
    required this.icon,
    required this.accentColor,
    required this.duration,
    required this.gscorePoints,
    required this.topics,
    this.hasAssignment = false,
    this.assignmentTitle,
    this.assignmentDueDateText,
    this.assignmentUrgent = false,
  });

  final String chapterNumber;
  final String title;
  final String typeTag;
  final int contentType;
  final IconData icon;
  final Color accentColor;
  final String duration;
  final String gscorePoints;
  final List<String> topics;
  final bool hasAssignment;
  final String? assignmentTitle;
  final String? assignmentDueDateText;
  final bool assignmentUrgent;

  @override
  State<StudentLessonContentPage> createState() =>
      _StudentLessonContentPageState();
}

const _unlockThreshold = 0.9;

enum _Phase { before, during, after }

class _StudentLessonContentPageState extends State<StudentLessonContentPage> {
  bool get _isVideo => widget.contentType == 1;

  _Phase _phase = _Phase.before;
  double _watchProgress = 0;
  Timer? _progressTimer;

  bool get _unlocked => _watchProgress >= _unlockThreshold;

  // คะแนนแบบทดสอบก่อน/หลังเรียน — มาจาก StudentLessonQuizPage จริงๆ
  // แล้ว ไม่ใช่ mock ค่าคงที่อีกต่อไป เป็น null จนกว่าจะทำแบบทดสอบนั้นๆ
  int get _quizFullScore => widget.topics.isEmpty ? 1 : widget.topics.length;
  int? _preTestScoreValue;
  int? _postTestScoreValue;
  double get _preTestScore => (_preTestScoreValue ?? 0) / _quizFullScore;
  double get _postTestScore => (_postTestScoreValue ?? 0) / _quizFullScore;

  Future<void> _startLesson() async {
    final score = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentLessonQuizPage(
          quizTitle: 'แบบทดสอบก่อนเรียน',
          lessonTitle: widget.title,
          topics: widget.topics,
        ),
      ),
    );
    if (score == null || !mounted) return;
    setState(() {
      _preTestScoreValue = score;
      _phase = _Phase.during;
    });
    // จำลองความคืบหน้าการดู/ศึกษาเนื้อหาไล่ขึ้นทีละนิดตามเวลาจริง
    // แทนการปลดล็อกทันที เพื่อให้ต้องอยู่ในขั้นตอนนี้สักพักก่อน
    _progressTimer = Timer.periodic(const Duration(milliseconds: 300), (timer) {
      if (!mounted) return;
      setState(() {
        _watchProgress = (_watchProgress + 0.05).clamp(0.0, 1.0);
      });
      if (_watchProgress >= 1.0) timer.cancel();
    });
  }

  Future<void> _goToAfter() async {
    final score = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => StudentLessonQuizPage(
          quizTitle: 'แบบทดสอบหลังเรียน',
          lessonTitle: widget.title,
          topics: widget.topics,
        ),
      ),
    );
    if (score == null || !mounted) return;
    setState(() {
      _postTestScoreValue = score;
      _phase = _Phase.after;
    });
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    super.dispose();
  }

  void _markComplete() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ทำเครื่องหมายว่าเรียนจบ ${widget.chapterNumber} แล้ว (+${widget.gscorePoints} G-Score)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ปุ่มย้อนกลับอยู่ใน AppBar มาตรฐานแบบเดียวกับหน้าอื่นๆ ทั้งหมด
      // (ตำแหน่ง/สี/ขนาดเดียวกัน) แทนที่จะฝังไว้ในการ์ด gradient ด้านล่าง
      // ซึ่งทำให้ตำแหน่งกับสีของปุ่มไม่ตรงกับหน้าอื่น
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        // Align(topCenter) not Center() — Center() vertically centers the
        // whole scroll view when content is shorter than the viewport,
        // making the page look like it "shrinks to the middle" instead of
        // staying pinned to the top.
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 760 : 640),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 520 ? 14 : 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 16),
                      _buildProgressCard(),
                      const SizedBox(height: 16),
                      switch (_phase) {
                        _Phase.before => _buildBeforePhase(),
                        _Phase.during => _buildDuringPhase(),
                        _Phase.after => _buildAfterPhase(),
                      },
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: const Text(
                          '🧪 ตัวอย่างหน้าตาเท่านั้น ยังไม่เล่นเนื้อหาจริง',
                          style: TextStyle(
                            color: Color(0xFFD97706),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: SchoolPalette.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26165042),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.chapterNumber,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Stepper + score/progress metrics used to live in two separate cards
  /// stacked on top of each other — merged into one so they read as a
  /// single "your progress" unit instead of two unrelated boxes.
  Widget _buildProgressCard() {
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPhaseStepper(),
          const SizedBox(height: 14),
          _buildResultMetricsRow(),
        ],
      ),
    );
  }

  Widget _buildPhaseStepper() {
    const steps = ['ก่อนเรียน', 'ระหว่างเรียน', 'หลังเรียน'];
    const stepIcons = [
      Icons.edit_note_rounded,
      Icons.play_arrow_rounded,
      Icons.flag_rounded,
    ];
    final activeIndex = _phase.index;

    // ไม่ใส่ label "ก่อนเรียน/ระหว่างเรียน/หลังเรียน" ใต้จุดซ้ำอีกรอบ —
    // ใช้ label ของแถวคะแนนด้านล่าง (คะแนนก่อนเรียน/ดูวิดีโอครบ/คะแนน
    // หลังเรียน) แทน เพราะสื่อความหมาย 3 ช่วงเดียวกันอยู่แล้ว
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepCircle(
            icon: stepIcons[i],
            state: i < activeIndex
                ? _StepState.done
                : i == activeIndex
                ? _StepState.active
                : _StepState.pending,
          ),
          if (i != steps.length - 1)
            Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                color: i < activeIndex
                    ? SchoolPalette.deepGreen
                    : const Color(0xFFE2E8F0),
              ),
            )
          else
            // เส้นต่อท้าย "หลังเรียน" ให้จบสวยเหมือนมีเส้นเชื่อมทุกจุด
            // แล้วเปลี่ยนเป็นสีเขียวด้วยเมื่อทำขั้นตอนสุดท้ายนี้เสร็จแล้ว
            Expanded(
              child: Container(
                height: 2.5,
                margin: const EdgeInsets.only(left: 4),
                color: i <= activeIndex && _phase == _Phase.after
                    ? SchoolPalette.deepGreen
                    : const Color(0xFFE2E8F0),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildTitleBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: const TextStyle(
            color: SchoolPalette.navy,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.typeTag,
          style: const TextStyle(
            color: SchoolPalette.muted,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTopicsCard({required bool checked}) {
    if (widget.topics.isEmpty) return const SizedBox.shrink();
    return SoftCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < widget.topics.length; i++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (checked)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: widget.accentColor,
                  )
                else
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.accentColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: widget.accentColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: Text(
                      widget.topics[i],
                      style: const TextStyle(
                        color: SchoolPalette.navy,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (i != widget.topics.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  Widget _buildBeforePhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTitleBlock(),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SchoolPalette.softGreenBg,
                SchoolPalette.mint.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFBFE0D2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  gradient: SchoolPalette.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'ก่อนเริ่มเรียน เตรียมตัวให้พร้อม หาที่เงียบๆ '
                  'และตั้งใจดู$_isVideoOrDocLabelให้ครบ (ใช้เวลาประมาณ ${widget.duration})',
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'สิ่งที่จะได้เรียนในบทนี้',
          style: TextStyle(
            color: SchoolPalette.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _buildTopicsCard(checked: false),
        const SizedBox(height: 20),
        GradientButton(
          label: 'เริ่มเรียน',
          icon: Icons.play_arrow_rounded,
          onPressed: _startLesson,
        ),
        if (widget.hasAssignment) ...[
          const SizedBox(height: 14),
          _buildAssignmentBanner(),
        ],
      ],
    );
  }

  /// เตือนล่วงหน้าว่าบทนี้มีใบงานผูกอยู่ ก่อนที่นักเรียนจะกด "เริ่มเรียน"
  /// — เดิมต้องออกจากหน้านี้ไปเปิดแท็บใบงานเองถึงจะรู้
  ///
  /// การ์ดตัวเดียวกับหน้าใบงานเดิมทีวางลอยๆ ต่อจากการ์ดเนื้อหาบทเรียนอื่น
  /// ทำให้ดูเป็นเนื้อหาบทเรียนอีกใบ ไม่รู้ว่าเป็นคนละหมวด — ห่อด้วยกรอบ
  /// พื้นหลังฟ้าอ่อน + ป้ายหัวข้อ "งานที่เกี่ยวข้อง" กันไว้ชั้นหนึ่งก่อน
  /// เพื่อตัดขาดจากบริบทเนื้อหาบทเรียนด้านบนให้ชัดเจน
  Widget _buildAssignmentBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F9FF),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFCBDFFB), width: 1.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: Color(0xFF2563EB)),
                SizedBox(width: 5),
                Text(
                  'งานที่เกี่ยวข้องกับบทนี้',
                  style: TextStyle(
                    color: Color(0xFF2563EB),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          // ใช้ AssignmentCardItem ตัวจริงจากหน้าใบงาน (ไม่ใช่แค่การ์ดหน้าตา
          // เหมือน) เพื่อให้แตะแล้วเปิด modal ส่งงานได้เลยในหน้านี้ โดยไม่
          // ต้องออกไปหน้าใบงานก่อน — สอดคล้องกับพฤติกรรมจริงของการ์ดใบงาน
          //
          // ไม่โชว์สถานะความด่วน ("ด่วนที่สุด") ตรงนี้ — เก็บไว้เฉพาะหน้า
          // ใบงานที่รวมทุกงานไว้ในที่เดียวเท่านั้น ในนี้แค่บอกกำหนดส่งก็พอ
          AssignmentCardItem(
            subject: 'วิชา AIoT สมาร์ตแล็บ',
            subjectCode: 'AIOT-501',
            subjectIcon: widget.icon,
            title:
                widget.assignmentTitle ?? 'ใบงานประกอบ${widget.chapterNumber}',
            dueDateText:
                widget.assignmentDueDateText ?? 'ดูกำหนดส่งในหน้าใบงาน',
            statusLabel: 'มีงานให้ทำ',
            statusColor: const Color(0xFF2563EB),
            statusBg: const Color(0xFFEFF6FF),
            gscorePoints: widget.gscorePoints,
            filterGroup: widget.assignmentUrgent ? 1 : 2,
          ),
        ],
      ),
    );
  }

  String get _isVideoOrDocLabel => _isVideo ? 'วิดีโอ' : 'เนื้อหา';

  Widget _buildDuringPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStage(),
        const SizedBox(height: 18),
        _buildTitleBlock(),
        const SizedBox(height: 18),
        _buildGateStatus(),
        const SizedBox(height: 10),
        GradientButton(
          label: 'ไปขั้นตอนสรุปหลังเรียน',
          icon: Icons.arrow_forward_rounded,
          onPressed: _unlocked ? _goToAfter : null,
        ),
      ],
    );
  }

  Widget _buildAfterPhase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                SchoolPalette.softGreenBg,
                SchoolPalette.mint.withValues(alpha: 0.15),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFBFE0D2)),
          ),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  gradient: SchoolPalette.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x40165042),
                      blurRadius: 18,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'เรียนจบเนื้อหาบทนี้แล้ว!',
                style: TextStyle(
                  color: SchoolPalette.navy,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: SchoolPalette.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'สรุปสิ่งที่ได้เรียนไป',
          style: TextStyle(
            color: SchoolPalette.navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        _buildTopicsCard(checked: true),
        const SizedBox(height: 20),
        GradientButton(
          label: 'ยืนยันว่าเรียนจบบทนี้',
          icon: Icons.check_circle_rounded,
          onPressed: _markComplete,
        ),
      ],
    );
  }

  Widget _buildResultMetricsRow() {
    // "ดูวิดีโอครบ" มีความหมายเฉพาะบทเรียนวิดีโอเท่านั้น — เอกสาร/แล็บ
    // ไม่มี timeline ให้วัดเป็นเปอร์เซ็นต์ เลยไม่ต้องโชว์เมตริกนี้เลย
    final metrics = <_ResultMetric>[
      _ResultMetric(
        label: 'คะแนนก่อนเรียน',
        percent: _preTestScore,
        valueText: '$_preTestScoreValue/$_quizFullScore คะแนน',
        color: const Color(0xFF2563EB),
        locked: _preTestScoreValue == null,
      ),
      if (_isVideo)
        _ResultMetric(
          label: 'ดูวิดีโอครบ',
          percent: _watchProgress,
          color: const Color(0xFFD97706),
        ),
      _ResultMetric(
        label: 'คะแนนหลังเรียน',
        percent: _postTestScore,
        valueText: '$_postTestScoreValue/$_quizFullScore คะแนน',
        color: SchoolPalette.deepGreen,
        // ยังไม่ทำแบบทดสอบหลังเรียนจนกว่าจะถึงขั้น "หลังเรียน" จริง
        locked: _postTestScoreValue == null,
      ),
    ];

    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          Expanded(child: metrics[i]),
          if (i != metrics.length - 1) const SizedBox(width: 14),
        ],
      ],
    );
  }

  Widget _buildGateStatus() {
    if (_unlocked) {
      return const Row(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 15,
            color: SchoolPalette.deepGreen,
          ),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              'ครบเงื่อนไขแล้ว ไปขั้นตอนสรุปหลังเรียนได้เลย',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: SchoolPalette.deepGreen,
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Color(0xFFD97706),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _isVideo
                ? 'กำลังดูวิดีโอ... ต้องดูให้ครบก่อนไปขั้นตอนถัดไป'
                : 'กำลังตรวจสอบว่าใช้เวลาศึกษาเนื้อหาครบ...',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFD97706),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStage() {
    late final String label;
    late final Gradient gradient;
    late final Color fg;

    switch (widget.contentType) {
      case 1: // วิดีโอ
        label = 'กำลังเล่นวิดีโอ (จำลอง)';
        gradient = const LinearGradient(
          colors: [Color(0xFF0B1F19), Color(0xFF16342A), Color(0xFF1E4A3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        fg = Colors.white;
        break;
      case 2: // เอกสาร/ไฟล์
        label = 'กำลังแสดงเอกสาร (จำลอง)';
        gradient = const LinearGradient(
          colors: [Color(0xFFEAF5F0), Color(0xFFDCEFE6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        fg = SchoolPalette.navy;
        break;
      default: // แล็บเชิงโต้ตอบ
        label = 'กิจกรรมแล็บเชิงโต้ตอบ (จำลอง)';
        gradient = const LinearGradient(
          colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
        fg = SchoolPalette.navy;
    }

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26165042),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              gradient: widget.contentType == 1
                  ? SchoolPalette.primaryGradient
                  : null,
              color: widget.contentType == 1
                  ? null
                  : widget.accentColor.withValues(alpha: 0.14),
              shape: BoxShape.circle,
              boxShadow: widget.contentType == 1
                  ? const [
                      BoxShadow(
                        color: Color(0x40165042),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              widget.icon,
              color: widget.contentType == 1
                  ? Colors.white
                  : widget.accentColor,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// One column of the pre-test/post-test/watch-time result row — big
/// percent number, label underneath, then a thin progress bar.
class _ResultMetric extends StatelessWidget {
  const _ResultMetric({
    required this.label,
    required this.percent,
    required this.color,
    this.locked = false,
    this.valueText,
  });

  final String label;
  final double percent;
  final Color color;

  /// เช่น "คะแนนหลังเรียน" ที่ยังไม่มีค่าจริงจนกว่าจะถึงขั้นตอนนั้นๆ —
  /// โชว์ "-" สีเทาแทนตัวเลข เพื่อไม่ให้ดูเหมือนมีผลลัพธ์อยู่แล้วตั้งแต่ต้น
  final bool locked;

  /// แสดงเป็น "คะแนนที่ได้/คะแนนเต็ม" แทนเปอร์เซ็นต์ เมื่อกำหนดมา
  /// (ใช้กับคะแนนก่อน/หลังเรียน ส่วน "ดูวิดีโอครบ" ยังโชว์ % ตามปกติ)
  final String? valueText;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = locked ? SchoolPalette.muted : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: locked ? 0 : percent.clamp(0.0, 1.0),
            minHeight: 5,
            backgroundColor: effectiveColor.withValues(alpha: 0.13),
            color: effectiveColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          locked ? '-' : (valueText ?? '${(percent * 100).round()}%'),
          style: TextStyle(
            color: effectiveColor,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: SchoolPalette.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum _StepState { done, active, pending }

/// Circular step marker for the ก่อน/ระหว่าง/หลังเรียน stepper — check for a
/// finished step, a filled brand-gradient dot for the current one, a hollow
/// grey outline for what's still ahead.
class _StepCircle extends StatelessWidget {
  const _StepCircle({required this.icon, required this.state});

  final IconData icon;
  final _StepState state;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case _StepState.done:
        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: SchoolPalette.deepGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_rounded, color: Colors.white, size: 18),
        );
      case _StepState.active:
        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            gradient: SchoolPalette.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x40165042),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 17),
        );
      case _StepState.pending:
        return Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.6),
          ),
          child: Icon(icon, color: const Color(0xFFB0BEC5), size: 16),
        );
    }
  }
}
