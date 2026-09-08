import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:url_launcher/url_launcher.dart';
import 'student_redesign_palette.dart';

class _CourseFileGroup {
  const _CourseFileGroup({
    required this.courseName,
    required this.icon,
    required this.color,
    required this.files,
  });

  final String courseName;
  final IconData icon;
  final Color color;
  final List<CourseFile> files;
}

String _typeLabelFor(String fileName) {
  final dot = fileName.lastIndexOf('.');
  if (dot == -1 || dot == fileName.length - 1) return 'FILE';
  return fileName.substring(dot + 1).toUpperCase();
}

const _imageExtensions = {'JPG', 'JPEG', 'PNG', 'GIF', 'WEBP', 'BMP'};
bool _isImageType(String typeLabel) => _imageExtensions.contains(typeLabel);

class StudentCourseFilesPage extends StatefulWidget {
  const StudentCourseFilesPage({
    super.key,
    this.loadCourses,
    this.listFiles,
  });

  /// Read seams threaded to the corresponding CourseService/
  /// CourseFileService static calls in production.
  final Future<List<CourseSummary>> Function()? loadCourses;
  final Future<List<CourseFile>> Function(String courseId)? listFiles;

  @override
  State<StudentCourseFilesPage> createState() => _StudentCourseFilesPageState();
}

class _StudentCourseFilesPageState extends State<StudentCourseFilesPage> {
  static const _icons = [
    Icons.memory_rounded,
    Icons.bolt_rounded,
    Icons.calculate_rounded,
    Icons.eco_rounded,
    Icons.science_rounded,
    Icons.menu_book_rounded,
  ];
  static const _colors = [
    Color(0xFF0D9488),
    Color(0xFF0284C7),
    Color(0xFF7C3AED),
    Color(0xFF16A34A),
    Color(0xFFD97706),
    Color(0xFFDC2626),
  ];

  bool _loading = true;
  String? _error;
  List<_CourseFileGroup> _groups = const [];
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedType = 'ทั้งหมด';
  int _selectedGroupIndex = 0;

  _CourseFileGroup? get _selectedGroup => _groups.isEmpty
      ? null
      : _groups[_selectedGroupIndex.clamp(0, _groups.length - 1)];

  List<String> get _fileTypes {
    final group = _selectedGroup;
    if (group == null) return const ['ทั้งหมด'];
    return [
      'ทั้งหมด',
      ...{for (final f in group.files) _typeLabelFor(f.fileName)},
    ];
  }

  List<CourseFile> get _filteredFiles {
    final group = _selectedGroup;
    if (group == null) return const [];
    return group.files.where((f) {
      final matchesQuery =
          _query.isEmpty ||
          f.fileName.toLowerCase().contains(_query.toLowerCase());
      final matchesType =
          _selectedType == 'ทั้งหมด' ||
          _typeLabelFor(f.fileName) == _selectedType;
      return matchesQuery && matchesType;
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loadCourses = widget.loadCourses ?? CourseService.listMyCourses;
      final loadFiles = widget.listFiles ?? CourseFileService.listFiles;
      final courses = (await loadCourses())
          .where((c) => c.isActive)
          .toList();
      final fileLists = await Future.wait(
        courses.map((c) => loadFiles(c.id)),
      );
      final groups = <_CourseFileGroup>[];
      for (var i = 0; i < courses.length; i++) {
        groups.add(
          _CourseFileGroup(
            courseName: courses[i].subjectName,
            icon: _icons[i % _icons.length],
            color: _colors[i % _colors.length],
            files: fileLists[i],
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _groups = groups;
        _selectedGroupIndex = 0;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'โหลดข้อมูลไม่สำเร็จ';
        _loading = false;
      });
    }
  }

  void _selectGroup(int index) {
    if (index == _selectedGroupIndex) return;
    setState(() {
      _selectedGroupIndex = index;
      _selectedType = 'ทั้งหมด';
    });
  }

  @override
  Widget build(BuildContext context) {
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
        child: RefreshIndicator(
          onRefresh: _load,
          child: Align(
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 1024;
                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1000 : 720),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: constraints.maxWidth < 520 ? 14 : 16,
                      vertical: 16,
                    ),
                    child: _loading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 60),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : _buildBody(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return _buildErrorBanner();
    }
    if (_groups.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            'ยังไม่มีรายวิชาที่ลงทะเบียน',
            style: TextStyle(color: SchoolPalette.muted, fontSize: 13),
          ),
        ),
      );
    }

    final group = _selectedGroup!;
    final files = _filteredFiles;

    return Column(
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
          '${group.files.length} ไฟล์ · ${group.courseName}',
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
        if (files.isEmpty)
          _buildEmptyState()
        else
          for (final file in files) ...[
            CourseFileCard(file: file),
            const SizedBox(height: 12),
          ],
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFDC2626),
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                color: Color(0xFFB91C1C),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(onPressed: _load, child: const Text('ลองใหม่')),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _groups.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final group = _groups[index];
          final selected = index == _selectedGroupIndex;
          return GestureDetector(
            onTap: () => _selectGroup(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 132,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? group.color : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: selected ? group.color : SchoolPalette.glassBorder,
                  width: 1.4,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: group.color.withValues(alpha: 0.3),
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
                    group.icon,
                    size: 20,
                    color: selected ? Colors.white : group.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    group.courseName,
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
        hintText: 'ค้นหาชื่อไฟล์...',
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
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 34, color: SchoolPalette.muted),
          SizedBox(height: 10),
          Text(
            'ยังไม่มีไฟล์ในวิชานี้',
            style: TextStyle(
              color: SchoolPalette.navy,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

/// Folded-corner document glyph with a colored file-type tag overlapping
/// the bottom edge.
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
  const CourseFileCard({super.key, required this.file, this.getDownloadUrl});

  final CourseFile file;

  /// Read seam threaded to CourseFileService.getDownloadUrl in production.
  final Future<String> Function(String fileId)? getDownloadUrl;

  @override
  State<CourseFileCard> createState() => _CourseFileCardState();
}

class _CourseFileCardState extends State<CourseFileCard> {
  bool _opening = false;
  String? _error;

  bool get _isImage => _isImageType(_typeLabelFor(widget.file.fileName));

  Future<void> _openFile() async {
    if (_isImage) {
      await _previewImage();
      return;
    }
    setState(() {
      _opening = true;
      _error = null;
    });
    try {
      final getUrl = widget.getDownloadUrl ?? CourseFileService.getDownloadUrl;
      final url = await getUrl(widget.file.id);
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, webOnlyWindowName: '_blank');
      if (!launched) throw Exception('เปิดลิงก์ไม่สำเร็จ');
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'ดาวน์โหลดไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  /// รูปภาพ — เปิดดูในแอปเลย ไม่ต้องดาวน์โหลด/เปิดแท็บใหม่
  Future<void> _previewImage() async {
    setState(() {
      _opening = true;
      _error = null;
    });
    String? url;
    try {
      final getUrl = widget.getDownloadUrl ?? CourseFileService.getDownloadUrl;
      url = await getUrl(widget.file.id);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'เปิดรูปภาพไม่สำเร็จ');
    } finally {
      if (mounted) setState(() => _opening = false);
    }
    if (url == null || !mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  url!,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Padding(
                      padding: EdgeInsets.all(48),
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Container(
                    padding: const EdgeInsets.all(32),
                    color: Colors.white,
                    child: const Text('โหลดรูปภาพไม่สำเร็จ'),
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: () => Navigator.pop(ctx),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withValues(alpha: 0.5),
              ),
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = widget.file;
    final typeLabel = _typeLabelFor(file.fileName);
    const accent = SchoolPalette.deepGreen;
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
          onTap: _opening ? null : _openFile,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FileTypeIcon(typeLabel: typeLabel, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.navy,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'อัปโหลดโดย ${file.uploaderFullName}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: SchoolPalette.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: Color(0xFFDC2626),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              file.formattedSize,
                              style: const TextStyle(
                                color: SchoolPalette.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _opening ? null : _openFile,
                            icon: _opening
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(
                                    _isImage
                                        ? Icons.visibility_rounded
                                        : Icons.download_rounded,
                                    size: 14,
                                  ),
                            label: Text(_isImage ? 'ดูรูปภาพ' : 'ดาวน์โหลด'),
                            style: FilledButton.styleFrom(
                              backgroundColor: accent,
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
