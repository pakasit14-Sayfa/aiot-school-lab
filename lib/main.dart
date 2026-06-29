import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/auth_service.dart';
import 'services/realtime_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'pages/register_page.dart';
import 'pages/profile_page.dart';
import 'pages/forgot_password_page.dart';
import 'pages/user_list_page.dart';
import 'pages/role_router.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // เปิด offline persistence
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
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
      home: StreamBuilder(
        stream: AuthService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return FutureBuilder(
              future: AuthService.getUserModel(snapshot.data!.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return const RoleRouter();
              },
            );
          }
          return const LoginPage();
        },
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
        '/users': (context) => const UserListPage(),
        '/forgot-password': (context) => const ForgotPasswordPage(),
      },
    );
  }
}
