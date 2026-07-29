import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

/// Professional Enterprise Lesson View Page (Clean, Emoji-Free Layout)
class LessonViewPage extends StatefulWidget {
  const LessonViewPage({super.key, required this.lessonId});

  final String lessonId;

  @override
  State<LessonViewPage> createState() => _LessonViewPageState();
}

class _LessonViewPageState extends State<LessonViewPage> {
  LessonDetail? lesson;
  bool isLoading = true;
  bool isMarkingComplete = false;
  String? errorMessage;
  final Map<String, List<({DateTime ts, num value})>> sensorHistory = {};

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });
    try {
      final result = await LessonService.getLesson(widget.lessonId);
      if (!mounted) return;
      setState(() => lesson = result);

      if ((result.progressPct ?? 0) < 10) {
        unawaited(
          LessonService.updateProgress(lessonId: widget.lessonId, progressPct: 10),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => errorMessage = 'โหลดบทเรียนไม่สำเร็จ: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> markComplete() async {
    setState(() => isMarkingComplete = true);
    try {
      await LessonService.markComplete(widget.lessonId);
      setState(() {
        lesson = LessonDetail(
          id: lesson!.id,
          courseId: lesson!.courseId,
          title: lesson!.title,
          content: lesson!.content,
          status: lesson!.status,
          publishedAt: lesson!.publishedAt,
          materials: lesson!.materials,
          sensorLinks: lesson!.sensorLinks,
          progressPct: 100,
          completed: true,
        );
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('บันทึกสถานะเรียนจบแล้วเรียบร้อย'),
          backgroundColor: Color(0xFF059669),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('บันทึกสถานะไม่สำเร็จ: $e')),
      );
    } finally {
      if (mounted) setState(() => isMarkingComplete = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          lesson?.title ?? 'บทเรียน',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0284C7)))
          : errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(errorMessage!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: load,
                          child: const Text('ลองใหม่'),
                        ),
                      ],
                    ),
                  ),
                )
              : lesson == null
                  ? const Center(child: Text('ไม่พบบทเรียน'))
                  : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (lesson!.completed == true)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF059669).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF059669).withOpacity(0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, color: Color(0xFF059669), size: 20),
                              SizedBox(width: 10),
                              Text(
                                'สถานะ: เรียนจบแล้ว (100%)',
                                style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0284C7).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF0284C7), size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lesson!.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text('วิชา SC30201: AIoT ชีววิทยาและสิ่งแวดล้อม', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 30),
                          if (lesson!.content?['body'] != null)
                            Text(
                              lesson!.content!['body'] as String,
                              style: const TextStyle(fontSize: 14.5, height: 1.7, color: Color(0xFF1E293B)),
                            ),
                        ],
                      ),
                    ),
                    if (lesson!.materials.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        'สื่อเอกสารประกอบการเรียน',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 12),
                      ...lesson!.materials.map(
                        (m) => Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF0284C7), size: 20),
                            ),
                            title: Text(m.title ?? m.url, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                            subtitle: Text('ประเภท: ${m.type}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0284C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('เปิดอ่าน', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    if (lesson!.completed != true)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isMarkingComplete ? null : markComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: isMarkingComplete
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check_circle_outline_rounded, size: 20),
                          label: const Text('ทำเครื่องหมายว่าเรียนจบแล้ว', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                  ],
                ),
    );
  }
}
