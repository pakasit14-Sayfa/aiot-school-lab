import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../pages/login_page.dart';
import 'student/student_main_nav.dart';
import 'dashboard/teacher_dashboard.dart';
import 'dashboard/building_admin_dashboard.dart';
import 'dashboard/school_admin_dashboard.dart';
import 'dashboard/executive_dashboard.dart';
import 'dashboard/super_admin_dashboard.dart';
import 'dashboard/technician_dashboard.dart';
import 'dashboard/parent_dashboard.dart';

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    if (user == null) return const LoginPage();

    switch (user.role) {
      case UserRole.student:
        return const StudentMainNav();
      case UserRole.teacher:
        return const TeacherDashboard();
      case UserRole.facilityManager:
        return const BuildingAdminDashboard();
      case UserRole.schoolAdmin:
        return const SchoolAdminDashboard();
      case UserRole.executive:
        return const ExecutiveDashboard();
      case UserRole.superAdmin:
        return const SuperAdminDashboard();
      case UserRole.technician:
        return const TechnicianDashboard();
      case UserRole.parent:
        return const ParentDashboard();
    }
  }
}
