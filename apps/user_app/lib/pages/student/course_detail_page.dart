import 'package:flutter/material.dart';

class CourseDetailPage extends StatelessWidget {
  final String courseName;
  final bool isActive;

  const CourseDetailPage({
    super.key,
    required this.courseName,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(courseName),
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'บทเรียน'),
              Tab(text: 'ใบงาน'),
              Tab(text: 'แบบทดสอบ'),
              Tab(text: 'คะแนน'),
              Tab(text: 'กลุ่มของฉัน'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('หน้ารายการบทเรียน')),
            Center(child: Text('หน้ารายการใบงาน/โครงงาน')),
            Center(child: Text('หน้ารายการแบบทดสอบ')),
            Center(child: Text('หน้าคะแนนวิชานี้')),
            Center(child: Text('หน้าจัดการกลุ่ม (แสดงถ้ามีการจับกลุ่ม)')),
          ],
        ),
      ),
    );
  }
}
