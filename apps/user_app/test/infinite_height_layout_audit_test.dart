import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_academic_calendar_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_cctv_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_classrooms_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_emergency_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_environment_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_learning_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_meetings_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_notifications_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_overview_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_reports_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_settings_page.dart';
import 'package:my_first_app/pages/executive_redesign_prototype/pages/director_teachers_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_academic_calendar_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_attendance_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_dashboard_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_learning_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_schedule_page.dart';
import 'package:my_first_app/pages/parent_redesign_prototype/pages/parent/parent_settings_page.dart';

void main() {
  Widget createTestWidget(Widget child, Size size) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Scaffold(body: child),
        ),
      ),
    );
  }

  const desktopSize = Size(1200, 900);
  const mobileSize = Size(400, 800);

  group('Executive Prototype Layout Audit (Desktop & Mobile)', () {
    testWidgets('DirectorOverviewPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          DirectorOverviewPage(
            onNavigate: (_) {},
            sensorStreamOverride: const Stream.empty(),
            rawReadingsStreamOverride: const Stream.empty(),
          ),
          desktopSize,
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(
          DirectorOverviewPage(
            onNavigate: (_) {},
            sensorStreamOverride: const Stream.empty(),
            rawReadingsStreamOverride: const Stream.empty(),
          ),
          mobileSize,
        ),
      );
      await tester.pump();
    });

    testWidgets('DirectorEmergencyPage (Desktop & Mobile)', (tester) async {
      // Drive the read seams: the page's initState otherwise reaches the
      // Supabase singleton, which no widget test initializes.
      Widget page() => DirectorEmergencyPage(
        watchUpdates: false,
        loadEmergencyEvents: () async => const [],
        loadIncidentSummary: () async => const [],
        loadIncidentReports: () async => const [],
      );
      await tester.pumpWidget(createTestWidget(page(), desktopSize));
      await tester.pumpAndSettle();
      await tester.pumpWidget(createTestWidget(page(), mobileSize));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('DirectorLearningPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorLearningPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorLearningPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorTeachersPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorTeachersPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorTeachersPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorClassroomsPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorClassroomsPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorClassroomsPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorMeetingsPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorMeetingsPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorMeetingsPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorAcademicCalendarPage (Desktop & Mobile)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorAcademicCalendarPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorAcademicCalendarPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorCctvPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorCctvPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorCctvPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorEnvironmentPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorEnvironmentPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorEnvironmentPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorReportsPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorReportsPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorReportsPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorNotificationsPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorNotificationsPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorNotificationsPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('DirectorSettingsPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const DirectorSettingsPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const DirectorSettingsPage(), mobileSize),
      );
      await tester.pump();
    });
  });

  group('Parent Prototype Layout Audit (Desktop & Mobile)', () {
    testWidgets('ParentLearningPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ParentLearningPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const ParentLearningPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('ParentDashboardPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ParentDashboardPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const ParentDashboardPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('ParentAttendancePage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ParentAttendancePage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const ParentAttendancePage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('ParentAcademicCalendarPage (Desktop & Mobile)', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestWidget(const ParentAcademicCalendarPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const ParentAcademicCalendarPage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('ParentSchedulePage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ParentSchedulePage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const ParentSchedulePage(), mobileSize),
      );
      await tester.pump();
    });

    testWidgets('ParentSettingsPage (Desktop & Mobile)', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ParentSettingsPage(), desktopSize),
      );
      await tester.pump();
      await tester.pumpWidget(
        createTestWidget(const ParentSettingsPage(), mobileSize),
      );
      await tester.pump();
    });
  });
}
