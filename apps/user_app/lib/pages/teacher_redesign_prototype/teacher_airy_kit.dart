// ชุดคอนโทรลสไตล์ "โปร่ง-ขาว" ของเลนครู (2026-09-22)
//
// ถอดจากภาพอ้างอิงที่เจ้าของเลือก: พื้นขาว การ์ดเงานุ่ม ป้ายเล็กสีเทาคู่กับค่า
// ตัวหนาเข้ม ไอคอนเส้นบางสีเดียว อินพุตเป็นกล่องมีขอบ (โฟกัส = ขอบสีเน้น /
// ผิดพลาด = ขอบแดงพร้อมข้อความ) และปุ่ม 4 ระดับ
//
// อยู่ไฟล์เดียวเพื่อให้ทุกหน้าในเลนใช้ค่าชุดเดียวกันจริง ๆ ไม่ใช่ก๊อปตัวเลข
// ไปวางคนละที่แล้วค่อย ๆ เพี้ยนออกจากกัน

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'teacher_assignment_form_page.dart' show kMetricThai;
import 'teacher_redesign_prototype_page.dart' show TeacherPalette;

const _thaiMonthsShort = [
  'ม.ค.',
  'ก.พ.',
  'มี.ค.',
  'เม.ย.',
  'พ.ค.',
  'มิ.ย.',
  'ก.ค.',
  'ส.ค.',
  'ก.ย.',
  'ต.ค.',
  'พ.ย.',
  'ธ.ค.',
];

String _fmtThaiShort(DateTime d) {
  final l = d.toLocal();
  final hh = l.hour.toString().padLeft(2, '0');
  final mm = l.minute.toString().padLeft(2, '0');
  return '${l.day} ${_thaiMonthsShort[l.month - 1]} $hh:$mm';
}

/// ชุดค่าของสไตล์ "โปร่ง-ขาว" ที่เจ้าของเลือกจากภาพอ้างอิง (2026-09-22):
/// พื้นขาว การ์ดเงานุ่ม เส้นคั่นบาง ป้ายเล็กสีเทาคู่กับค่าตัวหนาเข้ม
/// ไอคอนเส้นบางสีเดียว และใช้สีเน้นเฉพาะสถานะจริง ๆ เท่านั้น
/// สเกลขนาดตัวอักษรของเลนครู — 7 ระดับสำหรับข้อความ + 1 สำหรับตัวเลขใหญ่
///
/// ก่อน 2026-09-22 เลนนี้ใช้ขนาดต่างกัน **35 ขนาด** ตั้งแต่ 8.5 ถึง 42 รวม
/// ครึ่งหน่วยอย่าง 10.8 / 12.5 / 16.5 — ตาแยกไม่ออกแต่ทำให้ไม่มีใครรู้ว่า
/// ควรใช้อันไหน คนต่อไปจึงเดาแล้วเพิ่มขนาดใหม่เข้าไปเรื่อย ๆ
///
/// ใช้ค่าจากที่นี่เสมอ อย่าพิมพ์ตัวเลขดิบ — `teacher_type_scale_test.dart`
/// จะ fail ถ้ามีขนาดนอกสเกลโผล่มา
abstract final class TeacherType {
  /// ชื่อหน้า · ชื่อบทเรียนบนหัวสีประจำวิชา
  static const double hero = 22;

  /// ชื่อบนแถบบน · หัวไดอะล็อก · หัวชีต
  static const double title = 17;

  /// ชื่อรายการในการ์ด · ค่าที่ต้องการให้อ่านก่อน
  static const double cardTitle = 15;

  /// ย่อหน้าเนื้อหา · คำอธิบาย
  static const double body = 14;

  /// ป้ายปุ่ม · ค่าในแถวข้อมูล
  static const double secondary = 13;

  /// ป้ายกำกับเหนือค่า · ข้อมูลประกอบในแถว
  static const double label = 12;

  /// ชิปสถานะ · หมายเหตุ · หน่วยวัด
  static const double caption = 11;

  /// ตัวเลขสรุปขนาดใหญ่เท่านั้น (จำนวนที่ส่งแล้ว · เปอร์เซ็นต์รวม)
  /// ไม่ใช่สำหรับข้อความ
  static const double figure = 32;

  /// ทุกค่าที่อนุญาต — เทสต์อ่านจากที่นี่ เพิ่มขนาดใหม่ต้องมาแก้ตรงนี้ก่อน
  /// ซึ่งเป็นจุดที่จะมีคนเห็นและถามว่าทำไมถึงต้องมี
  // List ไม่ใช่ Set เพราะ const Set<double> คอมไพล์ไม่ผ่าน
  // (double ไม่มี primitive equality)
  static const List<double> all = [
    hero,
    title,
    cardTitle,
    body,
    secondary,
    label,
    caption,
    figure,
  ];
}

class AirySpec {
  static const ink = Color(0xFF17161C);
  static const label = Color(0xFF8E8C99);
  static const hairline = Color(0xFFF0F0F4);
  static const chevron = Color(0xFFC9C7D2);
}

class AiryCard extends StatelessWidget {
  const AiryCard({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          const Divider(height: 1, indent: 52, color: AirySpec.hairline),
        );
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F101828),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }
}

class AiryRow extends StatelessWidget {
  const AiryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailingNote,
    this.muted = false,
    this.onTap,
    this.accent,
  });
  final IconData icon;
  final String label;
  final String value;
  final String? trailingNote;
  final bool muted;
  final VoidCallback? onTap;

  /// ใส่เมื่อแถวนี้เป็น "การกระทำ" ไม่ใช่ค่าที่ตั้งไว้ — ชื่อแถวจะรับสีนี้
  final Color? accent;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
      child: Row(
        children: [
          Icon(icon, size: 19, color: accent ?? AirySpec.label),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: accent == null ? 12.5 : 15.5,
                    fontWeight: accent == null
                        ? FontWeight.w500
                        : FontWeight.w700,
                    color: accent ?? AirySpec.label,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: accent == null ? 15.5 : 12.5,
                    fontWeight: accent == null
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: accent != null
                        ? AirySpec.label
                        : (muted ? const Color(0xFF6E6C7A) : AirySpec.ink),
                  ),
                ),
                if (trailingNote != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    trailingNote!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AirySpec.label),
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null)
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AirySpec.chevron,
            ),
        ],
      ),
    ),
  );
}

/// กล่องยืนยันสไตล์โปร่ง-ขาว — แทน AlertDialog ของ Material ที่พื้นออกเทา
/// และวางปุ่มเป็นตัวหนังสือเล็ก ๆ มุมขวาล่าง (แตะยากและไม่บอกว่าอันไหนอันตราย)
/// ที่นี่ปุ่มทำลายเป็นปุ่มแดงเต็มความกว้าง ส่วนทางถอยเป็นตัวหนังสือเทาใต้ปุ่ม
Future<bool?> showAiryConfirm({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  Color confirmColor = const Color(0xFFB3261E),
}) => showDialog<bool>(
  context: context,
  builder: (ctx) => Dialog(
    backgroundColor: Colors.white,
    insetPadding: const EdgeInsets.symmetric(horizontal: 40),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: AirySpec.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AirySpec.label,
            ),
          ),
          const SizedBox(height: 16),
          AiryButton(
            label: confirmLabel,
            kind: AiryCta.destructive,
            height: 42,
            onPressed: () => Navigator.pop(ctx, true),
          ),
          const SizedBox(height: 8),
          AiryButton(
            label: cancelLabel,
            kind: AiryCta.tertiary,
            height: 42,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          const SizedBox(height: 4),
        ],
      ),
    ),
  ),
);

/// ── ชุดคอนโทรลตามภาพอ้างอิงที่เจ้าของเลือก (2026-09-22) ──
///
/// อินพุต: กล่องขาวขอบ 1px มุม 12 ป้ายกำกับอยู่นอกกล่องด้านบน โฟกัสแล้ว
/// ขอบเปลี่ยนเป็นสีเน้นหนา 1.6 (พื้นไม่เปลี่ยน) · สถานะผิดพลาดขอบแดงพร้อม
/// ข้อความใต้กล่อง
///
/// ปุ่ม 4 ระดับ: primary (ทึบสีเน้น) · secondary (พื้นเทาอ่อน) ·
/// tertiary (ขาวมีขอบ) · destructive (พื้นแดงอ่อน ขอบแดง ตัวแดง)
class AiryInput extends StatefulWidget {
  const AiryInput({
    required this.label,
    required this.controller,
    required this.hint,
    required this.accent,
    this.optional = false,
    this.big = false,
    this.minLines = 1,
    this.maxLines = 1,
    this.errorText,
  });
  final String label;
  final TextEditingController controller;
  final String hint;
  final Color accent;
  final bool optional;
  final bool big;
  final int minLines;
  final int maxLines;
  final String? errorText;

  @override
  State<AiryInput> createState() => AiryInputState();
}

class AiryInputState extends State<AiryInput> {
  final _node = FocusNode();

  @override
  void initState() {
    super.initState();
    _node.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText != null;
    final on = _node.hasFocus;
    final border = error
        ? const Color(0xFFD3324A)
        : (on ? widget.accent : const Color(0xFFE3E1EB));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Row(
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AirySpec.label,
                  ),
                ),
                if (widget.optional) ...[
                  const SizedBox(width: 6),
                  const Text(
                    'ไม่บังคับ',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB6B4C2)),
                  ),
                ],
              ],
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border, width: on || error ? 1.6 : 1),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              minLines: widget.minLines,
              maxLines: widget.maxLines,
              cursorColor: widget.accent,
              style: TextStyle(
                fontSize: widget.big ? 16 : 15,
                height: widget.maxLines > 1 ? 1.45 : null,
                fontWeight: widget.big ? FontWeight.w700 : FontWeight.w500,
                color: AirySpec.ink,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  color: Color(0xFFB6B4C2),
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (error)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 2),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: Color(0xFFD3324A),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.errorText!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFD3324A),
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

enum AiryCta { primary, secondary, tertiary, destructive }

class AiryButton extends StatelessWidget {
  const AiryButton({
    required this.label,
    required this.onPressed,
    required this.kind,
    this.accent,
    this.height = 44,
    this.child,
  });
  final String label;
  final VoidCallback? onPressed;
  final AiryCta kind;
  final Color? accent;
  final double height;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    Color? line;
    switch (kind) {
      case AiryCta.primary:
        bg = accent ?? TeacherPalette.primary;
        fg = Colors.white;
      case AiryCta.secondary:
        bg = const Color(0xFFF2F2F5);
        fg = AirySpec.ink;
      case AiryCta.tertiary:
        bg = Colors.white;
        fg = AirySpec.ink;
        line = const Color(0xFFE3E1EB);
      case AiryCta.destructive:
        bg = const Color(0xFFFDECEF);
        fg = const Color(0xFFD3324A);
        line = const Color(0xFFF6C9D2);
    }
    return SizedBox(
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          disabledBackgroundColor: const Color(0xFFF2F2F5),
          disabledForegroundColor: const Color(0xFFB6B4C2),
          elevation: 0,
          shadowColor: Colors.transparent,
          // padding เริ่มต้นของ ElevatedButton คือ 16 ต่อข้าง ซึ่งกินที่จน
          // ปุ่มแคบ ๆ ที่จอ 360 ใส่ไอคอน+ข้อความไม่พอ
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: line == null
                ? BorderSide.none
                : BorderSide(color: line, width: 1),
          ),
        ),
        child:
            child ??
            Text(
              label,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
      ),
    );
  }
}

class AirySection extends StatelessWidget {
  const AirySection(this.text, {super.key, this.count});
  final String text;

  /// จำนวนรายการในหมวด แสดงเป็นป้ายเล็กข้างหัวข้อ (เช่น 'ยังไม่ส่ง 3')
  final int? count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 22, 4, 10),
    child: Row(
      children: [
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
            color: AirySpec.ink,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AirySpec.label,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class AirySwitchRow extends StatelessWidget {
  const AirySwitchRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.on,
    required this.accent,
    required this.onChanged,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool on;
  final Color accent;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 6, 10, 6),
    child: Row(
      children: [
        Icon(icon, size: 19, color: AirySpec.label),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AirySpec.label,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AirySpec.ink,
                ),
              ),
            ],
          ),
        ),
        // Switch.adaptive บน iOS คือ 51x31 ซึ่งสูงกว่าตัวแถวทั้งแถว
        // ย่อเหลือ 84% ให้พอดีกับความสูงของข้อความสองบรรทัด
        Transform.scale(
          scale: 0.84,
          child: Switch.adaptive(
            value: on,
            onChanged: onChanged,
            activeTrackColor: accent,
          ),
        ),
      ],
    ),
  );
}

class AiryNote extends StatelessWidget {
  const AiryNote(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
    child: Text(
      text,
      style: const TextStyle(fontSize: 13, height: 1.45, color: AirySpec.label),
    ),
  );
}

class AiryDatasetRow extends StatelessWidget {
  const AiryDatasetRow({
    required this.dataset,
    required this.deviceName,
    required this.onRemove,
  });
  final AssignmentSensorDataset dataset;
  final String deviceName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final d = dataset;
    final range = d.timeStart == null && d.timeEnd == null
        ? 'ข้อมูลล่าสุด'
        : '${d.timeStart == null ? '…' : _fmtThaiShort(d.timeStart!)} – '
              '${d.timeEnd == null ? 'ตอนนี้' : _fmtThaiShort(d.timeEnd!)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.insights_outlined, size: 19, color: AirySpec.label),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.label?.trim().isNotEmpty == true
                      ? d.label!
                      : (kMetricThai[d.metric] ?? d.metric),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AirySpec.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$deviceName · $range',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AirySpec.label),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'เอาออก',
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded, size: 19),
            color: AirySpec.chevron,
          ),
        ],
      ),
    );
  }
}
