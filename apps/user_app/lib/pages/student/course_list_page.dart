import 'package:flutter/material.dart';
import 'course_detail_page.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock data for courses
    final courses = [
      {
        'id': '1',
        'name': 'วิทยาศาสตร์ ม.3',
        'teacher': 'ครูสมปอง สุขใจ',
        'status': 'active',
      },
      {
        'id': '2',
        'name': 'โครงงาน IoT เบื้องต้น',
        'teacher': 'ครูสายฟ้า พาเพลิน',
        'status': 'active',
      },
      {
        'id': '3',
        'name': 'คณิตศาสตร์พื้นฐาน ม.3',
        'teacher': 'ครูวิภา งามตา',
        'status': 'closed', // ปิดแล้ว
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายวิชาของฉัน'),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: courses.length,
        itemBuilder: (context, index) {
          final course = courses[index];
          final isActive = course['status'] == 'active';
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                course['name']!,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('สอนโดย: ${course['teacher']}'),
                    const SizedBox(height: 8),
                    if (!isActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ปิดแล้ว — ดูอย่างเดียว',
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                      )
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CourseDetailPage(
                      courseName: course['name']!,
                      isActive: isActive,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
