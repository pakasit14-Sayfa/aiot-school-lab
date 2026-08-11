import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';

/// UI-only mock quiz used for both "แบบทดสอบก่อนเรียน" and "แบบทดสอบหลังเรียน".
/// Questions are generated from the lesson's topic list (one question per
/// topic, correct answer = the topic itself, distractors = an unrelated
/// static pool) — there's no real question bank behind this yet.
///
/// Returns the number of correct answers via `Navigator.pop<int>(score)`
/// when the student submits, or `null` if they back out without finishing.
class StudentLessonQuizPage extends StatefulWidget {
  const StudentLessonQuizPage({
    super.key,
    required this.quizTitle,
    required this.lessonTitle,
    required this.topics,
  });

  final String quizTitle;
  final String lessonTitle;
  final List<String> topics;

  @override
  State<StudentLessonQuizPage> createState() => _StudentLessonQuizPageState();
}

const _distractorPool = [
  'การทำอาหารไทยพื้นบ้าน',
  'ประวัติศาสตร์กรีกโบราณ',
  'การวาดภาพสีน้ำ',
  'กติกาฟุตบอลสากล',
  'การปลูกกล้วยไม้',
];

const _choiceLetters = ['ก', 'ข', 'ค', 'ง'];

class _QuizQuestion {
  const _QuizQuestion({required this.correct, required this.choices});

  final String correct;
  final List<String> choices;
}

class _StudentLessonQuizPageState extends State<StudentLessonQuizPage> {
  late final List<_QuizQuestion> _questions = _buildQuestions();
  late final List<String?> _selected = List.filled(_questions.length, null);
  bool _submitted = false;

  List<_QuizQuestion> _buildQuestions() {
    final topics = widget.topics.isEmpty
        ? const ['เนื้อหาหลักของบทเรียนนี้']
        : widget.topics;
    return List.generate(topics.length, (i) {
      final correct = topics[i];
      final distractors = List<String>.from(_distractorPool)
        ..shuffle(); // ไม่ fix seed เพื่อให้ตัวเลือกลวงสลับกันทุกครั้งที่ทำ
      final choices = [correct, ...distractors.take(2)]..shuffle();
      return _QuizQuestion(correct: correct, choices: choices);
    });
  }

  bool get _allAnswered => !_selected.contains(null);

  int get _answeredCount => _selected.where((s) => s != null).length;

  int get _score =>
      _questions.indexed.where((e) => _selected[e.$1] == e.$2.correct).length;

  void _submit() {
    setState(() => _submitted = true);
  }

  void _finish() {
    Navigator.pop(context, _score);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // ปุ่มย้อนกลับอยู่ใน AppBar มาตรฐานแบบเดียวกับหน้าอื่นๆ ทั้งหมด
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
                constraints: BoxConstraints(maxWidth: isDesktop ? 720 : 620),
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
                      if (!_submitted) _buildProgressBar(),
                      if (!_submitted) const SizedBox(height: 16),
                      if (_submitted)
                        _buildResultCard()
                      else
                        for (var i = 0; i < _questions.length; i++) ...[
                          _QuestionCard(
                            index: i,
                            question: _questions[i],
                            selected: _selected[i],
                            onSelect: (choice) =>
                                setState(() => _selected[i] = choice),
                          ),
                          const SizedBox(height: 12),
                        ],
                      const SizedBox(height: 8),
                      GradientButton(
                        label: _submitted ? 'เสร็จสิ้น' : 'ส่งคำตอบ',
                        icon: _submitted
                            ? Icons.check_circle_rounded
                            : Icons.send_rounded,
                        onPressed: _submitted
                            ? _finish
                            : (_allAnswered ? _submit : null),
                      ),
                      if (!_submitted && !_allAnswered) ...[
                        const SizedBox(height: 8),
                        Text(
                          'ตอบให้ครบทุกข้อก่อนถึงจะส่งคำตอบได้ (เหลืออีก '
                          '${_selected.where((s) => s == null).length} ข้อ)',
                          style: const TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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
                          '🧪 ตัวอย่างหน้าตาเท่านั้น คำถามสุ่มจากหัวข้อบทเรียน ไม่ใช่คลังข้อสอบจริง',
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.quizTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            widget.lessonTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_questions.length} คำถาม · เลือกคำตอบที่ถูกต้องที่สุด',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    final total = _questions.length;
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : _answeredCount / total,
              minHeight: 7,
              backgroundColor: const Color(0xFFDCE7E2),
              color: SchoolPalette.mint,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '$_answeredCount/$total',
          style: const TextStyle(
            color: SchoolPalette.deepGreen,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildResultCard() {
    final total = _questions.length;
    final score = _score;
    final percent = total == 0 ? 0 : (score / total * 100).round();

    return SoftCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              gradient: SchoolPalette.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.fact_check_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '$score/$total',
            style: const TextStyle(
              color: SchoolPalette.deepGreen,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'ตอบถูก $percent%',
            style: const TextStyle(
              color: SchoolPalette.navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              for (var i = 0; i < _questions.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnswerReviewRow(
                    index: i,
                    question: _questions[i],
                    selected: _selected[i],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.index,
    required this.question,
    required this.selected,
    required this.onSelect,
  });

  final int index;
  final _QuizQuestion question;
  final String? selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: SchoolPalette.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'ข้อใดเป็นหัวข้อในบทเรียนนี้?',
                    style: TextStyle(
                      color: SchoolPalette.navy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var c = 0; c < question.choices.length; c++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onSelect(question.choices[c]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: selected == question.choices[c]
                        ? SchoolPalette.softGreenBg
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected == question.choices[c]
                          ? SchoolPalette.deepGreen
                          : const Color(0xFFE2E8F0),
                      width: selected == question.choices[c] ? 1.6 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected == question.choices[c]
                              ? SchoolPalette.deepGreen
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected == question.choices[c]
                                ? SchoolPalette.deepGreen
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Text(
                          _choiceLetters[c % _choiceLetters.length],
                          style: TextStyle(
                            color: selected == question.choices[c]
                                ? Colors.white
                                : SchoolPalette.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          question.choices[c],
                          style: TextStyle(
                            color: selected == question.choices[c]
                                ? SchoolPalette.deepGreen
                                : SchoolPalette.navy,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (selected == question.choices[c])
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: SchoolPalette.deepGreen,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AnswerReviewRow extends StatelessWidget {
  const _AnswerReviewRow({
    required this.index,
    required this.question,
    required this.selected,
  });

  final int index;
  final _QuizQuestion question;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    final isCorrect = selected == question.correct;
    final color = isCorrect ? SchoolPalette.deepGreen : const Color(0xFFDC2626);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ข้อ ${index + 1}: ${question.correct}',
                  style: const TextStyle(
                    color: SchoolPalette.navy,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (!isCorrect)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'คุณตอบ: ${selected ?? '-'}',
                      style: const TextStyle(
                        color: Color(0xFFDC2626),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
