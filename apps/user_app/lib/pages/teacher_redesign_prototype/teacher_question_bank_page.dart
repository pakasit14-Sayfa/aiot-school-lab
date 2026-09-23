import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'teacher_redesign_prototype_page.dart';
import 'teacher_shared_widgets.dart';

/// ตรงกับ enum `question_type` ในฐานข้อมูลแบบ 1:1 —
/// `multiple_choice` / `true_false` / `short_answer`
///
/// เดิมมีแค่ `{ multipleChoice, essay }` และโค้ดโหลดคลังเทียบ
/// `question.type == 'essay'` ซึ่งเป็นค่าที่ไม่มีอยู่ใน enum ฝั่ง DB เลย
/// เงื่อนไขจึงเป็นเท็จทุกครั้ง และคำถาม **ทุกข้อ** ที่โหลดจากหลังบ้าน
/// กลายเป็นปรนัย — ข้ออัตนัยถูกดึงเข้า Exam Builder เป็นปรนัยที่ไม่มี
/// ตัวเลือกและมีเฉลยชี้ไปที่ตัวเลือกที่ไม่มีอยู่ โดยไม่มี error ที่ใดเลย
enum BankQuestionType { multipleChoice, trueFalse, shortAnswer }

/// อัตนัยไม่มีตัวเลือกให้เลือก ที่เหลือมี — ใช้ตัวนี้ตัดสินใจว่าจะแสดง/
/// บันทึกตัวเลือกไหม อย่าเทียบ `== multipleChoice` เพราะถูก/ผิดก็มีตัวเลือก
bool bankTypeHasChoices(BankQuestionType type) =>
    type != BankQuestionType.shortAnswer;

String bankTypeLabel(BankQuestionType type) => switch (type) {
  BankQuestionType.multipleChoice => 'ปรนัย',
  BankQuestionType.trueFalse => 'ถูก / ผิด',
  BankQuestionType.shortAnswer => 'อัตนัย',
};

BankQuestionType bankTypeFromDb(String dbType) => switch (dbType) {
  'true_false' => BankQuestionType.trueFalse,
  'short_answer' => BankQuestionType.shortAnswer,
  _ => BankQuestionType.multipleChoice,
};

Color bankTypeAccent(BankQuestionType type) => switch (type) {
  BankQuestionType.multipleChoice => TeacherPalette.primary,
  BankQuestionType.trueFalse => TeacherPalette.sky,
  BankQuestionType.shortAnswer => TeacherPalette.orange,
};

/// A single reusable question in the shared question bank — public so other
/// pages (e.g. the exam builder) can accept a selection back via
/// `Navigator.push<List<BankQuestion>>`.
class BankQuestion {
  const BankQuestion({
    required this.questionText,
    required this.subject,
    required this.type,
    this.options = const [],
    this.correctIndex,
    this.explanation = '',
    this.score = 2,
    this.difficulty = 'ปานกลาง',
  });

  final String questionText;
  final String subject;
  final BankQuestionType type;
  final List<String> options;
  final int? correctIndex;
  final String explanation;
  final int score;
  final String difficulty;
}

/// A ready-made bundle of bank questions (e.g. "ก่อนเรียน บทที่ 1") that a
/// teacher can add to an exam in one tap, instead of picking questions one
/// by one.
class BankQuestionSet {
  const BankQuestionSet({
    required this.quizId,
    required this.name,
    required this.kind,
    required this.subject,
    required this.description,
    this.questions = const [],
  });

  final String quizId;
  final String name;
  final String kind; // e.g. ก่อนเรียน / หลังเรียน / เก็บคะแนน
  final String subject;
  final String description;
  final List<BankQuestion> questions;
}

class TeacherQuestionBankPage extends StatefulWidget {
  const TeacherQuestionBankPage({
    super.key,
    this.loadCourses,
    this.listQuizzesForCourse,
    this.listQuizQuestions,
  });

  /// Read seams threaded to the corresponding CourseService/QuizService
  /// static calls in production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<QuizSummary>> Function(String courseId)?
  listQuizzesForCourse;
  final Future<List<QuizQuestionSummary>> Function(String quizId)?
  listQuizQuestions;

  @override
  State<TeacherQuestionBankPage> createState() =>
      _TeacherQuestionBankPageState();
}

class _TeacherQuestionBankPageState extends State<TeacherQuestionBankPage> {
  String _setSearch = '';
  final Set<int> _selectedSetIds = {};

  bool _isLoading = true;
  List<BankQuestionSet> _questionSets = [];

  @override
  void initState() {
    super.initState();
    _loadQuestionBank();
  }

  Future<void> _loadQuestionBank() async {
    setState(() => _isLoading = true);
    try {
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final listQuizzes =
          widget.listQuizzesForCourse ?? QuizService.listCourseQuizzes;
      final listQuestions =
          widget.listQuizQuestions ?? QuizService.listQuizQuestions;
      final courses = await loadCourses();
      // Quizzes per course, then questions per quiz — both were awaited inside
      // their loop, so a teacher with 6 courses × 3 quizzes waited out 25
      // sequential round trips. Each level is independent; fetch it as one
      // batch. listQuizzes stays uncaught so a real failure still falls
      // through to the outer catch, as before.
      final quizzesPerCourse = await Future.wait(
        courses.map((course) => listQuizzes(course.id)),
      );
      final allQuizzes = [for (final quizzes in quizzesPerCourse) ...quizzes];
      final questionsByQuiz = <String, List<QuizQuestionSummary>>{};
      await Future.wait(
        allQuizzes.map((q) async {
          try {
            questionsByQuiz[q.id] = await listQuestions(q.id);
          } catch (e) {
            // เดิม catch นี้อยู่ในลูป — ชุดที่ดึงคำถามไม่ได้ยังต้องโชว์ได้ (0 ข้อ)
            debugPrint('Error loading questions for quiz ${q.id}: $e');
          }
        }),
      );
      final loadedSets = <BankQuestionSet>[];

      for (var ci = 0; ci < courses.length; ci++) {
        final course = courses[ci];
        for (final q in quizzesPerCourse[ci]) {
          final kindLabel = q.type == 'pre_test'
              ? 'ก่อนเรียน'
              : (q.type == 'post_test' ? 'หลังเรียน' : 'เก็บคะแนน');

          // เดิมไม่มี RPC ให้ดึงคำถามในชุดข้อสอบเลย ทุกชุดจึงโชว์ "0 ข้อ"
          // ตายตัวเสมอ ไม่ว่าจะมีคำถามจริงกี่ข้อ (list_quiz_questions ใหม่)
          final real = questionsByQuiz[q.id] ?? const <QuizQuestionSummary>[];
          final questions = real.map((question) {
              final correctIdx = question.choices.indexWhere(
                (c) => c.isCorrect,
              );
              return BankQuestion(
                questionText: question.question,
                subject: course.subjectName,
                type: bankTypeFromDb(question.type),
                options: question.choices.map((c) => c.text).toList(),
                // ไม่มีตัวเลือกถูก = ไม่มีเฉลย ต้องเป็น null
                // เดิมบังคับเป็น 0 ซึ่งทำให้ข้ออัตนัยดูเหมือนมีเฉลยอยู่ที่ข้อแรก
                correctIndex: correctIdx >= 0 ? correctIdx : null,
                score: question.points.round(),
              );
          }).toList();

          loadedSets.add(
            BankQuestionSet(
              quizId: q.id,
              name: q.title,
              kind: kindLabel,
              subject: course.subjectName,
              description: 'ชุดข้อสอบ $kindLabel - ${course.subjectName}',
              questions: questions,
            ),
          );
        }
      }

      if (mounted) {
        setState(() {
          _questionSets = loadedSets;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _questionSets = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('โหลดคลังคำถามไม่สำเร็จ'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  List<int> _filteredSetIndexes() {
    final query = _setSearch.trim().toLowerCase();
    if (query.isEmpty) {
      return List.generate(_questionSets.length, (i) => i);
    }
    final indexes = <int>[];
    for (int i = 0; i < _questionSets.length; i++) {
      final s = _questionSets[i];
      if (s.name.toLowerCase().contains(query) ||
          s.description.toLowerCase().contains(query) ||
          s.subject.toLowerCase().contains(query) ||
          s.kind.toLowerCase().contains(query)) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  Color _setKindAccent(String kind) {
    switch (kind) {
      case 'ก่อนเรียน':
        return TeacherPalette.primary;
      case 'หลังเรียน':
        return TeacherPalette.green;
      default:
        return TeacherPalette.orange;
    }
  }

  Widget _buildSetsList() {
    final visibleSetIndexes = _filteredSetIndexes();
    if (visibleSetIndexes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          _questionSets.isEmpty
              ? 'ยังไม่มีชุดข้อสอบในคลังคำถาม\n(สามารถสร้างชุดข้อสอบใหม่ได้ในเมนู "ออกแบบทดสอบ / Exam Builder")'
              : 'ไม่พบชุดข้อสอบที่ตรงกับเงื่อนไข',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TeacherPalette.muted,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: visibleSetIndexes.length,
      itemBuilder: (context, listIdx) {
        final setId = visibleSetIndexes[listIdx];
        final set = _questionSets[setId];

        final selected = _selectedSetIds.contains(setId);
        final accent = _setKindAccent(set.kind);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Material(
              color: selected ? accent.withValues(alpha: 0.06) : Colors.white,
              child: InkWell(
                onTap: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _BankQuestionSetDetailPage(
                        set: set,
                        initiallySelected: selected,
                      ),
                    ),
                  );
                  if (result == null || !mounted) return;
                  setState(() {
                    if (result) {
                      _selectedSetIds.add(setId);
                    } else {
                      _selectedSetIds.remove(setId);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: selected ? accent : TeacherPalette.border,
                        width: selected ? 1.6 : 1,
                      ),
                      right: BorderSide(
                        color: selected ? accent : TeacherPalette.border,
                        width: selected ? 1.6 : 1,
                      ),
                      bottom: BorderSide(
                        color: selected ? accent : TeacherPalette.border,
                        width: selected ? 1.6 : 1,
                      ),
                      left: BorderSide(color: accent, width: 5),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Tag(text: set.kind, color: accent),
                            const SizedBox(width: 6),
                            _Tag(
                              text: set.subject,
                              color: TeacherPalette.primary,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: TeacherPalette.muted,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${set.questions.length} ข้อ',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(999),
                              onTap: () => setState(() {
                                if (selected) {
                                  _selectedSetIds.remove(setId);
                                } else {
                                  _selectedSetIds.add(setId);
                                }
                              }),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  selected
                                      ? Icons.check_box_rounded
                                      : Icons.check_box_outline_blank_rounded,
                                  color: selected
                                      ? accent
                                      : TeacherPalette.muted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          set.name,
                          style: const TextStyle(
                            color: TeacherPalette.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          set.description,
                          style: const TextStyle(
                            color: TeacherPalette.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// รวมคำถามจริงของทุกชุดที่ติ๊กเลือกไว้ ส่งกลับให้หน้าที่เปิดมา (เช่น
  /// exam builder ที่รอผลผ่าน `Navigator.push<List<BankQuestion>>` อยู่แล้ว)
  /// — เดิมหน้านี้ไม่เคย pop ค่ากลับเลยสักครั้ง ต่อให้ติ๊กเลือกไว้เท่าไหร่
  /// ก็ไม่มีผลอะไรกับหน้าที่เรียกมา
  List<BankQuestion> get _selectedQuestions => _selectedSetIds
      .where((i) => i < _questionSets.length)
      .expand((i) => _questionSets[i].questions)
      .toList();

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedQuestions.length;
    return Scaffold(
      backgroundColor: TeacherPalette.card,
      body: TeacherMockPageShell(
        title: 'คลังข้อสอบ',
        activeMenuLabel: 'คลังข้อสอบ',
        builder: (context, isDesktop) {
          if (_isLoading) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: TeacherSearchInput(
                  hintText: 'ค้นหาชุดข้อสอบ...',
                  value: _setSearch,
                  onChanged: (v) => setState(() => _setSearch = v),
                  onClear: () => setState(() => _setSearch = ''),
                ),
              ),
              _buildSetsList(),
              if (selectedCount > 0) const SizedBox(height: 90),
            ],
          );
        },
      ),
      bottomNavigationBar: selectedCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: FilledButton.icon(
                  onPressed: () =>
                      Navigator.pop(context, _selectedQuestions),
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: Text('ยืนยันการเลือก ($selectedCount ข้อ)'),
                  style: FilledButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Full detail view of a single bank question — shown when a teacher taps a
/// card in the bank list, so they can read every option / the full rubric
/// before deciding whether to add it to the exam.
class BankQuestionDetailPage extends StatefulWidget {
  const BankQuestionDetailPage({
    super.key,
    required this.question,
    required this.initiallySelected,
  });

  final BankQuestion question;
  final bool initiallySelected;

  @override
  State<BankQuestionDetailPage> createState() => _BankQuestionDetailPageState();
}

class _BankQuestionDetailPageState extends State<BankQuestionDetailPage> {
  late bool _selected = widget.initiallySelected;

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final accent = bankTypeAccent(q.type);
    final optionLabels = ['ก.', 'ข.', 'ค.', 'ง.'];

    return Scaffold(
      backgroundColor: TeacherPalette.card,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TeacherPalette.ink,
        title: const Text(
          'รายละเอียดคำถาม',
          style: TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: const BorderSide(color: TeacherPalette.border),
                right: const BorderSide(color: TeacherPalette.border),
                bottom: const BorderSide(color: TeacherPalette.border),
                left: BorderSide(color: accent, width: 6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag(text: q.subject, color: TeacherPalette.primary),
                      _Tag(
                        text: bankTypeLabel(q.type),
                        color: accent,
                      ),
                      _Tag(text: q.difficulty, color: TeacherPalette.muted),
                      _Tag(
                        text: '${q.score} คะแนน',
                        color: TeacherPalette.green,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    q.questionText,
                    style: const TextStyle(
                      color: TeacherPalette.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (bankTypeHasChoices(q.type)) ...[
                    const Text(
                      'ตัวเลือกคำตอบ',
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (int i = 0; i < q.options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: i == q.correctIndex
                                ? TeacherPalette.green.withValues(alpha: 0.08)
                                : TeacherPalette.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: i == q.correctIndex
                                  ? TeacherPalette.green
                                  : TeacherPalette.border,
                              width: i == q.correctIndex ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                i == q.correctIndex
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 18,
                                color: i == q.correctIndex
                                    ? TeacherPalette.green
                                    : TeacherPalette.border,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                optionLabels[i],
                                style: TextStyle(
                                  color: i == q.correctIndex
                                      ? TeacherPalette.green
                                      : TeacherPalette.muted,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  q.options[i],
                                  style: TextStyle(
                                    color: TeacherPalette.ink,
                                    fontWeight: i == q.correctIndex
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: TeacherPalette.orange.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: TeacherPalette.orange.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 18,
                            color: TeacherPalette.orange,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'คำถามแบบอัตนัย — นักเรียนพิมพ์คำตอบเอง ครูตรวจให้คะแนนภายหลัง',
                              style: TextStyle(
                                color: TeacherPalette.muted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (q.explanation.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      bankTypeHasChoices(q.type)
                          ? 'คำอธิบายเฉลย'
                          : 'แนวคำตอบ/เกณฑ์ให้คะแนน',
                      style: const TextStyle(
                        color: TeacherPalette.muted,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: TeacherPalette.card,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: TeacherPalette.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              q.explanation,
                              style: const TextStyle(
                                color: TeacherPalette.ink,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton.icon(
            onPressed: () {
              setState(() => _selected = !_selected);
              Navigator.pop(context, _selected);
            },
            icon: Icon(
              _selected
                  ? Icons.remove_circle_rounded
                  : Icons.add_circle_rounded,
              size: 18,
            ),
            label: Text(
              _selected ? 'เอาออกจากรายการที่เลือก' : 'เลือกเข้าชุดข้อสอบ',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _selected
                  ? TeacherPalette.red
                  : TeacherPalette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only view of everything inside a ready-made exam set. Teachers can
/// see every question but can't cherry-pick or edit them individually here
/// — the whole set is added (or removed) as one unit, mirroring how these
/// sets will eventually be curated/locked by an admin rather than teachers.
class _BankQuestionSetDetailPage extends StatefulWidget {
  const _BankQuestionSetDetailPage({
    required this.set,
    required this.initiallySelected,
  });

  final BankQuestionSet set;
  final bool initiallySelected;

  @override
  State<_BankQuestionSetDetailPage> createState() =>
      _BankQuestionSetDetailPageState();
}

class _BankQuestionSetDetailPageState
    extends State<_BankQuestionSetDetailPage> {
  late bool _selected = widget.initiallySelected;

  @override
  Widget build(BuildContext context) {
    final set = widget.set;
    final optionLabels = ['ก.', 'ข.', 'ค.', 'ง.'];

    return Scaffold(
      backgroundColor: TeacherPalette.card,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TeacherPalette.ink,
        title: Text(
          set.name,
          style: const TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: TeacherPalette.muted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${set.description}\nชุดสำเร็จรูป — ดูได้อย่างเดียว เพิ่มเข้าข้อสอบได้ทั้งชุดเท่านั้น',
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          for (int i = 0; i < set.questions.length; i++) ...[
            Builder(
              builder: (context) {
                final q = set.questions[i];
                final accent = bankTypeAccent(q.type);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: const BorderSide(color: TeacherPalette.border),
                        right: const BorderSide(color: TeacherPalette.border),
                        bottom: const BorderSide(color: TeacherPalette.border),
                        left: BorderSide(color: accent, width: 5),
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _Tag(
                              text: 'ข้อที่ ${i + 1}',
                              color: TeacherPalette.muted,
                            ),
                            const SizedBox(width: 6),
                            _Tag(
                              text: bankTypeLabel(q.type),
                              color: accent,
                            ),
                            const Spacer(),
                            _Tag(
                              text: '${q.score} คะแนน',
                              color: TeacherPalette.green,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          q.questionText,
                          style: const TextStyle(
                            color: TeacherPalette.ink,
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                          ),
                        ),
                        if (bankTypeHasChoices(q.type)) ...[
                          const SizedBox(height: 8),
                          for (int j = 0; j < q.options.length; j++)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '${optionLabels[j]} ${q.options[j]}'
                                '${j == q.correctIndex ? "  ✓ เฉลย" : ""}',
                                style: TextStyle(
                                  color: j == q.correctIndex
                                      ? TeacherPalette.green
                                      : TeacherPalette.ink,
                                  fontWeight: j == q.correctIndex
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: FilledButton.icon(
            onPressed: () {
              setState(() => _selected = !_selected);
              Navigator.pop(context, _selected);
            },
            icon: Icon(
              _selected
                  ? Icons.remove_circle_rounded
                  : Icons.add_circle_rounded,
              size: 18,
            ),
            label: Text(
              _selected
                  ? 'เอาออกทั้งชุด'
                  : 'เพิ่มทั้งชุด (${set.questions.length} ข้อ)',
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _selected
                  ? TeacherPalette.red
                  : TeacherPalette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
