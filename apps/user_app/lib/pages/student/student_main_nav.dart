import 'package:flutter/material.dart';
import '../student_home_page/student_home_page_widget.dart';
import 'course_list_page.dart';
import '../profile_page.dart';

class StudentMainNav extends StatefulWidget {
  const StudentMainNav({super.key});

  @override
  State<StudentMainNav> createState() => _StudentMainNavState();
}

class _StudentMainNavState extends State<StudentMainNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const StudentHomePageWidget(),
    const CourseListPage(),
    const Center(child: Text('คะแนนของฉัน (เร็วๆ นี้)')), // Placeholder for grades
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF2E7D32), // Green school theme
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'หน้าแรก',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'รายวิชา',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'คะแนน',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'โปรไฟล์',
          ),
        ],
      ),
    );
  }
}
