import 'package:flutter/material.dart';
import 'facility_building_overview_page.dart';
import 'facility_dashboard_page.dart';
import 'facility_device_health_page.dart';
import 'facility_incident_inbox_page.dart';
import 'facility_light_water_control_page.dart';
import 'facility_security_events_page.dart';
import 'facility_shared_widgets.dart';
import 'facility_ux_states.dart';

class FacilityStorybookPage extends StatefulWidget {
  const FacilityStorybookPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<FacilityStorybookPage> createState() => _FacilityStorybookPageState();
}

class _FacilityStorybookPageState extends State<FacilityStorybookPage> {
  late int _activeRouteIndex;

  @override
  void initState() {
    super.initState();
    _activeRouteIndex = widget.initialIndex;
  }

  // STK-12 BR6: เปิดแล้วต้องรอครู/ผู้บริหารยืนยันปิดเท่านั้น ผู้ดูแลอาคาร
  // เปิดเองปิดเองไม่ได้ — ค้างเป็น non-null จนกว่าจะมี flow ฝั่งครูมายืนยัน
  // (ยังไม่ implement ในโปรโตไทป์นี้)
  String? _activeAreaAlertLocation;

  void _handleSOSTriggered(String location, String details) {
    setState(() {
      _activeAreaAlertLocation = location;
    });
    // 2026-08-15: เดิม modal ยืนยันใช้ไอคอน+สีเขียว check ตาม default ของ
    // showSuccessToast — สื่อว่า "จบแล้ว/ปลอดภัยแล้ว" ทั้งที่ตาม STK-12
    // BR6 เหตุนี้ยังไม่ปิด ต้องรอครู/ผู้บริหารยืนยันก่อน จึงสั่ง override
    // เป็นสีแดง+ไอคอนกระจายสัญญาณแทน และบอกขั้นต่อไปชัดเจนใน subtitle
    // (แทนที่จะปล่อยให้ผู้ดูแลอาคารเข้าใจผิดว่ากดแล้วจบ)
    FacilityUXStates.showSuccessToast(
      context,
      'สัญญาณ SOS ถูกกระจายสำเร็จ',
      subtitle:
          '$location'
          '${details.isNotEmpty ? " ($details)" : ""}\n'
          'รอครู/ผู้บริหารยืนยันปิดสัญญาณ — ดูสถานะได้จากแบนเนอร์ด้านบน',
      accentColor: FacilityTheme.emergencyRed,
      icon: Icons.campaign_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FacilityAppShell(
      selectedRouteIndex: _activeRouteIndex,
      onNavigate: (idx) {
        setState(() {
          _activeRouteIndex = idx;
        });
      },
      onSOSTriggered: _handleSOSTriggered,
      activeAreaAlertLocation: _activeAreaAlertLocation,
      child: _buildActivePage(),
    );
  }

  Widget _buildActivePage() {
    switch (_activeRouteIndex) {
      case 0:
        return FacilityDashboardPage(
          // onNavigateToWizard เดิมชื่อไว้ตอน index 1 ยังเป็น checklist
          // wizard — ตอนนี้ index 1 คือ FacilityLightWaterControlPage แล้ว
          // (2026-08-14) ยังไม่ได้เปลี่ยนชื่อ callback เพราะแค่ปรับ
          // ปลายทางไม่กระทบ behavior
          onNavigateToWizard: () => setState(() => _activeRouteIndex = 1),
          onNavigateToIncidents: () => setState(() => _activeRouteIndex = 2),
          onNavigateToMaintenance: () => setState(() => _activeRouteIndex = 2),
          // 2026-08-15: 'แผนที่อาคาร' เป็นเมนูซ้ำกับ 'ภาพรวมอาคาร (สเปกใหม่)'
          // (ชี้ไปหน้าเดียวกัน) ถูกตัดออกจาก _navItems แล้ว ปุ่มลัดนี้เลย
          // ต้องชี้ไปที่เมนูจริงที่เหลืออยู่แทน (index 3 หลังตัด Storybook
          // ออกจาก nav ด้วย ทำให้ index เลื่อนขึ้นมาอีก 1)
          onNavigateToMap: () => setState(() => _activeRouteIndex = 3),
        );
      case 1:
        return const FacilityLightWaterControlPage();
      case 2:
        return const FacilityIncidentInboxPage();
      // 2026-08-15: ตัดเมนูซ้ำ 3 อัน ('แผนที่อาคาร', 'งานซ่อมบำรุง',
      // 'อุปกรณ์ AIoT'), เมนูไม่มี UC รองรับ 1 อัน ('เวรและการตรวจ'), และ
      // 'Storybook' (ไม่ใช่ฟีเจอร์จริง แยกไปเป็น FacilityUXShowcasePage
      // เข้าถึงผ่าน URL /prototype/facility-storybook แทน) ออกจาก
      // _navItems แล้ว เหลือ index 3-5 ตรงกับภาพรวมอาคาร/STK-9/STK-10
      case 3:
        return const FacilityBuildingOverviewContent();
      case 4:
        return const FacilityDeviceHealthPage();
      case 5:
        return const FacilitySecurityEventsPage();
      default:
        return const FacilityIncidentInboxPage();
    }
  }
}
