import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
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
    this.uploaderName,
    this.createdAt,
  });

  final String id;
  String name;
  final String typeLabel;
  final String sizeLabel;
  final Color color;
  String category;
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
  });

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
  const TeacherKnowledgeLibraryPage({super.key});

  @override
  State<TeacherKnowledgeLibraryPage> createState() =>
      _TeacherKnowledgeLibraryPageState();
}

class _TeacherKnowledgeLibraryPageState
    extends State<TeacherKnowledgeLibraryPage> {
  bool _isLoading = true;
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
    setState(() => _isLoading = true);

    try {
      if (AuthService.sessionToken != null) {
        final courses = await CourseService.listMyCourses();
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

        for (var i = 0; i < courses.length; i++) {
          final c = courses[i];
          List<CourseFile> files = [];
          try {
            files = await CourseFileService.listFiles(c.id);
          } catch (_) {}

          final mappedFiles = files.map((f) {
            final ext = f.fileName.contains('.')
                ? f.fileName.split('.').last.toUpperCase()
                : 'FILE';
            return TeacherLibraryFile(
              id: f.id,
              name: f.fileName,
              typeLabel: ext,
              sizeLabel: f.formattedSize,
              color: _colorForExtension(ext),
              category: 'เอกสารประกอบการเรียน',
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
        _loadFallbackMock();
      }
    } catch (_) {
      _loadFallbackMock();
    }
  }

  void _loadFallbackMock() {
    if (!mounted) return;
    setState(() {
      _subjects = [
        TeacherLibrarySubject(
          id: 'mock-1',
          code: 'AIOT-501',
          name: 'AIoT สมาร์ตแล็บ',
          icon: Icons.memory_rounded,
          color: TeacherPalette.primary,
          files: [
            TeacherLibraryFile(
              id: 'f1',
              name: 'แผนการสอน_AIoT-501.pdf',
              typeLabel: 'PDF',
              sizeLabel: '1.8 MB',
              color: _colorForExtension('PDF'),
              category: 'เอกสารประจำวิชา',
            ),
            TeacherLibraryFile(
              id: 'f2',
              name: 'โมเดล 3D_เซนเซอร์ PM2.5.glb',
              typeLabel: '3D',
              sizeLabel: '5.6 MB',
              color: _colorForExtension('GLB'),
              category: 'บทที่ 13',
            ),
          ],
        ),
        TeacherLibrarySubject(
          id: 'mock-2',
          code: 'PHYS-302',
          name: 'ฟิสิกส์ประยุกต์',
          icon: Icons.bolt_rounded,
          color: TeacherPalette.skyDeep,
          files: [
            TeacherLibraryFile(
              id: 'f4',
              name: 'แผนการสอน_PHYS-302.pdf',
              typeLabel: 'PDF',
              sizeLabel: '1.2 MB',
              color: _colorForExtension('PDF'),
              category: 'เอกสารประจำวิชา',
            ),
          ],
        ),
      ];
      _isLoading = false;
    });
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

    if (AuthService.sessionToken != null && !targetSubject.id.startsWith('mock-')) {
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
          await CourseFileService.uploadFile(
            courseId: targetSubject.id,
            fileName: result.fileName,
            bytes: result.bytes!,
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('อัปโหลดไฟล์ไม่สำเร็จ: $e'),
              backgroundColor: const Color(0xFFEF4444),
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
            sizeLabel: '${result.sizeValue.toStringAsFixed(1)} ${result.sizeUnit}',
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

  Future<void> _downloadFile(TeacherLibraryFile file) async {
    if (AuthService.sessionToken != null && !file.id.startsWith('f')) {
      try {
        final url = await CourseFileService.getDownloadUrl(file.id);
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('เปิดลิงก์ดาวน์โหลด: "${file.name}"'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('ไม่สามารถดาวน์โหลดไฟล์ได้: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('กำลังเปิดไฟล์: "${file.name}"'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
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
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
      builder: (context, isDesktop) {
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
              '${files.length} ไฟล์ · ${currentSubject?.name ?? ""}',
              style: const TextStyle(
                color: TeacherPalette.muted,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
            const SizedBox(height: 12),
            if (files.isEmpty)
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
                        fontSize: 13.5,
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
                  fontSize: 12.5,
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
                    fontSize: 10.5,
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
  });

  final TeacherLibraryFile file;
  final VoidCallback onDownload;

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
                  fontSize: 9.5,
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
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${file.category} · ${file.sizeLabel}',
                    style: const TextStyle(
                      color: TeacherPalette.muted,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDownload,
              icon: const Icon(Icons.download_rounded, size: 20),
              color: TeacherPalette.primary,
              tooltip: 'ดาวน์โหลดไฟล์',
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
    final result = await FilePicker.platform.pickFiles(withData: true);
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
                  fontSize: 18,
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
                            fontSize: 12.5,
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
