import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

const _materialTypes = ['video', 'file', 'link', 'image'];
const _metricTypes = [
  'pm25',
  'aqi',
  'temperature',
  'humidity',
  'light_lux',
  'energy_kwh',
  'power_w',
];

/// สร้าง/แก้ไขบทเรียน (LRN-1..6,10) รวมแนบสื่อ (LRN-2) และผูกข้อมูล AIoT
/// จริงจาก sensor_readings เข้าบทเรียน (LRN-8)
///
/// โหมดสร้าง: ส่ง [courseId] มาเฉยๆ · โหมดแก้ไข: ส่ง [lessonId] มา
class LessonFormPage extends StatefulWidget {
  const LessonFormPage({super.key, this.courseId, this.lessonId})
    : assert(
        courseId != null || lessonId != null,
        'ต้องระบุ courseId (สร้างใหม่) หรือ lessonId (แก้ไข) อย่างใดอย่างหนึ่ง',
      );

  final String? courseId;
  final String? lessonId;

  @override
  State<LessonFormPage> createState() => _LessonFormPageState();
}

class _LessonFormPageState extends State<LessonFormPage> {
  final titleController = TextEditingController();
  final bodyController = TextEditingController();

  LessonDetail? lesson;
  bool isLoading = false;
  bool isSaving = false;

  bool get isEditing => widget.lessonId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) loadLesson();
  }

  Future<void> loadLesson() async {
    setState(() => isLoading = true);
    try {
      final result = await LessonService.getLesson(widget.lessonId!);
      if (!mounted) return;
      setState(() {
        lesson = result;
        titleController.text = result.title;
        bodyController.text = result.content?['body'] as String? ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('โหลดบทเรียนไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> saveTitleAndContent() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('กรุณากรอกชื่อบทเรียน')));
      return;
    }

    // หน้านี้แก้ได้แค่ข้อความก้อนเดียว ถ้าบทเรียนถูกจัดเป็นบล็อกมาจากหน้า
    // แก้ไขบทเรียนของเลนใหม่ การบันทึกทับจะลบรูปแบบทั้งหมดทิ้ง — ตั้งแต่
    // นักเรียนอ่าน content['blocks'] จริง (2026-09-22) นี่คือการลบข้อมูล
    // ที่นักเรียนเห็นอยู่ จึงต้องถามก่อน ไม่ใช่ทำเงียบ ๆ
    final existingBlocks = lessonBlocksFromContent(lesson?.content);
    if (existingBlocks.isNotEmpty) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('บทเรียนนี้จัดเนื้อหาเป็นบล็อก'),
          content: Text(
            'บทเรียนนี้มีบล็อกอยู่ ${existingBlocks.length} บล็อก '
            '(หัวข้อ กล่องเตือน กล่องสรุป ฯลฯ) ที่นักเรียนเห็นอยู่ตอนนี้\n\n'
            'บันทึกจากหน้านี้จะแทนที่ด้วยข้อความก้อนเดียว และรูปแบบทั้งหมด '
            'จะหายถาวร — ถ้าต้องการคงรูปแบบไว้ ให้กลับไปแก้ที่หน้าแก้ไข '
            'บทเรียนแทน',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('ลบรูปแบบและบันทึก'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    setState(() => isSaving = true);
    try {
      final content = {'body': bodyController.text.trim()};
      if (isEditing) {
        await LessonService.updateLesson(
          lessonId: widget.lessonId!,
          title: titleController.text,
          content: content,
        );
        await loadLesson();
      } else {
        final newLessonId = await LessonService.createLesson(
          courseId: widget.courseId!,
          title: titleController.text,
          content: content,
        );
        if (!mounted) return;
        // สลับไปโหมดแก้ไขเพื่อแนบสื่อ/ผูกเซนเซอร์/เผยแพร่ต่อได้ทันที
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LessonFormPage(lessonId: newLessonId),
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
      await LessonService.publishLesson(widget.lessonId!);
      await loadLesson();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('เผยแพร่บทเรียนแล้ว'),
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

  Future<void> addMaterial() async {
    final titleCtrl = TextEditingController();
    final urlCtrl = TextEditingController();
    String type = _materialTypes.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('แนบสื่อการเรียน'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'ประเภท'),
                items: _materialTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (value) =>
                    setDialogState(() => type = value ?? type),
              ),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'ชื่อสื่อ'),
              ),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(labelText: 'URL'),
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
              child: const Text('แนบ'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || urlCtrl.text.trim().isEmpty) return;

    try {
      await LessonService.addLessonMaterial(
        lessonId: widget.lessonId!,
        type: type,
        title: titleCtrl.text.trim().isEmpty ? null : titleCtrl.text.trim(),
        url: urlCtrl.text,
      );
      await loadLesson();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('แนบสื่อไม่สำเร็จ: $e')));
    }
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
    final captionCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('ผูกข้อมูลเซนเซอร์จริงกับบทเรียน'),
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
                controller: captionCtrl,
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
      await LessonService.linkLessonSensor(
        lessonId: widget.lessonId!,
        deviceId: deviceId,
        metric: metric,
        timeStart: DateTime.now().subtract(const Duration(days: 1)),
        timeEnd: DateTime.now(),
        caption: captionCtrl.text.trim().isEmpty
            ? null
            : captionCtrl.text.trim(),
      );
      await loadLesson();
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
    bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'แก้ไขบทเรียน' : 'สร้างบทเรียนใหม่'),
        actions: [
          if (isEditing && lesson != null && !lesson!.isPublished)
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
                        lesson?.isPublished == true
                            ? 'เผยแพร่แล้ว'
                            : 'ฉบับร่าง',
                      ),
                      backgroundColor: lesson?.isPublished == true
                          ? Colors.green.shade100
                          : Colors.grey.shade300,
                    ),
                  ),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'ชื่อบทเรียน'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bodyController,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'เนื้อหาบทเรียน',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveTitleAndContent,
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'บันทึกเนื้อหา' : 'สร้างบทเรียน'),
                  ),
                ),
                if (isEditing) ...[
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'สื่อการเรียน',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextButton.icon(
                        onPressed: addMaterial,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('แนบ'),
                      ),
                    ],
                  ),
                  ...?lesson?.materials.map(
                    (m) => ListTile(
                      leading: const Icon(Icons.insert_drive_file),
                      title: Text(m.title ?? m.url),
                      subtitle: Text(m.type),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ข้อมูลเซนเซอร์ที่ผูกไว้',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (lesson?.sensorLinks.isEmpty ?? true)
                        TextButton.icon(
                          onPressed: linkSensor,
                          icon: const Icon(Icons.sensors),
                          label: const Text('ผูกข้อมูล'),
                        ),
                    ],
                  ),
                  if (lesson?.sensorLinks.isEmpty ?? true)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'ยังไม่มีข้อมูลเซนเซอร์ผูกกับบทเรียนนี้',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  else
                    ...?lesson?.sensorLinks.map(
                      (link) => ListTile(
                        leading: const Icon(Icons.sensors),
                        title: Text(link.metric),
                        subtitle: Text(link.caption ?? ''),
                      ),
                    ),
                ],
              ],
            ),
    );
  }
}
