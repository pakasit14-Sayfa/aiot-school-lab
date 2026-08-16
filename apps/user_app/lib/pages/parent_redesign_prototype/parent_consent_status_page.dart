// เชื่อมกับ ConsentService จริงแล้ว (2026-08-16) — เดิม mock ล้วน
//
// กลุ่ม CON ทั้งหมดของผู้ปกครองรวมอยู่หน้าเดียว เพราะเป็น flow ต่อเนื่องกัน
// ตามธรรมชาติ: CON-1 (ให้ความยินยอมแยกวัตถุประสงค์) กับ CON-2 (ถอนความ
// ยินยอม) คือ toggle เดียวกัน (เปิด=ยินยอม, ปิด=ถอน) ผ่าน
// grantParentConsent/withdrawParentConsent จริง — CON-3 (ดูสถานะ) คือส่วน
// แสดงผลของ toggle เดียวกันนี้จาก listMyConsents จริง
//
// ⚠️ สิ่งที่ตัดออกเพราะไม่มี backend รองรับ (ตรวจ RPC ทั้งไฟล์ consent_policy
// แล้วไม่พบ):
// - "ประวัติความยินยอม" (ใครให้/ถอนเมื่อไหร่) — ไม่มี RPC ดึงประวัติเลย มีแค่
//   สถานะปัจจุบัน ตัดส่วนนี้ทิ้งแทนที่จะโชว์ประวัติปลอม
// - CON-4/CON-5 (ขอสำเนา/ขอลบข้อมูล) — ไม่มี RPC สร้างคำขอ ยังคงเป็นฟอร์ม
//   UI เฉยๆ (ปรับข้อความให้ตรงว่ายังไม่เชื่อมระบบจริง ไม่ใช่ยิงคำขอจริง)
//
// รับ parentLinkId (ไม่ใช่ studentId) เพราะ listMyConsents ต้องใช้
// parent_link_id ของบุตรที่กำลังดูอยู่ — ส่งมาจาก parent_home_page.dart
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'parent_shared_widgets.dart';

class ParentConsentStatusPage extends StatefulWidget {
  const ParentConsentStatusPage({
    super.key,
    required this.parentLinkId,
    required this.childName,
  });

  final String parentLinkId;
  final String childName;

  @override
  State<ParentConsentStatusPage> createState() =>
      _ParentConsentStatusPageState();
}

class _ParentConsentStatusPageState extends State<ParentConsentStatusPage> {
  bool _loading = true;
  String? _loadError;
  List<ParentConsent> _consents = [];
  final Set<String> _busy = {};

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
      final consents = await ConsentService.listMyConsents(widget.parentLinkId);
      if (!mounted) return;
      setState(() {
        _consents = consents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = 'โหลดข้อมูลความยินยอมไม่สำเร็จ: $e';
        _loading = false;
      });
    }
  }

  Future<void> _toggle(ParentConsent consent, bool value) async {
    setState(() => _busy.add(consent.policyId));
    try {
      if (value) {
        await ConsentService.grantParentConsent(
          parentLinkId: widget.parentLinkId,
          policyId: consent.policyId,
        );
      } else {
        if (consent.consentId == null) return;
        await ConsentService.withdrawParentConsent(consent.consentId!);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'ให้ความยินยอม "${consent.consentType}" แล้ว'
                : 'ถอนความยินยอม "${consent.consentType}" แล้ว — ระบบหยุดใช้ข้อมูลส่วนนี้ทันที',
          ),
          backgroundColor: value
              ? ParentTheme.safeGreen
              : ParentTheme.warningOrange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ทำรายการไม่สำเร็จ: $e')));
    } finally {
      if (mounted) setState(() => _busy.remove(consent.policyId));
    }
  }

  Future<void> _openRequestDialog({
    required String title,
    required String description,
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
    // ยังไม่มี RPC รับคำขอ DSAR/ลบข้อมูลจริง — บอกตรงๆ แทนที่จะแสร้งว่า
    // ส่งคำขอสำเร็จแล้ว
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'ยังไม่รองรับการยื่นคำขอ "$title" ผ่านระบบในตอนนี้ — กรุณาติดต่อ'
          'ฝ่ายทะเบียนของโรงเรียนโดยตรง',
        ),
        backgroundColor: ParentTheme.warningOrange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ParentMockPageShell(
      title: 'ความเป็นส่วนตัวและ PDPA',
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
              child: Text(
                'ความยินยอมของ ${widget.childName} — เลือกให้/ถอนแยกตาม'
                'วัตถุประสงค์ได้อิสระ ไม่ใช่แบบ all-or-nothing',
                style: const TextStyle(
                  color: ParentTheme.primaryTeal,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
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
            if (_consents.isEmpty)
              const Text(
                'ยังไม่มีนโยบายความยินยอมที่โรงเรียนเผยแพร่ไว้',
                style: TextStyle(
                  color: ParentTheme.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              )
            else
              for (final consent in _consents) ...[
                _ConsentTile(
                  consent: consent,
                  isBusy: _busy.contains(consent.policyId),
                  onChanged: (v) => _toggle(consent, v),
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
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConsentTile extends StatelessWidget {
  const _ConsentTile({
    required this.consent,
    required this.isBusy,
    required this.onChanged,
  });

  final ParentConsent consent;
  final bool isBusy;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final granted = consent.isGranted;
    return ParentGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        consent.consentType,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                          color: ParentTheme.ink,
                        ),
                      ),
                    ),
                    if (consent.isRequired) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: ParentTheme.warningOrange.withValues(
                            alpha: 0.12,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'จำเป็น',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: ParentTheme.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'เวอร์ชันนโยบาย ${consent.version}',
                  style: const TextStyle(
                    color: ParentTheme.muted,
                    fontSize: 11.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  granted ? 'ยินยอมแล้ว' : 'ยังไม่ได้ให้ความยินยอม',
                  style: TextStyle(
                    color: granted ? ParentTheme.safeGreen : ParentTheme.muted,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (isBusy)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Switch(
              value: granted,
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
