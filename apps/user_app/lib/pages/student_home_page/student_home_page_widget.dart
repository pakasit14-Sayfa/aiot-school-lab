import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../student_redesign_prototype/widgets/widgets.dart';

/// Student Home Dashboard — Official Production Page.
/// Implements the finalized Variant A design (Single Source of Truth) with real Supabase / Realtime bindings.
class StudentHomePageWidget extends StatefulWidget {
  const StudentHomePageWidget({super.key});

  static String routeName = 'StudentHomePage';
  static String routePath = '/studentHomePage';

  @override
  State<StudentHomePageWidget> createState() => _StudentHomePageWidgetState();
}

class _StudentHomePageWidgetState extends State<StudentHomePageWidget> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Future<void> _handleRefresh() async {
    final user = currentUserModel;
    final schoolId = user?.schoolId ?? '';
    final building = user?.building ?? '';
    final room = user?.room ?? '';

    try {
      await Future.wait([
        CourseService.listMyCourses(),
        if (schoolId.isNotEmpty)
          RealtimeService.getSensorOnce(
            schoolId: schoolId,
            building: building,
            floor: '1',
            room: room,
          ),
      ]);
    } catch (_) {
      // Graceful fallback for offline mode
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      backgroundColor: const Color(0xFFFFFCF3),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFECFDF5),
                border: Border(
                  bottom: BorderSide(color: Color(0xFFA7F3D0), width: 1.0),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 15,
                    color: Color(0xFF059669),
                  ),
                  SizedBox(width: 6),
                  Text(
                    '🚀 ระบบจริง (PRODUCTION SYSTEM) · หน้าแรกนักเรียน',
                    style: TextStyle(
                      color: Color(0xFF047857),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _handleRefresh,
                color: SchoolPalette.green,
                child: const StudentVariantSchoolHome(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
