import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:shared_ui/shared_ui.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/role_router.dart';
import 'pages/student_redesign_prototype/student_redesign_prototype_page.dart';
import 'pages/student_home_page/student_home_page_widget.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  const isPrototypeRoute = true;
  runApp(const MyApp(isPrototypeMode: isPrototypeRoute));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, this.isPrototypeMode = false}) : super(key: key);

  final bool isPrototypeMode;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AIoT Smart School',
      theme: AppTheme.lightTheme,
      home: isPrototypeMode
          ? StudentRedesignPrototypePage(
              initialVariant: StudentPrototypeVariant.fromQuery(
                Uri.base.queryParameters['variant'],
              ),
            )
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
      },
      onGenerateRoute: (settings) {
        final name = settings.name;
        if (name == null) return null;
        final uri = Uri.parse(name);
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
        return null;
      },
    );
  }
}
