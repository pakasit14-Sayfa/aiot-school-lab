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
  const FacilityStorybookPage({super.key});

  @override
  State<FacilityStorybookPage> createState() => _FacilityStorybookPageState();
}

class _FacilityStorybookPageState extends State<FacilityStorybookPage> {
  int _activeRouteIndex = 0;

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
          // 2026-08-15: เดิมชี้ไป index 2 (incident inbox) เหมือน
          // maintenance เพราะตอนนั้น index 3 ('แผนที่อาคาร') ยังไม่มี
          // เนื้อหาจริง (ตกไป default) — ตอนนี้มีแล้ว ชี้ให้ตรงเมนูเดียวกัน
          onNavigateToMap: () => setState(() => _activeRouteIndex = 3),
        );
      case 1:
        return const FacilityLightWaterControlPage();
      case 2:
        return const FacilityIncidentInboxPage();
      // 2026-08-15: case 3/4/5 เดิมไม่มีเลย ตกไป default (แสดง incident
      // inbox) ทั้งที่ sidebar ไฮไลต์เมนูอื่น (แผนที่อาคาร/งานซ่อมบำรุง/
      // อุปกรณ์ AIoT) ทำให้เมนูกับเนื้อหาไม่ตรงกัน — ไม่มี UC แยกสำหรับ
      // "แผนที่อาคาร" แบบ 3D จริง จึงชี้ไปหน้าภาพรวมอาคารที่มีข้อมูลระดับ
      // อาคารตรงตาม STK-6/7 อยู่แล้วแทน ส่วน "งานซ่อมบำรุง" กับ "อุปกรณ์
      // AIoT" คือ flow เดียวกับ STK-12/STK-9 ที่มีอยู่แล้วพอดี (ชี้ไปหน้า
      // เดียวกัน ไม่ได้สร้างซ้ำ)
      case 3:
        return const FacilityBuildingOverviewContent();
      case 4:
        return const FacilityIncidentInboxPage();
      case 5:
        return const FacilityDeviceHealthPage();
      // 2026-08-15: เดิม index 6 คือ 'เวรและการตรวจ' (ไม่มี UC รองรับ ตกไป
      // default) — ตัดเมนูนั้นออกจาก _navItems แล้วตามที่ผู้ใช้ยืนยัน ทำให้
      // Storybook/ภาพรวมอาคาร/STK-9/STK-10 เลื่อนขึ้นมาคนละ 1 (เดิม 7-10
      // ตอนนี้เป็น 6-9)
      case 6:
        return _buildUXStatesShowcase();
      case 7:
        return const FacilityBuildingOverviewContent();
      case 8:
        return const FacilityDeviceHealthPage();
      case 9:
        return const FacilitySecurityEventsPage();
      default:
        return const FacilityIncidentInboxPage();
    }
  }

  /// Showcase of 3-Tier Notifications & 6 Required UX States
  Widget _buildUXStatesShowcase() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎨 Facility Design System Tokens & 6 UX States Gallery',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'ทดสอบและตรวจสอบการแสดงผลของ Notification Banners และ UX States ทั้งหมดในระบบ',
            style: TextStyle(fontSize: 13, color: FacilityTheme.textMuted),
          ),

          const SizedBox(height: 20),

          // 2026-08-15: STK-12 BR6 — สัญญาณเตือนพื้นที่ที่ผู้ดูแลอาคารเปิด
          // เองปิดเองไม่ได้ ต้องรอครู/ผู้บริหารยืนยัน แต่โปรโตไทป์นี้มีแค่
          // มุมมองผู้ดูแลอาคาร ไม่มีหน้าจอฝั่งครูจริง — ปุ่มนี้จำลองแค่การ
          // กด "ยืนยันปิด" จากฝั่งครู เพื่อให้ทดสอบวงจรทั้งหมดได้ครบ
          // (เปิด SOS → แบนเนอร์ค้าง → จำลองครูยืนยันปิด → แบนเนอร์หาย)
          // ไม่ใช่ฟีเจอร์จริงของผู้ดูแลอาคาร จึงแยก section ต่างหากชัดเจน
          const Text(
            '0. จำลองฝั่งครู/ผู้บริหาร (Demo เท่านั้น — ไม่ใช่ฟีเจอร์ของผู้ดูแลอาคาร):',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: FacilityTheme.bgSlate,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: FacilityTheme.purpleBorder),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _activeAreaAlertLocation == null
                        ? 'ไม่มีสัญญาณเตือนพื้นที่ค้างอยู่ตอนนี้'
                        : 'มีสัญญาณเตือนค้างอยู่: $_activeAreaAlertLocation',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: FacilityTheme.inkIndigo,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _activeAreaAlertLocation == null
                      ? null
                      : () {
                          setState(() => _activeAreaAlertLocation = null);
                          FacilityUXStates.showSuccessToast(
                            context,
                            'ครู/ผู้บริหารยืนยันปิดสัญญาณแล้ว (จำลอง)',
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FacilityTheme.safeGreen,
                    foregroundColor: Colors.white,
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                  ),
                  child: const Text('จำลองครูยืนยันปิด'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 1. 3-Tier Notification Banners
          const Text(
            '1. ระบบแจ้งเตือน 3 ระดับ (3-Tier Notifications):',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          FacilityNotificationBanner(
            tier: FacilityNotificationTier.critical,
            title: 'Critical Alert: สัญญาณ SOS แจ้งเหตุฉุกเฉิน!',
            message: 'พบการกดปุ่ม SOS จากห้อง 302 อาคาร 3',
            actionLabel: 'รับเรื่องทันที',
            onActionPressed: () {},
          ),
          FacilityNotificationBanner(
            tier: FacilityNotificationTier.warning,
            title: 'Warning Alert: กล้อง C-12 สถานะ Offline',
            message: 'กล้องบริเวณทางเดินชั้น 2 ขาดการติดต่อ 12 นาที',
            actionLabel: 'ตรวจสอบ',
            onActionPressed: () {},
          ),
          FacilityNotificationBanner(
            tier: FacilityNotificationTier.info,
            title: 'Info Alert: ประกาศแจ้งเวรประจำวัน',
            message: 'ตารางเวรตรวจรอบบ่ายวันนี้เป็นของ ครูสมชาย',
            actionLabel: 'ดูตารางเวร',
            onActionPressed: () {},
          ),

          const SizedBox(height: 24),

          // 2. 6 Required UX States Showcase
          const Text(
            '2. ตัวอย่าง 6 UX States (Skeleton, Empty, Error, Offline, Permission, Success):',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          const Text(
            '• Loading Skeleton:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          FacilityUXStates.buildSkeleton(height: 100),

          const SizedBox(height: 14),

          const Text(
            '• Empty State:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          FacilityUXStates.buildEmptyState(
            title: 'ยังไม่มีงานซ่อมค้างในระบบ',
            message: 'ทุกรายการซ่อมได้รับการแก้ไขเรียบร้อยแล้ว',
          ),

          const SizedBox(height: 14),

          const Text(
            '• Error State:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          FacilityUXStates.buildErrorState(
            errorMessage: 'ไม่สามารถเชื่อมต่อเซิฟเวอร์ Realtime ได้',
            onRetry: () {},
          ),

          const SizedBox(height: 14),

          const Text(
            '• Offline Sync Pending State:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          FacilityUXStates.buildOfflineSyncBanner(
            pendingCount: 3,
            lastSyncedTime: '15:20 น.',
            onSyncNow: () {},
          ),

          const SizedBox(height: 14),

          const Text(
            '• Permission Denied State:',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          FacilityUXStates.buildPermissionDenied(
            requiredRoleTitle: 'สิทธิ์อนุมัติข้ามของหัวหน้าอาคาร',
            message:
                'ต้องได้รับการยืนยันรหัสผ่านหรือสิทธิ์จากหัวหน้าอาคารในการปิดจุดเสี่ยง',
          ),
        ],
      ),
    );
  }
}
