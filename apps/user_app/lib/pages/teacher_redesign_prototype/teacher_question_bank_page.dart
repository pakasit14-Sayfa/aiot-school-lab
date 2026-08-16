import 'package:flutter/material.dart';
import 'teacher_redesign_prototype_page.dart';
import 'teacher_shared_widgets.dart';

enum BankQuestionType { multipleChoice, essay }

Color bankTypeAccent(BankQuestionType type) =>
    type == BankQuestionType.multipleChoice
    ? TeacherPalette.primary
    : TeacherPalette.orange;

/// A single reusable question in the shared question bank — public so other
/// pages (e.g. the exam builder) can accept a selection back via
/// `Navigator.push<List<BankQuestion>>`.
class BankQuestion {
  const BankQuestion({
    required this.questionText,
    required this.subject,
    required this.type,
    this.options = const [],
    this.correctIndex = 0,
    this.explanation = '',
    this.score = 2,
    this.difficulty = 'ปานกลาง',
  });

  final String questionText;
  final String subject;
  final BankQuestionType type;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final int score;
  final String difficulty;
}

final List<BankQuestion> mockQuestionBank = [
  BankQuestion(
    questionText:
        'การต่อตัวต้านทาน pull-up กับขาบัส I2C มีวัตถุประสงค์เพื่ออะไร?',
    subject: 'โครงงานเซนเซอร์',
    type: BankQuestionType.multipleChoice,
    options: [
      'รักษาลอจิกแรงดันในสภาวะปกติให้เป็น HIGH (5V/3.3V)',
      'เพิ่มกระแสไฟฟ้าให้กับเซนเซอร์',
      'แปลงสัญญาณจากดิจิทัลเป็นแอนะล็อก',
      'ป้องกันสัญญาณรบกวนคลื่นวิทยุ',
    ],
    correctIndex: 0,
    explanation:
        'บัส I2C เป็นแบบ open-drain จึงต้องใช้ตัวต้านทาน Pull-up ดึงแรงดันไว้ในสภาวะว่าง',
    score: 2,
    difficulty: 'ปานกลาง',
  ),
  BankQuestion(
    questionText: 'เซนเซอร์ HC-SR04 ใช้หลักการใดในการวัดระยะทาง?',
    subject: 'โครงงานเซนเซอร์',
    type: BankQuestionType.multipleChoice,
    options: [
      'วัดเวลาสะท้อนกลับของคลื่นเสียงอัลตราโซนิก',
      'วัดความต้านทานที่เปลี่ยนไปตามแสง',
      'วัดแรงดันไฟฟ้าที่เหนี่ยวนำจากสนามแม่เหล็ก',
      'วัดความจุไฟฟ้าที่เปลี่ยนตามความชื้น',
    ],
    correctIndex: 0,
    explanation:
        'HC-SR04 ส่งคลื่นเสียงแล้ววัดเวลาที่คลื่นสะท้อนกลับมา นำไปคำนวณระยะทางจากความเร็วเสียง',
    score: 2,
    difficulty: 'ง่าย',
  ),
  BankQuestion(
    questionText:
        'อธิบายข้อดีและข้อจำกัดของการส่งข้อมูลเซนเซอร์ผ่าน MQTT เทียบกับ HTTP',
    subject: 'โครงงานเซนเซอร์',
    type: BankQuestionType.essay,
    explanation:
        'ควรกล่าวถึง publish/subscribe, overhead ที่เบากว่า, การรองรับการเชื่อมต่อไม่เสถียร เทียบกับความเรียบง่ายของ HTTP request/response',
    score: 5,
    difficulty: 'ยาก',
  ),
  BankQuestion(
    questionText:
        'อัลกอริทึม Bubble Sort มีความซับซ้อนเวลาในกรณีเลวร้ายที่สุดเท่าใด?',
    subject: 'วิทยาการคำนวณ',
    type: BankQuestionType.multipleChoice,
    options: ['O(n)', 'O(n log n)', 'O(n²)', 'O(log n)'],
    correctIndex: 2,
    explanation:
        'Bubble Sort ต้องเปรียบเทียบทุกคู่ในกรณีเลวร้ายที่สุด ทำให้มีความซับซ้อน O(n²)',
    score: 2,
    difficulty: 'ปานกลาง',
  ),
  BankQuestion(
    questionText:
        'ตัวแปรชนิดใดในภาษา Python ที่ไม่สามารถเปลี่ยนแปลงค่าได้หลังสร้าง (immutable)?',
    subject: 'วิทยาการคำนวณ',
    type: BankQuestionType.multipleChoice,
    options: ['list', 'dict', 'tuple', 'set'],
    correctIndex: 2,
    explanation:
        'tuple เป็นชนิดข้อมูลที่ไม่สามารถแก้ไขค่าภายในได้หลังจากสร้างแล้ว',
    score: 1,
    difficulty: 'ง่าย',
  ),
  BankQuestion(
    questionText:
        'ออกแบบผังงาน (flowchart) สำหรับระบบรดน้ำต้นไม้อัตโนมัติที่ใช้เซนเซอร์วัดความชื้นในดิน',
    subject: 'วิทยาการคำนวณ',
    type: BankQuestionType.essay,
    explanation:
        'ควรมีเงื่อนไขเปรียบเทียบค่าความชื้นกับเกณฑ์ที่ตั้งไว้ และลูปตรวจสอบซ้ำตามรอบเวลา',
    score: 10,
    difficulty: 'ยาก',
  ),
  BankQuestion(
    questionText:
        'ก๊าซชนิดใดเป็นสาเหตุหลักของภาวะเรือนกระจกที่มนุษย์ปล่อยมากที่สุด?',
    subject: 'วิทยาศาสตร์สิ่งแวดล้อม',
    type: BankQuestionType.multipleChoice,
    options: [
      'ไนโตรเจน (N₂)',
      'คาร์บอนไดออกไซด์ (CO₂)',
      'ออกซิเจน (O₂)',
      'อาร์กอน (Ar)',
    ],
    correctIndex: 1,
    explanation:
        'CO₂ จากการเผาไหม้เชื้อเพลิงฟอสซิลเป็นก๊าซเรือนกระจกหลักที่มนุษย์ปล่อยออกมามากที่สุด',
    score: 1,
    difficulty: 'ง่าย',
  ),
  BankQuestion(
    questionText:
        'วิเคราะห์ผลกระทบของค่าฝุ่น PM2.5 ที่เกิน 50 µg/m³ ต่อสุขภาพนักเรียนในโรงเรียน พร้อมเสนอมาตรการรับมือ',
    subject: 'วิทยาศาสตร์สิ่งแวดล้อม',
    type: BankQuestionType.essay,
    explanation:
        'ควรกล่าวถึงผลกระทบทางเดินหายใจ กลุ่มเสี่ยง และมาตรการเช่น งดกิจกรรมกลางแจ้ง ใช้เครื่องฟอกอากาศ',
    score: 5,
    difficulty: 'ปานกลาง',
  ),
];

/// A ready-made bundle of bank questions (e.g. "ก่อนเรียน บทที่ 1") that a
/// teacher can add to an exam in one tap, instead of picking questions one
/// by one. Sets are fixed/curated — a teacher can view what's inside but
/// can't cherry-pick individual questions out of a set.
class BankQuestionSet {
  const BankQuestionSet({
    required this.name,
    required this.kind,
    required this.subject,
    required this.description,
    required this.questionIndexes,
  });

  final String name;
  final String kind; // e.g. ก่อนเรียน / หลังเรียน / เก็บคะแนน
  final String subject;
  final String description;
  final List<int> questionIndexes; // indices into mockQuestionBank

  List<BankQuestion> get questions =>
      questionIndexes.map((i) => mockQuestionBank[i]).toList();
}

final List<BankQuestionSet> mockQuestionSets = [
  const BankQuestionSet(
    name: 'ก่อนเรียน บทที่ 1: เซนเซอร์และการสื่อสาร',
    kind: 'ก่อนเรียน',
    subject: 'โครงงานเซนเซอร์',
    description:
        'วัดความรู้พื้นฐานก่อนเข้าสู่บทเรียนเรื่องเซนเซอร์และการสื่อสารข้อมูล',
    questionIndexes: [0, 1],
  ),
  const BankQuestionSet(
    name: 'หลังเรียน บทที่ 1: เซนเซอร์และการสื่อสาร',
    kind: 'หลังเรียน',
    subject: 'โครงงานเซนเซอร์',
    description: 'ประเมินความเข้าใจหลังเรียนจบบทที่ 1 ครบทั้งปรนัยและอัตนัย',
    questionIndexes: [0, 1, 2],
  ),
  const BankQuestionSet(
    name: 'หลังเรียน บทที่ 2: พื้นฐานวิทยาการคำนวณ',
    kind: 'หลังเรียน',
    subject: 'วิทยาการคำนวณ',
    description: 'ทบทวนอัลกอริทึม ชนิดข้อมูล และการออกแบบผังงาน',
    questionIndexes: [3, 4, 5],
  ),
];

enum _BankTab { items, sets }

class TeacherQuestionBankPage extends StatefulWidget {
  const TeacherQuestionBankPage({super.key});

  @override
  State<TeacherQuestionBankPage> createState() =>
      _TeacherQuestionBankPageState();
}

class _TeacherQuestionBankPageState extends State<TeacherQuestionBankPage> {
  _BankTab _tab = _BankTab.sets;
  String _search = '';
  String? _subjectFilter;
  BankQuestionType? _typeFilter;
  String _setSearch = '';
  final Set<int> _selectedIndividual = {};
  final Set<int> _selectedSetIds = {};

  List<int> get _filteredIndexes {
    final indexes = <int>[];
    for (int i = 0; i < mockQuestionBank.length; i++) {
      final q = mockQuestionBank[i];
      if (_subjectFilter != null && q.subject != _subjectFilter) continue;
      if (_typeFilter != null && q.type != _typeFilter) continue;
      if (_search.trim().isNotEmpty &&
          !q.questionText.toLowerCase().contains(
            _search.trim().toLowerCase(),
          )) {
        continue;
      }
      indexes.add(i);
    }
    return indexes;
  }

  List<int> get _filteredSetIndexes {
    final query = _setSearch.trim().toLowerCase();
    if (query.isEmpty) {
      return List.generate(mockQuestionSets.length, (i) => i);
    }
    final indexes = <int>[];
    for (int i = 0; i < mockQuestionSets.length; i++) {
      final s = mockQuestionSets[i];
      if (s.name.toLowerCase().contains(query) ||
          s.description.toLowerCase().contains(query) ||
          s.subject.toLowerCase().contains(query) ||
          s.kind.toLowerCase().contains(query)) {
        indexes.add(i);
      }
    }
    return indexes;
  }

  /// Union of individually-picked questions and every question that belongs
  /// to a selected ready-made set — deduped so a question counted twice
  /// (once loose, once via a set) is only added to the exam once.
  Set<int> get _allSelectedIndexes {
    final result = <int>{..._selectedIndividual};
    for (final setId in _selectedSetIds) {
      result.addAll(mockQuestionSets[setId].questionIndexes);
    }
    return result;
  }

  void _confirmSelection() {
    final chosen = _allSelectedIndexes.map((i) => mockQuestionBank[i]).toList();
    Navigator.pop(context, chosen);
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
    final visibleSetIndexes = _filteredSetIndexes;
    if (visibleSetIndexes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        alignment: Alignment.center,
        child: const Text(
          'ไม่พบชุดข้อสอบที่ตรงกับเงื่อนไข',
          style: TextStyle(
            color: TeacherPalette.muted,
            fontWeight: FontWeight.w700,
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
        final set = mockQuestionSets[setId];
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
                                '${set.questionIndexes.length} ข้อ',
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
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  selected
                                      ? Icons.check_circle_rounded
                                      : Icons.radio_button_unchecked_rounded,
                                  color: selected
                                      ? accent
                                      : TeacherPalette.border,
                                  size: 22,
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

  @override
  Widget build(BuildContext context) {
    final subjects = mockQuestionBank.map((q) => q.subject).toSet().toList();
    final visibleIndexes = _filteredIndexes;

    return Scaffold(
      backgroundColor: TeacherPalette.card,
      body: TeacherMockPageShell(
        title: 'คลังข้อสอบ',
        activeMenuLabel: 'คลังข้อสอบ',
        builder: (context, isDesktop) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _BankTabButton(
                        label: 'ชุดข้อสอบสำเร็จรูป',
                        icon: Icons.layers_rounded,
                        selected: _tab == _BankTab.sets,
                        onTap: () => setState(() => _tab = _BankTab.sets),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _BankTabButton(
                        label: 'รายข้อ',
                        icon: Icons.list_alt_rounded,
                        selected: _tab == _BankTab.items,
                        onTap: () => setState(() => _tab = _BankTab.items),
                      ),
                    ),
                  ],
                ),
              ),
              if (_tab == _BankTab.items)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'ค้นหาคำถามในคลัง...',
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: TeacherPalette.muted,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: TeacherPalette.border,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: TeacherPalette.border,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: const BorderSide(
                              color: TeacherPalette.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: 'ทุกวิชา',
                              selected: _subjectFilter == null,
                              onTap: () =>
                                  setState(() => _subjectFilter = null),
                            ),
                            for (final s in subjects) ...[
                              const SizedBox(width: 6),
                              _FilterChip(
                                label: s,
                                selected: _subjectFilter == s,
                                onTap: () => setState(
                                  () => _subjectFilter = _subjectFilter == s
                                      ? null
                                      : s,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _FilterChip(
                            label: 'ทุกประเภท',
                            icon: Icons.apps_rounded,
                            selected: _typeFilter == null,
                            onTap: () => setState(() => _typeFilter = null),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'ปรนัย',
                            icon: Icons.list_alt_rounded,
                            selected:
                                _typeFilter == BankQuestionType.multipleChoice,
                            onTap: () => setState(
                              () => _typeFilter =
                                  _typeFilter == BankQuestionType.multipleChoice
                                  ? null
                                  : BankQuestionType.multipleChoice,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _FilterChip(
                            label: 'อัตนัย',
                            icon: Icons.edit_note_rounded,
                            selected: _typeFilter == BankQuestionType.essay,
                            onTap: () => setState(
                              () => _typeFilter =
                                  _typeFilter == BankQuestionType.essay
                                  ? null
                                  : BankQuestionType.essay,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              if (_tab == _BankTab.sets)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: TextField(
                    onChanged: (v) => setState(() => _setSearch = v),
                    decoration: InputDecoration(
                      hintText: 'ค้นหาชุดข้อสอบ...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: TeacherPalette.muted,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: TeacherPalette.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: TeacherPalette.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(999),
                        borderSide: const BorderSide(
                          color: TeacherPalette.primary,
                          width: 1.6,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_tab == _BankTab.sets)
                _buildSetsList()
              else if (visibleIndexes.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  alignment: Alignment.center,
                  child: const Text(
                    'ไม่พบคำถามที่ตรงกับเงื่อนไข',
                    style: TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: visibleIndexes.length,
                  itemBuilder: (context, listIdx) {
                    final bankIdx = visibleIndexes[listIdx];
                    final q = mockQuestionBank[bankIdx];
                    final selected = _selectedIndividual.contains(bankIdx);
                    final accent = bankTypeAccent(q.type);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Material(
                          color: selected
                              ? accent.withValues(alpha: 0.06)
                              : Colors.white,
                          child: InkWell(
                            onTap: () async {
                              final result = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BankQuestionDetailPage(
                                    question: q,
                                    initiallySelected: selected,
                                  ),
                                ),
                              );
                              if (result == null || !mounted) return;
                              setState(() {
                                if (result) {
                                  _selectedIndividual.add(bankIdx);
                                } else {
                                  _selectedIndividual.remove(bankIdx);
                                }
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: selected
                                        ? accent
                                        : TeacherPalette.border,
                                    width: selected ? 1.6 : 1,
                                  ),
                                  right: BorderSide(
                                    color: selected
                                        ? accent
                                        : TeacherPalette.border,
                                    width: selected ? 1.6 : 1,
                                  ),
                                  bottom: BorderSide(
                                    color: selected
                                        ? accent
                                        : TeacherPalette.border,
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
                                        _Tag(
                                          text: q.subject,
                                          color: TeacherPalette.primary,
                                        ),
                                        const SizedBox(width: 6),
                                        _Tag(
                                          text:
                                              q.type ==
                                                  BankQuestionType
                                                      .multipleChoice
                                              ? 'ปรนัย'
                                              : 'อัตนัย',
                                          color: accent,
                                        ),
                                        const SizedBox(width: 6),
                                        _Tag(
                                          text: q.difficulty,
                                          color: TeacherPalette.muted,
                                        ),
                                        const Spacer(),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: TeacherPalette.green,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Text(
                                            '${q.score} คะแนน',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          onTap: () => setState(() {
                                            if (selected) {
                                              _selectedIndividual.remove(
                                                bankIdx,
                                              );
                                            } else {
                                              _selectedIndividual.add(bankIdx);
                                            }
                                          }),
                                          child: Padding(
                                            padding: const EdgeInsets.all(2),
                                            child: Icon(
                                              selected
                                                  ? Icons.check_circle_rounded
                                                  : Icons
                                                        .radio_button_unchecked_rounded,
                                              color: selected
                                                  ? accent
                                                  : TeacherPalette.border,
                                              size: 22,
                                            ),
                                          ),
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
                                    if (q.type ==
                                        BankQuestionType.multipleChoice) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        'เฉลย: ${q.options[q.correctIndex]}',
                                        style: const TextStyle(
                                          color: TeacherPalette.green,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Container(
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
                  child: Text(
                    _allSelectedIndexes.isEmpty
                        ? 'แตะการ์ดหรือชุดข้อสอบเพื่อเลือก'
                        : 'เลือกแล้ว ${_allSelectedIndexes.length} ข้อ',
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _allSelectedIndexes.isEmpty
                      ? null
                      : _confirmSelection,
                  icon: const Icon(Icons.add_circle_rounded, size: 18),
                  label: const Text('เพิ่มเข้าชุดข้อสอบ'),
                  style: FilledButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 13,
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

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
            color: selected ? TeacherPalette.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected ? Colors.white : TeacherPalette.muted,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : TeacherPalette.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 11.5,
                ),
              ),
            ],
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
                        text: q.type == BankQuestionType.multipleChoice
                            ? 'ปรนัย'
                            : 'อัตนัย',
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
                  if (q.type == BankQuestionType.multipleChoice) ...[
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
                      q.type == BankQuestionType.multipleChoice
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

class _BankTabButton extends StatelessWidget {
  const _BankTabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? TeacherPalette.primary : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected ? Colors.white : TeacherPalette.muted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : TeacherPalette.muted,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ],
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
                              text: q.type == BankQuestionType.multipleChoice
                                  ? 'ปรนัย'
                                  : 'อัตนัย',
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
                        if (q.type == BankQuestionType.multipleChoice) ...[
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
