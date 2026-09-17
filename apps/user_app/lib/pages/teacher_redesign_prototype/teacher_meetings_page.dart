import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import '../executive_redesign_prototype/pages/director_meetings_page.dart';
import 'teacher_staff_requests_card.dart';

class TeacherMeetingsPage extends StatelessWidget {
  const TeacherMeetingsPage({super.key, this.staffRequestService});

  /// Test seam for the "คำขอของฉัน" card.
  final StaffRequestService? staffRequestService;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('ประชุม / เรียกพบ')),
    body: Column(
      children: [
        // 2026-09-17: teachers can finally file the requests executives
        // review — create_staff_request had no caller before this.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TeacherStaffRequestsCard(service: staffRequestService),
        ),
        // DirectorMeetingsPage scrolls on its own and expects bounded height.
        const Expanded(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: DirectorMeetingsPage(allowOrganize: false),
          ),
        ),
      ],
    ),
  );
}
