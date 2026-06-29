import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../pages/login_page.dart';
import 'dashboard/student_dashboard.dart';
import 'dashboard/teacher_dashboard.dart';
import 'dashboard/building_admin_dashboard.dart';
import 'dashboard/school_admin_dashboard.dart';
import 'dashboard/executive_dashboard.dart';
import 'dashboard/developer_dashboard.dart';
import 'dashboard/parent_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    if (user == null) return const LoginPage();

    switch (user.role) {
      case UserRole.student:
        return const StudentDashboard();
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.buildingAdmin:
        return const BuildingAdminDashboard();
      case UserRole.schoolAdmin:
        return const SchoolAdminDashboard();
      case UserRole.executive:
        return const ExecutiveDashboard();
      case UserRole.developer:
        return const DeveloperDashboard();
      case UserRole.parent:
        return const ParentDashboard();
    }
  }
}
