import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';

import 'student_redesign_palette.dart';

class _QuizWithCourse {
  const _QuizWithCourse({
    required this.quiz,
    required this.courseName,
    required this.attempt,
  });

  final QuizSummary quiz;
  final String courseName;
  final QuizAttemptResult? attempt;

  bool get isSubmitted => attempt?.isSubmitted ?? false;
}

class StudentPretestPosttestPage extends StatefulWidget {
  const StudentPretestPosttestPage({
    super.key,
    this.loadCourses,
    this.loadQuizzesForCourse,
    this.loadLatestAttempt,
    this.getQuizForStudent,
    this.startQuizAttempt,
    this.saveQuizAnswer,
    this.submitQuizAttempt,
  });

  /// Read/write seams threaded to the corresponding CourseService/
  /// QuizService static calls in production — widget tests supply these
  /// to drive the list load and the full attempt flow (start/save/submit)
  /// without a live Supabase client.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<QuizSummary>> Function(String courseId)?
  loadQuizzesForCourse;
  final Future<QuizAttemptResult?> Function(String quizId)? loadLatestAttempt;
  final Future<QuizForStudent> Function(String quizId)? getQuizForStudent;
  final Future<({String attemptId, DateTime startedAt})> Function(
    String quizId,
  )?
  startQuizAttempt;
  final Future<void> Function({
    required String attemptId,
    required String questionId,
    required Map<String, dynamic> answer,
  })?
  saveQuizAnswer;
  final Future<num> Function(String attemptId)? submitQuizAttempt;

  @override
  State<StudentPretestPosttestPage> createState() =>
      _StudentPretestPosttestPageState();
}

class _StudentPretestPosttestPageState
    extends State<StudentPretestPosttestPage> {
  bool _loading = true;
  String? _error;
  List<_QuizWithCourse> _items = const [];

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
      final loadQuizzes =
          widget.loadQuizzesForCourse ?? QuizService.listCourseQuizzes;
      final loadAttempt =
          widget.loadLatestAttempt ?? QuizService.getMyLatestQuizAttempt;

      final courses = (await loadCourses()).where((c) => c.isActive).toList();
      final quizLists = await Future.wait(
        courses.map((c) => loadQuizzes(c.id)),
      );

      final published = <(QuizSummary, String)>[];
      for (var i = 0; i < courses.length; i++) {
        for (final q in quizLists[i].where((q) => q.isPublished)) {
          published.add((q, courses[i].subjectName));
        }
      }

      final attempts = await Future.wait(
        published.map((e) => loadAttempt(e.$1.id)),
      );

      final items = <_QuizWithCourse>[];
      for (var i = 0; i < published.length; i++) {
        items.add(
          _QuizWithCourse(
            quiz: published[i].$1,
            courseName: published[i].$2,
            attempt: attempts[i],
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  Future<void> _openQuiz(_QuizWithCourse item) async {
    if (item.isSubmitted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(item.quiz.title),
          content: Text('คะแนนที่ได้: ${item.attempt!.autoScore ?? 0} คะแนน'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ปิด'),
            ),
          ],
        ),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _QuizTakingPage(
          quizId: item.quiz.id,
          getQuizForStudent: widget.getQuizForStudent,
          startQuizAttempt: widget.startQuizAttempt,
          saveQuizAnswer: widget.saveQuizAnswer,
          submitQuizAttempt: widget.submitQuizAttempt,
        ),
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
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
          'สอบก่อนเรียนและหลังเรียน',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 17,
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_error != null) ...[
                          _buildErrorBanner(),
                          const SizedBox(height: 16),
                        ],
                        if (_loading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (_items.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: SchoolPalette.glassBorder,
                              ),
                            ),
                            child: const Text(
                              'ยังไม่มีแบบทดสอบก่อน-หลังเรียนที่เปิดให้ทำ',
                              style: TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 13,
                              ),
                            ),
                          )
                        else
                          for (final item in _items) ...[
                            _QuizCard(item: item, onTap: () => _openQuiz(item)),
                            const SizedBox(height: 12),
                          ],
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

class _QuizCard extends StatelessWidget {
  const _QuizCard({required this.item, required this.onTap});

  final _QuizWithCourse item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isPre = item.quiz.isPreTest;
    final accent = isPre ? const Color(0xFF0284C7) : SchoolPalette.deepGreen;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isPre
                        ? Icons.play_circle_outline_rounded
                        : Icons.flag_rounded,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPre
                            ? 'ก่อนเรียน · ${item.courseName}'
                            : 'หลังเรียน · ${item.courseName}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.quiz.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.navy,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (item.isSubmitted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: SchoolPalette.softGreenBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${item.attempt!.autoScore ?? 0} คะแนน',
                      style: const TextStyle(
                        color: SchoolPalette.deepGreen,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'เริ่มทำ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizTakingPage extends StatefulWidget {
  const _QuizTakingPage({
    required this.quizId,
    this.getQuizForStudent,
    this.startQuizAttempt,
    this.saveQuizAnswer,
    this.submitQuizAttempt,
  });

  final String quizId;
  final Future<QuizForStudent> Function(String quizId)? getQuizForStudent;
  final Future<({String attemptId, DateTime startedAt})> Function(
    String quizId,
  )?
  startQuizAttempt;
  final Future<void> Function({
    required String attemptId,
    required String questionId,
    required Map<String, dynamic> answer,
  })?
  saveQuizAnswer;
  final Future<num> Function(String attemptId)? submitQuizAttempt;

  @override
  State<_QuizTakingPage> createState() => _QuizTakingPageState();
}

class _QuizTakingPageState extends State<_QuizTakingPage> {
  bool _loading = true;
  String? _error;
  QuizForStudent? _quiz;
  String? _attemptId;
  final Map<String, String> _selectedChoice = {};
  final Map<String, TextEditingController> _shortAnswerControllers = {};
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in _shortAnswerControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final getQuiz = widget.getQuizForStudent ?? QuizService.getQuizForStudent;
      final startAttempt =
          widget.startQuizAttempt ?? QuizService.startQuizAttempt;
      final quiz = await getQuiz(widget.quizId);
      final attempt = await startAttempt(widget.quizId);
      if (!mounted) return;
      setState(() {
        _quiz = quiz;
        _attemptId = attempt.attemptId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดแบบทดสอบไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    if (_attemptId == null || _quiz == null) return;
    setState(() => _submitting = true);
    try {
      final saveAnswer = widget.saveQuizAnswer ?? QuizService.saveQuizAnswer;
      final submitAttempt =
          widget.submitQuizAttempt ?? QuizService.submitQuizAttempt;
      for (final question in _quiz!.questions) {
        if (question.type == 'short_answer') {
          final text = _shortAnswerControllers[question.id]?.text.trim();
          if (text != null && text.isNotEmpty) {
            await saveAnswer(
              attemptId: _attemptId!,
              questionId: question.id,
              answer: {'text': text},
            );
          }
        } else {
          final choiceId = _selectedChoice[question.id];
          if (choiceId != null) {
            await saveAnswer(
              attemptId: _attemptId!,
              questionId: question.id,
              answer: {'choice_id': choiceId},
            );
          }
        }
      }
      final score = await submitAttempt(_attemptId!);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ส่งแบบทดสอบแล้ว ได้ $score คะแนน')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ส่งไม่สำเร็จ กรุณาลองใหม่')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _quiz?.title ?? 'แบบทดสอบ',
          style: const TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        ),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(_error!),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  if (_quiz!.timeLimitMin != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'เวลาที่กำหนด: ${_quiz!.timeLimitMin} นาที',
                        style: const TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  for (var i = 0; i < _quiz!.questions.length; i++) ...[
                    _buildQuestion(i + 1, _quiz!.questions[i]),
                    const SizedBox(height: 16),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _submitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: SchoolPalette.deepGreen,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('ส่งคำตอบ'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _openAttachment(QuizAttachment attachment) async {
    try {
      final url = await QuizService.getQuestionAttachmentDownloadUrl(
        attachment.id,
      );
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เปิดไฟล์แนบไม่สำเร็จ'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  Widget _buildQuestion(int number, QuizQuestion question) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ข้อ $number. ${question.question}',
            style: const TextStyle(
              color: SchoolPalette.navy,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (question.attachments.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final attachment in question.attachments)
                  ActionChip(
                    avatar: Icon(
                      attachment.type == 'video'
                          ? Icons.play_circle_outline
                          : Icons.image_outlined,
                      size: 18,
                      color: SchoolPalette.navy,
                    ),
                    label: Text(
                      attachment.type == 'video'
                          ? 'ดูวิดีโอแนบ'
                          : 'ดูรูปภาพแนบ',
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: SchoolPalette.glassBorder),
                    onPressed: () => _openAttachment(attachment),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          if (question.type == 'short_answer')
            TextField(
              controller: _shortAnswerControllers.putIfAbsent(
                question.id,
                () => TextEditingController(),
              ),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'พิมพ์คำตอบที่นี่...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            )
          else
            for (final choice in question.choices)
              Material(
                type: MaterialType.transparency,
                child: RadioListTile<String>(
                  value: choice.id,
                  groupValue: _selectedChoice[question.id],
                  onChanged: (value) {
                    setState(() => _selectedChoice[question.id] = value!);
                  },
                  title: Text(choice.text),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
        ],
      ),
    );
  }
}
