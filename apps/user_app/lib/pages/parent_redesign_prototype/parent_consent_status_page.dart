// PROTOTYPE — UI/UX เท่านั้น mock ทั้งหมด ยังไม่ผูก Supabase จริง
//
// กลุ่ม CON ทั้งหมดของผู้ปกครองรวมอยู่หน้าเดียว เพราะเป็น flow ต่อเนื่องกัน
// ตามธรรมชาติ: CON-1 (ให้ความยินยอมแยกวัตถุประสงค์) กับ CON-2 (ถอนความ
// ยินยอม) คือ toggle เดียวกัน (เปิด=ยินยอม, ปิด=ถอน) — CON-3 (ดูสถานะ/
// ประวัติ) คือส่วนแสดงผลของ toggle เดียวกันนี้บวกประวัติด้านล่าง — CON-4
// (ขอสำเนาข้อมูล) กับ CON-5 (ขอลบ/แก้ไข) เป็นคำขอที่ School Admin ต้อง
// พิจารณาต่อ จึงแยกเป็นปุ่ม "ยื่นคำขอ" ต่างหาก ไม่ใช่ toggle

import 'package:flutter/material.dart';

import 'parent_shared_widgets.dart';

class _ConsentPurpose {
  _ConsentPurpose({
    required this.title,
    required this.description,
    required this.grantedAt,
    this.granted = true,
  });

  final String title;
  final String description;
  final String grantedAt;
  bool granted;
}

class _HistoryEntry {
  const _HistoryEntry(this.text, this.timeLabel);
  final String text;
  final String timeLabel;
}

const _policyVersion = 'v2.3 (มีผล 1 ส.ค. 2569)';

class ParentConsentStatusPage extends StatefulWidget {
  const ParentConsentStatusPage({super.key});

  @override
  State<ParentConsentStatusPage> createState() =>
      _ParentConsentStatusPageState();
}

class _ParentConsentStatusPageState extends State<ParentConsentStatusPage> {
  final List<_ConsentPurpose> _purposes = [
    _ConsentPurpose(
      title: 'ข้อมูลการเรียน',
      description: 'คะแนน ผลการเรียน ความคืบหน้าบทเรียน',
      grantedAt: '1 ส.ค. 2569',
    ),
    _ConsentPurpose(
      title: 'ข้อมูลพฤติกรรม',
      description: 'การส่งงาน การเข้าเรียน สถิติการมีส่วนร่วม',
      grantedAt: '1 ส.ค. 2569',
    ),
    _ConsentPurpose(
      title: 'ภาพเหตุการณ์ความปลอดภัย',
      description: 'สรุปเหตุการณ์จากกล้อง/ระบบความปลอดภัยที่เกี่ยวข้องกับบุตร',
      grantedAt: '1 ส.ค. 2569',
      granted: false,
    ),
    _ConsentPurpose(
      title: 'การแจ้งเตือน',
      description: 'แจ้งเตือนฉุกเฉินและรายงานสรุปเป็นระยะ',
      grantedAt: '1 ส.ค. 2569',
    ),
  ];

  final List<_HistoryEntry> _history = [
    const _HistoryEntry(
      'ให้ความยินยอม "ข้อมูลการเรียน", "ข้อมูลพฤติกรรม", "การแจ้งเตือน"',
      '1 ส.ค. 2569 · 09:12 น.',
    ),
    const _HistoryEntry(
      'ไม่ให้ความยินยอม "ภาพเหตุการณ์ความปลอดภัย"',
      '1 ส.ค. 2569 · 09:12 น.',
    ),
  ];

  void _toggle(_ConsentPurpose purpose, bool value) {
    setState(() {
      purpose.granted = value;
      _history.insert(
        0,
        _HistoryEntry(
          '${value ? "ให้" : "ถอน"}ความยินยอม "${purpose.title}"',
          'วันนี้ · ${TimeOfDay.now().format(context)}',
        ),
      );
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value
              ? 'ให้ความยินยอม "${purpose.title}" แล้ว'
              : 'ถอนความยินยอม "${purpose.title}" แล้ว — ระบบหยุดใช้ข้อมูลส่วนนี้ทันที',
        ),
        backgroundColor: value
            ? ParentTheme.safeGreen
            : ParentTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openRequestDialog({
    required String title,
    required String description,
    required String submitLabel,
  }) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(
                fontSize: 12.5,
                color: ParentTheme.softText,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'รายละเอียดเพิ่มเติม (ถ้ามี)...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: ParentTheme.primaryTeal,
            ),
            child: const Text('ยื่นคำขอ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ส่งคำขอ "$title" แล้ว — ฝ่ายทะเบียน/School Admin จะพิจารณาและแจ้งผลกลับ',
        ),
        backgroundColor: ParentTheme.primaryTeal,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'ความเป็นส่วนตัวและ PDPA',
      builder: (context, isDesktop) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: ParentTheme.lightTealBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: ParentTheme.tealBorder),
              ),
              child: const Text(
                'เลือกให้/ถอนความยินยอมแยกตามวัตถุประสงค์ได้อิสระ ไม่ใช่แบบ '
                'all-or-nothing — ส่วนที่ไม่ยินยอมจะถูกปิดใช้งาน แต่ส่วนอื่นยังใช้ได้ปกติ',
                style: TextStyle(
                  color: ParentTheme.primaryTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'นโยบายความเป็นส่วนตัวเวอร์ชันปัจจุบัน: $_policyVersion',
              style: TextStyle(color: ParentTheme.muted, fontSize: 11),
            ),
            const SizedBox(height: 16),
            const Text(
              'ความยินยอมของฉัน',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: ParentTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            for (final purpose in _purposes) ...[
              _ConsentTile(
                purpose: purpose,
                onChanged: (v) => _toggle(purpose, v),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
            const Text(
              'สิทธิ์เจ้าของข้อมูล',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: ParentTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            _RequestActionCard(
              icon: Icons.file_download_outlined,
              title: 'ขอสำเนาข้อมูล (DSAR)',
              subtitle: 'ขอดู/ขอสำเนาข้อมูลส่วนบุคคลของบุตรที่ระบบเก็บไว้',
              buttonLabel: 'ยื่นคำขอสำเนา',
              onTap: () => _openRequestDialog(
                title: 'ขอสำเนาข้อมูล (DSAR)',
                description:
                    'ระบบจะรวบรวมข้อมูลของบุตรท่านและส่งสำเนาให้ภายในกรอบเวลาตามกฎหมาย',
                submitLabel: 'ยื่นคำขอสำเนา',
              ),
            ),
            const SizedBox(height: 10),
            _RequestActionCard(
              icon: Icons.delete_outline_rounded,
              title: 'ขอลบ/แก้ไขข้อมูล',
              subtitle: 'คำขอต้องผ่านการพิจารณาจากฝ่ายทะเบียนก่อนดำเนินการ',
              buttonLabel: 'ยื่นคำขอลบ/แก้ไข',
              onTap: () => _openRequestDialog(
                title: 'ขอลบ/แก้ไขข้อมูล',
                description:
                    'หากข้อมูลบางส่วนต้องเก็บไว้ตามกฎหมาย (เช่นหลักฐานการศึกษา) '
                    'คำขออาจถูกปฏิเสธบางส่วนพร้อมเหตุผล',
                submitLabel: 'ยื่นคำขอ',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ประวัติความยินยอม',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 15,
                color: ParentTheme.ink,
              ),
            ),
            const SizedBox(height: 10),
            ParentGlassCard(
              child: Column(
                children: [
                  for (var i = 0; i < _history.length; i++) ...[
                    if (i != 0) const Divider(height: 20),
                    _HistoryRow(entry: _history[i]),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({required this.purpose, required this.onChanged});

  final _ConsentPurpose purpose;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ParentGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  purpose.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: ParentTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  purpose.description,
                  style: const TextStyle(
                    color: ParentTheme.muted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  purpose.granted
                      ? 'ยินยอมตั้งแต่ ${purpose.grantedAt}'
                      : 'ยังไม่ได้ให้ความยินยอม',
                  style: TextStyle(
                    color: purpose.granted
                        ? ParentTheme.safeGreen
                        : ParentTheme.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: purpose.granted,
            activeTrackColor: ParentTheme.primaryTeal,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _RequestActionCard extends StatelessWidget {
  const _RequestActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ParentGlassCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: ParentTheme.primaryTeal.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: ParentTheme.primaryTeal, size: 20),
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
                    fontSize: 13,
                    color: ParentTheme.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: ParentTheme.muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: ParentTheme.primaryTeal,
              side: const BorderSide(color: ParentTheme.primaryTeal),
            ),
            child: Text(buttonLabel, style: const TextStyle(fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final _HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.history_rounded, size: 15, color: ParentTheme.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.text,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: ParentTheme.softText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.timeLabel,
                style: const TextStyle(
                  fontSize: 10.5,
                  color: ParentTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
