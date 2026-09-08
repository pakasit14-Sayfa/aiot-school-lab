// PBL-2: สร้างกิจกรรม Project-Based Learning แบบครบวงจร — ต่างจาก PBL-1
// (สร้างใบงาน/การบ้านทั่วไป ทำไว้แล้วใน teacher_assignment_editor_page.dart)
// ตรงที่ PBL-2 ผูกหัวข้อ + ข้อมูล AIoT จริง + Rubric + ระยะเวลา + รูปแบบ
// เดี่ยว/กลุ่ม เข้าด้วยกันเป็นขั้นตอนเดียวตั้งแต่ต้น เพิ่มเมื่อ 2026-08-16
//
// เชื่อมกับ RubricService/AiotLabService/AssignmentService จริงแล้ว
// (2026-08-21) — เดิม comment บอกว่า "mock ทั้งหมด" แต่จริงๆ ปุ่มเผยแพร่ถูก
// ต่อเข้า Supabase ไปครึ่งหนึ่งแล้วโดยไม่มีใครอัปเดต comment: ใช้
// courses.first.id เดาวิชาแบบสุ่ม (ไม่ใช้ courseId ที่ถูกต้องจากบริบทที่เปิด
// มา), กลืน error แล้วยังโชว์ "สำเร็จ" ให้ครูเห็นอยู่ดี, และข้อมูลที่กรอกไว้
// (อุปกรณ์ AIoT ที่เลือก/Rubric/ระยะเวลา/รูปแบบงาน) ไม่ถูกส่งไปที่ไหนเลย —
// แก้ทั้ง 3 จุดนี้แล้ว
//
// ยังมีข้อจำกัดจริงที่แก้ไม่ได้ในรอบนี้: assignments ไม่มีคอลัมน์ rubric_id ที่
// RPC ไหนตั้งค่าได้ (เหมือนที่เจอใน teacher_submission_review_page.dart) และ
// ไม่มีที่เก็บ device links/duration/group-mode แบบมีโครงสร้างเลย — ข้อมูล
// พวกนี้เลยถูกพับรวมเป็นข้อความใน instructions แทน (ดีกว่าไม่บันทึกอะไร
// เลย) ถ้าจะทำให้ถูกต้องสมบูรณ์ ต้องเพิ่มคอลัมน์/RPC ใหม่
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' hide RubricModel;
import 'package:shared_core/shared_core.dart' as core show RubricModel;

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_rubric_page.dart'
    show RubricModel, RubricCriterion, RubricLevel;
import 'teacher_shared_widgets.dart' show TeacherMockPageShell;

class _PblTopic {
  const _PblTopic(this.title, this.icon, this.color);
  final String title;
  final IconData icon;
  final Color color;
}

const _pblTopics = [
  _PblTopic('พลังงาน', Icons.bolt_rounded, Color(0xFFD97706)),
  _PblTopic('คุณภาพอากาศ', Icons.air_rounded, Color(0xFF0284C7)),
  _PblTopic('แสงในห้องเรียน', Icons.wb_sunny_rounded, Color(0xFFCA8A04)),
  _PblTopic('ความปลอดภัย', Icons.shield_rounded, Color(0xFFDC2626)),
];

class TeacherPblActivityEditorPage extends StatefulWidget {
  const TeacherPblActivityEditorPage({
    super.key,
    required this.courseId,
    this.listTeachingKitDevices,
    this.listMyRubrics,
    this.getRubric,
    this.createAssignment,
    this.publishAssignment,
  });

  final String courseId;

  /// Read/write seams threaded to the corresponding AiotLabService/
  /// RubricService/AssignmentService static calls in production.
  /// listMyRubrics/getRubric return the shared_core RubricModel, imported
  /// under the `core` prefix since this file's own RubricModel (from
  /// teacher_rubric_page.dart) shadows the unprefixed name.
  final Future<List<AiotLabDeviceItem>> Function()? listTeachingKitDevices;
  final Future<List<core.RubricModel>> Function()? listMyRubrics;
  final Future<core.RubricModel> Function(String rubricId)? getRubric;
  final Future<String> Function({
    required String courseId,
    required String type,
    required String title,
    String? instructions,
    DateTime? dueAt,
    String? rubricId,
  })?
  createAssignment;
  final Future<void> Function(String assignmentId)? publishAssignment;

  @override
  State<TeacherPblActivityEditorPage> createState() =>
      _TeacherPblActivityEditorPageState();
}

class _TeacherPblActivityEditorPageState
    extends State<TeacherPblActivityEditorPage> {
  int _step = 0;
  String? _selectedTopic;
  final _problemCtrl = TextEditingController();
  final _objectiveCtrl = TextEditingController();
  final _outcomeCtrl = TextEditingController();
  final Set<String> _selectedDevices = {};
  RubricModel? _selectedRubric;
  final _durationCtrl = TextEditingController(text: '3 สัปดาห์');
  bool _isGroupWork = true;

  bool _loadingOptions = true;
  String? _loadError;
  List<AiotLabDeviceItem> _devices = [];
  List<dynamic> _rubricSummaries = []; // shared_core RubricModel, hidden import
  bool _loadingRubricDetail = false;
  bool _publishing = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    setState(() {
      _loadingOptions = true;
      _loadError = null;
    });
    try {
      final loadDevices =
          widget.listTeachingKitDevices ??
          AiotLabService.listTeachingKitDevices;
      final loadRubrics = widget.listMyRubrics ?? RubricService.listMyRubrics;
      final results = await Future.wait([loadDevices(), loadRubrics()]);
      final allDevices = results[0] as List<AiotLabDeviceItem>;
      if (!mounted) return;
      setState(() {
        _devices = allDevices
            .where((d) => d.courseId == widget.courseId)
            .toList();
        _rubricSummaries = results[1];
        _loadingOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดข้อมูลอุปกรณ์/เกณฑ์ประเมินไม่สำเร็จ';
        _loadingOptions = false;
      });
    }
  }

  Future<void> _pickRubric(String rubricId) async {
    setState(() => _loadingRubricDetail = true);
    try {
      final getRubric = widget.getRubric ?? RubricService.getRubric;
      final d = await getRubric(rubricId);
      final rubric = RubricModel(
        id: d.id,
        title: d.title,
        description: d.description ?? '',
        scope: 'เกณฑ์การประเมินโรงเรียน',
        isLocked: false,
        usedCount: 0,
        updatedAt: '-',
        criteria: d.criteria
            .map(
              (c) => RubricCriterion(
                id: c.id,
                title: c.name,
                maxPoints: c.maxScore.toDouble(),
                levels: (c.levels ?? []).map((l) {
                  final map = l as Map<String, dynamic>;
                  return RubricLevel(
                    name: map['name'] as String? ?? '',
                    score: (map['score'] as num?)?.toDouble() ?? 0.0,
                    description: map['description'] as String? ?? '',
                  );
                }).toList(),
              ),
            )
            .toList(),
      );
      if (!mounted) return;
      setState(() {
        _selectedRubric = rubric;
        _loadingRubricDetail = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRubricDetail = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('โหลดเกณฑ์ไม่สำเร็จ')));
    }
  }

  @override
  void dispose() {
    _problemCtrl.dispose();
    _objectiveCtrl.dispose();
    _outcomeCtrl.dispose();
    _durationCtrl.dispose();
    super.dispose();
  }

  bool get _canGoNextFromStep0 => _selectedTopic != null;
  bool get _canGoNextFromStep1 =>
      _problemCtrl.text.trim().isNotEmpty &&
      _objectiveCtrl.text.trim().isNotEmpty &&
      _outcomeCtrl.text.trim().isNotEmpty;
  bool get _canGoNextFromStep2 => _selectedDevices.isNotEmpty;
  // BR2: Rubric ต้องผูกกับกิจกรรมก่อนจึงจะใช้ตรวจงานได้ — บังคับเลือกก่อน
  // เผยแพร่เสมอ ไม่ใช่แค่ทางเลือก
  bool get _canGoNextFromStep3 => _selectedRubric != null;

  void _next() => setState(() => _step += 1);
  void _back() => setState(() => _step -= 1);

  Future<void> _publish() async {
    setState(() => _publishing = true);
    final instructions =
        '${_problemCtrl.text.trim()}\n\n'
        'วัตถุประสงค์: ${_objectiveCtrl.text.trim()}\n'
        'ผลลัพธ์ที่คาดหวัง: ${_outcomeCtrl.text.trim()}\n'
        'ข้อมูล AIoT ที่ใช้: ${_selectedDevices.join(', ')}\n'
        'Rubric: ${_selectedRubric?.title ?? '-'}\n'
        'ระยะเวลา: ${_durationCtrl.text.trim()} · '
        '${_isGroupWork ? 'งานกลุ่ม' : 'งานเดี่ยว'}';

    try {
      final create =
          widget.createAssignment ?? AssignmentService.createAssignment;
      final publish =
          widget.publishAssignment ?? AssignmentService.publishAssignment;
      final pblId = await create(
        courseId: widget.courseId,
        type: 'project',
        title: 'PBL: ${_selectedTopic ?? "โครงงาน AIoT"}',
        instructions: instructions,
        // BR2 บังคับเลือก Rubric ก่อนเผยแพร่เสมอ (ดู _canGoNextFromStep3) —
        // ต้องส่งค่านี้ไปด้วย ไม่งั้น Rubric ที่ครูเลือกจะหายไปเงียบๆ แม้
        // RPC และคอลัมน์ rubric_id จะรองรับอยู่แล้ว (20260824100000)
        rubricId: _selectedRubric?.id,
      );
      await publish(pblId);

      if (!mounted) return;
      setState(() => _publishing = false);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'เผยแพร่กิจกรรม PBL หัวข้อ "$_selectedTopic" ให้นักเรียนแล้ว',
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _publishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เผยแพร่ไม่สำเร็จ'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'สร้างกิจกรรม PBL',
      activeMenuLabel: 'รายวิชา',
      builder: (context, isDesktop) {
        if (_loadingOptions) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (_loadError != null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(_loadError!),
            ),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStepper(),
            const SizedBox(height: 18),
            switch (_step) {
              0 => _buildTopicStep(),
              1 => _buildProblemStep(),
              2 => _buildDeviceStep(),
              3 => _buildRubricStep(),
              4 => _buildTimelineStep(),
              _ => _buildReviewStep(),
            },
          ],
        );
      },
    );
  }

  Widget _buildStepper() {
    const labels = [
      'หัวข้อ',
      'โจทย์',
      'ข้อมูล AIoT',
      'Rubric',
      'ระยะเวลา',
      'รีวิว',
    ];
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final isActive = index == _step;
          final isDone = index < _step;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isActive
                  ? TeacherPalette.primary
                  : (isDone ? const Color(0xFFF1EEF9) : Colors.white),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive
                    ? TeacherPalette.primary
                    : TeacherPalette.border,
              ),
            ),
            child: Text(
              '${index + 1}. ${labels[index]}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: isActive ? Colors.white : TeacherPalette.softText,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: child,
    );
  }

  Widget _buildNavRow({
    required bool canNext,
    VoidCallback? onNext,
    bool busy = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_step > 0)
            OutlinedButton(onPressed: _back, child: const Text('ย้อนกลับ')),
          const Spacer(),
          FilledButton(
            onPressed: (canNext && !busy) ? (onNext ?? _next) : null,
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
            ),
            child: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_step == 5 ? 'เผยแพร่กิจกรรม' : 'ถัดไป'),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicStep() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เลือกหัวข้อกิจกรรม PBL',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final topic in _pblTopics)
                ChoiceChip(
                  avatar: Icon(topic.icon, size: 16, color: topic.color),
                  label: Text(topic.title),
                  selected: _selectedTopic == topic.title,
                  onSelected: (_) => setState(() {
                    _selectedTopic = topic.title;
                    _selectedDevices.clear();
                  }),
                ),
            ],
          ),
          _buildNavRow(canNext: _canGoNextFromStep0),
        ],
      ),
    );
  }

  Widget _buildProblemStep() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'กำหนดโจทย์และวัตถุประสงค์',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 14),
          _labeledField(
            'โจทย์/ปัญหา',
            _problemCtrl,
            'เช่น ห้องเรียนใช้พลังงานเกินความจำเป็นช่วงพักเที่ยง',
          ),
          const SizedBox(height: 12),
          _labeledField(
            'วัตถุประสงค์',
            _objectiveCtrl,
            'นักเรียนจะได้เรียนรู้อะไร',
          ),
          const SizedBox(height: 12),
          _labeledField(
            'ผลลัพธ์การเรียนรู้ที่คาดหวัง',
            _outcomeCtrl,
            'นักเรียนทำอะไรได้เมื่อจบกิจกรรม',
          ),
          _buildNavRow(
            canNext: _canGoNextFromStep1,
            onNext: () => setState(() => _step += 1),
          ),
        ],
      ),
    );
  }

  Widget _labeledField(String label, TextEditingController ctrl, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          onChanged: (_) => setState(() {}),
          maxLines: 2,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceStep() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เลือกข้อมูล AIoT ที่จะให้นักเรียนใช้',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'อุปกรณ์ที่ลงทะเบียนจริงในวิชานี้',
            style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 14),
          if (_devices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                // Exception Flow 1: ไม่มีอุปกรณ์ AIoT ลงทะเบียนในวิชานี้
                'ยังไม่มีอุปกรณ์ AIoT ที่ลงทะเบียนในวิชานี้ — '
                'กรุณารอ Technician ติดตั้งอุปกรณ์ก่อน',
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (final device in _devices)
              CheckboxListTile(
                value: _selectedDevices.contains(device.deviceId),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedDevices.add(device.deviceId);
                  } else {
                    _selectedDevices.remove(device.deviceId);
                  }
                }),
                title: Text(
                  '${device.name} (${device.location})',
                  style: const TextStyle(fontSize: 13),
                ),
                contentPadding: EdgeInsets.zero,
              ),
          _buildNavRow(canNext: _canGoNextFromStep2),
        ],
      ),
    );
  }

  Widget _buildRubricStep() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ผูก Rubric สำหรับตรวจกิจกรรมนี้',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 4),
          const Text(
            'ต้องเลือก Rubric ก่อนจึงจะเผยแพร่กิจกรรมได้',
            style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 14),
          if (_rubricSummaries.isEmpty)
            const Text(
              'ยังไม่มี Rubric ในระบบ — สร้างที่หน้า Rubric ก่อน',
              style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
            )
          else
            for (final r in _rubricSummaries)
              RadioListTile<String>(
                value: r.id as String,
                groupValue: _selectedRubric?.id,
                onChanged: _loadingRubricDetail
                    ? null
                    : (v) {
                        if (v != null) _pickRubric(v);
                      },
                title: Text(
                  r.title as String,
                  style: const TextStyle(fontSize: 13),
                ),
                contentPadding: EdgeInsets.zero,
              ),
          if (_loadingRubricDetail)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(),
            ),
          _buildNavRow(canNext: _canGoNextFromStep3),
        ],
      ),
    );
  }

  Widget _buildTimelineStep() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ระยะเวลาและรูปแบบงาน',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 14),
          _labeledField('ระยะเวลาทำกิจกรรม', _durationCtrl, 'เช่น 3 สัปดาห์'),
          const SizedBox(height: 14),
          const Text(
            'รูปแบบงาน',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('งานกลุ่ม'),
                selected: _isGroupWork,
                onSelected: (_) => setState(() => _isGroupWork = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('งานเดี่ยว'),
                selected: !_isGroupWork,
                onSelected: (_) => setState(() => _isGroupWork = false),
              ),
            ],
          ),
          _buildNavRow(canNext: true),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ตรวจสอบก่อนเผยแพร่',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 14),
          _reviewRow('หัวข้อ', _selectedTopic ?? '-'),
          _reviewRow('โจทย์', _problemCtrl.text),
          _reviewRow(
            'ข้อมูล AIoT',
            _devices
                .where((d) => _selectedDevices.contains(d.deviceId))
                .map((d) => d.name)
                .join(', '),
          ),
          _reviewRow('Rubric', _selectedRubric?.title ?? '-'),
          _reviewRow('ระยะเวลา', _durationCtrl.text),
          _reviewRow('รูปแบบงาน', _isGroupWork ? 'งานกลุ่ม' : 'งานเดี่ยว'),
          _buildNavRow(canNext: true, onNext: _publish, busy: _publishing),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TeacherPalette.muted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontSize: 12.5, color: TeacherPalette.ink),
            ),
          ),
        ],
      ),
    );
  }
}
