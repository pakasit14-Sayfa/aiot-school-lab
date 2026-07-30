import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_core/shared_core.dart';
import '../student/course_list_page.dart';
import '../student/course_detail_page.dart';
import '../student/grades_overview_page.dart';
import '../profile_page.dart';
import 'student_home_page_model.dart';
export 'student_home_page_model.dart';

/// Student Home Dashboard — real course list + real sensor readings.
class StudentHomePageWidget extends StatefulWidget {
  const StudentHomePageWidget({super.key});

  static String routeName = 'StudentHomePage';
  static String routePath = '/studentHomePage';

  @override
  State<StudentHomePageWidget> createState() => _StudentHomePageWidgetState();
}

class _StudentHomePageWidgetState extends State<StudentHomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<CourseSummary> _courses = [];
  bool _isLoadingCourses = true;
  SensorModel? _sensor;
  bool _isLoadingSensor = true;

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _loadSensor();
  }

  Future<void> _loadCourses() async {
    setState(() => _isLoadingCourses = true);
    try {
      final result = await CourseService.listMyCourses();
      if (!mounted) return;
      setState(() => _courses = result);
    } catch (_) {
      // Home page tolerates a failed course fetch; CourseListPage shows the real error.
    } finally {
      if (mounted) setState(() => _isLoadingCourses = false);
    }
  }

  Future<void> _loadSensor() async {
    final user = currentUserModel;
    final schoolId = user?.schoolId ?? '';
    final building = user?.building ?? '';
    final room = user?.room ?? '';
    if (schoolId.isEmpty) {
      setState(() => _isLoadingSensor = false);
      return;
    }
    setState(() => _isLoadingSensor = true);
    try {
      final result = await RealtimeService.getSensorOnce(
        schoolId: schoolId,
        building: building,
        floor: '1',
        room: room,
      );
      if (!mounted) return;
      setState(() => _sensor = result);
    } catch (_) {
      // No sensor data available; the card below shows an honest placeholder.
    } finally {
      if (mounted) setState(() => _isLoadingSensor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    final name = user?.name ?? 'นักเรียน';
    final building = user?.building ?? '';
    final room = user?.room ?? '';

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([_loadCourses(), _loadSensor()]),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Perfectly Balanced Green Header + Floating Frosted Glass Card
              _buildPerfectOverlappingHeader(name, building, room),

              // 2. Space for the overlapping floating card
              const SizedBox(height: 80),

              // 3. Main Content Body
              Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 800),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Access Title
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Quick Access',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CourseListPage()),
                              );
                            },
                            child: Text(
                              'View All',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF059669),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // Quick Access Grid
                      _buildPerfectQuickAccessGrid(context),

                      const SizedBox(height: 28),

                      // Enrolled Courses Progress Section
                      _buildEnrolledCoursesSection(context),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPerfectOverlappingHeader(String name, String building, String room) {
    return Column(
      children: [
        // Top Emerald Gradient Container
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF047857), Color(0xFF10B981)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(36),
              bottomRight: Radius.circular(36),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'ST',
                      style: TextStyle(
                        color: Color(0xFF047857),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'สวัสดี, $name 👋',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          room.isEmpty && building.isEmpty
                              ? 'ยังไม่กำหนดห้องเรียน'
                              : [
                                  if (room.isNotEmpty) 'ห้อง $room',
                                  if (building.isNotEmpty) building,
                                ].join(' • '),
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Floating Glass Card in clean layout flow
        Transform.translate(
          offset: const Offset(0, -28),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF047857).withOpacity(0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ข้อมูลเซนเซอร์ห้องเรียน',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF0F172A).withOpacity(0.85),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _sensor?.updatedAt != null
                                      ? 'อัปเดตล่าสุด ${_sensor!.updatedAt!.hour.toString().padLeft(2, '0')}:${_sensor!.updatedAt!.minute.toString().padLeft(2, '0')}'
                                      : (_isLoadingSensor ? 'กำลังโหลด...' : 'ยังไม่มีข้อมูล'),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF0F172A),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            if (_sensor?.updatedAt != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF059669),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF059669).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'Live',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        if (_sensor?.updatedAt == null)
                          Text(
                            'ยังไม่มีข้อมูลเซนเซอร์สำหรับห้องเรียนนี้',
                            style: GoogleFonts.plusJakartaSans(
                              color: const Color(0xFF64748B),
                              fontSize: 12.5,
                            ),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStatusMetric('${_sensor!.temperature.toStringAsFixed(1)}°C', 'Temp', Icons.thermostat_rounded, const Color(0xFF0284C7)),
                              _buildStatusMetric('${_sensor!.humidity.toStringAsFixed(0)}%', 'Humidity', Icons.water_drop_rounded, const Color(0xFF0284C7)),
                              _buildStatusMetric('${_sensor!.pm25.toStringAsFixed(0)} µg', 'PM2.5', Icons.air_rounded, const Color(0xFF059669)),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusMetric(String value, String label, IconData icon, Color iconColor) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, color: iconColor, size: 19),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF334155),
            fontWeight: FontWeight.w600,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPerfectQuickAccessGrid(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 640 ? 4 : 2;
    final double childAspectRatio = screenWidth > 640 ? 1.5 : 1.25;

    final coursesSubtitle = _isLoadingCourses
        ? 'กำลังโหลด...'
        : '${_courses.length} วิชา';

    final items = [
      {
        'title': 'My Courses',
        'subtitle': coursesSubtitle,
        'icon': Icons.school_rounded,
        'iconColor': const Color(0xFF059669),
        'cardBg': const Color(0xFFEBF5ED),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CourseListPage()),
          );
        },
      },
      {
        'title': 'Grades',
        'subtitle': 'ดูผลการเรียน',
        'icon': Icons.bar_chart_rounded,
        'iconColor': const Color(0xFF0284C7),
        'cardBg': const Color(0xFFE6F7F7),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GradesOverviewPage()),
          );
        },
      },
      {
        'title': 'Assignments',
        'subtitle': 'ดูในแต่ละวิชา',
        'icon': Icons.assignment_outlined,
        'iconColor': const Color(0xFF2563EB),
        'cardBg': const Color(0xFFEBF5ED),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CourseListPage()),
          );
        },
      },
      {
        'title': 'Profile',
        'subtitle': 'Settings',
        'icon': Icons.person_rounded,
        'iconColor': const Color(0xFF334155),
        'cardBg': const Color(0xFFE6F7F7),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfilePage()),
          );
        },
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: childAspectRatio,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final Color cardBg = item['cardBg'] as Color;
        final Color iconColor = item['iconColor'] as Color;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: item['onTap'] as VoidCallback,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item['icon'] as IconData, color: iconColor, size: 22),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['title'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEnrolledCoursesSection(BuildContext context) {
    final placeholderColors = [
      const Color(0xFF059669),
      const Color(0xFF0284C7),
      const Color(0xFF6366F1),
      const Color(0xFFD97706),
    ];
    final placeholderIcons = [
      Icons.eco_rounded,
      Icons.memory_rounded,
      Icons.biotech_rounded,
      Icons.bolt_rounded,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'วิชาเรียนของฉัน',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 16.5,
                color: const Color(0xFF0F172A),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CourseListPage()),
                );
              },
              child: Text(
                'ทั้งหมด',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_isLoadingCourses)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_courses.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'คุณยังไม่ได้ลงทะเบียนเรียนในรายวิชาใดเลย',
              style: TextStyle(color: Colors.grey),
            ),
          )
        else
          ..._courses.take(3).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final course = entry.value;
            final color = placeholderColors[index % placeholderColors.length];
            final icon = placeholderIcons[index % placeholderIcons.length];

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            if (course.gradeLevel != null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(course.gradeLevel!, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11.5)),
                              ),
                            if (course.room != null)
                              Text('ห้องเรียน ${course.room}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(course.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => CourseDetailPage(courseId: course.id)),
                      );
                    },
                    child: const Text('เข้าเรียน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
