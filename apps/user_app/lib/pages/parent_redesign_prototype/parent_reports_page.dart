// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// STK-5: รับรายงานสรุปเป็นระยะ (รายสัปดาห์/เดือน) — BR2: เนื้อหาต้องผ่าน
// การยืนยันแล้วเท่านั้น (เหมือน STK-2) Exception 1: ถ้าข้อมูลบุตรยังไม่พอ
// สรุปในรอบนั้น ให้ข้ามรอบหรือส่งพร้อมระบุว่าข้อมูลยังไม่ครบ — เดโมนี้ใส่
// ตัวอย่างทั้งสองแบบไว้ให้เห็นความต่าง

import 'package:flutter/material.dart';

import 'parent_shared_widgets.dart';

class _ReportMock {
  const _ReportMock({
    required this.period,
    required this.summary,
    required this.isIncomplete,
  });

  final String period;
  final String summary;
  final bool isIncomplete;
}

const _mockReports = [
  _ReportMock(
    period: 'รายงานประจำเดือน ธันวาคม 2569',
    summary:
        'คะแนนเฉลี่ยรวม 79% (เพิ่มขึ้นจากเดือนก่อน) ส่งงานตรงเวลา 9/10 ครั้ง '
        'เข้าเรียนครบ ไม่มีเหตุการณ์ด้านความปลอดภัยในรอบนี้',
    isIncomplete: false,
  ),
  _ReportMock(
    period: 'รายงานประจำเดือน พฤศจิกายน 2569',
    summary: 'คะแนนเฉลี่ยรวม 74% ส่งงานตรงเวลา 7/9 ครั้ง',
    isIncomplete: false,
  ),
  _ReportMock(
    period: 'รายงานประจำเดือน ตุลาคม 2569',
    summary:
        'ข้อมูลในรอบนี้ยังไม่เพียงพอสำหรับสรุปผลอย่างมีความหมาย '
        '(เพิ่งเริ่มผูกบัญชีระหว่างเดือน)',
    isIncomplete: true,
  ),
];

class ParentReportsPage extends StatelessWidget {
  const ParentReportsPage({super.key, required this.childName});

  final String childName;

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'รายงานสรุปเป็นระยะ',
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
            for (final report in _mockReports) ...[
              _ReportCard(report: report),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final _ReportMock report;

  @override
  Widget build(BuildContext context) {
    return ParentGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  report.period,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: ParentTheme.ink,
                  ),
                ),
              ),
              if (report.isIncomplete)
                const ParentStatusChip(
                  label: 'ข้อมูลไม่ครบ',
                  color: ParentTheme.warningOrange,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            report.summary,
            style: const TextStyle(
              color: ParentTheme.softText,
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
