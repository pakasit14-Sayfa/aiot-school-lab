// PROTOTYPE — หน้าสำหรับทีมพัฒนา/ออกแบบใช้ตรวจสอบ UI เท่านั้น ไม่ใช่
// ฟีเจอร์จริงของผู้ดูแลอาคาร
//
// 2026-08-15: เดิมเป็นหนึ่งใน case ของ FacilityStorybookPage (มีเมนู
// "Storybook" ในแถบข้าง) — ผู้ใช้ขอให้เอาออกจากเมนูจริง แล้วเข้าถึงผ่าน URL
// โดยตรงแทน (แพทเทิร์นเดียวกับ TeacherStorybookPage ที่เป็นหน้าแยกอิสระ
// ไม่ได้อยู่ในเมนูของ TeacherRedesignPrototypePage) จึงแยกออกมาเป็น widget
// อิสระของตัวเอง เข้าผ่าน `/prototype/facility-storybook` ใน main.dart —
// ส่วน "จำลองฝั่งครู" เดิมอ้างอิง state จริงของ FacilityStorybookPage
// (`_activeAreaAlertLocation`) ซึ่งพอแยกไฟล์แล้วเข้าถึงไม่ได้อีก จึงเปลี่ยน
// เป็น state จำลองในตัวเอง (ทดสอบแค่หน้าตา/การโต้ตอบของ component ไม่ได้
// ผูกกับสัญญาณเตือนจริงในแอปอีกต่อไป — เหมาะกับจุดประสงค์ "ห้องทดลอง UI"
// มากกว่าด้วย)
import 'package:flutter/material.dart';
import 'facility_shared_widgets.dart';
import 'facility_ux_states.dart';

class FacilityUXShowcasePage extends StatefulWidget {
  const FacilityUXShowcasePage({super.key});

  @override
  State<FacilityUXShowcasePage> createState() => _FacilityUXShowcasePageState();
}

class _FacilityUXShowcasePageState extends State<FacilityUXShowcasePage> {
  bool _demoAreaAlertActive = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FacilityTheme.bgSlate,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: FacilityTheme.inkIndigo,
        title: const Text(
          'Facility UI Storybook',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
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
                'ทดสอบและตรวจสอบการแสดงผลของ Notification Banners และ UX States ทั้งหมดในระบบ — ไม่ใช่หน้าที่ผู้ดูแลอาคารจริงจะเห็น',
                style: TextStyle(fontSize: 13, color: FacilityTheme.textMuted),
              ),

              const SizedBox(height: 20),

              // BR6 component demo — ไม่ได้ผูกกับสัญญาณเตือนจริงในแอปแล้ว
              // (ดูเหตุผลในคอมเมนต์หัวไฟล์) ใช้แค่ทดสอบหน้าตา/ปุ่มกด
              const Text(
                '0. ตัวอย่างแบนเนอร์สัญญาณเตือนพื้นที่ (STK-12 BR6):',
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
                        _demoAreaAlertActive
                            ? 'จำลอง: มีสัญญาณเตือนค้างอยู่'
                            : 'จำลอง: ไม่มีสัญญาณเตือนค้างอยู่ตอนนี้',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: FacilityTheme.inkIndigo,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () => setState(
                        () => _demoAreaAlertActive = !_demoAreaAlertActive,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _demoAreaAlertActive
                            ? FacilityTheme.safeGreen
                            : FacilityTheme.emergencyRed,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                      child: Text(
                        _demoAreaAlertActive
                            ? 'จำลองปิดสัญญาณ'
                            : 'จำลองเปิดสัญญาณ',
                      ),
                    ),
                  ],
                ),
              ),
              if (_demoAreaAlertActive) ...[
                const SizedBox(height: 12),
                FacilityNotificationBanner(
                  tier: FacilityNotificationTier.critical,
                  title:
                      '🔴 สัญญาณเตือนพื้นที่เปิดอยู่ (แจ้งเชิงรุกโดยผู้ดูแลอาคาร)',
                  message:
                      'ตัวอย่างข้อความแบนเนอร์จริง (ดูโค้ดจริงใน FacilityAppShell)',
                  actionLabel: 'แจ้งเตือนซ้ำ',
                  onActionPressed: () {},
                ),
              ],
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
        ),
      ),
    );
  }
}
