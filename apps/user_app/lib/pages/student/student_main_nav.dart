import 'package:flutter/material.dart';
import '../student_redesign_prototype/student_redesign_prototype_page.dart';
import 'course_list_page.dart';
import 'grades_overview_page.dart';
import '../profile_page.dart';

class StudentMainNav extends StatefulWidget {
  const StudentMainNav({super.key});

  @override
  State<StudentMainNav> createState() => _StudentMainNavState();
}

class _StudentMainNavState extends State<StudentMainNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const StudentRedesignPrototypePage(),
    const CourseListPage(),
    const GradesOverviewPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 65,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(
            0xFF059669,
          ).withOpacity(0.15), // Emerald Pill
          selectedIndex: _selectedIndex,
          onDestinationSelected: (int index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.grid_view_rounded, color: Colors.grey),
              selectedIcon: Icon(
                Icons.grid_view_rounded,
                color: Color(0xFF059669),
              ),
              label: 'หน้าแรก',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined, color: Colors.grey),
              selectedIcon: Icon(
                Icons.groups_rounded,
                color: Color(0xFF059669),
              ),
              label: 'รายวิชา (Teams)',
            ),
            NavigationDestination(
              icon: Icon(Icons.assessment_outlined, color: Colors.grey),
              selectedIcon: Icon(
                Icons.assessment_rounded,
                color: Color(0xFF059669),
              ),
              label: 'ผลการเรียน',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.grey),
              selectedIcon: Icon(
                Icons.person_rounded,
                color: Color(0xFF059669),
              ),
              label: 'โปรไฟล์',
            ),
          ],
        ),
      ),
    );
  }
}
