import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../pages/login_page.dart';
import 'student_redesign_prototype/widgets/student_navigation_prototype.dart';
import 'teacher_redesign_prototype/teacher_redesign_prototype_page.dart';
import 'dashboard/school_admin_dashboard.dart';
import 'executive_redesign_prototype/widgets/director_navigation_shell.dart';
import 'dashboard/super_admin_dashboard.dart';
import 'parent_redesign_prototype/widgets/parent_navigation_shell.dart';

/// RoleRouter routes authenticated users to their respective dashboard/shells
/// for the 6 core system roles.
class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final user = currentUserModel;
    if (user == null) return const LoginPage();

    switch (user.role) {
      case UserRole.student:
        return const StudentNavigationPrototype();
      case UserRole.teacher:
        return const TeacherRedesignPrototypePage();
      case UserRole.schoolAdmin:
        return const SchoolAdminDashboard();
      case UserRole.executive:
        return const DirectorNavigationShell();
      case UserRole.superAdmin:
        return const SuperAdminDashboard();
      case UserRole.parent:
        return const ParentNavigationShell();
    }
  }
}
