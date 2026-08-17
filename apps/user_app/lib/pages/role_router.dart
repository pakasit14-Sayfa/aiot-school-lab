import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import '../pages/login_page.dart';
import 'student_redesign_prototype/widgets/student_navigation_prototype.dart';
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
        // 2026-08-17: เดิมชี้ไป StudentHomePageWidget (แค่ห่อ banner รอบ
        // StudentVariantSchoolHome เฉยๆ ไม่มี nav shell เลย) แต่พบว่า
        // StudentNavigationPrototype มีไซด์บาร์/ดรอว์เออร์+ค้นหา+แจ้งเตือน
        // ครบกว่า และ 2/5 แท็บ (หน้าแรก, ใบงาน) เรียกใช้
        // StudentVariantSchoolHome/StudentAssignmentsPage ตัวเดียวกับที่
        // เชื่อมข้อมูลจริงไปแล้วโดยตรง (ไม่ใช่สำเนาซ้ำ) ผู้ใช้ยืนยันให้ใช้
        // เชลล์นี้เป็นตัวจริงแทน — อีก 3 แท็บ (บทเรียน/ปฏิทิน/โปรไฟล์) กับ
        // ปุ่ม "ความปลอดภัยห้องเรียน" ยังเป็น mock รอเชื่อมต่อไป ดู
        // student_redesign_prototype/NOTES.md
        return const StudentNavigationPrototype();
      case UserRole.teacher:
        return const TeacherRedesignPrototypePage();
      case UserRole.facilityManager:
        final frag = Uri.base.fragment;
        if (frag.contains('light-water') || frag.contains('stk11')) {
          return const FacilityStorybookPage(initialIndex: 1);
        }
        if (frag.contains('device-health') || frag.contains('stk9')) {
          return const FacilityStorybookPage(initialIndex: 4);
        }
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
