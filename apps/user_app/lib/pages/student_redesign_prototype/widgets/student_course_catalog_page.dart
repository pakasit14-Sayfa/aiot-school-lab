import 'package:flutter/material.dart';
import 'student_redesign_palette.dart';
import 'student_lessons_page.dart';
import 'student_assignments_page.dart';

class StudentCourseCatalogPage extends StatefulWidget {
  const StudentCourseCatalogPage({
    super.key,
    this.showAppBar = true,
    this.searchPopupTick,
  });

  final bool showAppBar;
  final ValueNotifier<int>? searchPopupTick;

  @override
  State<StudentCourseCatalogPage> createState() =>
      _StudentCourseCatalogPageState();
}

class _StudentCourseCatalogPageState extends State<StudentCourseCatalogPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  int _lastSearchPopupTick = 0;
  bool _isSearchPopupOpen = false;

  final List<_SearchSuggestion> _searchSuggestions = const [
    _SearchSuggestion(label: 'ทั้งหมด', query: ''),
    _SearchSuggestion(label: 'AIoT', query: 'AIoT'),
    _SearchSuggestion(label: 'วิทย์', query: 'วิทย์'),
    _SearchSuggestion(label: 'งานค้าง', query: 'งานค้าง'),
    _SearchSuggestion(label: 'ครูสมชาย', query: 'ครูสมชาย'),
  ];

  @override
  void initState() {
    super.initState();
    widget.searchPopupTick?.addListener(_handleExternalSearchRequest);
  }

  @override
  void didUpdateWidget(covariant StudentCourseCatalogPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchPopupTick != widget.searchPopupTick) {
      oldWidget.searchPopupTick?.removeListener(_handleExternalSearchRequest);
      widget.searchPopupTick?.addListener(_handleExternalSearchRequest);
    }
  }

  void _handleExternalSearchRequest() {
    final tick = widget.searchPopupTick?.value ?? 0;
    if (tick == _lastSearchPopupTick) {
      return;
    }
    _lastSearchPopupTick = tick;
    _showSearchPopup();
  }

  Future<void> _showSearchPopup() async {
    if (!mounted || _isSearchPopupOpen) {
      return;
    }

    _isSearchPopupOpen = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'ค้นหารายวิชาและบทเรียน',
                          style: TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: const Color(0xFF334155),
                        tooltip: 'ปิด',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildSearchSuggestionChips(),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: () {
                        _clearSearch();
                        Navigator.of(dialogContext).pop();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('ล้างคำค้น'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    _isSearchPopupOpen = false;
  }

  @override
  void dispose() {
    widget.searchPopupTick?.removeListener(_handleExternalSearchRequest);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _setSearchQuery(String value) {
    setState(() {
      _searchQuery = value;
      _searchController.text = value;
      _searchController.selection = TextSelection.collapsed(
        offset: value.length,
      );
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              scrolledUnderElevation: 0.5,
              title: const Text(
                'วิชาเรียนและบทเรียน',
                style: TextStyle(
                  color: Color(0xFF0F172A),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final screenWidth = constraints.maxWidth;
                final isDesktop = screenWidth >= 1024;
                final horizontalPadding = screenWidth < 520 ? 12.0 : 16.0;

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isDesktop ? 1080 : 760),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchableSectionHeader(context),
                        const SizedBox(height: 18),
                        _buildCourseGrid(screenWidth),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableSectionHeader(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.school_rounded,
                          color: Color(0xFF059669),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'ห้องเรียนของฉัน',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      borderRadius: BorderRadius.all(Radius.circular(20)),
                      border: Border.fromBorderSide(
                        BorderSide(color: Color(0xFFA7F3D0)),
                      ),
                    ),
                    child: const Text(
                      'ปีการศึกษา 2569 · 5 วิชา',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        autofocus: true,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _searchQuery = value),
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        decoration: InputDecoration(
          hintText: 'ค้นหารายวิชา บทเรียน หรือครูผู้สอน',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF059669),
            size: 20,
          ),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _clearSearch();
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minHeight: 24,
            minWidth: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSearchSuggestionChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _searchSuggestions.map((suggestion) {
        final selected = suggestion.query.isEmpty
            ? _searchQuery.isEmpty
            : _searchQuery.toLowerCase() == suggestion.query.toLowerCase();

        return InkWell(
          onTap: () => _setSearchQuery(suggestion.query),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? const Color(0xFF93C5FD)
                    : const Color(0xFFD7E1EA),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  suggestion.icon,
                  size: 14,
                  color: selected
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 6),
                Text(
                  suggestion.label,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF1D4ED8)
                        : const Color(0xFF334155),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCourseGrid(double screenWidth) {
    final courses = [
      const CourseClassroomCardItem(
        code: 'AIOT-501',
        title: 'วิชา AIoT สมาร์ตแล็บเพื่อการเรียนรู้',
        teacher: 'ครูสมชาย สายวิทย์',
        studentsCount: '32 คน',
        themeColor: Color(0xFF0F3E33),
        headerGradient: [Color(0xFF0F3E33), Color(0xFF134E4A)],
        icon: Icons.memory_rounded,
        progress: 0.60,
        progressText: '60% (12/20 บทเรียน)',
        urgentBadge: '🔴 2 งานค้างส่ง',
        badgeBg: Color(0xFFFFE4E6),
        badgeText: Color(0xFFE11D48),
        nextLesson: 'บทที่ 13 การวัดค่าฝุ่น PM2.5',
      ),
      const CourseClassroomCardItem(
        code: 'PHYS-302',
        title: 'วิชา ฟิสิกส์ประยุกต์และการทดลอง',
        teacher: 'ครูวิภาดา วิทยาศาสตร์',
        studentsCount: '30 คน',
        themeColor: Color(0xFF134E4A),
        headerGradient: [Color(0xFF134E4A), Color(0xFF165042)],
        icon: Icons.bolt_rounded,
        progress: 0.85,
        progressText: '85% (17/20 บทเรียน)',
        urgentBadge: '🟢 งานส่งครบแล้ว',
        badgeBg: Color(0xFFECFDF5),
        badgeText: Color(0xFF059669),
        nextLesson: 'บทที่ 18 คลื่นและแสงประยุกต์',
      ),
      const CourseClassroomCardItem(
        code: 'MATH-401',
        title: 'วิชา คณิตศาสตร์เพิ่มเติม (สถิติและพีชคณิต)',
        teacher: 'ครูอนันต์ คำนวณ',
        studentsCount: '35 คน',
        themeColor: Color(0xFF1E293B),
        headerGradient: [Color(0xFF1E293B), Color(0xFF334155)],
        icon: Icons.calculate_rounded,
        progress: 0.40,
        progressText: '40% (8/20 บทเรียน)',
        urgentBadge: '🔵 1 งานกำลังทำ',
        badgeBg: Color(0xFFE0F2FE),
        badgeText: Color(0xFF0284C7),
        nextLesson: 'บทที่ 9 การวิเคราะห์ความน่าจะเป็น',
      ),
      const CourseClassroomCardItem(
        code: 'SCI-204',
        title: 'วิชา วิทยาศาสตร์กายภาพและสิ่งแวดล้อม',
        teacher: 'ครูพรทิพย์ อนุรักษ์',
        studentsCount: '31 คน',
        themeColor: Color(0xFF064E3B),
        headerGradient: [Color(0xFF064E3B), Color(0xFF047857)],
        icon: Icons.science_rounded,
        progress: 0.90,
        progressText: '90% (18/20 บทเรียน)',
        urgentBadge: '🔴 1 งานค้างส่ง',
        badgeBg: Color(0xFFFFE4E6),
        badgeText: Color(0xFFE11D48),
        nextLesson: 'บทที่ 19 สภาพภูมิอากาศเมือง',
      ),
      const CourseClassroomCardItem(
        code: 'BIO-105',
        title: 'วิชา ชีววิทยาและการสังเคราะห์แสง',
        teacher: 'ครูนภา ชีวิน',
        studentsCount: '28 คน',
        themeColor: Color(0xFF0F3E33),
        headerGradient: [Color(0xFF0F3E33), Color(0xFF165042)],
        icon: Icons.nature_people_rounded,
        progress: 0.75,
        progressText: '75% (15/20 บทเรียน)',
        urgentBadge: '⭐ ตรวจแล้ว (A+)',
        badgeBg: Color(0xFFFEF3C7),
        badgeText: Color(0xFFD97706),
        nextLesson: 'บทที่ 16 โครงสร้างเซลล์พืช',
      ),
    ];

    final filteredCourses = courses
        .where((course) => course.matchesQuery(_searchQuery))
        .toList();

    if (screenWidth >= 768) {
      if (filteredCourses.isEmpty) {
        return const _EmptyCourseState();
      }
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: filteredCourses.map((card) {
          return SizedBox(
            width: (screenWidth >= 1024 ? 1080 : 760) / 2 - 24,
            child: card,
          );
        }).toList(),
      );
    } else {
      if (filteredCourses.isEmpty) {
        return const _EmptyCourseState();
      }
      return Column(
        children: filteredCourses.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: card,
          );
        }).toList(),
      );
    }
  }
}

class _SearchSuggestion {
  const _SearchSuggestion({required this.label, required this.query});

  final String label;
  final String query;

  IconData get icon {
    switch (label) {
      case 'AIoT':
        return Icons.memory_rounded;
      case 'วิทย์':
        return Icons.science_rounded;
      case 'งานค้าง':
        return Icons.assignment_rounded;
      case 'ครูสมชาย':
        return Icons.person_search_rounded;
      default:
        return Icons.grid_view_rounded;
    }
  }
}

class _EmptyCourseState extends StatelessWidget {
  const _EmptyCourseState();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off_rounded, color: Color(0xFF94A3B8), size: 34),
          SizedBox(height: 10),
          Text(
            'ไม่พบรายวิชาที่ตรงกับคำค้น',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ลองค้นหาด้วยรหัสวิชา ชื่อวิชา หรือชื่อครูผู้สอน',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class CourseClassroomCardItem extends StatelessWidget {
  const CourseClassroomCardItem({
    super.key,
    required this.code,
    required this.title,
    required this.teacher,
    required this.studentsCount,
    required this.themeColor,
    required this.headerGradient,
    required this.icon,
    required this.progress,
    required this.progressText,
    required this.urgentBadge,
    required this.badgeBg,
    required this.badgeText,
    required this.nextLesson,
  });

  final String code;
  final String title;
  final String teacher;
  final String studentsCount;
  final Color themeColor;
  final List<Color> headerGradient;
  final IconData icon;
  final double progress;
  final String progressText;
  final String urgentBadge;
  final Color badgeBg;
  final Color badgeText;
  final String nextLesson;

  bool matchesQuery(String query) {
    final normalized = query.trim().toLowerCase();
    if (normalized.isEmpty) {
      return true;
    }

    final haystack = <String>[
      code,
      title,
      teacher,
      studentsCount,
      progressText,
      urgentBadge,
      nextLesson,
    ].join(' ').toLowerCase();

    return haystack.contains(normalized);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const StudentLessonsPage()),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: headerGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white30),
                          ),
                          child: Text(
                            code,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            urgentBadge,
                            style: TextStyle(
                              color: badgeText,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          color: Colors.white70,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '$teacher · $studentsCount',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ความคืบหน้าการเรียน:',
                          style: TextStyle(
                            color: SchoolPalette.muted,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          progressText,
                          style: const TextStyle(
                            color: Color(0xFF0F3E33),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: const Color(0xFFF1F5F9),
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFFECFDF5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF059669),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nextLesson,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: SchoolPalette.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF059669),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'เรียนต่อ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentAssignmentsPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.assignment_outlined, size: 15),
                          label: const Text('ดูการบ้าน'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SchoolPalette.ink,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            side: const BorderSide(color: Color(0xFFCBD5E1)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const StudentLessonsPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            minimumSize: const Size(0, 36),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'เข้าเรียน',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 3),
                              Icon(Icons.arrow_forward_rounded, size: 14),
                            ],
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
    );
  }
}
