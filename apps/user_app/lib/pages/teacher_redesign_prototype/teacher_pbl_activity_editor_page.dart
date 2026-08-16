// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// PBL-2: สร้างกิจกรรม Project-Based Learning แบบครบวงจร — ต่างจาก PBL-1
// (สร้างใบงาน/การบ้านทั่วไป ทำไว้แล้วใน teacher_assignment_editor_page.dart)
// ตรงที่ PBL-2 ผูกหัวข้อ + ข้อมูล AIoT จริง + Rubric + ระยะเวลา + รูปแบบ
// เดี่ยว/กลุ่ม เข้าด้วยกันเป็นขั้นตอนเดียวตั้งแต่ต้น เพิ่มเมื่อ 2026-08-16

import 'package:flutter/material.dart';

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

// PBL-2 BR1: ข้อมูล AIoT ที่เลือกใช้ได้ต้องมาจากอุปกรณ์ที่ลงทะเบียนในระบบ
// เท่านั้น — "ความปลอดภัย" ตั้งใจไม่มีอุปกรณ์เลยเพื่อสาธิต Exception Flow 1
const _devicesByTopic = <String, List<String>>{
  'พลังงาน': [
    'Smart Meter Node-3 (มิเตอร์ไฟฟ้าอาคาร 2)',
    'Solar Panel Monitor Node-8',
  ],
  'คุณภาพอากาศ': ['AQI Sensor Node-1 (ห้อง GreenLab)', 'PM2.5 Sensor Node-7'],
  'แสงในห้องเรียน': ['Light Sensor Node-2 (ห้อง 421)'],
  'ความปลอดภัย': [],
};

RubricModel _mockPblRubric(String id, String title) => RubricModel(
  id: id,
  title: title,
  description: 'เกณฑ์ประเมินโครงงาน PBL ตามหัวข้อที่เลือก',
  scope: 'ใช้ร่วมข้ามวิชา',
  isLocked: false,
  usedCount: 0,
  updatedAt: '-',
  criteria: [
    RubricCriterion(
      id: 'c1',
      title: 'ความเข้าใจปัญหาและการใช้ข้อมูลจริง',
      maxPoints: 10,
      levels: [
        RubricLevel(
          name: 'ดีมาก',
          score: 10,
          description: 'เชื่อมโยงข้อมูล AIoT กับปัญหาได้ชัดเจน',
        ),
        RubricLevel(
          name: 'พอใช้',
          score: 6,
          description: 'เชื่อมโยงได้บางส่วน',
        ),
      ],
    ),
    RubricCriterion(
      id: 'c2',
      title: 'การนำเสนอผลลัพธ์',
      maxPoints: 10,
      levels: [
        RubricLevel(
          name: 'ดีมาก',
          score: 10,
          description: 'นำเสนอเป็นระบบ เข้าใจง่าย',
        ),
        RubricLevel(name: 'พอใช้', score: 6, description: 'นำเสนอพอเข้าใจได้'),
      ],
    ),
  ],
);

final _mockAvailableRubrics = [
  _mockPblRubric(
    'rubric-pbl-1',
    'เกณฑ์ประเมินโครงงาน STEM & AIoT (มาตรฐานโรงเรียน)',
  ),
  _mockPblRubric('rubric-pbl-2', 'เกณฑ์ประเมินโครงงานสิ่งแวดล้อม'),
];

class TeacherPblActivityEditorPage extends StatefulWidget {
  const TeacherPblActivityEditorPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    return TeacherMockPageShell(
      title: 'สร้างกิจกรรม PBL',
      activeMenuLabel: 'รายวิชา',
      builder: (context, isDesktop) {
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

  Widget _buildNavRow({required bool canNext, VoidCallback? onNext}) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        children: [
          if (_step > 0)
            OutlinedButton(onPressed: _back, child: const Text('ย้อนกลับ')),
          const Spacer(),
          FilledButton(
            onPressed: canNext ? (onNext ?? _next) : null,
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
            ),
            child: Text(_step == 5 ? 'เผยแพร่กิจกรรม' : 'ถัดไป'),
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
    final devices = _devicesByTopic[_selectedTopic] ?? [];
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'เลือกข้อมูล AIoT ที่จะให้นักเรียนใช้',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            'อุปกรณ์ที่ลงทะเบียนในระบบตรงกับหัวข้อ "$_selectedTopic"',
            style: const TextStyle(fontSize: 12, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 14),
          if (devices.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                // Exception Flow 1: ไม่มีอุปกรณ์ AIoT ตรงกับหัวข้อที่เลือก
                'ยังไม่มีอุปกรณ์ AIoT ที่ลงทะเบียนตรงกับหัวข้อนี้ในระบบ — '
                'กรุณาเลือกหัวข้ออื่น หรือรอ Technician ติดตั้งอุปกรณ์เพิ่มก่อน',
                style: TextStyle(
                  color: Color(0xFFB91C1C),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            for (final device in devices)
              CheckboxListTile(
                value: _selectedDevices.contains(device),
                onChanged: (v) => setState(() {
                  if (v == true) {
                    _selectedDevices.add(device);
                  } else {
                    _selectedDevices.remove(device);
                  }
                }),
                title: Text(device, style: const TextStyle(fontSize: 13)),
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
          for (final rubric in _mockAvailableRubrics)
            RadioListTile<RubricModel>(
              value: rubric,
              // ignore: deprecated_member_use
              groupValue: _selectedRubric,
              // ignore: deprecated_member_use
              onChanged: (v) => setState(() => _selectedRubric = v),
              title: Text(rubric.title, style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                '${rubric.criteria.length} เกณฑ์ · เต็ม ${rubric.totalMaxPoints.toStringAsFixed(0)} คะแนน',
                style: const TextStyle(fontSize: 11),
              ),
              contentPadding: EdgeInsets.zero,
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
          _reviewRow('ข้อมูล AIoT', _selectedDevices.join(', ')),
          _reviewRow('Rubric', _selectedRubric?.title ?? '-'),
          _reviewRow('ระยะเวลา', _durationCtrl.text),
          _reviewRow('รูปแบบงาน', _isGroupWork ? 'งานกลุ่ม' : 'งานเดี่ยว'),
          _buildNavRow(
            canNext: true,
            onNext: () {
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
            },
          ),
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
