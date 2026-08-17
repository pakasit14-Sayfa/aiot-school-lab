import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../../widgets/custom_text_field.dart';

/// สร้าง/แก้ไขรายวิชา (CLS-1/2/3). ถ้า [course] เป็น null คือโหมดสร้างใหม่
class CourseFormPage extends StatefulWidget {
  const CourseFormPage({super.key, this.course});

  final CourseDetail? course;

  @override
  State<CourseFormPage> createState() => _CourseFormPageState();
}

class _CourseFormPageState extends State<CourseFormPage> {
  final formKey = GlobalKey<FormState>();
  final subjectController = TextEditingController();
  final gradeLevelController = TextEditingController();
  final roomController = TextEditingController();
  final descriptionController = TextEditingController();

  List<TermOption> terms = [];
  String? selectedTermId;
  bool isLoadingTerms = true;
  bool isSaving = false;

  bool get isEditing => widget.course != null;

  @override
  void initState() {
    super.initState();
    if (widget.course != null) {
      subjectController.text = widget.course!.subjectName;
      gradeLevelController.text = widget.course!.gradeLevel ?? '';
      roomController.text = widget.course!.room ?? '';
      descriptionController.text = widget.course!.description ?? '';
      selectedTermId = widget.course!.termId;
    }
    if (!isEditing) {
      loadTerms();
    } else {
      isLoadingTerms = false;
    }
  }

  Future<void> loadTerms() async {
    setState(() => isLoadingTerms = true);
    try {
      final result = await CourseService.listTerms();
      if (!mounted) return;
      setState(() {
        terms = result;
        selectedTermId ??= terms.isNotEmpty ? terms.first.id : null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดภาคเรียนไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isLoadingTerms = false);
    }
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate()) return;
    if (!isEditing && selectedTermId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณาเลือกภาคเรียน')));
      return;
    }

    setState(() => isSaving = true);
    try {
      if (isEditing) {
        await CourseService.updateCourse(
          courseId: widget.course!.id,
          subjectName: subjectController.text,
          gradeLevel: gradeLevelController.text.trim().isEmpty
              ? null
              : gradeLevelController.text.trim(),
          room: roomController.text.trim().isEmpty
              ? null
              : roomController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );
      } else {
        await CourseService.createCourse(
          termId: selectedTermId!,
          subjectName: subjectController.text,
          gradeLevel: gradeLevelController.text.trim().isEmpty
              ? null
              : gradeLevelController.text.trim(),
          room: roomController.text.trim().isEmpty
              ? null
              : roomController.text.trim(),
          description: descriptionController.text.trim().isEmpty
              ? null
              : descriptionController.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  void dispose() {
    subjectController.dispose();
    gradeLevelController.dispose();
    roomController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขรายวิชา' : 'สร้างรายวิชาใหม่'),
      ),
      body: isLoadingTerms
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isEditing) ...[
                      DropdownButtonFormField<String>(
                        value: selectedTermId,
                        decoration: const InputDecoration(
                          labelText: 'ภาคเรียน',
                        ),
                        items: terms
                            .map(
                              (term) => DropdownMenuItem(
                                value: term.id,
                                child: Text(
                                  '${term.name} (${term.academicYearName})',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedTermId = value),
                      ),
                      const SizedBox(height: 16),
                    ],
                    CustomTextField(
                      controller: subjectController,
                      labelText: 'ชื่อวิชา',
                      hintText: 'เช่น วิทยาศาสตร์สิ่งแวดล้อม',
                      prefixIcon: Icons.book,
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? 'กรุณากรอกชื่อวิชา'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: gradeLevelController,
                      labelText: 'ระดับชั้น (ไม่บังคับ)',
                      hintText: 'เช่น ม.3',
                      prefixIcon: Icons.stairs,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: roomController,
                      labelText: 'ห้องเรียน (ไม่บังคับ)',
                      hintText: 'เช่น 301',
                      prefixIcon: Icons.meeting_room,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: descriptionController,
                      labelText: 'คำอธิบาย (ไม่บังคับ)',
                      hintText: 'รายละเอียดรายวิชา',
                      prefixIcon: Icons.description,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : save,
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing ? 'บันทึก' : 'สร้างรายวิชา'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
