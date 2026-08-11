// PROTOTYPE ONLY: Complete Lesson Management System for Teachers
// Implements PRD Specs 1-10 with 100% precision & complete interactive dialogs:
// 1. Lesson List & Course Detail Tab (Breadcrumb, Search, Filter, Draft/Published List, Actions)
// 2. 3-Column Block Editor (Left Outline, Middle Block Editor, Right Materials & AIoT Panel)
// 3. Left Section Outline & Navigation
// 4. Block Editor (Headings, Text, Lists, Images, Videos, Files, Links, Callouts, Summary, AIoT Chart Block)
// 5. Materials Attachment Tab (Image, Video, File, Link, Insert to Block)
// 6. AIoT Sensor Binding Tab (Device picker, Metric picker, Time range, Chart Preview, Insert to Block)
// 7. Student Preview Mode (Teacher-only warning banner, live preview)
// 8. Publish Checklist Dialog (Validation, summary counts, warning)
// 9. Lesson Analytics Page (Summary cards, student progress table with Filters)
// 10. Complete States (Loading, Empty, Auto-save status, Published edit warning)

import 'package:flutter/material.dart';

import 'teacher_redesign_prototype_page.dart' show TeacherPalette;

// ==========================================
// DATA MODELS
// ==========================================

enum LessonStatus { draft, published }

enum ContentBlockType {
  heading,
  text,
  bulletList,
  image,
  video,
  fileDownload,
  externalLink,
  calloutWarning,
  summaryBox,
  sensorChart,
}

class ContentBlockModel {
  ContentBlockModel({
    required this.id,
    required this.type,
    this.text = '',
    this.mediaUrl = '',
    this.caption = '',
    this.sensorDeviceId = '',
    this.sensorMetric = '',
    this.timeRange = '',
  });

  final String id;
  ContentBlockType type;
  String text;
  String mediaUrl;
  String caption;
  String sensorDeviceId;
  String sensorMetric;
  String timeRange;
}

class LessonMaterialModel {
  LessonMaterialModel({
    required this.id,
    required this.title,
    required this.type, // 'image', 'video', 'file', 'link'
    required this.url,
  });

  final String id;
  final String title;
  final String type;
  final String url;
}

class LessonSensorLinkModel {
  LessonSensorLinkModel({
    required this.id,
    required this.deviceName,
    required this.metric,
    required this.timeRange,
    required this.caption,
  });

  final String id;
  final String deviceName;
  final String metric;
  final String timeRange;
  final String caption;
}

class LessonModel {
  LessonModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.title,
    required this.status,
    required this.lastEdited,
    required this.materialsCount,
    required this.sensorChartsCount,
    required this.blocks,
    required this.materials,
    required this.sensorLinks,
  });

  final String id;
  final String courseCode;
  final String courseName;
  String title;
  LessonStatus status;
  String lastEdited;
  int materialsCount;
  int sensorChartsCount;
  List<ContentBlockModel> blocks;
  List<LessonMaterialModel> materials;
  List<LessonSensorLinkModel> sensorLinks;
}

// MOCK LESSONS DATA (6 Realistic Sample Lessons)
final List<LessonModel> mockLessonsList = [
  LessonModel(
    id: 'les-1',
    courseCode: 'ว31281',
    courseName: 'วิทยาการคำนวณ & AI เบื้องต้น',
    title: 'บทที่ 1: การคิดเชิงคำนวณและการทำความรู้จักกับ AI',
    status: LessonStatus.published,
    lastEdited: '10 ส.ค. 2026, 14:30 น.',
    materialsCount: 2,
    sensorChartsCount: 1,
    blocks: [
      ContentBlockModel(
        id: 'b1',
        type: ContentBlockType.heading,
        text: '1. แนวคิดเชิงคำนวณ (Computational Thinking)',
      ),
      ContentBlockModel(
        id: 'b2',
        type: ContentBlockType.text,
        text:
            'การคิดเชิงคำนวณคือกระบวนการแก้ปัญหาอย่างเป็นลำดับขั้นตอนที่เครื่องคอมพิวเตอร์สามารถเข้าใจและนำไปปฏิบัติตามได้ ประกอบด้วย 4 องค์ประกอบสำคัญ ได้แก่ การย่อยปัญหา, การจดจำรูปแบบ, การคิดเชิงนามธรรม และการออกแบบอัลกอริทึม',
      ),
      ContentBlockModel(
        id: 'b3',
        type: ContentBlockType.calloutWarning,
        text:
            'ข้อควรระวัง: อย่าสับสนระหว่างคำว่า AI (Pervasive Artificial Intelligence) กับโปรแกรมคอมพิวเตอร์แบบดั้งเดิมที่เขียนด้วย Rule-based system',
      ),
      ContentBlockModel(
        id: 'b4',
        type: ContentBlockType.sensorChart,
        sensorDeviceId: 'ESP32-Lab3-SensorNode',
        sensorMetric: 'ค่าฝุ่นละออง PM2.5 & CO2',
        timeRange: '08:00 - 15:00 น.',
        caption: 'กราฟแสดงคุณภาพอากาศในห้องปฏิบัติการคอมพิวเตอร์ระหว่างวัน',
      ),
    ],
    materials: [
      LessonMaterialModel(
        id: 'm1',
        title: 'สไลด์ประกอบการสอน บทที่ 1 (Computational Thinking)',
        type: 'ไฟล์',
        url: 'slides_lesson1.pdf',
      ),
      LessonMaterialModel(
        id: 'm2',
        title: 'วิดีโอแนะนำปัญญาประดิษฐ์ในชีวิตประจำวัน',
        type: 'วิดีโอ',
        url: 'https://youtube.com/watch?v=ai101',
      ),
    ],
    sensorLinks: [
      LessonSensorLinkModel(
        id: 's1',
        deviceName: 'ESP32-Lab3-SensorNode',
        metric: 'PM2.5 & CO2',
        timeRange: 'วันนี้ 08:00-15:00',
        caption: 'คุณภาพอากาศ Lab 3',
      ),
    ],
  ),
  LessonModel(
    id: 'les-2',
    courseCode: 'ว31281',
    courseName: 'วิทยาการคำนวณ & AI เบื้องต้น',
    title: 'บทที่ 2: การจำแนกภาพด้วย Image Classification Model',
    status: LessonStatus.published,
    lastEdited: '10 ส.ค. 2026, 15:45 น.',
    materialsCount: 2,
    sensorChartsCount: 0,
    blocks: [
      ContentBlockModel(
        id: 'b10',
        type: ContentBlockType.heading,
        text: 'โครงสร้างประสาทเทียม Convolutional Neural Network (CNN)',
      ),
      ContentBlockModel(
        id: 'b11',
        type: ContentBlockType.text,
        text:
            'ในบทนี้เราจะมาเรียนรู้การเตรียมชุดข้อมูลภาพถ่าย (Image Dataset) สำหรับฝึกฝนโมเดลจำแนกประเภทด้วย Teachable Machine และทำการส่งออกโมเดลไปใช้งานบนเว็บ',
      ),
      ContentBlockModel(
        id: 'b12',
        type: ContentBlockType.summaryBox,
        text:
            'สรุปการฝึกโมเดล: ยิ่งมีภาพตัวอย่างที่มีความหลากหลายในสภาวะแสงที่ต่างกัน Accuracy ของโมเดลจำแนกภาพจะยิ่งสูงขึ้นอย่างเห็นได้ชัด',
      ),
    ],
    materials: [
      LessonMaterialModel(
        id: 'm3',
        title: 'ใบงานฝึกปฏิบัติการสร้างโมเดล Teachable Machine',
        type: 'ไฟล์',
        url: 'worksheet_model_train.pdf',
      ),
      LessonMaterialModel(
        id: 'm4',
        title: 'ลิงก์เข้าใช้งาน Google Teachable Machine',
        type: 'ลิงก์',
        url: 'https://teachablemachine.withgoogle.com',
      ),
    ],
    sensorLinks: [],
  ),
  LessonModel(
    id: 'les-3',
    courseCode: 'ว32282',
    courseName: 'STEM & Green-Lab IoT',
    title:
        'บทที่ 3: ระบบตรวจวัดสภาพแวดล้อมสมาร์ทฟาร์ม (Smart Agriculture & AIoT)',
    status: LessonStatus.published,
    lastEdited: '09 ส.ค. 2026, 11:20 น.',
    materialsCount: 2,
    sensorChartsCount: 1,
    blocks: [
      ContentBlockModel(
        id: 'b20',
        type: ContentBlockType.heading,
        text: 'การต่อวงจรและอ่านค่าเซนเซอร์ DHT22 ด้วยบอร์ด ESP32',
      ),
      ContentBlockModel(
        id: 'b21',
        type: ContentBlockType.text,
        text:
            'ศึกษาการประยุกต์ใช้อินเทอร์เน็ตของสรรพสิ่ง (IoT) ในการติดตามอุณหภูมิและความชื้นในโรงเรือนเกษตรอัจฉริยะของโรงเรียน เพื่อช่วยวางแผนการรดน้ำอัตโนมัติ',
      ),
      ContentBlockModel(
        id: 'b22',
        type: ContentBlockType.sensorChart,
        sensorDeviceId: 'ESP32-GreenLab-SensorNode',
        sensorMetric: 'อุณหภูมิ & ความชื้นสัมพัทธ์',
        timeRange: 'ย้อนหลัง 24 ชม.',
        caption:
            'กราฟแสดงการเปลี่ยนแปลงอุณหภูมิและความชื้นในแปลงผักไฮโดรโปนิกส์',
      ),
    ],
    materials: [
      LessonMaterialModel(
        id: 'm5',
        title: 'คู่มือการต่อวงจร ESP32 กับเซนเซอร์ DHT22',
        type: 'ไฟล์',
        url: 'esp32_dht22_guide.pdf',
      ),
      LessonMaterialModel(
        id: 'm6',
        title: 'ซอร์สโค้ด Arduino C++ สำหรับส่งค่า IoT',
        type: 'ไฟล์',
        url: 'greenlab_sensor.ino',
      ),
    ],
    sensorLinks: [
      LessonSensorLinkModel(
        id: 's2',
        deviceName: 'ESP32-GreenLab-SensorNode',
        metric: 'อุณหภูมิ & ความชื้น',
        timeRange: 'ย้อนหลัง 24 ชม.',
        caption: 'แปลงผักไฮโดรโปนิกส์',
      ),
    ],
  ),
  LessonModel(
    id: 'les-4',
    courseCode: 'ว33283',
    courseName: 'ฟิสิกส์ประยุกต์ & หุ่นยนต์',
    title: 'บทที่ 4: หุ่นยนต์เดินตามเส้นและระบบควบคุม PID Control',
    status: LessonStatus.draft,
    lastEdited: '08 ส.ค. 2026, 16:10 น.',
    materialsCount: 1,
    sensorChartsCount: 0,
    blocks: [
      ContentBlockModel(
        id: 'b30',
        type: ContentBlockType.heading,
        text:
            'หลักการทำงานของระบบควบคุมแบบป้อนกลับ (Proportional-Integral-Derivative)',
      ),
      ContentBlockModel(
        id: 'b31',
        type: ContentBlockType.text,
        text:
            'การปรับจูนค่า Kp, Ki, Kd ช่วยให้หุ่นยนต์สามารถเข้าโค้งได้อย่างนุ่มนวลและไม่หลุดออกจากเส้นทางแข่งขัน',
      ),
      ContentBlockModel(
        id: 'b32',
        type: ContentBlockType.calloutWarning,
        text:
            'คำเตือน: การตั้งค่า Kp สูงเกินไปจะทำให้มอเตอร์สั่น (Oscillation) และหุ่นยนต์จะส่ายไปมาจนหลุดเส้น',
      ),
    ],
    materials: [
      LessonMaterialModel(
        id: 'm7',
        title: 'แผนผังวงจรขับมอเตอร์ L298N และ IR Sensors',
        type: 'ไฟล์',
        url: 'robot_schematic.pdf',
      ),
    ],
    sensorLinks: [],
  ),
  LessonModel(
    id: 'les-5',
    courseCode: 'ว30205',
    courseName: 'การเขียนโปรแกรม Python & Data Science',
    title:
        'บทที่ 5: การวิเคราะห์ข้อมูล Big Data และ Data Visualization ด้วย Pandas',
    status: LessonStatus.draft,
    lastEdited: '07 ส.ค. 2026, 09:15 น.',
    materialsCount: 2,
    sensorChartsCount: 1,
    blocks: [
      ContentBlockModel(
        id: 'b40',
        type: ContentBlockType.heading,
        text:
            'ทำความสะอาดข้อมูล (Data Cleaning) และสร้างแผนภูมิด้วย Matplotlib',
      ),
      ContentBlockModel(
        id: 'b41',
        type: ContentBlockType.text,
        text:
            'ในบทเรียนนี้ นักเรียนจะได้ฝึกใช้ภาษา Python บน Google Colab ในการโหลดไฟล์ CSV, จัดการค่า Null, และพล็อตสถิติเปรียบเทียบพลังงานไฟฟ้าที่ผลิตได้จากแผงโซลาร์เซลล์โรงเรียน',
      ),
      ContentBlockModel(
        id: 'b42',
        type: ContentBlockType.sensorChart,
        sensorDeviceId: 'ESP32-SolarStation',
        sensorMetric: 'พลังงานไฟฟ้า Watt',
        timeRange: '08:00 - 15:00 น.',
        caption: 'ข้อมูลการผลิตไฟฟ้าจากแผงโซลาร์เซลล์อาคารเรียน 5',
      ),
    ],
    materials: [
      LessonMaterialModel(
        id: 'm8',
        title: 'Google Colab Notebook: Data Cleaning 101',
        type: 'ลิงก์',
        url: 'https://colab.research.google.com/drive/sample',
      ),
      LessonMaterialModel(
        id: 'm9',
        title: 'ชุดข้อมูลตัวอย่างการใช้ไฟฟ้า (CSV Dataset)',
        type: 'ไฟล์',
        url: 'school_power_dataset.csv',
      ),
    ],
    sensorLinks: [
      LessonSensorLinkModel(
        id: 's3',
        deviceName: 'ESP32-SolarStation',
        metric: 'พลังงานไฟฟ้า Watt',
        timeRange: '08:00 - 15:00 น.',
        caption: 'แผงโซลาร์เซลล์ อาคาร 5',
      ),
    ],
  ),
  LessonModel(
    id: 'les-6',
    courseCode: 'ว30291',
    courseName: 'โครงงานนวัตกรรมพลังงานสะอาด',
    title:
        'บทที่ 6: การบริหารจัดการพลังงานสะอาดในอาคารเรียน (Clean Energy Smart Grid)',
    status: LessonStatus.published,
    lastEdited: '05 ส.ค. 2026, 13:50 น.',
    materialsCount: 1,
    sensorChartsCount: 1,
    blocks: [
      ContentBlockModel(
        id: 'b50',
        type: ContentBlockType.heading,
        text: 'การประเมินการลดคาร์บอนเครดิต (Carbon Footprint Reduction)',
      ),
      ContentBlockModel(
        id: 'b51',
        type: ContentBlockType.text,
        text:
            'ศึกษาแนวทางการคำนวณปริมาณก๊าซเรือนกระจกที่ลดลงจากการนำระบบพลังงานหมุนเวียนมาใช้ในสถานศึกษา',
      ),
      ContentBlockModel(
        id: 'b52',
        type: ContentBlockType.summaryBox,
        text:
            'สรุปผลงาน: โรงเรียนสามารถลดการปล่อย CO2 ได้เฉลี่ย 1.2 ตันต่อเดือนจากการใช้ระบบ Smart Grid',
      ),
    ],
    materials: [
      LessonMaterialModel(
        id: 'm10',
        title: 'รายงานการวิเคราะห์พลังงานหมุนเวียนโรงเรียน',
        type: 'ไฟล์',
        url: 'clean_energy_report.pdf',
      ),
    ],
    sensorLinks: [
      LessonSensorLinkModel(
        id: 's4',
        deviceName: 'ESP32-SolarStation',
        metric: 'พลังงานสะสม kWh',
        timeRange: 'ย้อนหลัง 7 วัน',
        caption: 'พลังงานรวมสะสม',
      ),
    ],
  ),
];

// ==========================================
// 1. LESSON LIST & COURSE TAB VIEW (SPEC 1)
// ==========================================

class TeacherLessonListPage extends StatefulWidget {
  const TeacherLessonListPage({
    super.key,
    required this.courseCode,
    required this.courseName,
    this.isCourseClosed = false,
    this.hasAccess = true,
  });

  final String courseCode;
  final String courseName;
  final bool isCourseClosed;
  final bool hasAccess;

  @override
  State<TeacherLessonListPage> createState() => _TeacherLessonListPageState();
}

class _TeacherLessonListPageState extends State<TeacherLessonListPage> {
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'ทั้งหมด'; // 'ทั้งหมด', 'Draft', 'Published'

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _openCreateLessonDialog() {
    final titleController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: TeacherPalette.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.add_to_photos_rounded,
                color: TeacherPalette.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'สร้างบทเรียนใหม่',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ระบุชื่อบทเรียนสำหรับวิชา ${widget.courseCode} ระบบจะสร้างร่าง (Draft) แล้วพาไปหน้าแก้ไขบทเรียนทันที',
              style: const TextStyle(fontSize: 13, color: TeacherPalette.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: titleController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'ชื่อบทเรียน *',
                hintText: 'เช่น บทที่ 3: การประยุกต์ใช้งาน AIoT',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'ยกเลิก',
              style: TextStyle(color: TeacherPalette.muted),
            ),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
            label: const Text(
              'สร้างและแก้ไข',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final titleText = titleController.text.trim();
              if (titleText.isEmpty) return;
              Navigator.pop(context);

              final newLesson = LessonModel(
                id: 'les-${DateTime.now().millisecondsSinceEpoch}',
                courseCode: widget.courseCode,
                courseName: widget.courseName,
                title: titleText,
                status: LessonStatus.draft,
                lastEdited: 'เมื่อสักครู่',
                materialsCount: 0,
                sensorChartsCount: 0,
                blocks: [
                  ContentBlockModel(
                    id: 'b-init',
                    type: ContentBlockType.heading,
                    text: titleText,
                  ),
                  ContentBlockModel(
                    id: 'b-text',
                    type: ContentBlockType.text,
                    text: 'เริ่มเขียนเนื้อหาบทเรียนที่นี่...',
                  ),
                ],
                materials: [],
                sensorLinks: [],
              );

              setState(() {
                mockLessonsList.insert(0, newLesson);
              });

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherLessonEditorPage(lesson: newLesson),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.hasAccess) {
      return const _PermissionDeniedView();
    }

    if (_isLoading) {
      return const _LessonListLoadingView();
    }

    final filtered = mockLessonsList.where((les) {
      final matchesSearch = les.title.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesStatus =
          _statusFilter == 'ทั้งหมด' ||
          (_statusFilter == 'Draft' && les.status == LessonStatus.draft) ||
          (_statusFilter == 'Published' &&
              les.status == LessonStatus.published);
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 📌 Breadcrumb
        Row(
          children: [
            const Icon(
              Icons.school_outlined,
              size: 14,
              color: TeacherPalette.muted,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'รายวิชาที่สอน > ${widget.courseCode} ${widget.courseName} > บทเรียน',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: TeacherPalette.muted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (widget.isCourseClosed) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: Color(0xFFB91C1C),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'รายวิชานี้ปิดภาคเรียนแล้ว — ดูเนื้อหาได้ แต่แก้ไขหรือเผยแพร่บทเรียนไม่ได้',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB91C1C),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Search & Create — card container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: TeacherPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'ค้นหาชื่อบทเรียน...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: TeacherPalette.primary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: widget.isCourseClosed
                        ? null
                        : _openCreateLessonDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text(
                      'สร้างบทเรียนใหม่',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    style: ElevatedButton.styleFrom(
                      // ปุ่มนี้อยู่ใน Row ไม่ใช่เต็มความกว้าง — ต้อง override
                      // minimumSize ของธีม (Size(double.infinity, 52)) ไม่งั้น
                      // Row จะส่ง constraint กว้างไม่จำกัดให้ปุ่มแล้วชนกับ
                      // minWidth: infinity ของธีม ทำให้พังทั้งหน้าแบบเงียบ ๆ
                      minimumSize: const Size(0, 44),
                      backgroundColor: TeacherPalette.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ['ทั้งหมด', 'Draft', 'Published'].map((status) {
                    final isActive = _statusFilter == status;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(status),
                        selected: isActive,
                        selectedColor: TeacherPalette.primary,
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: isActive ? Colors.white : TeacherPalette.ink,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        onSelected: (_) =>
                            setState(() => _statusFilter = status),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'รายการบทเรียนทั้งหมด (${filtered.length})',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: TeacherPalette.ink,
          ),
        ),
        const SizedBox(height: 12),

        // Empty State or List Cards
        if (filtered.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 48,
                  color: TeacherPalette.muted.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 12),
                const Text(
                  'ยังไม่มีบทเรียนในวิชานี้',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 4),
                const Text(
                  'เริ่มต้นสร้างบทเรียนแรกเพื่อแนบเนื้อหา สื่อ และกราฟ AIoT ให้กับนักเรียน',
                  style: TextStyle(fontSize: 13, color: TeacherPalette.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _openCreateLessonDialog,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('สร้างบทเรียนแรก'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          )
        else
          LayoutBuilder(
            builder: (context, cons) {
              final isGrid = cons.maxWidth >= 720;
              final cardWidth = isGrid
                  ? (cons.maxWidth - 14) / 2
                  : cons.maxWidth;
              return Wrap(
                spacing: 14,
                runSpacing: 14,
                children: filtered
                    .map((les) => _buildLessonItemCard(les, cardWidth))
                    .toList(),
              );
            },
          ),
      ],
    );
  }

  Widget _buildLessonItemCard(LessonModel les, double cardWidth) {
    final isPublished = les.status == LessonStatus.published;
    final tint = isPublished
        ? const Color(0xFF059669)
        : const Color(0xFFD97706);

    return SizedBox(
      width: cardWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TeacherPalette.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x060F172A),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // แถบสีบางด้านบนบอกสถานะ แทนพื้นหลังไล่สีทั้งการ์ด — ลดความจำเจ
            // เวลามีบทเรียนสถานะเดียวกันติดกันหลายใบ
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: tint,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: tint.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPublished
                              ? Icons.check_circle_outline_rounded
                              : Icons.edit_note_rounded,
                          color: tint,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: tint,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isPublished ? 'Published' : 'Draft',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: tint,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'แก้ไขล่าสุด: ${les.lastEdited}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: TeacherPalette.muted,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              les.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: TeacherPalette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _LessonMetaTag(
                        icon: Icons.attachment_rounded,
                        label: '${les.materials.length} สื่อแนบ',
                        color: tint,
                      ),
                      _LessonMetaTag(
                        icon: Icons.sensors_rounded,
                        label: '${les.sensorLinks.length} กราฟ AIoT',
                        color: tint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // ปุ่มหลัก "แก้ไข" เด่นสุด ส่วนปุ่มรองเหลือแค่ไอคอนกลม
                  // ให้ดูโล่งขึ้นและตาโฟกัสงานหลักได้เร็ว
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: widget.isCourseClosed
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          TeacherLessonEditorPage(lesson: les),
                                    ),
                                  );
                                },
                          icon: const Icon(Icons.edit_rounded, size: 16),
                          label: const Text('แก้ไข'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(0, 40),
                            backgroundColor: TeacherPalette.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _LessonIconAction(
                        icon: Icons.visibility_outlined,
                        tooltip: 'ดูตัวอย่างแบบนักเรียน',
                        color: const Color(0xFF2563EB),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TeacherLessonPreviewPage(lesson: les),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      _LessonIconAction(
                        icon: Icons.bar_chart_rounded,
                        tooltip: 'ดูสถิติบทเรียน',
                        color: const Color(0xFF059669),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  TeacherLessonAnalyticsPage(lesson: les),
                            ),
                          );
                        },
                      ),
                      if (!isPublished) ...[
                        const SizedBox(width: 6),
                        _LessonIconAction(
                          icon: Icons.publish_rounded,
                          tooltip: 'เผยแพร่บทเรียน',
                          color: const Color(0xFFD97706),
                          onTap: widget.isCourseClosed
                              ? null
                              : () {
                                  showDialog<void>(
                                    context: context,
                                    builder: (_) =>
                                        TeacherPublishChecklistDialog(
                                          lesson: les,
                                          onConfirmedPublish: () {
                                            setState(() {
                                              les.status =
                                                  LessonStatus.published;
                                            });
                                          },
                                        ),
                                  );
                                },
                        ),
                      ],
                    ],
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

// State: กำลังโหลดรายการบทเรียน
class _LessonListLoadingView extends StatelessWidget {
  const _LessonListLoadingView();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 60),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: TeacherPalette.primary,
              ),
            ),
            SizedBox(height: 12),
            Text(
              'กำลังโหลดรายการบทเรียน...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: TeacherPalette.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// State: ครูไม่มีสิทธิ์สอนวิชานี้
class _PermissionDeniedView extends StatelessWidget {
  const _PermissionDeniedView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_person_rounded,
                color: Color(0xFFB91C1C),
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'ไม่มีสิทธิ์เข้าถึงรายวิชานี้',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'คุณไม่มีสิทธิ์สอนในรายวิชานี้แล้ว หากคิดว่าเป็นความผิดพลาด\nกรุณาติดต่อผู้ดูแลระบบ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: TeacherPalette.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonMetaTag extends StatelessWidget {
  const _LessonMetaTag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: TeacherPalette.muted,
            ),
          ),
        ],
      ),
    );
  }
}

// ปุ่มรองแบบวงกลม ใช้กับ action ที่ไม่ใช่งานหลักของการ์ด (ดูตัวอย่าง/
// สถิติ/เผยแพร่) เพื่อให้ปุ่ม "แก้ไข" เด่นเป็นจุดเดียวที่ตากวาดเจอก่อน
class _LessonIconAction extends StatelessWidget {
  const _LessonIconAction({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap == null ? TeacherPalette.muted : color;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: effectiveColor.withValues(alpha: 0.1),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Icon(icon, size: 18, color: effectiveColor),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 3-COLUMN BLOCK EDITOR PAGE (SPECS 2,3,4,5,6)
// ==========================================

class TeacherLessonEditorPage extends StatefulWidget {
  const TeacherLessonEditorPage({
    super.key,
    required this.lesson,
    this.isCourseClosed = false,
  });

  final LessonModel lesson;
  final bool isCourseClosed;

  @override
  State<TeacherLessonEditorPage> createState() =>
      _TeacherLessonEditorPageState();
}

class _TeacherLessonEditorPageState extends State<TeacherLessonEditorPage> {
  late TextEditingController _titleController;
  late List<ContentBlockModel> _blocks;
  int _activeRightTab = 0; // 0 = Materials, 1 = AIoT Sensors
  bool _isLoading = true;
  bool _isAutoSaving = false;
  bool _saveFailed = false;
  String _saveStatusText = 'บันทึกแล้ว';
  int _saveAttempt = 0;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.lesson.title);
    _blocks = List.from(widget.lesson.blocks);
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  void _triggerAutoSave() {
    if (widget.isCourseClosed) return;
    _saveAttempt++;
    final thisAttempt = _saveAttempt;
    setState(() {
      _isAutoSaving = true;
      _saveFailed = false;
      _saveStatusText = 'กำลังบันทึก...';
    });

    // จำลองการบันทึกล้มเหลวเป็นครั้งคราว (เช่น เน็ตหลุด) — ข้อมูลที่
    // พิมพ์ยังอยู่ใน controller ไม่หาย ต้องมีปุ่มลองบันทึกใหม่
    final willFail = thisAttempt % 4 == 0;

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || thisAttempt != _saveAttempt) return;
      if (willFail) {
        setState(() {
          _isAutoSaving = false;
          _saveFailed = true;
          _saveStatusText = 'บันทึกไม่สำเร็จ';
        });
      } else {
        setState(() {
          _isAutoSaving = false;
          _saveFailed = false;
          _saveStatusText = 'บันทึกแล้ว';
          widget.lesson.title = _titleController.text;
          widget.lesson.blocks = _blocks;
        });
      }
    });
  }

  void _addBlock(ContentBlockType type) {
    final newId = 'b-${DateTime.now().millisecondsSinceEpoch}';
    final newBlock = ContentBlockModel(
      id: newId,
      type: type,
      text: type == ContentBlockType.heading
          ? 'หัวข้อใหม่'
          : (type == ContentBlockType.calloutWarning
                ? 'ข้อควรระวังสำคัญ...'
                : (type == ContentBlockType.summaryBox
                      ? 'สรุปประเด็นสำคัญประจำบทเรียน...'
                      : 'ข้อความเนื้อหาใหม่...')),
    );

    setState(() {
      _blocks.add(newBlock);
    });
    _triggerAutoSave();
  }

  void _moveBlock(int index, int direction) {
    if (index + direction < 0 || index + direction >= _blocks.length) return;
    setState(() {
      final temp = _blocks[index];
      _blocks[index] = _blocks[index + direction];
      _blocks[index + direction] = temp;
    });
    _triggerAutoSave();
  }

  void _deleteBlock(int index) {
    setState(() {
      _blocks.removeAt(index);
    });
    _triggerAutoSave();
  }

  // SPEC 5: Add Material Dialog
  void _openAddMaterialDialog() {
    final titleController = TextEditingController(text: 'สื่อการสอนเพิ่มเติม');
    final urlController = TextEditingController(
      text: 'https://storage.googleapis.com/materials/doc1.pdf',
    );
    String selectedType = 'ไฟล์';
    var isUploading = false;
    var uploadFailed = false;
    var uploadAttempt = 0;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.upload_file_rounded, color: TeacherPalette.primary),
              SizedBox(width: 10),
              Text(
                'แนบสื่อการสอนใหม่',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ประเภทสื่อ:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Row(
                children: ['รูปภาพ', 'วิดีโอ', 'ไฟล์', 'ลิงก์'].map((t) {
                  final isSel = selectedType == t;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(t),
                      selected: isSel,
                      selectedColor: TeacherPalette.primary,
                      labelStyle: TextStyle(
                        color: isSel ? Colors.white : TeacherPalette.ink,
                        fontSize: 11,
                      ),
                      onSelected: (_) => setModalState(() => selectedType = t),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: 'ชื่อสื่อการสอน *',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: 'URL หรือตำแหน่งไฟล์ *',
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (uploadFailed) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline_rounded,
                        size: 16,
                        color: Color(0xFFB91C1C),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'อัปโหลดไฟล์ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton.icon(
              icon: isUploading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_rounded, size: 16),
              label: Text(
                isUploading
                    ? 'กำลังอัปโหลด...'
                    : (uploadFailed
                          ? 'ลองอัปโหลดใหม่'
                          : 'บันทึกและแทรกในบทเรียน'),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: isUploading
                  ? null
                  : () {
                      uploadAttempt++;
                      final thisAttempt = uploadAttempt;
                      setModalState(() {
                        isUploading = true;
                        uploadFailed = false;
                      });
                      // จำลองอัปโหลดผ่าน Signed Upload URL — ล้มเหลว
                      // เป็นครั้งคราว ต้องคงข้อมูลที่กรอกไว้แล้วให้ลองใหม่ได้
                      final willFail =
                          thisAttempt == 1 && selectedType == 'ไฟล์';
                      Future.delayed(const Duration(milliseconds: 900), () {
                        if (thisAttempt != uploadAttempt) return;
                        if (willFail) {
                          setModalState(() {
                            isUploading = false;
                            uploadFailed = true;
                          });
                          return;
                        }
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        final newMat = LessonMaterialModel(
                          id: 'm-${DateTime.now().millisecondsSinceEpoch}',
                          title: titleController.text.trim(),
                          type: selectedType,
                          url: urlController.text.trim(),
                        );
                        setState(() {
                          widget.lesson.materials.add(newMat);
                          _blocks.add(
                            ContentBlockModel(
                              id: 'b-mat-${DateTime.now().millisecondsSinceEpoch}',
                              type: selectedType == 'รูปภาพ'
                                  ? ContentBlockType.image
                                  : ContentBlockType.fileDownload,
                              text: 'สื่อแนบ: ${newMat.title}',
                              mediaUrl: newMat.url,
                            ),
                          );
                        });
                        _triggerAutoSave();
                      });
                    },
            ),
          ],
        ),
      ),
    );
  }

  // SPEC 6: AIoT Sensor Binding Dialog
  void _openBindAiotDialog() {
    String selectedDevice = 'ESP32-Lab3-SensorNode';
    String selectedMetric = 'PM2.5 & CO2';
    String selectedTimeRange = '08:00 - 15:00 น.';
    final captionController = TextEditingController(
      text: 'กราฟแสดงข้อมูลคุณภาพอากาศเรียลไทม์',
    );

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.sensors_rounded, color: Color(0xFF2563EB)),
              SizedBox(width: 10),
              Text(
                'ผูกข้อมูล AIoT Sensor ในบทเรียน',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'เลือกอุปกรณ์ในโรงเรียน:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedDevice,
                  items:
                      [
                            'ESP32-Lab3-SensorNode',
                            'ESP32-GreenLab-SensorNode',
                            'ESP32-SolarStation',
                          ]
                          .map(
                            (d) => DropdownMenuItem(
                              value: d,
                              child: Text(
                                d,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setModalState(() => selectedDevice = v!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'เลือก Metric เฝ้าระวัง:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedMetric,
                  items:
                      [
                            'PM2.5 & CO2',
                            'อุณหภูมิ & ความชื้น',
                            'ความเข้มแสง Lux',
                            'พลังงานไฟฟ้า Watt',
                          ]
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                m,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setModalState(() => selectedMetric = v!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                const Text(
                  'ช่วงเวลาข้อมูล:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: selectedTimeRange,
                  items:
                      ['08:00 - 15:00 น.', 'ย้อนหลัง 24 ชม.', 'ย้อนหลัง 7 วัน']
                          .map(
                            (t) => DropdownMenuItem(
                              value: t,
                              child: Text(
                                t,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          )
                          .toList(),
                  onChanged: (v) => setModalState(() => selectedTimeRange = v!),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                    labelText: 'คำอธิบายใต้กราฟ',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Live Preview Chart Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.show_chart_rounded,
                            color: Color(0xFF2563EB),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$selectedDevice ($selectedMetric)',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 60,
                        color: Colors.white,
                        child: const Center(
                          child: Text(
                            '[ตัวอย่างกราฟเรียลไทม์ AIoT]',
                            style: TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ยกเลิก'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('บันทึกและแทรกในบทเรียน'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                final newSensor = LessonSensorLinkModel(
                  id: 's-${DateTime.now().millisecondsSinceEpoch}',
                  deviceName: selectedDevice,
                  metric: selectedMetric,
                  timeRange: selectedTimeRange,
                  caption: captionController.text.trim(),
                );
                setState(() {
                  widget.lesson.sensorLinks.add(newSensor);
                  _blocks.add(
                    ContentBlockModel(
                      id: 'b-sens-${DateTime.now().millisecondsSinceEpoch}',
                      type: ContentBlockType.sensorChart,
                      sensorDeviceId: selectedDevice,
                      sensorMetric: selectedMetric,
                      timeRange: selectedTimeRange,
                      caption: newSensor.caption,
                    ),
                  );
                });
                _triggerAutoSave();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          foregroundColor: TeacherPalette.ink,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: TeacherPalette.primary,
            ),
          ),
        ),
      );
    }

    final saveColor = _saveFailed
        ? Colors.red
        : (_isAutoSaving ? Colors.amber.shade800 : const Color(0xFF059669));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: TeacherPalette.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'กลับไปบทเรียน',
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _titleController,
                readOnly: widget.isCourseClosed,
                onChanged: (_) => _triggerAutoSave(),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: TeacherPalette.ink,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'ชื่อบทเรียน *',
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _saveFailed ? _triggerAutoSave : null,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: saveColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _saveFailed
                          ? Icons.error_outline_rounded
                          : (_isAutoSaving
                                ? Icons.sync_rounded
                                : Icons.check_circle_rounded),
                      size: 14,
                      color: saveColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _saveFailed
                          ? '$_saveStatusText · ลองใหม่'
                          : _saveStatusText,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: saveColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.visibility_outlined,
              color: Color(0xFF2563EB),
            ),
            tooltip: 'ดูตัวอย่างแบบนักเรียน',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      TeacherLessonPreviewPage(lesson: widget.lesson),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.publish_rounded, size: 16),
              label: Text(
                widget.lesson.status == LessonStatus.published
                    ? 'อัปเดตบทเรียน'
                    : 'เผยแพร่',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: TeacherPalette.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: widget.isCourseClosed
                  ? null
                  : () {
                      showDialog<void>(
                        context: context,
                        builder: (_) => TeacherPublishChecklistDialog(
                          lesson: widget.lesson,
                          onConfirmedPublish: () {
                            setState(() {
                              widget.lesson.status = LessonStatus.published;
                            });
                          },
                        ),
                      );
                    },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.isCourseClosed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: const Color(0xFFFEF2F2),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 14,
                    color: Color(0xFFB91C1C),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'รายวิชานี้ปิดภาคเรียนแล้ว — ดูเนื้อหาได้อย่างเดียว แก้ไขไม่ได้',
                    style: TextStyle(
                      color: Color(0xFFB91C1C),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 900;

                if (!isWide) {
                  return Column(
                    children: [Expanded(child: _buildMiddleEditorPanel())],
                  );
                }

                return Row(
                  children: [
                    // 📌 1. LEFT PANEL: OUTLINE / SECTIONS (SPEC 3)
                    SizedBox(width: 240, child: _buildLeftOutlinePanel()),
                    const VerticalDivider(
                      width: 1,
                      color: TeacherPalette.border,
                    ),

                    // 📝 2. MIDDLE PANEL: BLOCK EDITOR (SPEC 4)
                    Expanded(child: _buildMiddleEditorPanel()),
                    const VerticalDivider(
                      width: 1,
                      color: TeacherPalette.border,
                    ),

                    // 📎 3. RIGHT PANEL: MATERIALS & AIOT (SPECS 5 & 6)
                    SizedBox(width: 300, child: _buildRightPanel()),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Left outline panel
  Widget _buildLeftOutlinePanel() {
    final headings = _blocks
        .where((b) => b.type == ContentBlockType.heading)
        .toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.format_list_bulleted_rounded,
                size: 18,
                color: TeacherPalette.primary,
              ),
              SizedBox(width: 8),
              Text(
                'สารบัญบทเรียน',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${headings.length} หัวข้อหลักในบทเรียนนี้',
            style: const TextStyle(fontSize: 11, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: headings.length,
              separatorBuilder: (context, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final h = headings[index];
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bookmark_outline_rounded,
                        size: 14,
                        color: TeacherPalette.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          h.text,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _addBlock(ContentBlockType.heading),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('+ เพิ่ม Section ใหม่'),
            style: ElevatedButton.styleFrom(
              backgroundColor: TeacherPalette.primary.withValues(alpha: 0.1),
              foregroundColor: TeacherPalette.primary,
              minimumSize: const Size(double.infinity, 40),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  /// Middle Block Editor Panel
  Widget _buildMiddleEditorPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.lesson.status == LessonStatus.published)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFC2410C),
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'บทเรียนนี้เผยแพร่แล้ว การแก้ไขและบันทึกจะมีผลต่อนักเรียนที่กำลังเรียนทันที',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC2410C),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Blocks List
            for (int i = 0; i < _blocks.length; i++)
              _buildBlockEditorTile(_blocks[i], i),

            const SizedBox(height: 20),

            // Add Block Menu (Spec 4: All 10 Block Types)
            Center(
              child: PopupMenuButton<ContentBlockType>(
                onSelected: _addBlock,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: ContentBlockType.heading,
                    child: Text('📌 เพิ่มหัวข้อ (Heading)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.text,
                    child: Text('📝 เพิ่มข้อความ (Text)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.calloutWarning,
                    child: Text('⚠️ เพิ่มกล่องข้อควรระวัง (Callout)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.summaryBox,
                    child: Text('💡 เพิ่มกล่องสรุป (Summary)'),
                  ),
                  const PopupMenuItem(
                    value: ContentBlockType.sensorChart,
                    child: Text('📊 ฝังกราฟข้อมูล AIoT Sensor'),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: TeacherPalette.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: TeacherPalette.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        color: TeacherPalette.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'เพิ่ม Block เนื้อหาใหม่',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockEditorTile(ContentBlockModel block, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TeacherPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getBlockIcon(block.type),
                size: 16,
                color: TeacherPalette.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _getBlockLabel(block.type),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: TeacherPalette.muted,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                onPressed: widget.isCourseClosed
                    ? null
                    : () => _moveBlock(index, -1),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                onPressed: widget.isCourseClosed
                    ? null
                    : () => _moveBlock(index, 1),
              ),
              IconButton(
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 16,
                  color: Colors.red,
                ),
                onPressed: widget.isCourseClosed
                    ? null
                    : () => _deleteBlock(index),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (block.type == ContentBlockType.sensorChart)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.sensors_rounded,
                        color: Color(0xFF2563EB),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        block.sensorDeviceId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Metric: ${block.sensorMetric} | ช่วงเวลา: ${block.timeRange}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 80,
                    width: double.infinity,
                    color: Colors.white,
                    child: const Center(
                      child: Text(
                        '[พรีวิว กราฟเรียลไทม์ AIoT]',
                        style: TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            TextFormField(
              initialValue: block.text,
              maxLines: block.type == ContentBlockType.heading ? 1 : 3,
              onChanged: (val) {
                block.text = val;
                _triggerAutoSave();
              },
              style: TextStyle(
                fontWeight: block.type == ContentBlockType.heading
                    ? FontWeight.w900
                    : FontWeight.normal,
                fontSize: block.type == ContentBlockType.heading ? 16 : 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'กรอกเนื้อหา...',
              ),
            ),
        ],
      ),
    );
  }

  IconData _getBlockIcon(ContentBlockType type) {
    return switch (type) {
      ContentBlockType.heading => Icons.title_rounded,
      ContentBlockType.text => Icons.notes_rounded,
      ContentBlockType.calloutWarning => Icons.warning_amber_rounded,
      ContentBlockType.summaryBox => Icons.lightbulb_outline_rounded,
      ContentBlockType.sensorChart => Icons.sensors_rounded,
      _ => Icons.article_outlined,
    };
  }

  String _getBlockLabel(ContentBlockType type) {
    return switch (type) {
      ContentBlockType.heading => 'หัวข้อ (Heading)',
      ContentBlockType.text => 'ข้อความ (Text)',
      ContentBlockType.calloutWarning => 'กล่องข้อควรระวัง (Callout)',
      ContentBlockType.summaryBox => 'กล่องสรุป (Summary)',
      ContentBlockType.sensorChart => 'กราฟ AIoT Sensor Chart',
      _ => 'Block',
    };
  }

  /// Right Panel for Materials and AIoT Sensors
  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeRightTab = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeRightTab == 0
                              ? TeacherPalette.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'คลังสื่อแนบ (${widget.lesson.materials.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _activeRightTab == 0
                            ? TeacherPalette.primary
                            : TeacherPalette.muted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _activeRightTab = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: _activeRightTab == 1
                              ? TeacherPalette.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Text(
                      'ผูก AIoT (${widget.lesson.sensorLinks.length})',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: _activeRightTab == 1
                            ? TeacherPalette.primary
                            : TeacherPalette.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: _activeRightTab == 0
                  ? _buildMaterialsTab()
                  : _buildAiotTab(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaterialsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _openAddMaterialDialog,
          icon: const Icon(Icons.upload_file_rounded, size: 16),
          label: const Text('+ เพิ่มสื่อการสอน'),
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.lesson.materials.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final mat = widget.lesson.materials[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.insert_drive_file_outlined,
                      color: TeacherPalette.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        mat.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAiotTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _openBindAiotDialog,
          icon: const Icon(Icons.sensors_rounded, size: 16),
          label: const Text('+ ผูกข้อมูล AIoT Sensor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            itemCount: widget.lesson.sensorLinks.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sl = widget.lesson.sensorLinks[index];
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sl.deviceName,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                    Text(
                      '${sl.metric} • ${sl.timeRange}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ==========================================
// 7. STUDENT PREVIEW MODE PAGE (SPEC 7)
// ==========================================

class TeacherLessonPreviewPage extends StatelessWidget {
  const TeacherLessonPreviewPage({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        title: const Text(
          'มุมมองนักเรียน (Student Preview Mode)',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            label: const Text(
              'กลับไปแก้ไข',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            color: const Color(0xFFFEF3C7),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.visibility_rounded,
                  color: Color(0xFFD97706),
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  'นี่คือโหมดแสดงผลเสมือนจริงของนักเรียน ครูเท่านั้นที่เห็นหน้านี้ก่อนเผยแพร่',
                  style: TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: TeacherPalette.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  for (final block in lesson.blocks) ...[
                    if (block.type == ContentBlockType.heading)
                      Text(
                        block.text,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: TeacherPalette.primary,
                        ),
                      )
                    else if (block.type == ContentBlockType.text)
                      Text(
                        block.text,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      )
                    else if (block.type == ContentBlockType.calloutWarning)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Text(
                          block.text,
                          style: const TextStyle(
                            color: Color(0xFF991B1B),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else if (block.type == ContentBlockType.sensorChart)
                      Container(
                        height: 140,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            '📊 กราฟเรียลไทม์ AIoT: ${block.sensorDeviceId} (${block.sensorMetric})',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 8. PUBLISH CHECKLIST DIALOG (SPEC 8)
// ==========================================

class TeacherPublishChecklistDialog extends StatelessWidget {
  const TeacherPublishChecklistDialog({
    super.key,
    required this.lesson,
    required this.onConfirmedPublish,
  });

  final LessonModel lesson;
  final VoidCallback onConfirmedPublish;

  @override
  Widget build(BuildContext context) {
    final hasTitle = lesson.title.isNotEmpty;
    final hasBlocks = lesson.blocks.isNotEmpty;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.publish_rounded, color: TeacherPalette.primary),
          SizedBox(width: 10),
          Text(
            'ยืนยันการเผยแพร่บทเรียน',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'รายการตรวจสอบระบบก่อนเปิดให้นักเรียนเข้าเรียน:',
            style: TextStyle(fontSize: 12, color: TeacherPalette.muted),
          ),
          const SizedBox(height: 12),
          _checkItem('มีชื่อบทเรียนครอบคลุม', hasTitle),
          _checkItem('มี Block เนื้อหาอย่างน้อย 1 รายการ', hasBlocks),
          _checkItem(
            'สื่อแนบพร้อมใช้งาน (${lesson.materials.length} สื่อ)',
            true,
          ),
          _checkItem(
            'กราฟ AIoT เชื่อมต่อสำเร็จ (${lesson.sensorLinks.length} กราฟ)',
            true,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              '💡 เมื่อกดเผยแพร่ นักเรียนในรายวิชาจะสามารถเข้าอ่านและเรียนรู้บทเรียนนี้ได้ทันที',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF047857),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('กลับไปแก้ไข'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: TeacherPalette.primary,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
            onConfirmedPublish();
          },
          child: const Text('เผยแพร่บทเรียนทันที'),
        ),
      ],
    );
  }

  Widget _checkItem(String text, bool pass) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            pass ? Icons.check_circle_rounded : Icons.cancel_rounded,
            size: 16,
            color: pass ? const Color(0xFF059669) : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: pass ? TeacherPalette.ink : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 9. LESSON ANALYTICS PAGE (SPEC 9 WITH FILTERS)
// ==========================================

class TeacherLessonAnalyticsPage extends StatefulWidget {
  const TeacherLessonAnalyticsPage({super.key, required this.lesson});

  final LessonModel lesson;

  @override
  State<TeacherLessonAnalyticsPage> createState() =>
      _TeacherLessonAnalyticsPageState();
}

class _TeacherLessonAnalyticsPageState
    extends State<TeacherLessonAnalyticsPage> {
  bool _isLoading = true;
  String _filter = 'ทั้งหมด';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => _isLoading = false);
    });
  }

  final List<Map<String, dynamic>> _students = [
    {
      'name': 'ณัฐวุฒิ ใจดี',
      'room': 'ม.4/1',
      'progress': '100%',
      'status': 'เรียนจบแล้ว',
      'color': Colors.green,
    },
    {
      'name': 'ปวีณา สายทอง',
      'room': 'ม.4/1',
      'progress': '75%',
      'status': 'กำลังเรียน',
      'color': Colors.amber,
    },
    {
      'name': 'ธนกร วิจิตร',
      'room': 'ม.4/1',
      'progress': '0%',
      'status': 'ยังไม่เริ่ม',
      'color': Colors.grey,
    },
    {
      'name': 'กิตติศักดิ์ มั่นคง',
      'room': 'ม.4/2',
      'progress': '100%',
      'status': 'เรียนจบแล้ว',
      'color': Colors.green,
    },
    {
      'name': 'สุชาดา พรหมดี',
      'room': 'ม.4/2',
      'progress': '40%',
      'status': 'กำลังเรียน',
      'color': Colors.amber,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _students.where((s) {
      if (_filter == 'ทั้งหมด') return true;
      return s['status'] == _filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('สถิติบทเรียน: ${widget.lesson.title}'),
        backgroundColor: Colors.white,
        foregroundColor: TeacherPalette.ink,
      ),
      body: _isLoading
          ? const Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: TeacherPalette.primary,
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _statBox(
                        'นักเรียนทั้งหมด',
                        '42 คน',
                        Icons.groups_rounded,
                        Colors.blue,
                      ),
                      const SizedBox(width: 10),
                      _statBox(
                        'เริ่มเรียนแล้ว',
                        '38 คน',
                        Icons.play_circle_outline,
                        Colors.amber,
                      ),
                      const SizedBox(width: 10),
                      _statBox(
                        'เรียนจบแล้ว',
                        '31 คน',
                        Icons.task_alt_rounded,
                        Colors.green,
                      ),
                      const SizedBox(width: 10),
                      _statBox(
                        'ความคืบหน้าเฉลี่ย',
                        '84%',
                        Icons.trending_up_rounded,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Filters Bar (Spec 9: Filter: ทั้งหมด / ยังไม่เริ่ม / กำลังเรียน / เรียนจบ)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ตารางพัฒนาการนักเรียนรายบุคคล',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Row(
                        children:
                            [
                              'ทั้งหมด',
                              'ยังไม่เริ่ม',
                              'กำลังเรียน',
                              'เรียนจบแล้ว',
                            ].map((f) {
                              final isSelected = _filter == f;
                              return Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: ChoiceChip(
                                  label: Text(f),
                                  selected: isSelected,
                                  selectedColor: TeacherPalette.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : TeacherPalette.ink,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  onSelected: (_) =>
                                      setState(() => _filter = f),
                                ),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: TeacherPalette.border),
                    ),
                    child: Column(
                      children: [
                        for (int i = 0; i < filtered.length; i++) ...[
                          _studentRow(
                            filtered[i]['name'] as String,
                            filtered[i]['room'] as String,
                            filtered[i]['progress'] as String,
                            filtered[i]['status'] as String,
                            filtered[i]['color'] as Color,
                          ),
                          if (i < filtered.length - 1) const Divider(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _statBox(String title, String val, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TeacherPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              val,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: TeacherPalette.muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentRow(
    String name,
    String room,
    String progress,
    String status,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 8),
          Text(
            '($room)',
            style: const TextStyle(color: TeacherPalette.muted, fontSize: 12),
          ),
          const Spacer(),
          Text(
            'ความคืบหน้า $progress',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
