import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/user_list_page.dart';
import 'pages/role_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  await AuthService.initialize();
  RealtimeService.enableOffline();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AIoT Smart School',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<UserModel?>(
        stream: AuthService.authStateChanges,
        initialData: currentUserModel, // Use the initially loaded user if any
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
      },
    );
  }
}
