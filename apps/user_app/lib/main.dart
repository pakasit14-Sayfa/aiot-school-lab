import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/role_router.dart';
import 'pages/student_redesign_prototype/widgets/widgets.dart';
import 'pages/teacher_redesign_prototype/teacher_redesign_prototype_page.dart';
import 'pages/teacher_redesign_prototype/teacher_design_system_page.dart';
import 'pages/teacher_redesign_prototype/teacher_storybook_page.dart';
import 'pages/teacher_redesign_prototype/teacher_courses_page.dart';
import 'pages/teacher_redesign_prototype/teacher_exam_builder_page.dart';
import 'pages/teacher_redesign_prototype/teacher_grading_page.dart';
import 'pages/teacher_redesign_prototype/teacher_question_bank_page.dart';
import 'pages/teacher_redesign_prototype/teacher_knowledge_library_page.dart';
import 'pages/teacher_redesign_prototype/teacher_gscore_confirm_page.dart';
import 'pages/teacher_redesign_prototype/teacher_student_support_page.dart';
import 'pages/executive_redesign_prototype/widgets/director_navigation_shell.dart';
import 'pages/parent_redesign_prototype/widgets/parent_navigation_shell.dart';
import 'pages/teacher_redesign_prototype/teacher_parent_binding_approval_page.dart';
import 'pages/teacher_redesign_prototype/teacher_pbl_activity_editor_page.dart';
import 'pages/student_home_page/student_home_page_widget.dart';
import 'pages/dashboard/teacher_dashboard.dart';
import 'pages/teacher/course_list_page.dart';
import 'pages/super_admin/super_admin_schools_page.dart';
import 'pages/super_admin/super_admin_device_control_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  // Restore the saved session before the first frame. This call was
  // dropped by accident in ea191dd (2026-08-03, a mascot commit) and from
  // then on every cold start landed on the login page even though the
  // token had been written to secure storage — invisible on the web, where
  // the tab stays open, but a login + OTP on every launch of the phone app.
  await AuthService.initialize();
  // false = เข้า login/auth จริงตามปกติ (RoleRouter ตัดสินหน้าแรกจาก role
  // จริงใน Supabase) — เปลี่ยนกลับเป็น true ชั่วคราวได้เวลาต้องการรีวิว
  // หน้า prototype โดยไม่ผ่าน login จริง (ดู teacher_redesign_prototype/
  // NOTES.md และ student_redesign_prototype/NOTES.md)
  const isPrototypeRoute = false;
  runApp(const MyApp(isPrototypeMode: isPrototypeRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.isPrototypeMode = false});

  final bool isPrototypeMode;

  @override
  Widget build(BuildContext context) {
    final initialUri = Uri.base;

    return MaterialApp(
      title: 'USER APP',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('th', 'TH'),
        Locale('en', 'US'),
      ],
      locale: const Locale('th', 'TH'),
      theme: AppTheme.lightTheme,
      home: isPrototypeMode
          ? _buildPrototypeHome(initialUri)
          : StreamBuilder<UserModel?>(
              stream: AuthService.authStateChanges,
              initialData: currentUserModel,
              builder: (context, snapshot) {
                if (snapshot.data != null) {
                  return const RoleRouter();
                }
                return const LoginPage();
              },
            ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/users': (context) => const UserListPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
        '/studentHomePage': (context) => const StudentHomePageWidget(),
        // Dev-preview routes. Gated behind isPrototypeMode so they are not
        // registered at all in a normal build: they were previously always
        // reachable by typing the URL (e.g. /#/prototype/executive), which
        // rendered a role's shell — and, more visibly, that shell's
        // hardcoded placeholder rows (fake staff names, emails and phone
        // numbers) — to anyone, signed in or not. Real data was never at
        // risk: every RPC checks the caller's role server-side, and the
        // services return early when there is no session token. Nothing in
        // the app navigates to these paths; they are typed by hand during
        // design review only.
        if (isPrototypeMode) ...{
          '/prototype/teacher-design-system': (context) =>
              const TeacherDesignSystemPage(),
          '/prototype/teacher-redesign/design-system': (context) =>
              const TeacherDesignSystemPage(),
          '/prototype/teacher-storybook': (context) =>
              const TeacherStorybookPage(),
          '/prototype/executive': (context) => const DirectorNavigationShell(),
          '/prototype/executive-inbox': (context) =>
              const DirectorNavigationShell(),
          '/prototype/storybook': (context) => const TeacherStorybookPage(),
          '/prototype/teacher-courses': (context) => const TeacherCoursesPage(),
          '/prototype/course-detail': (context) =>
              const TeacherCourseDetailPage(),
          '/prototype/teacher-courses/detail': (context) =>
              const TeacherCourseDetailPage(),
          '/prototype/courses': (context) => const TeacherCoursesPage(),
          '/prototype/student-catalog': (context) =>
              const StudentCourseCatalogPage(),
          '/prototype/student-catalog-minimal': (context) =>
              const StudentCourseCatalogMinimalPage(),
        },
        '/super_admin/schools': (context) => const SuperAdminSchoolsPage(),
        '/super_admin/device_control': (context) =>
            const SuperAdminDeviceControlPage(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (name == null) return null;
        final uri = Uri.parse(name);
        // Same gate as the routes table above — onGenerateRoute would
        // otherwise still resolve every /prototype/ path in a normal build.
        if (!isPrototypeMode && uri.path.startsWith('/prototype/')) {
          return null;
        }
        if (uri.path == '/prototype/teacher-dashboard') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TeacherDashboard(),
          );
        }
        if (uri.path == '/prototype/teacher-course-list') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TeacherCourseListPage(),
          );
        }
        if (uri.path == '/prototype/teacher-redesign') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => TeacherRedesignPrototypePage(
              initialVariant: TeacherPrototypeVariant.fromQuery(
                uri.queryParameters['variant'],
              ),
            ),
          );
        }
        if (uri.path == '/prototype/teacher-design-system' ||
            uri.path == '/prototype/teacher-redesign/design-system') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TeacherDesignSystemPage(),
          );
        }
        if (uri.path == '/prototype/teacher-storybook' ||
            uri.path == '/prototype/storybook') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TeacherStorybookPage(),
          );
        }
        if (uri.path == '/prototype/executive') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const DirectorNavigationShell(),
          );
        }
        if (uri.path == '/prototype/executive-inbox') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const DirectorNavigationShell(),
          );
        }
        if (uri.path == '/prototype/teacher-courses' ||
            uri.path == '/prototype/courses') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TeacherCoursesPage(),
          );
        }
        if (uri.path == '/prototype/course-detail' ||
            uri.path == '/prototype/teacher-courses/detail') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const TeacherCourseDetailPage(),
          );
        }
        return null;
      },
    );
  }

  Widget _buildPrototypeHome(Uri uri) {
    final path = uri.fragment.isNotEmpty ? uri.fragment : uri.path;

    if (path.contains('executive-inbox')) {
      return const DirectorNavigationShell();
    }
    if (path.contains('executive')) {
      return const DirectorNavigationShell();
    }
    if (path.contains('teacher-dashboard')) {
      return const TeacherDashboard();
    }
    if (path.contains('teacher-course-list')) {
      return const TeacherCourseListPage();
    }
    if (path.contains('teacher-storybook') || path.contains('storybook')) {
      return const TeacherStorybookPage();
    }
    if (path.contains('teacher-design-system')) {
      return const TeacherDesignSystemPage();
    }
    if (path.contains('course-detail')) {
      return const TeacherCourseDetailPage();
    }
    if (path.contains('exam-builder')) {
      return const TeacherExamBuilderPage();
    }
    if (path.contains('teacher-grading')) {
      return const TeacherGradingPage();
    }
    if (path.contains('question-bank')) {
      return const TeacherQuestionBankPage();
    }
    if (path.contains('knowledge-library')) {
      return const TeacherKnowledgeLibraryPage();
    }
    if (path.contains('gscore-confirm')) {
      return const TeacherGScoreConfirmPage();
    }
    if (path.contains('student-support')) {
      return const TeacherStudentSupportPage();
    }
    if (path.contains('parent-home') || path.contains('parent-redesign')) {
      return const ParentNavigationShell();
    }
    if (path.contains('parent-binding-approval')) {
      return const TeacherParentBindingApprovalPage();
    }
    if (path.contains('pbl-activity')) {
      // Dev-preview only route (isPrototypeRoute=false in production, see
      // top of this file) — no real course in scope here, so this shows
      // the page with an empty device/rubric list rather than real data.
      return const TeacherPblActivityEditorPage(courseId: '');
    }
    if (path.contains('teacher-courses') || path.contains('courses')) {
      return const TeacherCoursesPage();
    }
    if (path.contains('teacher-redesign')) {
      return TeacherRedesignPrototypePage(
        initialVariant: TeacherPrototypeVariant.fromQuery(
          uri.queryParameters['variant'],
        ),
      );
    }
    // Default landing page for prototype mode: Student Home. The old
    // multi-variant prototype gallery (student_redesign_prototype_page.dart)
    // was deleted 2026-09-07 — variant A was always just this same real
    // shell, and it was the only variant that ever went live.
    return const StudentNavigationPrototype();
  }
}
