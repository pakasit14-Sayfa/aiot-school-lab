import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'teacher_redesign_prototype_page.dart';
import 'teacher_shared_widgets.dart';

enum _ExamKind { preTest, postTest, quiz }

class _ExamQuestionMock {
  _ExamQuestionMock({
    required this.questionText,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.score = 2,
    this.hasImage = false,
    this.imageName,
    this.imageBytes,
    this.imagePath,
  });

  String questionText;
  List<String> options;
  int correctIndex;
  String explanation;
  int score;
  bool hasImage;
  String? imageName;
  Uint8List? imageBytes;
  String? imagePath;
}

class TeacherExamBuilderPage extends StatefulWidget {
  const TeacherExamBuilderPage({
    super.key,
    this.courseCode = 'PBL-110',
    this.courseName = 'โครงงานเซนเซอร์',
    this.initialKind = 'ข้อสอบก่อนเรียน',
  });

  final String courseCode;
  final String courseName;
  final String initialKind;

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

  final List<_ExamQuestionMock> _questions = [
    _ExamQuestionMock(
      questionText: 'เซนเซอร์ชนิดใดใช้วัดปริมาณฝุ่นละออง PM2.5 ในอากาศโดยตรง?',
      options: [
        'DHT11 (Temperature & Humidity Sensor)',
        'GP2Y1014AU0F (Optical Dust Sensor)',
        'HC-SR04 (Ultrasonic Distance Sensor)',
        'MQ-2 (Combustible Gas Sensor)',
      ],
      correctIndex: 1,
      explanation:
          'GP2Y1014AU0F เป็นเซนเซอร์วัดความหนาแน่นของฝุ่นละอองโดยใช้หลักการสะท้อนของแสงอินฟราเรด',
      score: 2,
      hasImage: true,
      imageName: 'sensor_circuit_diagram.png',
    ),
    _ExamQuestionMock(
      questionText:
          'พอร์ตใดย่อมาจากแบบสื่อสารบัสอนุกรม 2 สาย (SDA, SCL) ที่ใช้เชื่อมต่อหน้าจอ LCD?',
      options: [
        'I2C (Inter-Integrated Circuit)',
        'SPI (Serial Peripheral Interface)',
        'UART (Universal Asynchronous Receiver-Transmitter)',
        'PWM (Pulse Width Modulation)',
      ],
      correctIndex: 0,
      explanation:
          'I2C ใช้สายสัญญาณเพียง 2 เส้น คือ SDA (Serial Data) และ SCL (Serial Clock)',
      score: 2,
    ),
    _ExamQuestionMock(
      questionText:
          'ค่าความชื้นสัมพัทธ์ในอากาศที่แสดงบนบอร์ดเซนเซอร์มีหน่วยเป็นอะไร?',
      options: [
        'องศาเซลเซียส (°C)',
        'เปอร์เซ็นต์ (%RH)',
        'ไมโครกรัมต่อลูกบาศก์เมตร (µg/m³)',
        'แรงดันไฟฟ้า (Volt)',
      ],
      correctIndex: 1,
      explanation: '%RH ย่อมาจาก Relative Humidity หรือความชื้นสัมพัทธ์ในอากาศ',
      score: 2,
    ),
  ];

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

    _examTitleCtrl = TextEditingController(
      text: '$kindPrefixเรื่องการใช้งานเซนเซอร์วัดฝุ่นและการสื่อสารข้อมูล',
    );
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
          correctIndex: 0,
          explanation: 'ระบุคำอธิบายเฉลยคำตอบถูกต้องเพิ่มเติม...',
          score: 2,
        ),
      );
    });
  }

  void _importFromBank() {
    setState(() {
      _questions.add(
        _ExamQuestionMock(
          questionText:
              '(ดึงจากคลัง) การต่อตัวต้านทาน pull-up กับขาบัส I2C มีวัตถุประสงค์เพื่ออะไร?',
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
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ดึงโจทย์ข้อสอบมาตรฐานจากคลังสำเร็จ (+1 ข้อ)'),
        duration: Duration(seconds: 2),
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
          score: q.score,
          hasImage: q.hasImage,
          imageName: q.imageName,
          imageBytes: q.imageBytes,
          imagePath: q.imagePath,
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
    if (_questions.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ข้อสอบต้องมีอย่างน้อย 1 ข้อ')),
      );
      return;
    }
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _pickImageForQuestion(_ExamQuestionMock question) async {
    try {
      final result = await FilePicker.platform.pickFiles(
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาดในการเลือกไฟล์: $e')),
      );
    }
  }

  void _saveExam(bool isPublished) {
    final title = _examTitleCtrl.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อชุดข้อสอบก่อนบันทึก')),
      );
      return;
    }
    final statusText = isPublished
        ? 'เผยแพร่ข้อสอบสำเร็จ'
        : 'บันทึกร่างข้อสอบสำเร็จ';
    showTeacherMockAction(context, '$statusText ($title)');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TeacherPalette.page,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: TeacherPalette.ink,
        title: const Text(
          'ออกแบบทดสอบ / ออกข้อสอบ',
          style: TextStyle(
            color: TeacherPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: TeacherPalette.border, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F0F172A),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
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
                          color: TeacherPalette.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'วิชา ${widget.courseName} (${widget.courseCode})',
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
                          backgroundColor: TeacherPalette.page,
                          foregroundColor: TeacherPalette.muted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'ประเภทข้อสอบ',
                    style: TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _KindChip(
                          label: 'ข้อสอบก่อนเรียน (Pre-test)',
                          selected: _selectedKind == _ExamKind.preTest,
                          onTap: () =>
                              setState(() => _selectedKind = _ExamKind.preTest),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _KindChip(
                          label: 'ข้อสอบหลังเรียน (Post-test)',
                          selected: _selectedKind == _ExamKind.postTest,
                          onTap: () => setState(
                            () => _selectedKind = _ExamKind.postTest,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _KindChip(
                          label: 'แบบทดสอบเก็บคะแนน',
                          selected: _selectedKind == _ExamKind.quiz,
                          onTap: () =>
                              setState(() => _selectedKind = _ExamKind.quiz),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'ชื่อชุดข้อสอบ / หัวข้อประเมิน',
                    style: TextStyle(
                      color: TeacherPalette.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _examTitleCtrl,
                    style: const TextStyle(
                      color: TeacherPalette.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.quiz_rounded,
                        color: TeacherPalette.primary,
                        size: 20,
                      ),
                      filled: true,
                      fillColor: TeacherPalette.page,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: TeacherPalette.border,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: TeacherPalette.border,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: TeacherPalette.primary,
                          width: 1.8,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Metrics Row (Time, Total Score, Passing Grade)
                  Row(
                    children: [
                      Expanded(
                        child: _MetricSettingCard(
                          icon: Icons.timer_rounded,
                          label: 'เวลาทำข้อสอบ',
                          value: '$_timeLimitMinutes นาที',
                          onDecrease: () {
                            if (_timeLimitMinutes > 5) {
                              setState(() => _timeLimitMinutes -= 5);
                            }
                          },
                          onIncrease: () {
                            setState(() => _timeLimitMinutes += 5);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricSettingCard(
                          icon: Icons.grade_rounded,
                          label: 'คะแนนเต็มรวม',
                          value: '$_totalScore คะแนน',
                          color: TeacherPalette.green,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _MetricSettingCard(
                          icon: Icons.verified_rounded,
                          label: 'เกณฑ์ผ่านขั้นต่ำ',
                          value: '$_passingPercentage%',
                          onDecrease: () {
                            if (_passingPercentage > 40) {
                              setState(() => _passingPercentage -= 5);
                            }
                          },
                          onIncrease: () {
                            if (_passingPercentage < 90) {
                              setState(() => _passingPercentage += 5);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Automatic Shuffle Anti-Cheating Toggles
                  const Text(
                    'ระบบสลับข้อสอบและตัวเลือกอัตโนมัติ (ป้องกันการลอกข้อสอบ)',
                    style: TextStyle(
                      color: TeacherPalette.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _ShuffleToggleCard(
                          title: 'สลับลำดับข้อสอบ',
                          subtitle: 'สุ่มลำดับข้อ 1, 2, 3 สดๆ',
                          icon: Icons.shuffle_rounded,
                          selected: _shuffleQuestions,
                          onTap: () => setState(
                            () => _shuffleQuestions = !_shuffleQuestions,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ShuffleToggleCard(
                          title: 'สลับตัวเลือกคำตอบ',
                          subtitle: 'สุ่มลำดับ ก, ข, ค, ง สดๆ',
                          icon: Icons.alt_route_rounded,
                          selected: _shuffleOptions,
                          onTap: () => setState(
                            () => _shuffleOptions = !_shuffleOptions,
                          ),
                        ),
                      ),
                    ],
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
                    borderRadius: BorderRadius.circular(10),
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
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 16),
            ],

            // Add Question Action Buttons Row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _addNewQuestion,
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                    ),
                    label: const Text('+ เพิ่มข้อสอบใหม่'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TeacherPalette.primary,
                      side: const BorderSide(
                        color: TeacherPalette.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importFromBank,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('ดึงโจทย์จากคลัง'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: TeacherPalette.primary,
                      side: const BorderSide(
                        color: TeacherPalette.primary,
                        width: 1.5,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Bottom Sticky Action Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
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
        ),
      ),
    );
  }
}

class _ShuffleToggleCard extends StatelessWidget {
  const _ShuffleToggleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? TeacherPalette.primary.withValues(alpha: 0.08)
          : TeacherPalette.page,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? TeacherPalette.primary
                      : TeacherPalette.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 16,
                  color: selected ? Colors.white : TeacherPalette.muted,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: selected
                            ? TeacherPalette.primary
                            : TeacherPalette.ink,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      selected ? 'เปิดสลับแล้ว ✓' : subtitle,
                      style: TextStyle(
                        color: selected
                            ? TeacherPalette.primary
                            : TeacherPalette.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? TeacherPalette.primary : TeacherPalette.page,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? TeacherPalette.primary : TeacherPalette.border,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? Colors.white : TeacherPalette.ink,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricSettingCard extends StatelessWidget {
  const _MetricSettingCard({
    required this.icon,
    required this.label,
    required this.value,
    this.onDecrease,
    this.onIncrease,
    this.color = TeacherPalette.primary,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onDecrease;
  final VoidCallback? onIncrease;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: TeacherPalette.ink,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (onDecrease != null && onIncrease != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onDecrease,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: TeacherPalette.border),
                    ),
                    child: const Icon(Icons.remove_rounded, size: 14),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onIncrease,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: TeacherPalette.border),
                    ),
                    child: const Icon(Icons.add_rounded, size: 14),
                  ),
                ),
              ],
            ),
          ],
        ],
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
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final optionLabels = ['ก.', 'ข.', 'ค.', 'ง.'];

    Widget buildImageDisplay() {
      final sizeText = question.imageBytes != null
          ? '${(question.imageBytes!.length / 1024).toStringAsFixed(1)} KB'
          : 'ขนาดสัดส่วนจริง';

      Widget imageWidget;
      if (question.imageBytes != null) {
        imageWidget = Image.memory(
          question.imageBytes!,
          height: 240,
          fit: BoxFit.contain,
        );
      } else if (question.imagePath != null && !kIsWeb) {
        imageWidget = Image.file(
          File(question.imagePath!),
          height: 240,
          fit: BoxFit.contain,
        );
      } else {
        imageWidget = Container(
          height: 140,
          width: double.infinity,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.schema_rounded,
                size: 40,
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
          color: TeacherPalette.page,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: TeacherPalette.border),
        ),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageWidget,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.aspect_ratio_rounded,
                  size: 12,
                  color: TeacherPalette.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  'แสดงตามสัดส่วนจริงของไฟล์อัปโหลด ($sizeText)',
                  style: const TextStyle(
                    color: TeacherPalette.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: TeacherPalette.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'ข้อที่ $index',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // International LMS Standard Point Selector Pill
              _QuestionPointsPill(
                score: question.score,
                onChanged: (newScore) {
                  question.score = newScore;
                  onChanged();
                },
              ),
              const Spacer(),

              // Up/Down reorder
              IconButton(
                onPressed: isFirst ? null : onMoveUp,
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                tooltip: 'เลื่อนข้อสอบขึ้น',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                onPressed: isLast ? null : onMoveDown,
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                tooltip: 'เลื่อนข้อสอบลง',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              const SizedBox(width: 4),
              IconButton(
                onPressed: onDuplicate,
                icon: const Icon(Icons.copy_rounded, size: 16),
                tooltip: 'คัดลอกข้อนี้',
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                tooltip: 'ลบข้อนี้',
                style: IconButton.styleFrom(
                  foregroundColor: TeacherPalette.red,
                ),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Question Input
          TextFormField(
            initialValue: question.questionText,
            onChanged: (val) {
              question.questionText = val;
              onChanged();
            },
            decoration: InputDecoration(
              labelText: 'โจทย์คำถามข้อที่ $index',
              labelStyle: const TextStyle(
                color: TeacherPalette.ink,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
              filled: true,
              fillColor: TeacherPalette.page,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TeacherPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: TeacherPalette.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: TeacherPalette.primary,
                  width: 1.6,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Real Device FilePicker Image Section
          if (question.hasImage)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: TeacherPalette.page,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: TeacherPalette.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.image_rounded,
                        size: 16,
                        color: TeacherPalette.primary,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'รูปภาพประกอบ: ${question.imageName ?? "รูปจากเครื่อง"}',
                          style: const TextStyle(
                            color: TeacherPalette.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: onPickImage,
                        icon: const Icon(Icons.folder_open_rounded, size: 14),
                        label: const Text('เปลี่ยนรูป'),
                        style: TextButton.styleFrom(
                          foregroundColor: TeacherPalette.primary,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: () {
                          question.hasImage = false;
                          question.imageBytes = null;
                          question.imagePath = null;
                          onChanged();
                        },
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 14,
                        ),
                        label: const Text('ลบรูป'),
                        style: TextButton.styleFrom(
                          foregroundColor: TeacherPalette.red,
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  buildImageDisplay(),
                ],
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: onPickImage,
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 16),
              label: const Text('+ อัปโหลดรูปภาพจากเครื่องจริง'),
              style: OutlinedButton.styleFrom(
                foregroundColor: TeacherPalette.primary,
                side: const BorderSide(color: TeacherPalette.border),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          const SizedBox(height: 12),

          const Text(
            'ตัวเลือกคำตอบ (เลือกปุ่มวิทยุหน้าข้อเพื่อกำหนดเฉลยที่ถูกต้อง):',
            style: TextStyle(
              color: TeacherPalette.muted,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),

          // 4 Options
          for (int optIdx = 0; optIdx < question.options.length; optIdx++) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: question.correctIndex == optIdx
                    ? TeacherPalette.green.withValues(alpha: 0.08)
                    : TeacherPalette.page,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: question.correctIndex == optIdx
                      ? TeacherPalette.green
                      : TeacherPalette.border,
                  width: question.correctIndex == optIdx ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIdx,
                    groupValue: question.correctIndex,
                    activeColor: TeacherPalette.green,
                    onChanged: (val) {
                      if (val != null) {
                        question.correctIndex = val;
                        onChanged();
                      }
                    },
                  ),
                  Text(
                    optionLabels[optIdx],
                    style: TextStyle(
                      color: question.correctIndex == optIdx
                          ? TeacherPalette.green
                          : TeacherPalette.ink,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      initialValue: question.options[optIdx],
                      onChanged: (val) {
                        question.options[optIdx] = val;
                        onChanged();
                      },
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  if (question.correctIndex == optIdx)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: TeacherPalette.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'เฉลยข้อถูก ✓',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),

          // Explanation Input
          TextFormField(
            initialValue: question.explanation,
            onChanged: (val) {
              question.explanation = val;
              onChanged();
            },
            decoration: InputDecoration(
              labelText: 'คำอธิบายเฉลยเพิ่มเติม (แสดงหลังนักเรียนส่งข้อสอบ)',
              labelStyle: const TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
              prefixIcon: const Icon(
                Icons.lightbulb_outline_rounded,
                color: TeacherPalette.orange,
                size: 18,
              ),
              filled: true,
              fillColor: TeacherPalette.page,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: TeacherPalette.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: TeacherPalette.border),
              ),
            ),
          ),
        ],
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: TeacherPalette.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: TeacherPalette.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stars_rounded,
              size: 14,
              color: TeacherPalette.green,
            ),
            const SizedBox(width: 4),
            Text(
              '$score คะแนน',
              style: const TextStyle(
                color: TeacherPalette.green,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: TeacherPalette.green,
            ),
          ],
        ),
      ),
    );
  }
}
