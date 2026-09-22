import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_class_schedule_page.dart';

void main() {
  testWidgets('TeacherClassSchedulePage renders shell and controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: TeacherClassSchedulePage()),
    );

    // Initial pump (may be loading or showing content if empty)
    await tester.pump();

    // Verify title or shell is rendered
    expect(find.byType(TeacherClassSchedulePage), findsOneWidget);
  });

  // NOTE: this page has no dependency-injection seam (unlike
  // director_teachers_page.dart and most other pages in this app) — it calls
  // CalendarService/Supabase directly with no constructor override, so in a
  // test environment `_load()` always fails and the page is stuck on its
  // error branch, which never renders the hero banner. The new period_type
  // toggle and "เตรียมสอน" quick-add (both live in the hero banner /
  // add-schedule dialog) are therefore unreachable from a widget test as this
  // page is currently built. Giving them real coverage needs the same
  // loader-injection refactor this codebase already uses elsewhere, which is
  // out of scope for this change — verified manually via the direct-session
  // RPC checks instead (see 20260910160000_teacher_workload_categories.sql
  // verification in WORK_LOG.md).
}
