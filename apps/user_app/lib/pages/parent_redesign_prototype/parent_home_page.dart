// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// หน้าแรกฝั่งผู้ปกครอง — สมมติว่าผูกบัญชีและได้รับอนุมัติแล้ว (STK-1a)
// มีตัวสลับบุตร (รองรับผู้ปกครอง 1 คนมีบุตรหลายคน) แล้วเป็นทางเข้าไปยัง
// UC ต่างๆ ของผู้ปกครอง: STK-2 (คะแนน), STK-3 (พัฒนาการ), STK-4 (แจ้งเตือน
// ฉุกเฉิน), STK-5 (รายงานสรุป), และกลุ่ม CON (PDPA/ความยินยอม)

import 'package:flutter/material.dart';

import 'parent_consent_status_page.dart';
import 'parent_grades_page.dart';
import 'parent_progress_page.dart';
import 'parent_reports_page.dart';
import 'parent_shared_widgets.dart';
import 'parent_emergency_alerts_page.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  String _selectedChildId = parentMockChildren.first.id;

  ParentChildMock get _selectedChild =>
      parentMockChildren.firstWhere((c) => c.id == _selectedChildId);

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'ติดตามบุตรหลาน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParentChildSwitcher(
              children: parentMockChildren,
              selectedId: _selectedChildId,
              onSelected: (id) => setState(() => _selectedChildId = id),
            ),
            if (parentMockChildren.length > 1) const SizedBox(height: 16),
            _buildChildHeroCard(),
            const SizedBox(height: 20),
            const Text(
              'ติดตามบุตร',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: ParentTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            ParentResponsiveGrid(
              minItemWidth: 260,
              children: [
                _NavCard(
                  icon: Icons.school_rounded,
                  color: ParentTheme.primaryTeal,
                  title: 'ผลการเรียน',
                  subtitle: 'ดูคะแนนที่ครูยืนยันแล้ว',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ParentGradesPage(childName: _selectedChild.name),
                    ),
                  ),
                ),
                _NavCard(
                  icon: Icons.trending_up_rounded,
                  color: const Color(0xFF0284C7),
                  title: 'พัฒนาการ',
                  subtitle: 'แนวโน้มความก้าวหน้าของบุตร',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ParentProgressPage(childName: _selectedChild.name),
                    ),
                  ),
                ),
                _NavCard(
                  icon: Icons.emergency_rounded,
                  color: ParentTheme.emergencyRed,
                  title: 'แจ้งเตือนฉุกเฉิน',
                  subtitle: 'ประวัติเหตุการณ์ของบุตร',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentEmergencyAlertsPage(
                        childName: _selectedChild.name,
                      ),
                    ),
                  ),
                ),
                _NavCard(
                  icon: Icons.summarize_rounded,
                  color: const Color(0xFF7C3AED),
                  title: 'รายงานสรุป',
                  subtitle: 'รายงานตามรอบ (รายสัปดาห์/เดือน)',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          ParentReportsPage(childName: _selectedChild.name),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'ความเป็นส่วนตัว',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: ParentTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            _NavCard(
              icon: Icons.privacy_tip_rounded,
              color: const Color(0xFF475569),
              title: 'ความยินยอมและสิทธิ์ข้อมูล (PDPA)',
              subtitle: 'จัดการความยินยอม / ดูประวัติ / ขอสำเนา หรือขอลบข้อมูล',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ParentConsentStatusPage(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildChildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ParentTheme.primaryTeal, ParentTheme.primaryTealLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: Icon(
              _selectedChild.avatarIcon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedChild.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedChild.gradeRoom} · โรงเรียนสาธิต AIoT',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  const _NavCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: ParentGlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                      color: ParentTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: ParentTheme.muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: ParentTheme.muted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
