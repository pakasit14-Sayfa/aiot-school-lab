import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'teacher_redesign_prototype_page.dart';
import 'teacher_shared_widgets.dart';
import 'teacher_question_bank_page.dart';

enum _ExamKind { preTest, postTest, quiz }

/// แปล error จาก RPC เป็นข้อความที่ครูอ่านแล้วรู้ว่าต้องทำอะไรต่อ
///
/// เดิมทุก error ถูกกลืนแล้วขึ้นข้อความเดียวว่า "บันทึกข้อสอบไม่สำเร็จ"
/// สาเหตุจริงถูกทิ้งลง `debugPrint` ซึ่งบนเครื่องจริงไม่มีใครเห็น —
/// เจ้าของงานเจออาการ "กดบันทึกแล้วไม่สำเร็จ" บนมือถือแล้วไล่สาเหตุไม่ได้เลย
/// ต้องมานั่งเดาว่าติดสิทธิ์ ติดเซสชัน หรือข้อมูลไม่ครบ
///
/// โค้ดที่ RPC โยนมาดูได้จาก supabase/migrations/20260818000000_quiz_rpcs.sql
/// และ 20260923020000_quiz_question_type_integrity.sql
String examSaveErrorMessage(Object error) {
  final raw = error.toString();
  bool has(String code) => raw.contains(code);

  if (has('not_signed_in') || has('invalid_session')) {
    return 'เซสชันหมดอายุแล้ว กรุณาออกจากระบบแล้วเข้าสู่ระบบใหม่';
  }
  if (has('forbidden')) {
    return 'ไม่มีสิทธิ์บันทึกข้อสอบในวิชานี้ — ต้องเป็นครูผู้สอนของวิชานี้ '
        'และเข้าสู่ระบบด้วยบทบาทครู (ถ้าบัญชีมีหลายบทบาท ให้เลือกบทบาทครูตอนเข้าสู่ระบบ)';
  }
  if (has('course_not_found')) {
    return 'ไม่พบรายวิชานี้ในระบบแล้ว อาจถูกลบไปหลังจากเปิดหน้านี้';
  }
  if (has('quiz_already_published')) {
    return 'ข้อสอบชุดนี้เผยแพร่ไปแล้ว แก้ไขเพิ่มไม่ได้ — สร้างชุดใหม่แทน';
  }
  if (has('quiz_not_found')) {
    return 'ไม่พบชุดข้อสอบที่กำลังบันทึก';
  }
  if (has('title_required')) {
    return 'ยังไม่ได้ตั้งชื่อชุดข้อสอบ';
  }
  if (has('question_required')) {
    return 'มีข้อที่ยังไม่ได้พิมพ์โจทย์';
  }
  if (has('short_answer_takes_no_choices')) {
    return 'ข้อแบบอัตนัยมีตัวเลือกติดมาด้วย — ลบตัวเลือกออก หรือเปลี่ยนชนิดเป็นปรนัย';
  }
  if (has('true_false_needs_exactly_two_choices')) {
    return 'ข้อแบบถูก/ผิด ต้องมี 2 ตัวเลือกพอดี';
  }
  if (has('exactly_one_correct_choice_required')) {
    return 'มีข้อที่เลือกเฉลยไว้มากกว่าหนึ่ง หรือยังไม่ได้เลือกเฉลย';
  }
  if (has('choice_text_required')) {
    return 'มีตัวเลือกที่ยังเว้นว่างอยู่';
  }
  if (has('choices_required')) {
    return 'มีข้อปรนัยที่ยังไม่มีตัวเลือก — ต้องมีอย่างน้อย 2 ตัวเลือก';
  }
  if (has('SocketException') ||
      has('Failed host lookup') ||
      has('ClientException') ||
      has('TimeoutException')) {
    return 'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ ตรวจสอบอินเทอร์เน็ตแล้วลองใหม่';
  }

  // ไม่รู้จัก — ต้องโชว์ของจริงออกมา ไม่ใช่กลืนทิ้งเหมือนเดิม
  final trimmed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  final short = trimmed.length > 160 ? '${trimmed.substring(0, 160)}…' : trimmed;
  return 'บันทึกข้อสอบไม่สำเร็จ — $short';
}

/// ตรงกับ `question_type` ฝั่ง DB — ถูก/ผิด เคยหายไปจาก enum นี้ ทำให้
/// คำถามถูก/ผิดที่ดึงจากคลังถูกบันทึกกลับเป็นปรนัย เสียชนิดเดิมไปเงียบ ๆ
enum _QuestionType { multipleChoice, trueFalse, essay }

/// อัตนัยไม่มีตัวเลือก ที่เหลือมี
bool _typeHasChoices(_QuestionType type) => type != _QuestionType.essay;

enum _ExamDisplayMode { onePerScreen, allAtOnce }

/// Accent color per question type — purple reads as "structured/pick one"
/// (Forms), orange reads as "free write" so the two are scannable at a
/// glance without reading the toggle label.
Color _typeAccent(_QuestionType type) => switch (type) {
  _QuestionType.multipleChoice => TeacherPalette.primary,
  _QuestionType.trueFalse => TeacherPalette.sky,
  _QuestionType.essay => TeacherPalette.orange,
};

class _ExamQuestionMock {
  _ExamQuestionMock({
    required this.questionText,
    required this.options,
    this.correctIndex,
    required this.explanation,
    this.type = _QuestionType.multipleChoice,
    this.score = 2,
    this.hasImage = false,
    this.imageName,
    this.imageBytes,
    this.imagePath,
    this.hasVideo = false,
    this.videoName,
    this.videoBytes,
    this.videoPath,
  });

  String questionText;
  List<String> options;
  int? correctIndex;
  String explanation;
  _QuestionType type;
  int score;
  bool hasImage;
  String? imageName;
  Uint8List? imageBytes;
  String? imagePath;
  bool hasVideo;
  String? videoName;
  Uint8List? videoBytes;
  String? videoPath;
}

class TeacherExamBuilderPage extends StatefulWidget {
  const TeacherExamBuilderPage({
    super.key,
    this.courseId,
    this.courseCode = 'PBL-110',
    this.courseName = 'โครงงานเซนเซอร์',
    this.initialKind = 'ข้อสอบก่อนเรียน',
    this.listMyCourses,
    this.createQuiz,
  });

  // ไม่บังคับ required เพื่อไม่ให้ route dev-preview เดิมใน main.dart
  // (`/prototype/exam-builder`, เปิดโดยไม่มีคอร์สจริงในคอนเท็กซ์) พัง — แต่
  // ทุกจุดที่เปิดจากหน้าจริง (course detail) ต้องส่งมาเสมอ ดู _saveExam
  final String? courseId;
  final String courseCode;
  final String courseName;
  final String initialKind;
  // Seam for tests: lets a test prove _saveExam skips CourseService entirely
  // (and so never falls back to "the first course of any random list") once
  // a real courseId is supplied.
  final Future<List<CourseSummary>> Function()? listMyCourses;

  /// Seam for tests: lets a test capture the real courseId QuizService.
  /// createQuiz is actually called with, without relying on any error text
  /// reaching the screen. Defaults to the real service call in production.
  final Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? lessonId,
    int? timeLimitMin,
  })?
  createQuiz;

  @override
  State<TeacherExamBuilderPage> createState() => _TeacherExamBuilderPageState();
}

class _TeacherExamBuilderPageState extends State<TeacherExamBuilderPage> {
  late _ExamKind _selectedKind;
  late TextEditingController _examTitleCtrl;
  int _timeLimitMinutes = 20;
  int _passingPercentage = 60;
  bool _shuffleQuestions = true;
  bool _shuffleOptions = true;
  _ExamDisplayMode _displayMode = _ExamDisplayMode.allAtOnce;

  // เดิม seed ข้อสอบ AIoT ปลอมไว้ 3 ข้อ (PM2.5/I2C/%RH) ทุกครั้งที่เปิดหน้า
  // — ครูที่กดบันทึกจะได้ข้อสอบที่ตัวเองไม่ได้เขียนถูกเขียนลงฐานข้อมูลจริง
  // ผ่าน QuizService.addQuizQuestion เริ่มจากว่างเสมอ แล้วให้ครูเพิ่มเอง
  // หรือดึงจากคลังข้อสอบจริง (_importFromBank)
  final List<_ExamQuestionMock> _questions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialKind.contains('หลังเรียน')) {
      _selectedKind = _ExamKind.postTest;
    } else if (widget.initialKind.contains('ก่อนเรียน')) {
      _selectedKind = _ExamKind.preTest;
    } else {
      _selectedKind = _ExamKind.quiz;
    }

    final kindPrefix = switch (_selectedKind) {
      _ExamKind.preTest => 'ข้อสอบก่อนเรียน: ',
      _ExamKind.postTest => 'ข้อสอบหลังเรียน: ',
      _ExamKind.quiz => 'แบบทดสอบเก็บคะแนน: ',
    };

    // เดิมเติมชื่อเรื่องปลอม ("เรื่องการใช้งานเซนเซอร์วัดฝุ่น...") ให้อัตโนมัติ
    // ซึ่งถูกบันทึกเป็นชื่อข้อสอบจริงถ้าครูไม่ได้แก้ — เหลือแค่คำนำหน้าประเภท
    _examTitleCtrl = TextEditingController(text: kindPrefix);
  }

  @override
  void dispose() {
    _examTitleCtrl.dispose();
    super.dispose();
  }

  int get _totalScore => _questions.fold(0, (sum, q) => sum + q.score);

  void _addNewQuestion() {
    setState(() {
      _questions.add(
        _ExamQuestionMock(
          questionText: 'โจทย์ข้อสอบข้อที่ ${_questions.length + 1}',
          options: ['ตัวเลือก ก', 'ตัวเลือก ข', 'ตัวเลือก ค', 'ตัวเลือก ง'],
          correctIndex: null,
          explanation: 'ระบุคำอธิบายเฉลยคำตอบถูกต้องเพิ่มเติม...',
          score: 2,
        ),
      );
    });
  }

  Future<void> _importFromBank() async {
    final chosen = await Navigator.push<List<BankQuestion>>(
      context,
      MaterialPageRoute(builder: (_) => const TeacherQuestionBankPage()),
    );
    if (chosen == null || chosen.isEmpty || !mounted) return;
    setState(() {
      for (final bq in chosen) {
        // รักษาชนิดเดิมของคำถามไว้ 1:1 — เดิมยัดทุกอย่างเป็นปรนัย และถ้า
        // ไม่ใช่ปรนัยก็ใส่ตัวเลือกปลอม 'ตัวเลือก ก/ข/ค/ง' ให้ ทั้งที่
        // ครูไม่ได้เขียนไว้
        final type = switch (bq.type) {
          BankQuestionType.multipleChoice => _QuestionType.multipleChoice,
          BankQuestionType.trueFalse => _QuestionType.trueFalse,
          BankQuestionType.shortAnswer => _QuestionType.essay,
        };
        _questions.add(
          _ExamQuestionMock(
            questionText: bq.questionText,
            options: _typeHasChoices(type) ? List.from(bq.options) : const [],
            correctIndex: bq.correctIndex,
            explanation: bq.explanation,
            type: type,
            score: bq.score,
          ),
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('ดึงโจทย์จากคลังสำเร็จ (+${chosen.length} ข้อ)'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _duplicateQuestion(int index) {
    final q = _questions[index];
    setState(() {
      _questions.insert(
        index + 1,
        _ExamQuestionMock(
          questionText: '${q.questionText} (สำเนา)',
          options: List.from(q.options),
          correctIndex: q.correctIndex,
          explanation: q.explanation,
          type: q.type,
          score: q.score,
          hasImage: q.hasImage,
          imageName: q.imageName,
          imageBytes: q.imageBytes,
          imagePath: q.imagePath,
          hasVideo: q.hasVideo,
          videoName: q.videoName,
          videoBytes: q.videoBytes,
          videoPath: q.videoPath,
        ),
      );
    });
  }

  void _moveQuestion(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _questions.length) return;
    setState(() {
      final q = _questions.removeAt(index);
      _questions.insert(newIndex, q);
    });
  }

  void _deleteQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _pickImageForQuestion(_ExamQuestionMock question) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        setState(() {
          question.hasImage = true;
          question.imageName = pickedFile.name;
          question.imageBytes = pickedFile.bytes;
          question.imagePath = kIsWeb ? null : pickedFile.path;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'อัปโหลดรูปภาพ "${pickedFile.name}" จากเครื่องสำเร็จ!',
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking exam question image: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกไฟล์')),
      );
    }
  }

  Future<void> _pickVideoForQuestion(_ExamQuestionMock question) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.video,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.first;
        setState(() {
          question.hasVideo = true;
          question.videoName = pickedFile.name;
          question.videoBytes = pickedFile.bytes;
          question.videoPath = kIsWeb ? null : pickedFile.path;
        });
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('แนบวิดีโอ "${pickedFile.name}" จากเครื่องสำเร็จ!'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error picking exam question video: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกไฟล์วิดีโอ')),
      );
    }
  }

  void _openStudentPreview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _StudentExamPreviewPage(
          examTitle: _examTitleCtrl.text.trim().isEmpty
              ? 'ตัวอย่างข้อสอบ'
              : _examTitleCtrl.text.trim(),
          questions: _questions,
          displayMode: _displayMode,
        ),
      ),
    );
  }

  Future<void> _saveExam(bool isPublished) async {
    final title = _examTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อชุดข้อสอบก่อนบันทึก')),
      );
      return;
    }
    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ยังไม่มีโจทย์ในชุดข้อสอบ กรุณาเพิ่มอย่างน้อย 1 ข้อ')),
      );
      return;
    }
    // ASM-1 Exception Flow: ห้ามเผยแพร่ถ้าคำถามแบบเลือกตอบข้อใดยังไม่มีเฉลย
    if (isPublished) {
      // ข้อที่มีตัวเลือกต้องมีตัวเลือกให้เลือกจริง ๆ และต้องมีเฉลย
      // เดิมเช็คแค่ `correctIndex == null` ของปรนัย ซึ่งปล่อยให้เผยแพร่
      // ปรนัยที่ไม่มีตัวเลือกเลยได้ (เฉลยเป็น 0 ไม่ใช่ null จึงผ่านด่าน)
      // แล้วนักเรียนเจอคำถามที่ตอบไม่ได้
      final noChoices = <int>[];
      final missingAnswerKey = <int>[];
      for (var i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        if (!_typeHasChoices(q.type)) continue;
        final filled = q.options.where((o) => o.trim().isNotEmpty).length;
        if (filled < 2) {
          noChoices.add(i + 1);
        } else if (q.correctIndex == null) {
          missingAnswerKey.add(i + 1);
        }
      }
      if (noChoices.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ข้อที่ ${noChoices.join(", ")} ยังไม่มีตัวเลือกให้เลือก '
              '— ต้องมีอย่างน้อย 2 ตัวเลือกก่อนเผยแพร่ '
              '(ถ้าเป็นคำถามให้เขียนตอบ ให้เปลี่ยนชนิดเป็นอัตนัย)',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return;
      }
      if (missingAnswerKey.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'ยังไม่ได้เลือกเฉลยข้อที่ ${missingAnswerKey.join(", ")} '
              '— ต้องระบุเฉลยให้ครบก่อนเผยแพร่ข้อสอบ',
            ),
          ),
        );
        return;
      }
    }

    try {
      var targetCourseId = widget.courseId;
      if (targetCourseId == null) {
        // Dev-preview only (e.g. /prototype/exam-builder opened with no real
        // course in context) — never true for a real teacher, who always
        // reaches this page from a specific course's detail page.
        final listMyCourses =
            widget.listMyCourses ?? CourseService.listMyCourses;
        final courses = await listMyCourses();
        if (courses.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'ไม่พบรายวิชาของคุณในระบบ กรุณาสร้างรายวิชาก่อนออกข้อสอบ',
                ),
                backgroundColor: Color(0xFFEF4444),
              ),
            );
          }
          return;
        }
        targetCourseId = courses.first.id;
      }
      final quizKindStr = _selectedKind == _ExamKind.preTest
          ? 'pre_test'
          : (_selectedKind == _ExamKind.postTest ? 'post_test' : 'general');

      final createQuiz = widget.createQuiz ?? QuizService.createQuiz;
      final quizId = await createQuiz(
        courseId: targetCourseId,
        type: quizKindStr,
        title: title,
        timeLimitMin: _timeLimitMinutes,
      );

      for (final q in _questions) {
        final qTypeStr = switch (q.type) {
          _QuestionType.multipleChoice => 'multiple_choice',
          _QuestionType.trueFalse => 'true_false',
          _QuestionType.essay => 'short_answer',
        };
        final choicesPayload = _typeHasChoices(q.type)
            ? q.options
                  .asMap()
                  .entries
                  .map(
                    (entry) => {
                      'text': entry.value,
                      'is_correct': entry.key == q.correctIndex,
                    },
                  )
                  .toList()
            : null;

        final questionId = await QuizService.addQuizQuestion(
          quizId: quizId,
          type: qTypeStr,
          question: q.questionText,
          points: q.score,
          choices: choicesPayload,
        );

        if (q.hasImage && q.imageBytes != null) {
          await QuizService.uploadQuestionAttachment(
            questionId: questionId,
            fileName: q.imageName ?? 'image.jpg',
            bytes: q.imageBytes!,
            type: 'image',
          );
        }
        if (q.hasVideo && q.videoBytes != null) {
          await QuizService.uploadQuestionAttachment(
            questionId: questionId,
            fileName: q.videoName ?? 'video.mp4',
            bytes: q.videoBytes!,
            type: 'video',
          );
        }
      }

      if (isPublished) {
        await QuizService.publishQuiz(quizId);
      }

      final statusText = isPublished
          ? 'เผยแพร่ข้อสอบสำเร็จ'
          : 'บันทึกร่างข้อสอบสำเร็จ';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$statusText ($title)'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error saving exam: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(examSaveErrorMessage(e)),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'ออกแบบทดสอบ / ออกข้อสอบ',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card — Forms-style: colored top strip, big
            // borderless title, settings collapsed into compact pills.
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: TeacherPalette.border, width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 8,
                    decoration: const BoxDecoration(
                      color: TeacherPalette.primary,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: TeacherPalette.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '${widget.courseName} · ${widget.courseCode}',
                                style: const TextStyle(
                                  color: TeacherPalette.primary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded, size: 20),
                              style: IconButton.styleFrom(
                                backgroundColor: TeacherPalette.card,
                                foregroundColor: TeacherPalette.muted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SegmentedCapsule<_ExamKind>(
                          value: _selectedKind,
                          segments: const [
                            (
                              value: _ExamKind.preTest,
                              label: 'ก่อนเรียน',
                              icon: Icons.flag_outlined,
                            ),
                            (
                              value: _ExamKind.postTest,
                              label: 'หลังเรียน',
                              icon: Icons.flag_rounded,
                            ),
                            (
                              value: _ExamKind.quiz,
                              label: 'เก็บคะแนน',
                              icon: Icons.emoji_events_outlined,
                            ),
                          ],
                          color: TeacherPalette.primary,
                          onChanged: (v) => setState(() => _selectedKind = v),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _examTitleCtrl,
                          style: const TextStyle(
                            color: TeacherPalette.ink,
                            fontWeight: FontWeight.w900,
                            fontSize: 19,
                          ),
                          decoration: InputDecoration(
                            hintText: 'ชื่อชุดข้อสอบ / หัวข้อประเมิน',
                            hintStyle: TextStyle(
                              color: TeacherPalette.muted.withValues(
                                alpha: 0.5,
                              ),
                              fontWeight: FontWeight.w800,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 10,
                            ),
                            border: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: TeacherPalette.border,
                                width: 1.4,
                              ),
                            ),
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: TeacherPalette.border,
                                width: 1.4,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: TeacherPalette.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SpecPill(
                              icon: Icons.timer_rounded,
                              label: '$_timeLimitMinutes นาที',
                              color: TeacherPalette.primary,
                              onDecrease: _timeLimitMinutes > 5
                                  ? () => setState(() => _timeLimitMinutes -= 5)
                                  : null,
                              onIncrease: () =>
                                  setState(() => _timeLimitMinutes += 5),
                            ),
                            _SpecPill(
                              icon: Icons.stars_rounded,
                              label: '$_totalScore คะแนนเต็ม',
                              color: TeacherPalette.green,
                            ),
                            _SpecPill(
                              icon: Icons.verified_rounded,
                              label: 'ผ่าน $_passingPercentage%',
                              color: TeacherPalette.green,
                              onDecrease: _passingPercentage > 40
                                  ? () =>
                                        setState(() => _passingPercentage -= 5)
                                  : null,
                              onIncrease: _passingPercentage < 90
                                  ? () =>
                                        setState(() => _passingPercentage += 5)
                                  : null,
                            ),
                            _ToggleChip(
                              icon: Icons.shuffle_rounded,
                              label: 'สุ่มลำดับข้อ',
                              selected: _shuffleQuestions,
                              onTap: () => setState(
                                () => _shuffleQuestions = !_shuffleQuestions,
                              ),
                            ),
                            _ToggleChip(
                              icon: Icons.alt_route_rounded,
                              label: 'สุ่มตัวเลือก',
                              selected: _shuffleOptions,
                              onTap: () => setState(
                                () => _shuffleOptions = !_shuffleOptions,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'มุมมองนักเรียน',
                          style: TextStyle(
                            color: TeacherPalette.muted,
                            fontWeight: FontWeight.w800,
                            fontSize: 11.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _SegmentedCapsule<_ExamDisplayMode>(
                          value: _displayMode,
                          segments: const [
                            (
                              value: _ExamDisplayMode.onePerScreen,
                              label: 'ทีละข้อ',
                              icon: Icons.view_agenda_rounded,
                            ),
                            (
                              value: _ExamDisplayMode.allAtOnce,
                              label: 'เห็นทั้งหมดพร้อมกัน',
                              icon: Icons.view_list_rounded,
                            ),
                          ],
                          color: TeacherPalette.primary,
                          onChanged: (v) => setState(() => _displayMode = v),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section Header
            Row(
              children: [
                const Text(
                  'รายการโจทย์ข้อสอบ',
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: TeacherPalette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${_questions.length} ข้อ',
                    style: const TextStyle(
                      color: TeacherPalette.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Questions List
            if (_questions.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 28,
                ),
                decoration: BoxDecoration(
                  color: TeacherPalette.card,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 34,
                      color: TeacherPalette.muted,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'ยังไม่มีโจทย์ในชุดข้อสอบนี้',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'กด "เพิ่มข้อสอบใหม่" เพื่อเขียนเอง หรือ "ดึงโจทย์จากคลัง"',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: TeacherPalette.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            for (int i = 0; i < _questions.length; i++) ...[
              _QuestionBuilderCard(
                index: i + 1,
                isFirst: i == 0,
                isLast: i == _questions.length - 1,
                question: _questions[i],
                onMoveUp: () => _moveQuestion(i, -1),
                onMoveDown: () => _moveQuestion(i, 1),
                onDuplicate: () => _duplicateQuestion(i),
                onDelete: () => _deleteQuestion(i),
                onPickImage: () => _pickImageForQuestion(_questions[i]),
                onPickVideo: () => _pickVideoForQuestion(_questions[i]),
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],

            // Add Question Action Buttons
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _PillActionButton(
                  icon: Icons.add_circle_rounded,
                  label: 'เพิ่มข้อสอบใหม่',
                  color: TeacherPalette.primary,
                  filled: true,
                  onTap: _addNewQuestion,
                ),
                _PillActionButton(
                  icon: Icons.download_rounded,
                  label: 'ดึงโจทย์จากคลัง',
                  color: TeacherPalette.primary,
                  filled: false,
                  onTap: _importFromBank,
                ),
                _PillActionButton(
                  icon: Icons.visibility_rounded,
                  label: 'ดูตัวอย่างที่นักเรียนจะเห็น',
                  color: TeacherPalette.orange,
                  filled: false,
                  onTap: _openStudentPreview,
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Bottom Sticky Action Footer
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: TeacherPalette.border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x140F172A),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _saveExam(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TeacherPalette.ink,
                        side: const BorderSide(color: TeacherPalette.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: const Text('บันทึกร่างข้อสอบ'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () => _saveExam(true),
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: const Text('เผยแพร่ข้อสอบให้นักเรียนทำ'),
                      style: FilledButton.styleFrom(
                        backgroundColor: TeacherPalette.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Generic pill-shaped segmented control (2–3 options) used for exam kind,
/// question type, and student display mode — replaces the old boxy chip
/// rows with one compact, consistent Forms/Kahoot-style capsule.
class _SegmentedCapsule<T> extends StatelessWidget {
  const _SegmentedCapsule({
    required this.value,
    required this.segments,
    required this.onChanged,
    this.color = TeacherPalette.primary,
    super.key,
  });

  final T value;
  final List<({T value, String label, IconData icon})> segments;
  final ValueChanged<T> onChanged;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TeacherPalette.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final seg in segments)
            Flexible(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => onChanged(seg.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: value == seg.value ? color : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          seg.icon,
                          size: 14,
                          color: value == seg.value
                              ? Colors.white
                              : TeacherPalette.muted,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            seg.label,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: value == seg.value
                                  ? Colors.white
                                  : TeacherPalette.muted,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact rounded stat pill (Kahoot/Forms style) — shows an icon+value and
/// optionally tiny +/- steppers when [onDecrease]/[onIncrease] are given.
class _SpecPill extends StatelessWidget {
  const _SpecPill({
    required this.icon,
    required this.label,
    this.color = TeacherPalette.primary,
    this.onDecrease,
    this.onIncrease,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;

  @override
  Widget build(BuildContext context) {
    final hasStepper = onDecrease != null || onIncrease != null;
    return Container(
      padding: EdgeInsets.fromLTRB(12, 8, hasStepper ? 4 : 12, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (hasStepper) ...[
            const SizedBox(width: 4),
            _StepperDot(
              icon: Icons.remove_rounded,
              onTap: onDecrease,
              color: color,
            ),
            _StepperDot(
              icon: Icons.add_rounded,
              onTap: onIncrease,
              color: color,
            ),
          ],
        ],
      ),
    );
  }
}

class _StepperDot extends StatelessWidget {
  const _StepperDot({
    required this.icon,
    required this.onTap,
    required this.color,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 1),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: onTap == null ? Colors.transparent : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 12,
          color: onTap == null ? color.withValues(alpha: 0.3) : color,
        ),
      ),
    );
  }
}

/// Compact on/off pill (Kahoot-style) used for the anti-cheat shuffle
/// switches.
class _ToggleChip extends StatelessWidget {
  const _ToggleChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? TeacherPalette.primary : TeacherPalette.card,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : icon,
                size: 14,
                color: selected ? Colors.white : TeacherPalette.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : TeacherPalette.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillActionButton extends StatelessWidget {
  const _PillActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return filled
        ? FilledButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: FilledButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          )
        : OutlinedButton.icon(
            onPressed: onTap,
            icon: Icon(icon, size: 18),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color, width: 1.5),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
  }
}

class _QuestionBuilderCard extends StatelessWidget {
  const _QuestionBuilderCard({
    required this.index,
    required this.isFirst,
    required this.isLast,
    required this.question,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onDuplicate,
    required this.onDelete,
    required this.onPickImage,
    required this.onPickVideo,
    required this.onChanged,
  });

  final int index;
  final bool isFirst;
  final bool isLast;
  final _ExamQuestionMock question;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onPickImage;
  final VoidCallback onPickVideo;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final optionLabels = ['ก.', 'ข.', 'ค.', 'ง.'];
    final accent = _typeAccent(question.type);

    Widget buildImageDisplay() {
      final sizeText = question.imageBytes != null
          ? '${(question.imageBytes!.length / 1024).toStringAsFixed(1)} KB'
          : 'ขนาดสัดส่วนจริง';

      Widget imageWidget;
      if (question.imageBytes != null) {
        imageWidget = Image.memory(
          question.imageBytes!,
          height: 200,
          fit: BoxFit.contain,
        );
      } else if (question.imagePath != null && !kIsWeb) {
        imageWidget = Image.file(
          File(question.imagePath!),
          height: 200,
          fit: BoxFit.contain,
        );
      } else {
        imageWidget = Container(
          height: 120,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schema_rounded,
                size: 36,
                color: TeacherPalette.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 6),
              Text(
                '[ รูปภาพประกอบ: ${question.imageName ?? "รูปไดอะแกรม.png"} ]',
                style: const TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }

      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: TeacherPalette.card,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageWidget,
            ),
            const SizedBox(height: 6),
            Text(
              'แสดงตามสัดส่วนจริงของไฟล์อัปโหลด ($sizeText)',
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    Widget optionRow(int optIdx) {
      final isCorrect = question.correctIndex == optIdx;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Material(
          color: isCorrect
              ? TeacherPalette.green.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              question.correctIndex = optIdx;
              onChanged();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    isCorrect
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked_rounded,
                    size: 20,
                    color: isCorrect
                        ? TeacherPalette.green
                        : TeacherPalette.border,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    optionLabels[optIdx],
                    style: TextStyle(
                      color: isCorrect
                          ? TeacherPalette.green
                          : TeacherPalette.muted,
                      fontWeight: FontWeight.w900,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextFormField(
                      initialValue: question.options[optIdx],
                      onChanged: (val) {
                        question.options[optIdx] = val;
                        onChanged();
                      },
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isCorrect
                            ? FontWeight.w800
                            : FontWeight.w600,
                        color: TeacherPalette.ink,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 6),
                      ),
                    ),
                  ),
                  if (isCorrect)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'เฉลย',
                        style: TextStyle(
                          color: TeacherPalette.green,
                          fontSize: 10.5,
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

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TeacherPalette.border, width: 1),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D0F172A),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: accent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SegmentedCapsule<_QuestionType>(
                            value: question.type,
                            color: accent,
                            segments: const [
                              (
                                value: _QuestionType.multipleChoice,
                                label: 'ปรนัย',
                                icon: Icons.list_alt_rounded,
                              ),
                              (
                                value: _QuestionType.trueFalse,
                                label: 'ถูก/ผิด',
                                icon: Icons.rule_rounded,
                              ),
                              (
                                value: _QuestionType.essay,
                                label: 'อัตนัย',
                                icon: Icons.edit_note_rounded,
                              ),
                            ],
                            onChanged: (t) {
                              question.type = t;
                              // จัดข้อมูลให้เข้ากับชนิดใหม่ทันที ไม่ทิ้ง
                              // ตัวเลือกหรือเฉลยที่ขัดกับชนิดไว้ให้ไหลไป
                              // ถึงตอนบันทึก
                              switch (t) {
                                case _QuestionType.trueFalse:
                                  question.options = ['จริง', 'เท็จ'];
                                  if ((question.correctIndex ?? 0) > 1) {
                                    question.correctIndex = null;
                                  }
                                case _QuestionType.essay:
                                  question.options = [];
                                  question.correctIndex = null;
                                case _QuestionType.multipleChoice:
                                  break;
                              }
                              onChanged();
                            },
                          ),
                          const Spacer(),
                          _QuestionPointsPill(
                            score: question.score,
                            onChanged: (newScore) {
                              question.score = newScore;
                              onChanged();
                            },
                          ),
                          IconButton(
                            onPressed: isFirst ? null : onMoveUp,
                            icon: const Icon(
                              Icons.arrow_upward_rounded,
                              size: 15,
                            ),
                            tooltip: 'เลื่อนข้อสอบขึ้น',
                            visualDensity: VisualDensity.compact,
                            color: TeacherPalette.muted,
                          ),
                          IconButton(
                            onPressed: isLast ? null : onMoveDown,
                            icon: const Icon(
                              Icons.arrow_downward_rounded,
                              size: 15,
                            ),
                            tooltip: 'เลื่อนข้อสอบลง',
                            visualDensity: VisualDensity.compact,
                            color: TeacherPalette.muted,
                          ),
                          IconButton(
                            onPressed: onDuplicate,
                            icon: const Icon(Icons.copy_rounded, size: 15),
                            tooltip: 'คัดลอกข้อนี้',
                            visualDensity: VisualDensity.compact,
                            color: TeacherPalette.muted,
                          ),
                          IconButton(
                            onPressed: onDelete,
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 15,
                            ),
                            tooltip: 'ลบข้อนี้',
                            visualDensity: VisualDensity.compact,
                            color: TeacherPalette.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Question Input — underline only, Forms-style
                      TextFormField(
                        initialValue: question.questionText,
                        onChanged: (val) {
                          question.questionText = val;
                          onChanged();
                        },
                        style: const TextStyle(
                          color: TeacherPalette.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'พิมพ์โจทย์คำถาม...',
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: TeacherPalette.border,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: TeacherPalette.border,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: TeacherPalette.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Compact icon-only media attach row
                      Row(
                        children: [
                          _MediaIconButton(
                            icon: Icons.add_photo_alternate_rounded,
                            tooltip: 'แนบรูปภาพ',
                            color: TeacherPalette.primary,
                            active: question.hasImage,
                            onTap: onPickImage,
                          ),
                          const SizedBox(width: 8),
                          _MediaIconButton(
                            icon: Icons.video_call_rounded,
                            tooltip: 'แนบคลิป/วิดีโอ',
                            color: TeacherPalette.orange,
                            active: question.hasVideo,
                            onTap: onPickVideo,
                          ),
                        ],
                      ),

                      if (question.hasImage) ...[
                        const SizedBox(height: 10),
                        _AttachmentChipHeader(
                          icon: Icons.image_rounded,
                          color: TeacherPalette.primary,
                          label: question.imageName ?? 'รูปจากเครื่อง',
                          onRemove: () {
                            question.hasImage = false;
                            question.imageBytes = null;
                            question.imagePath = null;
                            onChanged();
                          },
                        ),
                        const SizedBox(height: 8),
                        buildImageDisplay(),
                      ],

                      if (question.hasVideo) ...[
                        const SizedBox(height: 10),
                        _AttachmentChipHeader(
                          icon: Icons.videocam_rounded,
                          color: TeacherPalette.orange,
                          label: question.videoName ?? 'วิดีโอจากเครื่อง',
                          onRemove: () {
                            question.hasVideo = false;
                            question.videoBytes = null;
                            question.videoPath = null;
                            onChanged();
                          },
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.play_circle_fill_rounded,
                            size: 38,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),

                      if (_typeHasChoices(question.type)) ...[
                        for (
                          int optIdx = 0;
                          optIdx < question.options.length;
                          optIdx++
                        )
                          optionRow(optIdx),
                      ] else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: TeacherPalette.orange.withValues(
                              alpha: 0.06,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: TeacherPalette.orange.withValues(
                                alpha: 0.25,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.edit_note_rounded,
                                size: 18,
                                color: TeacherPalette.orange,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'คำถามแบบอัตนัย — นักเรียนจะพิมพ์คำตอบเองในช่องข้อความ ครูตรวจให้คะแนนภายหลัง',
                                  style: TextStyle(
                                    color: TeacherPalette.muted,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Explanation Input — underline only
                      TextFormField(
                        initialValue: question.explanation,
                        onChanged: (val) {
                          question.explanation = val;
                          onChanged();
                        },
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          labelText:
                              _typeHasChoices(question.type)
                              ? 'คำอธิบายเฉลยเพิ่มเติม (แสดงหลังนักเรียนส่งข้อสอบ)'
                              : 'แนวคำตอบ/เกณฑ์ให้คะแนน (สำหรับครูใช้ตรวจ)',
                          labelStyle: const TextStyle(
                            color: TeacherPalette.muted,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          prefixIcon: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: TeacherPalette.orange,
                            size: 16,
                          ),
                          isDense: true,
                          border: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: TeacherPalette.border,
                            ),
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: TeacherPalette.border,
                            ),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: TeacherPalette.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaIconButton extends StatelessWidget {
  const _MediaIconButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? color : color.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: active ? 1 : 0.25),
            ),
          ),
          child: Icon(icon, size: 16, color: active ? Colors.white : color),
        ),
      ),
    );
  }
}

class _AttachmentChipHeader extends StatelessWidget {
  const _AttachmentChipHeader({
    required this.icon,
    required this.color,
    required this.label,
    required this.onRemove,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 11.5,
            ),
          ),
        ),
        InkWell(
          onTap: onRemove,
          borderRadius: BorderRadius.circular(999),
          child: const Padding(
            padding: EdgeInsets.all(2),
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: TeacherPalette.red,
            ),
          ),
        ),
      ],
    );
  }
}

class _QuestionPointsPill extends StatelessWidget {
  const _QuestionPointsPill({required this.score, required this.onChanged});

  final int score;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<int>(
      onSelected: onChanged,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      offset: const Offset(0, 36),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Icons.star_outline_rounded,
                size: 16,
                color: TeacherPalette.green,
              ),
              SizedBox(width: 8),
              Text(
                '1 คะแนน (มาตรฐาน)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(
                Icons.star_half_rounded,
                size: 16,
                color: TeacherPalette.green,
              ),
              SizedBox(width: 8),
              Text(
                '2 คะแนน (ปานกลาง)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 5,
          child: Row(
            children: [
              Icon(Icons.star_rounded, size: 16, color: TeacherPalette.green),
              SizedBox(width: 8),
              Text(
                '5 คะแนน (โจทย์ยาก/อัตนัย)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 10,
          child: Row(
            children: [
              Icon(
                Icons.military_tech_rounded,
                size: 16,
                color: TeacherPalette.green,
              ),
              SizedBox(width: 8),
              Text(
                '10 คะแนน (โจทย์ใหญ่)',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: TeacherPalette.green,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, size: 13, color: Colors.white),
            const SizedBox(width: 3),
            Text(
              '$score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 15,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only demo of how students will see the exam, respecting the
/// teacher's chosen display mode (one question per screen vs. all at once).
class _StudentExamPreviewPage extends StatefulWidget {
  const _StudentExamPreviewPage({
    required this.examTitle,
    required this.questions,
    required this.displayMode,
  });

  final String examTitle;
  final List<_ExamQuestionMock> questions;
  final _ExamDisplayMode displayMode;

  @override
  State<_StudentExamPreviewPage> createState() =>
      _StudentExamPreviewPageState();
}

class _StudentExamPreviewPageState extends State<_StudentExamPreviewPage> {
  int _currentIndex = 0;
  final Map<int, int> _selectedOption = {};
  final Map<int, String> _essayAnswers = {};

  Widget _buildAttachments(_ExamQuestionMock q) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (q.hasImage) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: q.imageBytes != null
                ? Image.memory(q.imageBytes!, height: 180, fit: BoxFit.contain)
                : (q.imagePath != null && !kIsWeb
                      ? Image.file(
                          File(q.imagePath!),
                          height: 180,
                          fit: BoxFit.contain,
                        )
                      : Container(
                          height: 120,
                          color: TeacherPalette.card,
                          alignment: Alignment.center,
                          child: Text(q.imageName ?? 'รูปภาพประกอบ'),
                        )),
          ),
          const SizedBox(height: 10),
        ],
        if (q.hasVideo) ...[
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 44,
                  color: Colors.white,
                ),
                const SizedBox(height: 6),
                Text(
                  q.videoName ?? 'วิดีโอประกอบคำถาม',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildQuestionCard(_ExamQuestionMock q, int qIndex) {
    final optionLabels = ['ก.', 'ข.', 'ค.', 'ง.'];
    final accent = _typeAccent(q.type);
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: TeacherPalette.border, width: 1),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 6, color: accent),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ข้อที่ ${qIndex + 1}. ${q.questionText}',
                        style: const TextStyle(
                          color: TeacherPalette.ink,
                          fontWeight: FontWeight.w900,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildAttachments(q),
                      if (_typeHasChoices(q.type))
                        for (int i = 0; i < q.options.length; i++)
                          RadioListTile<int>(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            activeColor: TeacherPalette.primary,
                            value: i,
                            groupValue: _selectedOption[qIndex],
                            onChanged: (val) =>
                                setState(() => _selectedOption[qIndex] = val!),
                            title: Text('${optionLabels[i]} ${q.options[i]}'),
                          )
                      else
                        TextField(
                          maxLines: 4,
                          onChanged: (val) => _essayAnswers[qIndex] = val,
                          decoration: InputDecoration(
                            hintText: 'พิมพ์คำตอบของคุณที่นี่...',
                            filled: true,
                            fillColor: TeacherPalette.card,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final questions = widget.questions;
    final isOnePerScreen = widget.displayMode == _ExamDisplayMode.onePerScreen;

    return Scaffold(
      backgroundColor: TeacherPalette.card,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TeacherPalette.ink,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.examTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
            ),
            Text(
              isOnePerScreen
                  ? 'มุมมองนักเรียน · ทีละข้อ'
                  : 'มุมมองนักเรียน · เห็นทั้งหมดพร้อมกัน',
              style: const TextStyle(fontSize: 11, color: TeacherPalette.muted),
            ),
          ],
        ),
      ),
      body: isOnePerScreen
          ? Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / questions.length,
                      minHeight: 8,
                      color: TeacherPalette.primary,
                      backgroundColor: TeacherPalette.border,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ข้อที่ ${_currentIndex + 1} จาก ${questions.length}',
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildQuestionCard(
                        questions[_currentIndex],
                        _currentIndex,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentIndex == 0
                              ? null
                              : () => setState(() => _currentIndex -= 1),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: const Text('ย้อนกลับ'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _currentIndex == questions.length - 1
                              ? () => Navigator.pop(context)
                              : () => setState(() => _currentIndex += 1),
                          style: FilledButton.styleFrom(
                            backgroundColor: TeacherPalette.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            _currentIndex == questions.length - 1
                                ? 'ส่งข้อสอบ'
                                : 'ข้อถัดไป',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: questions.length,
              itemBuilder: (context, i) => _buildQuestionCard(questions[i], i),
            ),
    );
  }
}
