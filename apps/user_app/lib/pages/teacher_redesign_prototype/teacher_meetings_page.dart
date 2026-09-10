import 'package:flutter/material.dart';
import '../executive_redesign_prototype/pages/director_meetings_page.dart';

class TeacherMeetingsPage extends StatelessWidget {
  const TeacherMeetingsPage({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ประชุม / เรียกพบ')),
    body: const Padding(
      padding: EdgeInsets.all(16),
      child: DirectorMeetingsPage(allowOrganize: false),
    ),
  );
}
