import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../pages/login_page.dart';
import 'student/student_main_nav.dart';
import 'teacher_redesign_prototype/teacher_redesign_prototype_page.dart';
import 'facility_redesign_prototype/facility_storybook_page.dart';
import 'dashboard/school_admin_dashboard.dart';
import 'executive_redesign_prototype/executive_home_page.dart';
import 'dashboard/super_admin_dashboard.dart';
import 'dashboard/technician_dashboard.dart';
import 'parent_redesign_prototype/parent_home_page.dart';

/// 2026-08-16: ครู/ผู้ดูแลอาคาร/ผู้บริหาร/ผู้ปกครอง เปลี่ยนจากหน้า dashboard
/// เก่า (dashboard/teacher_dashboard.dart ฯลฯ) มาชี้ไปหน้า
/// *_redesign_prototype/ ที่ทำดีไซน์พรีเมียม + ตรวจสอบ UC ครบแล้วแทน —
/// ก่อนหน้านี้ isPrototypeRoute เพิ่งถูกปิด (false) ให้เข้า login จริงได้
/// แล้ว แต่ RoleRouter ยังชี้ไปหน้าเก่าที่ไม่มีใครแตะมานาน ผู้ใช้จริง
/// หลัง login เลยไม่เห็นงานที่ทำมาทั้งหมด — จุดนี้แก้ให้ตรงแล้ว
/// school admin/super admin/technician ยังไม่มีหน้าพรีเมียมทดแทน (อยู่นอก
/// สโคปงานนี้) จึงคงหน้าเก่าไว้ก่อน
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
        return const TeacherRedesignPrototypePage();
      case UserRole.facilityManager:
        return const FacilityStorybookPage();
      case UserRole.schoolAdmin:
        return const SchoolAdminDashboard();
      case UserRole.executive:
        return const ExecutiveHomePage();
      case UserRole.superAdmin:
        return const SuperAdminDashboard();
      case UserRole.technician:
        return const TechnicianDashboard();
      case UserRole.parent:
        return const ParentHomePage();
    }
  }
}
