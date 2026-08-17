import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'submission_review_page.dart';

const _assignmentTypes = ['worksheet', 'homework', 'project'];
const _metricTypes = [
  'pm25',
  'aqi',
  'temperature',
  'humidity',
  'light_lux',
  'energy_kwh',
  'power_w',
];

/// สร้าง/แก้ไขงาน (PBL) รวมผูกข้อมูล AIoT จริงจาก sensor_readings (PBL-สนับสนุน)
///
/// โหมดสร้าง: ส่ง [courseId] มาเฉยๆ · โหมดแก้ไข: ส่ง [assignmentId] มา
class AssignmentFormPage extends StatefulWidget {
  const AssignmentFormPage({super.key, this.courseId, this.assignmentId})
    : assert(
        courseId != null || assignmentId != null,
        'ต้องระบุ courseId (สร้างใหม่) หรือ assignmentId (แก้ไข) อย่างใดอย่างหนึ่ง',
      );

  final String? courseId;
  final String? assignmentId;

  @override
  State<AssignmentFormPage> createState() => _AssignmentFormPageState();
}

class _AssignmentFormPageState extends State<AssignmentFormPage> {
  final titleController = TextEditingController();
  final instructionsController = TextEditingController();

  String type = _assignmentTypes.first;
  DateTime? dueAt;
  AssignmentDetail? assignment;
  bool isLoading = false;
  bool isSaving = false;

  bool get isEditing => widget.assignmentId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) loadAssignment();
  }

  Future<void> loadAssignment() async {
    setState(() => isLoading = true);
    try {
      final result = await AssignmentService.getAssignment(
        widget.assignmentId!,
      );
      if (!mounted) return;
      setState(() {
        assignment = result;
        titleController.text = result.title;
        instructionsController.text = result.instructions ?? '';
        type = result.type;
        dueAt = result.dueAt;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดข้อมูลงานไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> save() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่องาน')));
      return;
    }

    setState(() => isSaving = true);
    try {
      if (isEditing) {
        await AssignmentService.updateAssignment(
          assignmentId: widget.assignmentId!,
          title: titleController.text,
          instructions: instructionsController.text.trim().isEmpty
              ? null
              : instructionsController.text.trim(),
          dueAt: dueAt,
        );
        await loadAssignment();
      } else {
        final newAssignmentId = await AssignmentService.createAssignment(
          courseId: widget.courseId!,
          type: type,
          title: titleController.text,
          instructions: instructionsController.text.trim().isEmpty
              ? null
              : instructionsController.text.trim(),
          dueAt: dueAt,
        );
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentFormPage(assignmentId: newAssignmentId),
          ),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกแล้ว')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> publish() async {
    try {
      await AssignmentService.publishAssignment(widget.assignmentId!);
      await loadAssignment();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เผยแพร่งานแล้ว'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('เผยแพร่ไม่สำเร็จ: $e')));
    }
  }

  Future<void> pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dueAt ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) setState(() => dueAt = picked);
  }

  Future<void> linkSensor() async {
    List<DeviceOption> devices;
    try {
      devices = await LessonService.listSchoolDevices();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดรายชื่ออุปกรณ์ไม่สำเร็จ: $e')),
      );
      return;
    }
    if (devices.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('โรงเรียนยังไม่มีอุปกรณ์เซนเซอร์ลงทะเบียนไว้'),
        ),
      );
      return;
    }

    String deviceId = devices.first.id;
    String metric = _metricTypes.first;
    final labelCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('ผูกข้อมูลเซนเซอร์จริงกับงาน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: deviceId,
                decoration: const InputDecoration(labelText: 'อุปกรณ์'),
                items: devices
                    .map(
                      (d) => DropdownMenuItem(
                        value: d.id,
                        child: Text('${d.name} (${d.location ?? "-"})'),
                      ),
                    )
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => deviceId = value ?? deviceId),
              ),
              DropdownButtonFormField<String>(
                value: metric,
                decoration: const InputDecoration(labelText: 'ค่าที่วัด'),
                items: _metricTypes
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => metric = value ?? metric),
              ),
              TextField(
                controller: labelCtrl,
                decoration: const InputDecoration(
                  labelText: 'คำอธิบาย (ไม่บังคับ)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ผูกข้อมูล'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      await AssignmentService.linkSensorDataset(
        assignmentId: widget.assignmentId!,
        deviceId: deviceId,
        metric: metric,
        timeStart: DateTime.now().subtract(const Duration(days: 7)),
        timeEnd: DateTime.now(),
        label: labelCtrl.text.trim().isEmpty ? null : labelCtrl.text.trim(),
      );
      await loadAssignment();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ผูกข้อมูลไม่สำเร็จ: $e')));
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขงาน' : 'สร้างงานใหม่'),
        actions: [
          if (isEditing && assignment != null)
            IconButton(
              icon: const Icon(Icons.people_outline),
              tooltip: 'ดูงานที่ส่งแล้ว',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmissionReviewPage(
                      assignmentId: widget.assignmentId!,
                    ),
                  ),
                );
              },
            ),
          if (isEditing && assignment != null && !assignment!.isPublished)
            TextButton(
              onPressed: publish,
              child: const Text(
                'เผยแพร่',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Chip(
                      label: Text(
                        assignment?.isPublished == true
                            ? 'เผยแพร่แล้ว'
                            : 'ฉบับร่าง',
                      ),
                      backgroundColor: assignment?.isPublished == true
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                    ),
                  ),
                DropdownButtonFormField<String>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'ประเภทงาน'),
                  items: _assignmentTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: isEditing
                      ? null
                      : (value) => setState(() => type = value ?? type),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'ชื่องาน'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: instructionsController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'คำสั่งงาน',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event),
                  title: Text(
                    dueAt == null
                        ? 'ยังไม่กำหนดวันส่ง'
                        : 'กำหนดส่ง: ${dueAt!.day}/${dueAt!.month}/${dueAt!.year + 543}',
                  ),
                  trailing: TextButton(
                    onPressed: pickDueDate,
                    child: const Text('เลือกวันที่'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : save,
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'บันทึก' : 'สร้างงาน'),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ข้อมูลเซนเซอร์ที่ผูกไว้',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: linkSensor,
                        icon: const Icon(Icons.sensors),
                        label: const Text('ผูกข้อมูล'),
                      ),
                    ],
                  ),
                  if (assignment?.sensorDatasets.isEmpty ?? true)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'ยังไม่มีข้อมูลเซนเซอร์ผูกกับงานนี้',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...?assignment?.sensorDatasets.map(
                      (d) => ListTile(
                        leading: const Icon(Icons.sensors),
                        title: Text(d.metric),
                        subtitle: Text(d.label ?? ''),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
