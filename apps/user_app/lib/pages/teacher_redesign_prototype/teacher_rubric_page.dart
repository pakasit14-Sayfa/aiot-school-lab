// PROTOTYPE: Teacher Rubric Management Page (ระบบจัดการเกณฑ์การประเมิน Rubric)
// Wireframe MVP v1 Section 2.5.3 - 2.5.4
// Allows teachers to create, edit, duplicate, and manage school-wide and course-level Rubrics.
// Handles locked state (when rubric is used in student grading) with clear warning banners.

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
// เลี่ยงชนชื่อกับ class RubricModel ในไฟล์นี้เอง (โมเดล UI คนละก้อนกับ
// ของ backend) — ใช้ prefix เฉพาะจุดที่ต้องอ้างถึงชนิดจริงจาก RubricService
import 'package:shared_core/models/rubric_model.dart' as rubric_backend;

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart'
    show TeacherMockPageShell, TeacherSearchInput;

/// Model สำหรับระดับคะแนนในแต่ละเกณฑ์ (Rubric Level)
class RubricLevel {
  RubricLevel({
    required this.name,
    required this.score,
    required this.description,
  });

  String name; // e.g. "ดีมาก", "ดี", "พอใช้", "ต้องปรับปรุง"
  double score;
  String description;
}

/// Model สำหรับเกณฑ์แต่ละข้อ (Rubric Criterion)
class RubricCriterion {
  RubricCriterion({
    required this.id,
    required this.title,
    required this.maxPoints,
    required this.levels,
  });

  String id;
  String title;
  double maxPoints;
  List<RubricLevel> levels;
}

/// Model หลักสำหรับ Rubric
class RubricModel {
  RubricModel({
    required this.id,
    required this.title,
    required this.description,
    required this.scope,
    required this.criteria,
    required this.isLocked,
    required this.usedCount,
    required this.updatedAt,
  });

  String id;
  String title;
  String description;
  String scope; // e.g. "ใช้ร่วมข้ามวิชา", "ม.5/2 การออกแบบเทคโนโลยี"
  List<RubricCriterion> criteria;
  bool isLocked; // ถ้าตรวจงานไปแล้ว ห้ามแก้
  int usedCount;
  String updatedAt;

  double get totalMaxPoints =>
      criteria.fold(0, (sum, item) => sum + item.maxPoints);
}

class TeacherRubricPage extends StatefulWidget {
  const TeacherRubricPage({
    super.key,
    this.listMyRubrics,
    this.getRubric,
    this.createRubric,
    this.updateRubric,
  });

  /// Read/write seams threaded to the corresponding RubricService static
  /// calls in production — widget tests supply these to drive the list
  /// load, the duplicate flow, and the create/edit form without a live
  /// Supabase client.
  final Future<List<rubric_backend.RubricModel>> Function()? listMyRubrics;
  final Future<rubric_backend.RubricModel> Function(String rubricId)?
  getRubric;
  final Future<String> Function({
    required String title,
    String? description,
    List<Map<String, dynamic>>? criteria,
  })?
  createRubric;
  final Future<void> Function({
    required String rubricId,
    required String title,
    String? description,
    List<Map<String, dynamic>>? criteria,
  })?
  updateRubric;

  @override
  State<TeacherRubricPage> createState() => _TeacherRubricPageState();
}

class _TeacherRubricPageState extends State<TeacherRubricPage> {
  String _searchQuery = '';
  String _filterScope = 'ทั้งหมด'; // 'ทั้งหมด', 'ใช้ร่วมข้ามวิชา', 'ล็อกแล้ว'

  List<RubricModel> _rubrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRubrics();
  }

  Future<void> _loadRubrics() async {
    setState(() => _isLoading = true);
    try {
      final listRubrics = widget.listMyRubrics ?? RubricService.listMyRubrics;
      final getRubricDetail = widget.getRubric ?? RubricService.getRubric;
      final backendRubrics = await listRubrics();
      final loadedList = <RubricModel>[];
      for (final r in backendRubrics) {
        RubricModel? detail;
        try {
          final d = await getRubricDetail(r.id);
          detail = RubricModel(
            id: d.id,
            title: d.title,
            description: d.description ?? '',
            scope: 'เกณฑ์การประเมินโรงเรียน',
            isLocked: r.usedCount > 0,
            usedCount: r.usedCount,
            updatedAt: 'ยังไม่มีข้อมูล', // ไม่มี timestamp จริงจาก RPC ให้ใช้
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
        } catch (_) {
          detail = RubricModel(
            id: r.id,
            title: r.title,
            description: r.description ?? '',
            scope: 'เกณฑ์การประเมินโรงเรียน',
            isLocked: r.usedCount > 0,
            usedCount: r.usedCount,
            updatedAt: 'ยังไม่มีข้อมูล',
            criteria: [],
          );
        }
        loadedList.add(detail);
      }

      if (mounted) {
        setState(() {
          _rubrics = loadedList;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _rubrics = [];
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('โหลด Rubric ไม่สำเร็จ'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  /// เดิม "คัดลอกเป็น Rubric ใหม่" ไม่เคยเรียก backend เลย — สร้าง id ปลอมใน
  /// เครื่อง (`'rubric-${millisecondsSinceEpoch}'`) แล้วโชว์ว่าสำเร็จ พอรีเฟรช
  /// หน้าสำเนานั้นก็หายไปเพราะไม่เคยถูกบันทึกจริง ตอนนี้เรียก
  /// RubricService.createRubric จริง แล้วค่อยเพิ่มตัวที่ backend คืนมา
  /// (มี id จริง) เข้าลิสต์
  Future<void> _duplicateRubric(RubricModel sourceRubric) async {
    try {
      final criteriaPayload = sourceRubric.criteria
          .map(
            (c) => {
              'name': c.title,
              'description': '',
              'max_score': c.maxPoints,
              'levels': c.levels
                  .map(
                    (l) => {
                      'name': l.name,
                      'score': l.score,
                      'description': l.description,
                    },
                  )
                  .toList(),
            },
          )
          .toList();

      final newTitle = '${sourceRubric.title} (สำเนา)';
      final create = widget.createRubric ?? RubricService.createRubric;
      final newId = await create(
        title: newTitle,
        description: sourceRubric.description,
        criteria: criteriaPayload,
      );

      final dup = RubricModel(
        id: newId,
        title: newTitle,
        description: sourceRubric.description,
        scope: sourceRubric.scope,
        isLocked: false,
        usedCount: 0,
        updatedAt: 'วันนี้',
        criteria: sourceRubric.criteria,
      );

      if (!mounted) return;
      setState(() {
        _rubrics.insert(0, dup);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('คัดลอก Rubric เป็นฉบับใหม่ที่แก้ไขได้เรียบร้อย'),
          backgroundColor: Color(0xFF0EA5E9),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('คัดลอก Rubric ไม่สำเร็จ กรุณาลองใหม่'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      debugPrint('TeacherRubricPage duplicate failed: $e');
    }
  }

  void _openCreateEditForm({RubricModel? existingRubric}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RubricFormSheet(
        rubric: existingRubric,
        onSave: (savedRubric) {
          setState(() {
            final idx = _rubrics.indexWhere((r) => r.id == savedRubric.id);
            if (idx >= 0) {
              _rubrics[idx] = savedRubric;
            } else {
              _rubrics.insert(0, savedRubric);
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'บันทึก Rubric "${savedRubric.title}" เรียบร้อยแล้ว',
              ),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        },
        onDuplicate: (sourceRubric) => _duplicateRubric(sourceRubric),
        createRubric: widget.createRubric,
        updateRubric: widget.updateRubric,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return TeacherMockPageShell(
        title: 'Rubric (เกณฑ์การประเมิน)',
        activeMenuLabel: 'Rubric',
        builder: (_, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    final filtered = _rubrics.where((r) {
      final matchQuery =
          r.title.contains(_searchQuery) ||
          r.description.contains(_searchQuery) ||
          r.scope.contains(_searchQuery);
      if (_filterScope == 'ล็อกแล้ว') {
        return matchQuery && r.isLocked;
      }
      return matchQuery;
    }).toList();

    return TeacherMockPageShell(
      title: 'Rubric (เกณฑ์การประเมิน)',
      activeMenuLabel: 'Rubric',
      actions: [
        // Button with explicit minimumSize to prevent infinite width bug in Row
        ElevatedButton.icon(
          onPressed: () => _openCreateEditForm(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text(
            'สร้าง Rubric ใหม่',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 44),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ],
      builder: (context, isDesktop) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(isDesktop ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search & Filter Header Bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080F172A),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TeacherSearchInput(
                            hintText:
                                'ค้นหาชื่อ Rubric, คำอธิบาย หรือขอบเขตวิชา...',
                            value: _searchQuery,
                            onChanged: (val) =>
                                setState(() => _searchQuery = val),
                            onClear: () => setState(() => _searchQuery = ''),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'ตัวกรอง:',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: TeacherPalette.muted,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // เดิมมี 'ใช้ร่วมข้ามวิชา' เป็นตัวเลือกกรองด้วย แต่
                        // ไม่มีคอลัมน์ scope ใน DB เลย — ทุก rubric ที่โหลด
                        // จาก backend ถูก hardcode เป็น 'เกณฑ์การประเมิน
                        // โรงเรียน' เสมอ ตัวกรองนี้กรองอะไรไม่ได้จริงมาตั้งแต่
                        // ต้น (แค่ทำงานกับสำเนาที่สร้างในเซสชันปัจจุบันก่อน
                        // รีเฟรชเท่านั้น) เอาออก เหลือแค่ตัวกรองที่ใช้ได้จริง
                        Wrap(
                          spacing: 8,
                          children: ['ทั้งหมด', 'ล็อกแล้ว']
                              .map(
                                (f) => ChoiceChip(
                                  label: Text(f),
                                  selected: _filterScope == f,
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _filterScope = f);
                                    }
                                  },
                                  selectedColor: TeacherPalette.primary
                                      .withValues(alpha: 0.15),
                                  labelStyle: TextStyle(
                                    color: _filterScope == f
                                        ? TeacherPalette.primary
                                        : TeacherPalette.muted,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  side: BorderSide(
                                    color: _filterScope == f
                                        ? TeacherPalette.primary
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Rubrics List Section
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: TeacherPalette.border),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.fact_check_outlined,
                        size: 48,
                        color: TeacherPalette.muted,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'ไม่พบ Rubric ตามเงื่อนไขที่ค้นหา',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.ink,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ลองเปลี่ยนคำค้นหา หรือกดสร้าง Rubric ใหม่ได้ทันที',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: TeacherPalette.muted,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _RubricCardItem(
                      rubric: item,
                      onTapEdit: () =>
                          _openCreateEditForm(existingRubric: item),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

/// การ์ดแสดงรายการ Rubric แต่ละชุด
class _RubricCardItem extends StatelessWidget {
  const _RubricCardItem({required this.rubric, required this.onTapEdit});

  final RubricModel rubric;
  final VoidCallback onTapEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: TeacherPalette.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header Row (Title + Badges)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: rubric.isLocked
                      ? const Color(0xFFFFF7ED)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  rubric.isLocked
                      ? Icons.lock_rounded
                      : Icons.fact_check_rounded,
                  color: rubric.isLocked
                      ? const Color(0xFFEA580C)
                      : const Color(0xFF10B981),
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rubric.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: TeacherPalette.ink,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      rubric.description,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: TeacherPalette.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // Status Badge (Locked vs Editable)
              if (rubric.isLocked)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock_clock_rounded,
                        size: 13,
                        color: Color(0xFFEA580C),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'ล็อกแล้ว (ใช้ตรวจงานแล้ว)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 13,
                        color: Color(0xFF059669),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'แก้ไขได้',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Metadata Chips Bar
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildMetaChip(
                icon: Icons.folder_open_rounded,
                label: rubric.scope,
                bgColor: const Color(0xFFF1F5F9),
                textColor: const Color(0xFF475569),
              ),
              _buildMetaChip(
                icon: Icons.checklist_rounded,
                label: '${rubric.criteria.length} เกณฑ์ย่อย',
                bgColor: const Color(0xFFEFF6FF),
                textColor: const Color(0xFF1D4ED8),
              ),
              _buildMetaChip(
                icon: Icons.military_tech_rounded,
                label:
                    'คะแนนเต็ม ${rubric.totalMaxPoints.toStringAsFixed(0)} คะแนน',
                bgColor: const Color(0xFFFAF5FF),
                textColor: const Color(0xFF7E22CE),
              ),
              _buildMetaChip(
                icon: Icons.history_rounded,
                label: 'ตรวจไปแล้ว ${rubric.usedCount} งาน',
                bgColor: const Color(0xFFF8FAFC),
                textColor: TeacherPalette.muted,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Criteria Preview Chips
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'รายการเกณฑ์การประเมิน:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: TeacherPalette.muted,
                  ),
                ),
                const SizedBox(height: 8),
                Column(
                  children: rubric.criteria.map((c) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14,
                            color: TeacherPalette.primary,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              c.title,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: TeacherPalette.ink,
                              ),
                            ),
                          ),
                          Text(
                            '(${c.maxPoints.toStringAsFixed(0)} คะแนน)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: TeacherPalette.muted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Bottom Action Buttons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton.icon(
                onPressed: onTapEdit,
                icon: Icon(
                  rubric.isLocked
                      ? Icons.visibility_rounded
                      : Icons.edit_rounded,
                  size: 15,
                ),
                label: Text(rubric.isLocked ? 'ดูรายละเอียด' : 'แก้ไข Rubric'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: TeacherPalette.ink,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  minimumSize: const Size(0, 38),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: textColor),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal Sheet สำหรับสร้าง/แก้ไข/ดูรายละเอียด Rubric
class _RubricFormSheet extends StatefulWidget {
  const _RubricFormSheet({
    required this.rubric,
    required this.onSave,
    required this.onDuplicate,
    this.createRubric,
    this.updateRubric,
  });

  final RubricModel? rubric;
  final ValueChanged<RubricModel> onSave;
  final ValueChanged<RubricModel> onDuplicate;
  final Future<String> Function({
    required String title,
    String? description,
    List<Map<String, dynamic>>? criteria,
  })?
  createRubric;
  final Future<void> Function({
    required String rubricId,
    required String title,
    String? description,
    List<Map<String, dynamic>>? criteria,
  })?
  updateRubric;

  @override
  State<_RubricFormSheet> createState() => _RubricFormSheetState();
}

class _RubricFormSheetState extends State<_RubricFormSheet> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _scope;
  late List<RubricCriterion> _criteria;
  late bool _isLocked;

  @override
  void initState() {
    super.initState();
    final r = widget.rubric;
    _titleController = TextEditingController(text: r?.title ?? '');
    _descController = TextEditingController(text: r?.description ?? '');
    _scope = r?.scope ?? 'ใช้ร่วมข้ามวิชา';
    _isLocked = r?.isLocked ?? false;

    if (r != null) {
      _criteria = r.criteria
          .map(
            (c) => RubricCriterion(
              id: c.id,
              title: c.title,
              maxPoints: c.maxPoints,
              levels: c.levels
                  .map(
                    (l) => RubricLevel(
                      name: l.name,
                      score: l.score,
                      description: l.description,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList();
    } else {
      _criteria = [
        RubricCriterion(
          id: 'c-new-1',
          title: 'คุณภาพงานและความถูกต้อง',
          maxPoints: 10,
          levels: [
            RubricLevel(
              name: 'ดีมาก (10)',
              score: 10,
              description: 'ผลงานสมบูรณ์แบบ ตรงตามโจทย์',
            ),
            RubricLevel(
              name: 'ดี (8)',
              score: 8,
              description: 'ผลงานถูกต้อง เรียบร้อย',
            ),
            RubricLevel(
              name: 'พอใช้ (5)',
              score: 5,
              description: 'มีข้อผิดพลาดบางส่วน',
            ),
            RubricLevel(
              name: 'ต้องปรับปรุง (2)',
              score: 2,
              description: 'งานไม่สมบูรณ์',
            ),
          ],
        ),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _addCriterion() {
    setState(() {
      _criteria.add(
        RubricCriterion(
          id: 'c-${DateTime.now().millisecondsSinceEpoch}',
          title: 'เกณฑ์การประเมินข้อที่ ${_criteria.length + 1}',
          maxPoints: 10,
          levels: [
            RubricLevel(
              name: 'ดีมาก (10)',
              score: 10,
              description: 'ปฏิบัติตามเกณฑ์ได้อย่างสมบูรณ์',
            ),
            RubricLevel(
              name: 'ดี (8)',
              score: 8,
              description: 'ปฏิบัติตามเกณฑ์ได้ดี',
            ),
            RubricLevel(
              name: 'พอใช้ (5)',
              score: 5,
              description: 'ปฏิบัติตามเกณฑ์ได้บางส่วน',
            ),
            RubricLevel(
              name: 'ต้องปรับปรุง (2)',
              score: 2,
              description: 'ยังไม่ผ่านเกณฑ์',
            ),
          ],
        ),
      );
    });
  }

  void _removeCriterion(int index) {
    if (_criteria.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rubric ต้องมีอย่างน้อย 1 เกณฑ์การประเมิน'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      _criteria.removeAt(index);
    });
  }

  static final _realIdPattern = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  Future<void> _handleSave() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณากรอกชื่อ Rubric'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final isEdit = widget.rubric != null;

    try {
      final payloadCriteria = _criteria
          .map(
            (c) => {
              if (isEdit && _realIdPattern.hasMatch(c.id)) 'id': c.id,
              'name': c.title,
              'description': '',
              'max_score': c.maxPoints,
              'levels': c.levels
                  .map(
                    (l) => {
                      'name': l.name,
                      'score': l.score,
                      'description': l.description,
                    },
                  )
                  .toList(),
            },
          )
          .toList();

      final create = widget.createRubric ?? RubricService.createRubric;
      final update = widget.updateRubric ?? RubricService.updateRubric;
      final String rubricId;
      if (isEdit) {
        rubricId = widget.rubric!.id;
        await update(
          rubricId: rubricId,
          title: title,
          description: _descController.text.trim(),
          criteria: payloadCriteria,
        );
      } else {
        rubricId = await create(
          title: title,
          description: _descController.text.trim(),
          criteria: payloadCriteria,
        );
      }

      final newRubric = RubricModel(
        id: rubricId,
        title: title,
        description: _descController.text.trim(),
        scope: _scope,
        criteria: _criteria,
        isLocked: _isLocked,
        usedCount: widget.rubric?.usedCount ?? 0,
        updatedAt: 'วันนี้',
      );

      widget.onSave(newRubric);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit ? 'บันทึก Rubric ไม่สำเร็จ กรุณาลองใหม่' : 'สร้าง Rubric ไม่สำเร็จ กรุณาลองใหม่',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditMode = widget.rubric != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Sheet Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: TeacherPalette.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.fact_check_rounded,
                          color: TeacherPalette.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditMode
                            ? (_isLocked
                                  ? 'ดู Rubric (ล็อกแล้ว)'
                                  : 'แก้ไข Rubric')
                            : 'สร้าง Rubric ใหม่',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: TeacherPalette.ink,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const Divider(height: 24),

              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // Special Locked Warning Banner
                    if (_isLocked) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFEA580C),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Rubric นี้ถูกล็อกการแก้ไข',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'เนื่องจาก Rubric นี้ถูกใช้ในการตรวจงานนักเรียนไปแล้ว (${widget.rubric?.usedCount ?? 0} งาน) เพื่อป้องกันความผิดพลาดของประวัติคะแนนย้อนหลัง หากต้องการปรับเปลี่ยนเกณฑ์ กรุณากดปุ่ม "คัดลอกเป็น Rubric ใหม่" ด้านล่าง',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFEA580C),
                                      height: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      if (widget.rubric != null) {
                                        widget.onDuplicate(widget.rubric!);
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.copy_rounded,
                                      size: 15,
                                    ),
                                    label: const Text('คัดลอกเป็น Rubric ใหม่'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFEA580C),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size(0, 36),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 6,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Basic Rubric Form Info
                    const Text(
                      'ข้อมูลทั่วไป',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: TeacherPalette.ink,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _titleController,
                      enabled: !_isLocked,
                      decoration: InputDecoration(
                        labelText: 'ชื่อ Rubric *',
                        hintText: 'เช่น เกณฑ์ประเมินโครงงาน STEM & AIoT',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _descController,
                      enabled: !_isLocked,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'คำอธิบายเกณฑ์',
                        hintText:
                            'อธิบายรายละเอียดขอบเขตการใช้งานหรือวัตถุประสงค์',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // เดิมมี dropdown "ขอบเขตการใช้งาน" ให้เลือก ('ใช้ร่วม
                    // ข้ามวิชา', หรือรายวิชาที่ hardcode ชื่อไว้ตายตัวเช่น
                    // 'ม.5/2 การออกแบบเทคโนโลยี') แต่ไม่มี RPC ใดรับค่านี้
                    // เลย — เลือกแล้วหายไปเงียบๆ ทุกครั้งที่บันทึก เอาออก
                    // แทนปล่อยให้เลือกได้แล้วทิ้งของที่เลือก
                    const SizedBox(height: 24),

                    // Criteria List Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'รายการเกณฑ์การประเมินย่อย',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: TeacherPalette.ink,
                            ),
                          ),
                        ),
                        if (!_isLocked)
                          OutlinedButton.icon(
                            onPressed: _addCriterion,
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('เพิ่มเกณฑ์การประเมิน'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: TeacherPalette.primary,
                              side: const BorderSide(
                                color: TeacherPalette.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              minimumSize: const Size(0, 36),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Criteria Items Loop
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _criteria.length,
                      itemBuilder: (context, cIndex) {
                        final criterion = _criteria[cIndex];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: TeacherPalette.primary,
                                    child: Text(
                                      '${cIndex + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: criterion.title,
                                      enabled: !_isLocked,
                                      onChanged: (val) => criterion.title = val,
                                      decoration: const InputDecoration(
                                        hintText: 'ชื่อเกณฑ์การประเมิน...',
                                        border: InputBorder.none,
                                        isDense: true,
                                      ),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: TeacherPalette.ink,
                                      ),
                                    ),
                                  ),
                                  if (!_isLocked)
                                    IconButton(
                                      onPressed: () => _removeCriterion(cIndex),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Color(0xFFEF4444),
                                        size: 20,
                                      ),
                                    ),
                                ],
                              ),
                              const Divider(height: 16),

                              // Levels Grid
                              Column(
                                children: criterion.levels.map((lvl) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 110,
                                          child: Text(
                                            lvl.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w800,
                                              color: TeacherPalette.ink,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: TextFormField(
                                            initialValue: lvl.description,
                                            enabled: !_isLocked,
                                            onChanged: (val) =>
                                                lvl.description = val,
                                            decoration: InputDecoration(
                                              hintText: 'คำอธิบายเกณฑ์...',
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 8,
                                                  ),
                                              filled: true,
                                              fillColor: Colors.white,
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                borderSide: const BorderSide(
                                                  color: Color(0xFFCBD5E1),
                                                ),
                                              ),
                                            ),
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              // Sheet Footer Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(_isLocked ? 'ปิด' : 'ยกเลิก'),
                  ),
                  if (!_isLocked) ...[
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('บันทึก Rubric'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TeacherPalette.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
