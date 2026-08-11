import 'dart:async';
import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';

/// UI-only mock of a "Files" hub for one course — aggregates every
/// lesson's attachment in one place. No real file storage is wired up.
/// [courseFiles] and [CourseFileCard] are shared with the "ไฟล์ทั้งหมด" tab
/// on `StudentLessonsPage` (always AIoT — that tab lives inside the AIoT
/// course detail flow), so this exact list stays untouched. The standalone
/// "คลังความรู้" page below has its own multi-subject list built on top of
/// it (see [_subjects]) since it's opened generally, not from within one
/// course, and needs a subject picker.
const courseFiles = <CourseFile>[
  CourseFile(
    chapterLabel: 'เอกสารประจำวิชา',
    typeLabel: 'PDF',
    name: 'แผนการสอน_AIoT-501.pdf',
    sizeValue: 1.8,
    sizeUnit: 'MB',
    color: Color(0xFFDC2626),
  ),
  CourseFile(
    chapterLabel: 'บทที่ 13',
    typeLabel: '3D',
    name: 'โมเดล 3D_เซนเซอร์ PM2.5.glb',
    sizeValue: 5.6,
    sizeUnit: 'MB',
    color: Color(0xFF2563EB),
  ),
  CourseFile(
    chapterLabel: 'บทที่ 14',
    typeLabel: 'ZIP',
    name: 'โค้ดตัวอย่าง_เซนเซอร์แสง.zip',
    sizeValue: 480,
    sizeUnit: 'KB',
    color: Color(0xFFD97706),
  ),
  CourseFile(
    chapterLabel: 'บทที่ 14',
    typeLabel: 'PDF',
    name: 'เอกสารประกอบ_Dashboard_Realtime.pdf',
    sizeValue: 1.4,
    sizeUnit: 'MB',
    color: Color(0xFFDC2626),
  ),
  CourseFile(
    chapterLabel: 'บทที่ 12',
    typeLabel: 'PDF',
    name: 'คู่มือการตั้งค่า_Microcontroller.pdf',
    sizeValue: 2.1,
    sizeUnit: 'MB',
    color: Color(0xFFDC2626),
  ),
  CourseFile(
    chapterLabel: 'บทที่ 11',
    typeLabel: 'PDF',
    name: 'ใบงานเขียนโปรแกรม_IoT_Basics.pdf',
    sizeValue: 640,
    sizeUnit: 'KB',
    color: Color(0xFFDC2626),
  ),
  CourseFile(
    chapterLabel: 'บทที่ 10',
    typeLabel: 'PDF',
    name: 'สไลด์บรรยาย_สถาปัตยกรรมสมาร์ตสคูล.pdf',
    sizeValue: 3.2,
    sizeUnit: 'MB',
    color: Color(0xFFDC2626),
  ),
];

class _SubjectFileGroup {
  const _SubjectFileGroup({
    required this.subjectName,
    required this.subjectCode,
    required this.icon,
    required this.color,
    required this.files,
  });

  final String subjectName;
  final String subjectCode;
  final IconData icon;
  final Color color;
  final List<CourseFile> files;
}

final _subjects = <_SubjectFileGroup>[
  _SubjectFileGroup(
    subjectName: 'AIoT สมาร์ตแล็บ',
    subjectCode: 'AIOT-501',
    icon: Icons.memory_rounded,
    color: const Color(0xFF0D9488),
    files: courseFiles,
  ),
  const _SubjectFileGroup(
    subjectName: 'ฟิสิกส์ประยุกต์',
    subjectCode: 'PHYS-302',
    icon: Icons.bolt_rounded,
    color: Color(0xFF0284C7),
    files: [
      CourseFile(
        chapterLabel: 'เอกสารประจำวิชา',
        typeLabel: 'PDF',
        name: 'แผนการสอน_PHYS-302.pdf',
        sizeValue: 1.2,
        sizeUnit: 'MB',
        color: Color(0xFFDC2626),
      ),
      CourseFile(
        chapterLabel: 'บทที่ 5',
        typeLabel: 'PDF',
        name: 'สไลด์_การหักเหของแสง.pdf',
        sizeValue: 2.4,
        sizeUnit: 'MB',
        color: Color(0xFFDC2626),
      ),
      CourseFile(
        chapterLabel: 'บทที่ 6',
        typeLabel: '3D',
        name: 'โมเดล 3D_แรงและการเคลื่อนที่.glb',
        sizeValue: 4.1,
        sizeUnit: 'MB',
        color: Color(0xFF2563EB),
      ),
    ],
  ),
  const _SubjectFileGroup(
    subjectName: 'คณิตศาสตร์เพิ่มเติม',
    subjectCode: 'MATH-401',
    icon: Icons.calculate_rounded,
    color: Color(0xFF7C3AED),
    files: [
      CourseFile(
        chapterLabel: 'เอกสารประจำวิชา',
        typeLabel: 'PDF',
        name: 'แผนการสอน_MATH-401.pdf',
        sizeValue: 900,
        sizeUnit: 'KB',
        color: Color(0xFFDC2626),
      ),
      CourseFile(
        chapterLabel: 'บทที่ 3',
        typeLabel: 'PDF',
        name: 'ใบงาน_ความน่าจะเป็นและการจัดหมู่.pdf',
        sizeValue: 1.1,
        sizeUnit: 'MB',
        color: Color(0xFFDC2626),
      ),
    ],
  ),
  const _SubjectFileGroup(
    subjectName: 'ชีววิทยา',
    subjectCode: 'BIO-105',
    icon: Icons.eco_rounded,
    color: Color(0xFF16A34A),
    files: [
      CourseFile(
        chapterLabel: 'บทที่ 2',
        typeLabel: 'PDF',
        name: 'สรุป_การสังเคราะห์แสงของพืช.pdf',
        sizeValue: 1.6,
        sizeUnit: 'MB',
        color: Color(0xFFDC2626),
      ),
    ],
  ),
];

class StudentCourseFilesPage extends StatefulWidget {
  const StudentCourseFilesPage({super.key});

  @override
  State<StudentCourseFilesPage> createState() => _StudentCourseFilesPageState();
}

class _StudentCourseFilesPageState extends State<StudentCourseFilesPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedType = 'ทั้งหมด';
  int _selectedSubjectIndex = 0;

  _SubjectFileGroup get _selectedSubject => _subjects[_selectedSubjectIndex];

  List<String> get _fileTypes => [
    'ทั้งหมด',
    ...{for (final f in _selectedSubject.files) f.typeLabel},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectSubject(int index) {
    if (index == _selectedSubjectIndex) return;
    setState(() {
      _selectedSubjectIndex = index;
      _selectedType = 'ทั้งหมด';
    });
  }

  List<CourseFile> get _filteredFiles {
    return _selectedSubject.files.where((f) {
      final matchesQuery =
          _query.isEmpty ||
          f.name.toLowerCase().contains(_query.toLowerCase()) ||
          f.chapterLabel.toLowerCase().contains(_query.toLowerCase());
      final matchesType =
          _selectedType == 'ทั้งหมด' || f.typeLabel == _selectedType;
      return matchesQuery && matchesType;
    }).toList();
  }

  /// จัดกลุ่มตามบทเรียน คงลำดับตามที่ไฟล์ปรากฏครั้งแรกใน [courseFiles]
  /// แทนการเรียง A-Z เพื่อให้เอกสารประจำวิชา/บทหลังๆ ยังโผล่บนสุดตามเดิม
  Map<String, List<CourseFile>> get _groupedFiles {
    final grouped = <String, List<CourseFile>>{};
    for (final file in _filteredFiles) {
      grouped.putIfAbsent(file.chapterLabel, () => []).add(file);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedFiles;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SchoolPalette.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'ไฟล์ประกอบวิชา',
          style: TextStyle(
            color: SchoolPalette.ink,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        // Align(topCenter) instead of Center() — Center() vertically
        // centers the whole scroll view when content is shorter than the
        // viewport (e.g. after filtering down to few files), making the
        // page look like it "shrinks to the middle" instead of staying
        // pinned to the top like every other page.
        child: Align(
          alignment: Alignment.topCenter,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 1024;
              return ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 720),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 520 ? 14 : 16,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'เลือกรายวิชา',
                        style: TextStyle(
                          color: SchoolPalette.navy,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildSubjectSelector(),
                      const SizedBox(height: 18),
                      Text(
                        '${_selectedSubject.files.length} ไฟล์ · รวมทุกบทเรียนของ'
                        '${_selectedSubject.subjectName}',
                        style: const TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSearchField(),
                      const SizedBox(height: 10),
                      _buildTypeFilterRow(),
                      const SizedBox(height: 16),
                      if (grouped.isEmpty)
                        _buildEmptyState()
                      else
                        for (final entry in grouped.entries) ...[
                          _buildChapterHeader(entry.key),
                          const SizedBox(height: 10),
                          for (final file in entry.value) ...[
                            CourseFileCard(file: file),
                            const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 6),
                        ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _subjects.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final subject = _subjects[index];
          final selected = index == _selectedSubjectIndex;
          return GestureDetector(
            onTap: () => _selectSubject(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 132,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? subject.color : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? subject.color : SchoolPalette.glassBorder,
                  width: 1.4,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: subject.color.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    subject.icon,
                    size: 20,
                    color: selected ? Colors.white : subject.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subject.subjectName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selected ? Colors.white : SchoolPalette.navy,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      style: const TextStyle(color: SchoolPalette.navy, fontSize: 13.5),
      onChanged: (value) => setState(() => _query = value),
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อไฟล์หรือบทเรียน...',
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {
                  _searchController.clear();
                  setState(() => _query = '');
                },
              ),
        fillColor: Colors.white,
        filled: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: SchoolPalette.deepGreen,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypeFilterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final type in _fileTypes)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                selected: _selectedType == type,
                label: Text(type),
                labelStyle: TextStyle(
                  color: _selectedType == type
                      ? Colors.white
                      : SchoolPalette.navy,
                  fontWeight: _selectedType == type
                      ? FontWeight.w900
                      : FontWeight.w700,
                  fontSize: 12.5,
                ),
                selectedColor: SchoolPalette.deepGreen,
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                  side: BorderSide(
                    color: _selectedType == type
                        ? SchoolPalette.deepGreen
                        : SchoolPalette.glassBorder,
                  ),
                ),
                onSelected: (_) => setState(() => _selectedType = type),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChapterHeader(String label) {
    return Row(
      children: [
        const Icon(Icons.folder_rounded, size: 16, color: SchoolPalette.muted),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: SchoolPalette.navy,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 34,
            color: SchoolPalette.muted,
          ),
          const SizedBox(height: 10),
          const Text(
            'ไม่พบไฟล์ที่ค้นหา',
            style: TextStyle(
              color: SchoolPalette.navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'ลองค้นหาด้วยคำอื่น หรือเปลี่ยนตัวกรองประเภทไฟล์',
            style: TextStyle(
              color: SchoolPalette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CourseFile {
  const CourseFile({
    required this.chapterLabel,
    required this.typeLabel,
    required this.name,
    required this.sizeValue,
    required this.sizeUnit,
    required this.color,
  });

  final String chapterLabel;
  final String typeLabel;
  final String name;
  final double sizeValue;
  final String sizeUnit;
  final Color color;

  String get sizeLabel => '${_formatNumber(sizeValue)} $sizeUnit';

  static String _formatNumber(double value) {
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(1);
  }
}

/// Folded-corner document glyph with a colored file-type tag overlapping
/// the bottom edge — mirrors the reference "dog-ear" file icon style.
class _FileTypeIcon extends StatelessWidget {
  const _FileTypeIcon({required this.typeLabel, required this.color});

  final String typeLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (typeLabel == 'PDF') {
      return SizedBox(
        width: 46,
        height: 56,
        child: Image.asset(
          'assets/images/pdf-file-icon-512.png',
          fit: BoxFit.contain,
        ),
      );
    }

    return SizedBox(
      width: 46,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(38, 46),
              painter: _DocumentFoldPainter(),
            ),
          ),
          Positioned(
            left: 0,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                typeLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentFoldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const fold = 10.0;
    final pagePath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width - fold, 0)
      ..lineTo(size.width, fold)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawShadow(pagePath, Colors.black.withValues(alpha: 0.12), 3, false);

    final pagePaint = Paint()..color = const Color(0xFFF3F5F4);
    canvas.drawPath(pagePath, pagePaint);

    final borderPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(pagePath, borderPaint);

    final foldPath = Path()
      ..moveTo(size.width - fold, 0)
      ..lineTo(size.width, fold)
      ..lineTo(size.width - fold, fold)
      ..close();
    canvas.drawPath(foldPath, Paint()..color = const Color(0xFFDDE3E0));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CourseFileCard extends StatefulWidget {
  const CourseFileCard({super.key, required this.file});

  final CourseFile file;

  @override
  State<CourseFileCard> createState() => _CourseFileCardState();
}

enum _DownloadState { idle, downloading, completed }

class _CourseFileCardState extends State<CourseFileCard> {
  _DownloadState _state = _DownloadState.idle;
  double _progress = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startDownload() {
    if (_state == _DownloadState.downloading) return;
    setState(() {
      _state = _DownloadState.downloading;
      _progress = 0;
    });
    _timer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      setState(() {
        _progress = (_progress + 0.08).clamp(0.0, 1.0);
        if (_progress >= 1.0) {
          _state = _DownloadState.completed;
          timer.cancel();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SchoolPalette.glassBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: _state == _DownloadState.idle ? _startDownload : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FileTypeIcon(typeLabel: file.typeLabel, color: file.color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SchoolPalette.navy,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_state == _DownloadState.downloading)
                            Text(
                              '${(_progress * 100).round()}%',
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          else if (_state == _DownloadState.completed)
                            const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 15,
                                  color: SchoolPalette.deepGreen,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'เสร็จสิ้น',
                                  style: TextStyle(
                                    color: SchoolPalette.deepGreen,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      if (_state != _DownloadState.idle) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: _progress,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFEDF1EF),
                            color: _state == _DownloadState.completed
                                ? SchoolPalette.deepGreen
                                : const Color(0xFFD97706),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ] else
                        const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _state == _DownloadState.idle
                                  ? file.sizeLabel
                                  : '${CourseFile._formatNumber(file.sizeValue * (_state == _DownloadState.completed ? 1 : _progress))} ${file.sizeUnit} of ${file.sizeLabel}',
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (_state == _DownloadState.idle)
                            FilledButton.icon(
                              onPressed: _startDownload,
                              icon: const Icon(
                                Icons.download_rounded,
                                size: 14,
                              ),
                              label: const Text('ดาวน์โหลด'),
                              style: FilledButton.styleFrom(
                                backgroundColor: SchoolPalette.deepGreen,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                textStyle: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
