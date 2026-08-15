import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/role_router.dart';
import 'pages/student_redesign_prototype/student_redesign_prototype_page.dart';
import 'pages/teacher_redesign_prototype/teacher_redesign_prototype_page.dart';
import 'pages/teacher_redesign_prototype/teacher_design_system_page.dart';
import 'pages/teacher_redesign_prototype/teacher_storybook_page.dart';
import 'pages/teacher_redesign_prototype/teacher_courses_page.dart';
import 'pages/facility_redesign_prototype/facility_storybook_page.dart';
import 'pages/facility_redesign_prototype/facility_ux_showcase_page.dart';
import 'pages/executive_redesign_prototype/executive_dashboard_page.dart';
import 'pages/student_home_page/student_home_page_widget.dart';
import 'pages/dashboard/teacher_dashboard.dart';
import 'pages/teacher/course_list_page.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  const isPrototypeRoute = true;
  runApp(const MyApp(isPrototypeMode: isPrototypeRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.isPrototypeMode = false});

  final bool isPrototypeMode;

  @override
  Widget build(BuildContext context) {
    final initialUri = Uri.base;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AIoT Smart School',
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
        '/prototype/teacher-design-system': (context) =>
            const TeacherDesignSystemPage(),
        '/prototype/teacher-redesign/design-system': (context) =>
            const TeacherDesignSystemPage(),
        '/prototype/teacher-storybook': (context) =>
            const TeacherStorybookPage(),
        '/prototype/facility-storybook': (context) =>
            const FacilityUXShowcasePage(),
        '/prototype/facility-redesign': (context) =>
            const FacilityStorybookPage(),
        '/prototype/facility': (context) => const FacilityStorybookPage(),
        '/prototype/executive': (context) => const ExecutiveDashboardPage(),
        '/prototype/storybook': (context) => const TeacherStorybookPage(),
        '/prototype/teacher-courses': (context) => const TeacherCoursesPage(),
        '/prototype/course-detail': (context) =>
            const TeacherCourseDetailPage(),
        '/prototype/teacher-courses/detail': (context) =>
            const TeacherCourseDetailPage(),
        '/prototype/courses': (context) => const TeacherCoursesPage(),
      },
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (name == null) return null;
        final uri = Uri.parse(name);
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
        if (uri.path == '/prototype/student-redesign') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => StudentRedesignPrototypePage(
              initialVariant: StudentPrototypeVariant.fromQuery(
                uri.queryParameters['variant'],
              ),
            ),
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
        if (uri.path == '/prototype/facility-storybook') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const FacilityUXShowcasePage(),
          );
        }
        if (uri.path == '/prototype/facility-redesign' ||
            uri.path == '/prototype/facility') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const FacilityStorybookPage(),
          );
        }
        if (uri.path == '/prototype/executive') {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => const ExecutiveDashboardPage(),
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

    if (path.contains('facility-storybook')) {
      return const FacilityUXShowcasePage();
    }
    if (path.contains('facility')) {
      return const FacilityStorybookPage();
    }
    if (path.contains('executive')) {
      return const ExecutiveDashboardPage();
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
    if (path.contains('student-redesign')) {
      return StudentRedesignPrototypePage(
        initialVariant: StudentPrototypeVariant.fromQuery(
          uri.queryParameters['variant'],
        ),
      );
    }

    // Default landing page for prototype mode: Student Home
    return StudentRedesignPrototypePage(
      initialVariant: StudentPrototypeVariant.fromQuery(
        uri.queryParameters['variant'],
      ),
    );
  }
}
