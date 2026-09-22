import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

import 'student_redesign_palette.dart';

/// การแสดงผลบล็อกเนื้อหาบทเรียน — ใช้ร่วมกันระหว่างหน้าบทเรียนของนักเรียน
/// (`student_lesson_view_page.dart`) กับหน้าดูตัวอย่างของครู
/// (`teacher_lesson_editor_page.dart`)
///
/// ห้ามมีการวาดบล็อกชุดที่สองที่อื่นอีก: ก่อนหน้านี้ครูมีตัววาดของตัวเอง
/// ที่สวยกว่าของจริง ครูจึงเผยแพร่แล้วได้หน้าตาคนละอย่างกับที่พรีวิวสัญญาไว้
/// (ดู PITFALLS.md ข้อ 10)
class LessonBlockView extends StatelessWidget {
  const LessonBlockView({
    super.key,
    required this.blocks,
    required this.fallbackBody,
  });

  /// บล็อกจาก `content['blocks']`
  final List<ContentBlockModel> blocks;

  /// `content['body']` — ใช้เมื่อบทเรียนถูกสร้างก่อนมีตัวแก้ไขแบบบล็อก
  final String fallbackBody;

  /// ชนิดที่โครงสร้างรองรับแต่ยังวาดไม่ได้ในรอบนี้ — แสดงเป็นแถวจาง ๆ
  /// บอกตรง ๆ ดีกว่าเงียบหายไปจนนักเรียนงงว่าเนื้อหาขาด
  static const _unsupported = {
    ContentBlockType.image: 'รูปภาพ',
    ContentBlockType.video: 'วิดีโอ',
    ContentBlockType.fileDownload: 'ไฟล์ดาวน์โหลด',
    ContentBlockType.externalLink: 'ลิงก์ภายนอก',
  };

  @override
  Widget build(BuildContext context) {
    final visible = blocks
        .where(
          (b) =>
              b.type == ContentBlockType.sensorChart ||
              _unsupported.containsKey(b.type) ||
              b.text.trim().isNotEmpty,
        )
        .toList();

    if (visible.isEmpty) {
      return Text(
        fallbackBody.trim().isEmpty
            ? 'ไม่มีเนื้อหาข้อความในบทเรียนนี้'
            : fallbackBody,
        style: TextStyle(
          fontSize: 14.5,
          height: 1.65,
          fontWeight: FontWeight.w500,
          color: fallbackBody.trim().isEmpty
              ? SchoolPalette.muted
              : SchoolPalette.ink,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < visible.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
            child: _block(visible[i]),
          ),
      ],
    );
  }

  Widget _block(ContentBlockModel block) {
    switch (block.type) {
      case ContentBlockType.heading:
        return _Heading(block.text);
      case ContentBlockType.bulletList:
        return _BulletList(block.text);
      case ContentBlockType.calloutWarning:
        return _Callout(block.text);
      case ContentBlockType.summaryBox:
        return _SummaryBox(block.text);
      case ContentBlockType.sensorChart:
        return _SensorNote(block);
      case ContentBlockType.image:
      case ContentBlockType.video:
      case ContentBlockType.fileDownload:
      case ContentBlockType.externalLink:
        return _Unsupported(
          label: _unsupported[block.type]!,
          caption: block.caption.trim().isEmpty
              ? block.text.trim()
              : block.caption.trim(),
        );
      case ContentBlockType.text:
        return _Body(block.text);
    }
  }
}

class _Body extends StatelessWidget {
  const _Body(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14.5,
      height: 1.65,
      fontWeight: FontWeight.w500,
      color: SchoolPalette.ink,
    ),
  );
}

/// หัวข้อย่อย — เส้นคาดซ้ายสีมิ้นต์ แบ่งตอนได้โดยไม่กินพื้นที่แนวตั้งมาก
class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.only(left: 11),
    decoration: const BoxDecoration(
      border: Border(left: BorderSide(color: SchoolPalette.mint, width: 3)),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        height: 1.4,
        fontWeight: FontWeight.w900,
        color: SchoolPalette.deepGreen,
      ),
    ),
  );
}

/// รายการ — หนึ่งบรรทัดต่อหนึ่งข้อ ตัดบรรทัดว่างทิ้ง
class _BulletList extends StatelessWidget {
  const _BulletList(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final items = text
        .split('\n')
        .map((line) => line.trim().replaceFirst(RegExp(r'^[-•]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < items.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7, right: 10),
                  child: SizedBox(
                    width: 5,
                    height: 5,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: SchoolPalette.mint,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    items[i],
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                      color: SchoolPalette.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// กล่องเตือน — ใช้สีเหลืองที่ palette ของเลนนักเรียนมีอยู่แล้ว
class _Callout extends StatelessWidget {
  const _Callout(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF8E6),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SchoolPalette.yellow.withValues(alpha: 0.5)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 11, top: 1),
          child: Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: Color(0xFF8A5A00),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A5A00),
            ),
          ),
        ),
      ],
    ),
  );
}

/// กล่องสรุป — มีป้ายกำกับ นักเรียนย้อนกลับมาทวนได้เร็ว
class _SummaryBox extends StatelessWidget {
  const _SummaryBox(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: SchoolPalette.softGreenBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SchoolPalette.glassBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'สรุป',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: SchoolPalette.deepGreen,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13.5,
            height: 1.65,
            fontWeight: FontWeight.w500,
            color: SchoolPalette.ink,
          ),
        ),
      ],
    ),
  );
}

/// บล็อกกราฟในเนื้อหา — กราฟจริงอยู่ในหัวข้อ 'ข้อมูลเซนเซอร์ AIoT' ของหน้า
/// เพราะฝั่งนักเรียนดึงข้อมูลจากตาราง `lesson_sensor_links` ไม่ใช่จากบล็อก
/// ตรงนี้จึงเป็นป้ายชี้ทาง ไม่ใช่กราฟซ้ำ
class _SensorNote extends StatelessWidget {
  const _SensorNote(this.block);
  final ContentBlockModel block;

  @override
  Widget build(BuildContext context) {
    final metric = block.sensorMetric.trim();
    final label = block.caption.trim().isNotEmpty
        ? block.caption.trim()
        : (block.text.trim().isNotEmpty ? block.text.trim() : null);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: SchoolPalette.softGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 11, top: 1),
            child: Icon(
              Icons.insights_rounded,
              size: 18,
              color: SchoolPalette.deepGreen,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                        color: SchoolPalette.ink,
                      ),
                    ),
                  ),
                Text(
                  metric.isEmpty
                      ? 'ดูกราฟข้อมูลเซนเซอร์ได้ที่หัวข้อด้านล่างของหน้านี้'
                      : 'ดูกราฟ $metric ได้ที่หัวข้อด้านล่างของหน้านี้',
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.5,
                    color: SchoolPalette.muted,
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

class _Unsupported extends StatelessWidget {
  const _Unsupported({required this.label, required this.caption});
  final String label;
  final String caption;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
    decoration: BoxDecoration(
      color: SchoolPalette.softGreenBg,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: SchoolPalette.glassBorder),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(right: 11, top: 1),
          child: Icon(
            Icons.hourglass_empty_rounded,
            size: 17,
            color: SchoolPalette.muted,
          ),
        ),
        Expanded(
          child: Text(
            caption.isEmpty
                ? '$label — ยังไม่รองรับการแสดงผล'
                : '$label — ยังไม่รองรับการแสดงผล ($caption)',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.5,
              color: SchoolPalette.muted,
            ),
          ),
        ),
      ],
    ),
  );
}
