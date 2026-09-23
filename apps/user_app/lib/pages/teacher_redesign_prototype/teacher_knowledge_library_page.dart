import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'teacher_airy_kit.dart' show TeacherType;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;
import 'teacher_shared_widgets.dart';

class TeacherLibraryFile {
  TeacherLibraryFile({
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.sizeLabel,
    required this.color,
    required this.category,
    this.isLink = false,
    this.url,
    this.usedByAssignments = 0,
    this.uploaderName,
    this.createdAt,
  });

  final String id;
  String name;
  final String typeLabel;
  final String sizeLabel;
  final Color color;
  String category;

  /// ลิงก์ไม่มีไฟล์จริงในถัง เปิดตรงจาก [url] ไม่ต้องขอ signed URL
  final bool isLink;
  final String? url;

  /// นับมาจากฐานข้อมูล — มากกว่า 0 คือลบไม่ได้ (FK on delete restrict)
  int usedByAssignments;
  bool get inUse => usedByAssignments > 0;

  final String? uploaderName;
  final DateTime? createdAt;
}

class TeacherLibrarySubject {
  TeacherLibrarySubject({
    required this.id,
    required this.code,
    required this.name,
    required this.icon,
    required this.color,
    required this.files,
    this.filesLoadFailed = false,
  });

  /// list_course_files ของวิชานี้ล้ม — ต้องแยกจาก "ยังไม่มีไฟล์" เพราะเดิม
  /// กลืนเงียบแล้วโชว์รายการว่าง ครูอ่านว่าวิชานี้ไม่มีไฟล์ทั้งที่โหลดไม่ขึ้น
  final bool filesLoadFailed;

  final String id;
  final String code;
  final String name;
  final IconData icon;
  final Color color;
  final List<TeacherLibraryFile> files;
}

Color _colorForExtension(String ext) {
  switch (ext.toUpperCase()) {
    case 'PDF':
      return TeacherPalette.red;
    case 'ZIP':
    case 'RAR':
      return TeacherPalette.orange;
    case 'GLB':
    case 'GLTF':
    case '3D':
      return TeacherPalette.skyDeep;
    case 'PPT':
    case 'PPTX':
      return TeacherPalette.orange;
    case 'DOC':
    case 'DOCX':
      return TeacherPalette.skyDeep;
    default:
      return TeacherPalette.primary;
  }
}

class TeacherKnowledgeLibraryPage extends StatefulWidget {
  const TeacherKnowledgeLibraryPage({
    super.key,
    this.loadCourses,
    this.listFiles,
    this.uploadFile,
    this.getDownloadUrl,
    this.addLink,
    this.updateFile,
    this.deleteFile,
    this.hasSessionOverride,
  });

  /// Read/write seams threaded to the corresponding CourseService/
  /// CourseFileService static calls in production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<CourseFile>> Function(String courseId)? listFiles;
  final Future<void> Function({
    required String courseId,
    required String fileName,
    required Uint8List bytes,
    String? category,
  })?
  uploadFile;
  final Future<String> Function(String fileId)? getDownloadUrl;

  /// 2026-09-23 — คลังรับลิงก์ได้ และแก้/ลบของในคลังได้แล้ว ก่อนหน้านี้
  /// register/list/download เท่านั้น ลบอะไรไม่ได้เลยทั้งระบบ
  final Future<String> Function({
    required String courseId,
    required String url,
    String? title,
    String? category,
  })?
  addLink;
  final Future<void> Function({
    required String fileId,
    String? fileName,
    String? category,
    String? url,
  })?
  updateFile;
  final Future<void> Function(String fileId)? deleteFile;

  /// Overrides AuthService.sessionToken != null for tests, since that's a
  /// static field the seams above can't otherwise replace.
  final bool? hasSessionOverride;

  @override
  State<TeacherKnowledgeLibraryPage> createState() =>
      _TeacherKnowledgeLibraryPageState();
}

class _TeacherKnowledgeLibraryPageState
    extends State<TeacherKnowledgeLibraryPage> {
  bool _isLoading = true;
  // เดิม error ใดๆ (session หมดอายุ, RPC ล้ม, ฯลฯ) ถูกกลืนแล้วสลับไปโชว์
  // ห้องสมุดปลอม 2 วิชา ('AIoT สมาร์ตแล็บ'/'ฟิสิกส์ประยุกต์') ทันทีโดยไม่มี
  // error banner เลย — ครูจะเห็นข้อมูลที่ดูสมจริงทั้งที่จริงคือโหลดพัง
  bool _hasError = false;
  List<TeacherLibrarySubject> _subjects = [];
  int _selectedIndex = 0;

  TeacherLibrarySubject? get _selectedSubject =>
      _subjects.isNotEmpty && _selectedIndex < _subjects.length
      ? _subjects[_selectedIndex]
      : null;

  @override
  void initState() {
    super.initState();
    _loadLibraryData();
  }

  Future<void> _loadLibraryData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final hasSession =
          widget.hasSessionOverride ?? (AuthService.sessionToken != null);
      if (hasSession) {
        final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
        final courses = await loadCourses();
        if (courses.isEmpty) {
          if (mounted) {
            setState(() {
              _subjects = [];
              _isLoading = false;
            });
          }
          return;
        }

        final subjectList = <TeacherLibrarySubject>[];
        final paletteColors = [
          TeacherPalette.primary,
          TeacherPalette.skyDeep,
          TeacherPalette.orange,
          TeacherPalette.violet,
        ];
        final paletteIcons = [
          Icons.memory_rounded,
          Icons.bolt_rounded,
          Icons.calculate_rounded,
          Icons.biotech_rounded,
        ];

        // One RPC per course, awaited in the loop — N sequential round trips
        // before the library rendered. They are independent; batch them, and
        // keep the per-course failure isolated exactly as the catch did.
        final listFiles = widget.listFiles ?? CourseFileService.listFiles;
        final filesPerCourse = await Future.wait(
          courses.map((c) async {
            try {
              return (files: await listFiles(c.id), failed: false);
            } catch (e) {
              debugPrint(
                'TeacherKnowledgeLibraryPage: โหลดไฟล์วิชา ${c.subjectName} ไม่สำเร็จ — $e',
              );
              return (files: const <CourseFile>[], failed: true);
            }
          }),
        );

        for (var i = 0; i < courses.length; i++) {
          final c = courses[i];
          final files = filesPerCourse[i].files;
          final filesLoadFailed = filesPerCourse[i].failed;

          final mappedFiles = files.map((f) {
            // หมวดเคย hardcode เป็น 'เอกสารประกอบการเรียน' ทุกไฟล์ ทั้งที่
            // ชีตอัปโหลดมีช่องให้ครูกรอก — ค่าที่กรอกไม่เคยถูกแสดงเลย
            final ext = f.isLink
                ? 'ลิงก์'
                : (f.fileName.contains('.')
                      ? f.fileName.split('.').last.toUpperCase()
                      : 'FILE');
            return TeacherLibraryFile(
              id: f.id,
              name: f.fileName,
              typeLabel: ext,
              sizeLabel: f.isLink
                  ? (Uri.tryParse(f.url ?? '')?.host ?? 'ลิงก์')
                  : f.formattedSize,
              color: f.isLink ? TeacherPalette.violet : _colorForExtension(ext),
              category: f.category ?? 'ยังไม่ระบุหมวด',
              isLink: f.isLink,
              url: f.url,
              usedByAssignments: f.usedByAssignments,
              uploaderName: f.uploaderFullName,
              createdAt: f.createdAt,
            );
          }).toList();

          subjectList.add(
            TeacherLibrarySubject(
              id: c.id,
              code: c.subjectName.split(' ').first,
              name: c.subjectName,
              icon: paletteIcons[i % paletteIcons.length],
              color: paletteColors[i % paletteColors.length],
              files: mappedFiles,
              filesLoadFailed: filesLoadFailed,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _subjects = subjectList;
            _isLoading = false;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _subjects = [];
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (e) {
      debugPrint('TeacherKnowledgeLibraryPage load failed: $e');
      if (!mounted) return;
      setState(() {
        _subjects = [];
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  /// เพิ่มลิงก์เข้าคลัง — คลังเก็บได้แต่ไฟล์ที่อัปขึ้นถังมาตลอด ลิงก์เก็บไม่ได้
  Future<void> _addLink() async {
    if (_subjects.isEmpty) return;
    final subject = _subjects[_selectedIndex];

    final url = TextEditingController();
    final title = TextEditingController();
    final category = TextEditingController();
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('ใส่ลิงก์ใน ${subject.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: url,
                autofocus: true,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'ลิงก์',
                  hintText: 'https://…',
                  errorText: error,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: title,
                decoration: const InputDecoration(
                  labelText: 'ชื่อที่จะแสดง (ไม่บังคับ)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: category,
                decoration: const InputDecoration(
                  labelText: 'หมวด / บทเรียน (ไม่บังคับ)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                // ตรวจตั้งแต่หน้าจอ หลังบ้านตรวจซ้ำอีกชั้น (register_course_link
                // โยน invalid_url) — ครูจะได้รู้ทันทีไม่ใช่หลังกดบันทึก
                if (!RegExp(r'^https?://\S+$').hasMatch(url.text.trim())) {
                  setLocal(
                    () => error = 'ต้องขึ้นต้นด้วย http:// หรือ https://',
                  );
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('เพิ่ม'),
            ),
          ],
        ),
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await (widget.addLink ?? CourseFileService.addLink)(
        courseId: subject.id,
        url: url.text.trim(),
        title: title.text.trim().isEmpty ? null : title.text.trim(),
        category: category.text.trim().isEmpty ? null : category.text.trim(),
      );
      await _loadLibraryData();
      _snack('เพิ่มลิงก์เข้าคลังแล้ว');
    } catch (e) {
      debugPrint('เพิ่มลิงก์ไม่สำเร็จ — $e');
      _snack('เพิ่มลิงก์ไม่สำเร็จ ลองใหม่อีกครั้ง', error: true);
    }
  }

  Future<void> _openUploadSheet() async {
    if (_subjects.isEmpty) return;

    final result = await showModalBottomSheet<_UploadResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _UploadFileSheet(
        subjects: _subjects,
        initialSubjectIndex: _selectedIndex,
      ),
    );

    if (result == null || !mounted) return;

    final targetSubject = _subjects[result.subjectIndex];

    final hasSession =
        widget.hasSessionOverride ?? (AuthService.sessionToken != null);
    if (hasSession && !targetSubject.id.startsWith('mock-')) {
      // Real upload to Supabase Storage
      try {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('กำลังอัปโหลด "${result.fileName}"...'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (result.bytes != null) {
          final upload = widget.uploadFile ?? CourseFileService.uploadFile;
          await upload(
            courseId: targetSubject.id,
            fileName: result.fileName,
            bytes: result.bytes!,
            category: result.category.trim().isEmpty
                ? null
                : result.category.trim(),
          );
        }

        await _loadLibraryData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อัปโหลด "${result.fileName}" สำเร็จแล้ว!'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('อัปโหลดไฟล์ไม่สำเร็จ'),
              backgroundColor: Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      // Mock mode upload
      setState(() {
        targetSubject.files.insert(
          0,
          TeacherLibraryFile(
            id: 'f_${DateTime.now().millisecondsSinceEpoch}',
            name: result.fileName,
            typeLabel: result.typeLabel,
            sizeLabel:
                '${result.sizeValue.toStringAsFixed(1)} ${result.sizeUnit}',
            color: _colorForExtension(result.typeLabel),
            category: result.category.trim().isEmpty
                ? 'ไม่ระบุหมวด'
                : result.category.trim(),
          ),
        );
        _selectedIndex = result.subjectIndex;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('อัปโหลด "${result.fileName}" สำเร็จ (ตัวอย่าง)'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // เดิมเช็ค "เป็นไฟล์ mock หรือไม่" จาก id ขึ้นต้นด้วย 'f' — ตอนนี้ไม่มีไฟล์
  // mock ในหน้านี้แล้ว (ลบ _loadFallbackMock ทิ้งไปแล้ว) ทุกไฟล์ที่แสดงเป็น
  // ไฟล์จริงจาก CourseFileService เสมอ จึงเรียก getDownloadUrl ตรงๆ ได้เลย
  // ไม่ต้องเดาจาก id อีกต่อไป (เดิมมีความเสี่ยงที่ id จริงขึ้นต้นด้วย 'f'
  // จะถูกเข้าใจผิดว่าเป็นไฟล์ mock)
  Future<void> _downloadFile(TeacherLibraryFile file) async {
    try {
      // ลิงก์เปิดตรงจาก url ที่เก็บไว้ ไม่มีไฟล์ในถังให้ขอ signed URL
      final url = file.isLink
          ? (file.url ?? '')
          : await (widget.getDownloadUrl ?? CourseFileService.getDownloadUrl)(
              file.id,
            );
      if (url.isEmpty) throw StateError('no_url');
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('เปิด "${file.name}"'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('เปิดของในคลังไม่สำเร็จ — $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              file.isLink ? 'เปิดลิงก์ไม่สำเร็จ' : 'ไม่สามารถดาวน์โหลดไฟล์ได้',
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: error ? const Color(0xFFEF4444) : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// เมนู ⋯ ของของหนึ่งชิ้นในคลัง
  ///
  /// ชื่อกับหมวดเป็นของตัวไฟล์ แก้ที่นี่ทีเดียวเปลี่ยนทุกใบงานที่อ้างถึง —
  /// ตั้งใจให้เป็นแบบนั้น จึงเขียนกำกับไว้ในเมนูให้ครูรู้ก่อนกด
  Future<void> _openFileMenu(TeacherLibraryFile file) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: TeacherPalette.ink,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('เปลี่ยนชื่อ'),
              subtitle: const Text('เปลี่ยนทุกใบงานที่ใช้ไฟล์นี้'),
              onTap: () => Navigator.pop(ctx, 'rename'),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('เปลี่ยนหมวด'),
              subtitle: const Text('ใช้จัดกลุ่มในคลังความรู้'),
              onTap: () => Navigator.pop(ctx, 'category'),
            ),
            if (file.isLink)
              ListTile(
                leading: const Icon(Icons.link_rounded),
                title: const Text('แก้ลิงก์ปลายทาง'),
                subtitle: Text(file.url ?? ''),
                onTap: () => Navigator.pop(ctx, 'url'),
              ),
            ListTile(
              leading: Icon(
                Icons.delete_outline_rounded,
                color: file.inUse ? TeacherPalette.muted : TeacherPalette.red,
              ),
              title: Text(
                'ลบออกจากคลัง',
                style: TextStyle(
                  color: file.inUse ? TeacherPalette.muted : TeacherPalette.red,
                ),
              ),
              subtitle: file.inUse
                  ? Text(
                      'ใช้อยู่ใน ${file.usedByAssignments} ใบงาน — เอาออกจากใบงานก่อน',
                    )
                  : null,
              enabled: !file.inUse,
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;

    switch (action) {
      case 'rename':
        await _editField(
          file,
          title: 'เปลี่ยนชื่อ',
          label: 'ชื่อที่จะแสดง',
          initial: file.name,
          apply: (v) => (fileName: v, category: null, url: null),
        );
      case 'category':
        await _editField(
          file,
          title: 'เปลี่ยนหมวด',
          label: 'หมวด / บทเรียน',
          initial: file.category == 'ยังไม่ระบุหมวด' ? '' : file.category,
          allowEmpty: true,
          apply: (v) => (fileName: null, category: v, url: null),
        );
      case 'url':
        await _editField(
          file,
          title: 'แก้ลิงก์ปลายทาง',
          label: 'ลิงก์',
          initial: file.url ?? '',
          validate: (v) => RegExp(r'^https?://\S+$').hasMatch(v)
              ? null
              : 'ต้องขึ้นต้นด้วย http:// หรือ https://',
          apply: (v) => (fileName: null, category: null, url: v),
        );
      case 'delete':
        await _deleteFile(file);
    }
  }

  Future<void> _editField(
    TeacherLibraryFile file, {
    required String title,
    required String label,
    required String initial,
    required ({String? fileName, String? category, String? url}) Function(
      String,
    )
    apply,
    String? Function(String)? validate,
    bool allowEmpty = false,
  }) async {
    final controller = TextEditingController(text: initial);
    String? error;
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: label, errorText: error),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('ยกเลิก'),
            ),
            TextButton(
              onPressed: () {
                final v = controller.text.trim();
                if (!allowEmpty && v.isEmpty) {
                  setLocal(() => error = 'กรอกค่าก่อน');
                  return;
                }
                final err = validate?.call(v);
                if (err != null) {
                  setLocal(() => error = err);
                  return;
                }
                Navigator.pop(ctx, v);
              },
              child: const Text('บันทึก'),
            ),
          ],
        ),
      ),
    );
    if (value == null || !mounted) return;

    final patch = apply(value);
    try {
      await (widget.updateFile ?? CourseFileService.updateFile)(
        fileId: file.id,
        fileName: patch.fileName,
        category: patch.category,
        url: patch.url,
      );
      // โหลดใหม่ทั้งชุดแทนการแก้ในเครื่อง — ค่าที่แสดงต้องมาจากหลังบ้านจริง
      await _loadLibraryData();
      _snack('บันทึกแล้ว');
    } catch (e) {
      debugPrint('แก้ของในคลังไม่สำเร็จ — $e');
      _snack('บันทึกไม่สำเร็จ ลองใหม่อีกครั้ง', error: true);
    }
  }

  Future<void> _deleteFile(TeacherLibraryFile file) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('ลบออกจากคลัง?'),
        content: Text(
          file.isLink
              ? 'ลบลิงก์ "${file.name}" ออกจากคลังความรู้ถาวร'
              : 'ลบ "${file.name}" ออกจากคลังความรู้ถาวร ไฟล์จะหายไปเลย',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'ลบ',
              style: TextStyle(color: TeacherPalette.red),
            ),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;

    try {
      await (widget.deleteFile ?? CourseFileService.deleteFile)(file.id);
      await _loadLibraryData();
      _snack('ลบออกจากคลังแล้ว');
    } catch (e) {
      debugPrint('ลบของในคลังไม่สำเร็จ — $e');
      // หลังบ้านโยน 'file_in_use_by_N assignments' ถ้ามีใบงานอ้างอยู่ —
      // แปลงเป็นข้อความที่บอกทางออก ไม่ใช่โยน error ดิบใส่หน้าครู
      final inUse = RegExp(r'file_in_use_by_(\d+)').firstMatch('$e');
      _snack(
        inUse != null
            ? 'ลบไม่ได้ — ใช้อยู่ใน ${inUse.group(1)} ใบงาน เอาออกจากใบงานก่อน'
            : 'ลบไม่สำเร็จ ลองใหม่อีกครั้ง',
        error: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return TeacherMockPageShell(
        title: 'คลังความรู้',
        activeMenuLabel: 'คลังความรู้',
        builder: (context, isDesktop) => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    final currentSubject = _selectedSubject;
    final files = currentSubject?.files ?? [];

    return TeacherMockPageShell(
      title: 'คลังความรู้',
      activeMenuLabel: 'คลังความรู้',
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: OutlinedButton.icon(
            onPressed: _subjects.isEmpty ? null : _addLink,
            icon: const Icon(Icons.link_rounded, size: 17),
            label: const Text('ใส่ลิงก์'),
            style: OutlinedButton.styleFrom(
              foregroundColor: TeacherPalette.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.icon(
            onPressed: _subjects.isEmpty ? null : _openUploadSheet,
            icon: const Icon(Icons.upload_file_rounded, size: 17),
            label: const Text('อัปโหลดไฟล์ใหม่'),
            style: FilledButton.styleFrom(
              backgroundColor: TeacherPalette.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
      builder: (context, isDesktop) {
        // แยก "โหลดไม่สำเร็จ" ออกจาก "ไม่มีรายวิชาจริง" — เดิมทั้งสองเคส
        // กลืนรวมกันเป็นห้องสมุดปลอมที่ดูเหมือนโหลดสำเร็จ
        if (_hasError) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(height: 10),
                const Text(
                  'โหลดข้อมูลคลังความรู้ไม่สำเร็จ',
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _loadLibraryData,
                  child: const Text('ลองใหม่'),
                ),
              ],
            ),
          );
        }
        if (_subjects.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: TeacherPalette.border),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 40,
                  color: TeacherPalette.muted,
                ),
                SizedBox(height: 10),
                Text(
                  'ยังไม่มีรายวิชาที่สอนในระบบ',
                  style: TextStyle(
                    color: TeacherPalette.ink,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'เลือกรายวิชา',
              style: TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _subjects.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final subject = _subjects[index];
                  final selected = index == _selectedIndex;
                  return _SubjectChip(
                    subject: subject,
                    selected: selected,
                    onTap: () => setState(() => _selectedIndex = index),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              (currentSubject?.filesLoadFailed ?? false)
                  ? 'โหลดไฟล์ไม่สำเร็จ · ${currentSubject?.name ?? ""}'
                  : '${files.length} ไฟล์ · ${currentSubject?.name ?? ""}',
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            if (currentSubject?.filesLoadFailed ?? false)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 34,
                      color: TeacherPalette.red,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'โหลดไฟล์ของวิชานี้ไม่สำเร็จ',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _loadLibraryData,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('ลองใหม่'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TeacherPalette.primary,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              )
            else if (files.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: TeacherPalette.border),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.folder_off_outlined,
                      size: 34,
                      color: TeacherPalette.muted,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'ยังไม่มีไฟล์ในวิชานี้',
                      style: TextStyle(
                        color: TeacherPalette.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _openUploadSheet,
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('อัปโหลดไฟล์แรก'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TeacherPalette.primary,
                        shape: const StadiumBorder(),
                      ),
                    ),
                  ],
                ),
              )
            else
              for (final file in files) ...[
                _LibraryFileCard(
                  file: file,
                  onDownload: () => _downloadFile(file),
                  onMenu: () => _openFileMenu(file),
                ),
                const SizedBox(height: 10),
              ],
          ],
        );
      },
    );
  }
}

class _SubjectChip extends StatelessWidget {
  const _SubjectChip({
    required this.subject,
    required this.selected,
    required this.onTap,
  });

  final TeacherLibrarySubject subject;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? subject.color : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? subject.color : TeacherPalette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                subject.icon,
                size: 16,
                color: selected ? Colors.white : subject.color,
              ),
              const SizedBox(width: 6),
              Text(
                subject.name,
                style: TextStyle(
                  color: selected ? Colors.white : TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.25)
                      : subject.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${subject.files.length}',
                  style: TextStyle(
                    color: selected ? Colors.white : subject.color,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryFileCard extends StatelessWidget {
  const _LibraryFileCard({
    required this.file,
    required this.onDownload,
    required this.onMenu,
  });

  final TeacherLibraryFile file;
  final VoidCallback onDownload;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: const BorderSide(color: TeacherPalette.border),
            right: const BorderSide(color: TeacherPalette.border),
            bottom: const BorderSide(color: TeacherPalette.border),
            left: BorderSide(color: file.color, width: 5),
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: file.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                file.typeLabel,
                style: TextStyle(
                  color: file.color,
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TeacherPalette.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${file.category} · ${file.sizeLabel}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TeacherPalette.muted,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      // บอกตั้งแต่ก่อนกดว่าลบไม่ได้ ดีกว่าให้กดแล้วเด้ง error
                      // จาก delete_course_file
                      if (file.inUse) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF3E3),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '${file.usedByAssignments} ใบงาน',
                            style: const TextStyle(
                              color: Color(0xFFB4650F),
                              fontWeight: FontWeight.w800,
                              fontSize: TeacherType.caption,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDownload,
              icon: Icon(
                file.isLink
                    ? Icons.open_in_new_rounded
                    : Icons.download_rounded,
                size: 20,
              ),
              color: TeacherPalette.primary,
              tooltip: file.isLink ? 'เปิดลิงก์' : 'ดาวน์โหลดไฟล์',
            ),
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.more_horiz_rounded, size: 20),
              color: TeacherPalette.muted,
              tooltip: 'ตัวเลือก',
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadResult {
  const _UploadResult({
    required this.subjectIndex,
    required this.fileName,
    required this.typeLabel,
    required this.sizeValue,
    required this.sizeUnit,
    required this.category,
    this.bytes,
  });

  final int subjectIndex;
  final String fileName;
  final String typeLabel;
  final double sizeValue;
  final String sizeUnit;
  final String category;
  final Uint8List? bytes;
}

class _UploadFileSheet extends StatefulWidget {
  const _UploadFileSheet({
    required this.subjects,
    required this.initialSubjectIndex,
  });

  final List<TeacherLibrarySubject> subjects;
  final int initialSubjectIndex;

  @override
  State<_UploadFileSheet> createState() => _UploadFileSheetState();
}

class _UploadFileSheetState extends State<_UploadFileSheet> {
  late int _subjectIndex = widget.initialSubjectIndex;
  final _categoryCtrl = TextEditingController();
  PlatformFile? _pickedFile;

  @override
  void dispose() {
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() => _pickedFile = result.files.first);
  }

  void _submit() {
    final file = _pickedFile;
    if (file == null) return;
    final ext = (file.extension ?? '').toUpperCase();
    final sizeMb = file.size / (1024 * 1024);
    final useKb = sizeMb < 1;
    Navigator.pop(
      context,
      _UploadResult(
        subjectIndex: _subjectIndex,
        fileName: file.name,
        typeLabel: ext.isEmpty ? 'FILE' : ext,
        sizeValue: useKb ? file.size / 1024 : sizeMb,
        sizeUnit: useKb ? 'KB' : 'MB',
        category: _categoryCtrl.text,
        bytes: file.bytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: TeacherPalette.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: TeacherPalette.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Text(
                'อัปโหลดไฟล์ใหม่',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'วิชา',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (int i = 0; i < widget.subjects.length; i++)
                    _SubjectChip(
                      subject: widget.subjects[i],
                      selected: i == _subjectIndex,
                      onTap: () => setState(() => _subjectIndex = i),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'หมวด/บทเรียน (ไม่บังคับ)',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _categoryCtrl,
                decoration: InputDecoration(
                  hintText: 'เช่น บทที่ 5 หรือ เอกสารประจำวิชา',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TeacherPalette.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: TeacherPalette.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: TeacherPalette.primary,
                      width: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'ไฟล์',
                style: TextStyle(
                  color: TeacherPalette.ink,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              if (_pickedFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TeacherPalette.primary.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: TeacherPalette.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.insert_drive_file_rounded,
                        color: TeacherPalette.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _pickedFile!.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: TeacherPalette.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickFile,
                        child: const Text('เปลี่ยน'),
                      ),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 18),
                  label: const Text('เลือกไฟล์จากเครื่อง'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: TeacherPalette.primary,
                    side: const BorderSide(color: TeacherPalette.border),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _pickedFile == null ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: TeacherPalette.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  child: const Text('อัปโหลด'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
