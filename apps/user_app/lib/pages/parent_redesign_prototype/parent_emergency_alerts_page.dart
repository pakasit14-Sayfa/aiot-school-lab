// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// STK-4: รับแจ้งเตือนเหตุฉุกเฉิน (ต่อจาก EMG-4) — เห็นเฉพาะเหตุการณ์ของบุตร
// ตนเอง (BR1) ข้อความต้องไม่เปิดเผย PII ของเด็กคนอื่น (BR2) แม้ผู้ปกครองปิด
// การแจ้งเตือนไป เหตุการณ์ก็ยังต้องดูย้อนหลังได้ในระบบเสมอ (Exception 1)
// หน้านี้จึงเป็นทั้งจุดรับแจ้งเตือนสดและประวัติย้อนหลังในที่เดียว

import 'package:flutter/material.dart';

import 'parent_shared_widgets.dart';

class _AlertMock {
  const _AlertMock({
    required this.title,
    required this.detail,
    required this.timeLabel,
    required this.resolved,
  });

  final String title;
  final String detail;
  final String timeLabel;
  final bool resolved;
}

const _mockAlerts = [
  _AlertMock(
    title: 'แจ้งเหตุฉุกเฉินจากห้องเรียน',
    detail:
        'บุตรของท่านอยู่ในเหตุการณ์ที่ห้อง ม.5/2 อาคาร 3 — ครูเวรรับเรื่องและ'
        'ตรวจสอบแล้ว ปิดเหตุเรียบร้อย ไม่มีการบาดเจ็บ',
    timeLabel: '3 ส.ค. 2569 · 10:24 น.',
    resolved: true,
  ),
];

class ParentEmergencyAlertsPage extends StatelessWidget {
  const ParentEmergencyAlertsPage({super.key, required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'แจ้งเตือนฉุกเฉิน',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              childName,
              style: const TextStyle(
                color: ParentTheme.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (_mockAlerts.isEmpty)
              const _EmptyState()
            else
              for (final alert in _mockAlerts) ...[
                _AlertCard(alert: alert),
                const SizedBox(height: 12),
              ],
          ],
        );
      },
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final _AlertMock alert;

  @override
  Widget build(BuildContext context) {
    return ParentGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: ParentTheme.emergencyRed.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emergency_rounded,
                  color: ParentTheme.emergencyRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: ParentTheme.ink,
                  ),
                ),
              ),
              ParentStatusChip(
                label: alert.resolved ? 'ปิดเหตุแล้ว' : 'กำลังดำเนินการ',
                color: alert.resolved
                    ? ParentTheme.safeGreen
                    : ParentTheme.warningOrange,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.detail,
            style: const TextStyle(
              color: ParentTheme.softText,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            alert.timeLabel,
            style: const TextStyle(
              color: ParentTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ParentGlassCard(
      child: Column(
        children: [
          Icon(
            Icons.shield_rounded,
            size: 40,
            color: ParentTheme.safeGreen.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 10),
          const Text(
            'ไม่มีเหตุการณ์ฉุกเฉิน',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
          ),
          const SizedBox(height: 4),
          const Text(
            'จะแจ้งเตือนที่นี่ทันทีหากมีเหตุการณ์เกี่ยวข้องกับบุตรของท่าน',
            textAlign: TextAlign.center,
            style: TextStyle(color: ParentTheme.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
