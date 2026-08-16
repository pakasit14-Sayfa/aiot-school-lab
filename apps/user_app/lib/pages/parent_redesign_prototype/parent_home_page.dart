// เชื่อมกับ ConsentService จริงแล้ว (2026-08-16) — เดิม mock ล้วน
//
// หน้าแรกฝั่งผู้ปกครอง — ตัวสลับบุตรตอนนี้โหลดจริงจาก
// ConsentService.listMyParentLinks() แล้วเป็นทางเข้าไปยัง UC ต่างๆ ของ
// ผู้ปกครอง: STK-2 (คะแนน), STK-3 (พัฒนาการ), STK-4 (แจ้งเตือนฉุกเฉิน),
// STK-5 (รายงานสรุป), และกลุ่ม CON (PDPA/ความยินยอม)
//
// BR5 (STK-1): "ก่อนอนุมัติ ผู้ปกครองยังเห็นข้อมูลบุตรไม่ได้" — กรองเหลือ
// เฉพาะบุตรที่ status == 'approved' เท่านั้นในตัวสลับ ถ้ามีแต่คำขอที่ยัง
// รออนุมัติ/ถูกปฏิเสธ จะไม่โผล่ในนี้เลย (แสดง empty state แทน)
//
// ⚠️ STK-2/3/4/5 (คะแนน/พัฒนาการ/แจ้งเตือน/รายงาน) ที่เปิดจากหน้านี้ยังเป็น
// mock อยู่ — ตรวจสอบ RPC แล้วพบว่าไม่มี backend รองรับให้ผู้ปกครองดูข้อมูล
// บุตรเลยสักตัว (list_my_grades เป็นของนักเรียนเรียกเองเท่านั้น ไม่มี
// endpoint ให้ผู้ปกครองเรียกแทน) — ต่างจากตัวสลับบุตรตรงนี้ที่มี backend จริง
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'parent_consent_status_page.dart';
import 'parent_grades_page.dart';
import 'parent_progress_page.dart';
import 'parent_reports_page.dart';
import 'parent_shared_widgets.dart';
import 'parent_binding_page.dart';
import 'parent_emergency_alerts_page.dart';

class ParentHomePage extends StatefulWidget {
  const ParentHomePage({super.key});

  @override
  State<ParentHomePage> createState() => _ParentHomePageState();
}

class _ParentHomePageState extends State<ParentHomePage> {
  bool _loading = true;
  String? _loadError;
  List<ParentChildMock> _children = [];
  String? _selectedChildId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final links = await ConsentService.listMyParentLinks();
      final approved = links.where((l) => l.status == 'approved').toList();
      final children = [
        for (final l in approved)
          ParentChildMock(
            id: l.studentId,
            name: l.studentName,
            gradeRoom: l.relationship,
            avatarColor: ParentTheme.primaryTeal,
            avatarIcon: Icons.face_rounded,
          ),
      ];
      if (!mounted) return;
      setState(() {
        _children = children;
        _selectedChildId = children.isEmpty ? null : children.first.id;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดข้อมูลบุตรไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  ParentChildMock? get _selectedChild => _children.isEmpty
      ? null
      : _children.firstWhere(
          (c) => c.id == _selectedChildId,
          orElse: () => _children.first,
        );

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'ติดตามบุตรหลาน',
      builder: (context, isDesktop) {
        if (_loading) {
          return const Padding(
            padding: EdgeInsets.all(48),
            child: Center(
              child: CircularProgressIndicator(color: ParentTheme.primaryTeal),
            ),
          );
        }
        if (_loadError != null) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _loadError!,
                  style: const TextStyle(
                    color: ParentTheme.emergencyRed,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton(onPressed: _load, child: const Text('ลองใหม่')),
              ],
            ),
          );
        }
        if (_children.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ยังไม่มีบุตรที่ผูกบัญชีและได้รับอนุมัติแล้ว',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: ParentTheme.ink,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'ถ้ายื่นคำขอไว้แล้วกรุณารอครูประจำชั้นหรือฝ่ายทะเบียน'
                  'อนุมัติก่อน หรือยื่นคำขอผูกบัญชีใหม่ได้ที่นี่',
                  style: TextStyle(color: ParentTheme.muted, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ParentBindingPage(),
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: ParentTheme.primaryTeal,
                  ),
                  child: const Text('ยื่นคำขอผูกบัญชี'),
                ),
              ],
            ),
          );
        }
        final selectedChild = _selectedChild!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ParentChildSwitcher(
              children: _children,
              selectedId: selectedChild.id,
              onSelected: (id) => setState(() => _selectedChildId = id),
            ),
            if (_children.length > 1) const SizedBox(height: 16),
            _buildChildHeroCard(selectedChild),
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
                          ParentGradesPage(childName: selectedChild.name),
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
                          ParentProgressPage(childName: selectedChild.name),
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
                        childName: selectedChild.name,
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
                          ParentReportsPage(childName: selectedChild.name),
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

  Widget _buildChildHeroCard(ParentChildMock child) {
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
            child: Icon(child.avatarIcon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  child.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'ความสัมพันธ์: ${child.gradeRoom}',
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
