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
    this.materials = const [],
    this.resolveMaterialUrl,
    this.onOpenMaterial,
    this.onOpenLink,
  });

  /// บล็อกจาก `content['blocks']`
  final List<ContentBlockModel> blocks;

  /// `content['body']` — ใช้เมื่อบทเรียนถูกสร้างก่อนมีตัวแก้ไขแบบบล็อก
  final String fallbackBody;

  /// สื่อแนบของบทเรียน — บล็อก รูป/วิดีโอ/ไฟล์ อ้างถึงด้วย `materialId`
  final List<LessonMaterial> materials;

  /// แลก material id เป็น signed URL อายุสั้น (ไฟล์อยู่ใน bucket แบบ private)
  /// ไม่ส่งมา = แสดงการ์ดสื่อโดยไม่โหลดรูป
  final Future<String> Function(String materialId)? resolveMaterialUrl;

  /// เปิดสื่อที่อัปโหลดไว้ / เปิดลิงก์ภายนอก — ไม่ส่งมา (เช่นหน้าดูตัวอย่าง
  /// ของครู) ปุ่มจะแสดงแต่กดไม่ได้ ตรงกับที่พรีวิวไม่ควรพาออกจากหน้า
  final void Function(LessonMaterial material)? onOpenMaterial;
  final void Function(String url)? onOpenLink;

  static const _mediaTypes = {
    ContentBlockType.image,
    ContentBlockType.video,
    ContentBlockType.fileDownload,
    ContentBlockType.externalLink,
  };

  @override
  Widget build(BuildContext context) {
    final visible = blocks
        .where(
          (b) =>
              b.type == ContentBlockType.sensorChart ||
              _mediaTypes.contains(b.type) ||
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

  String _captionOf(ContentBlockModel block) =>
      block.caption.trim().isEmpty ? block.text.trim() : block.caption.trim();

  /// สื่อที่บล็อกอ้างถึง — คืน null เมื่อครูยังไม่ได้เลือก หรือเลือกไว้แล้ว
  /// แต่สื่อชิ้นนั้นถูกลบออกจากบทเรียนไปแล้ว ทั้งสองกรณีต้องบอกนักเรียน
  /// ตรง ๆ ไม่ใช่โชว์กรอบว่าง
  LessonMaterial? _materialOf(ContentBlockModel block) {
    if (block.materialId.trim().isEmpty) return null;
    for (final m in materials) {
      if (m.id == block.materialId.trim()) return m;
    }
    return null;
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
      case ContentBlockType.externalLink:
        return _LinkBlock(
          url: block.mediaUrl.trim(),
          label: _captionOf(block),
          onOpen: onOpenLink,
        );
      case ContentBlockType.image:
      case ContentBlockType.video:
      case ContentBlockType.fileDownload:
        return _MediaBlock(
          type: block.type,
          material: _materialOf(block),
          caption: _captionOf(block),
          resolveUrl: resolveMaterialUrl,
          onOpen: onOpenMaterial,
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

/// รูป/วิดีโอ/ไฟล์ที่ครูอัปโหลดไว้เป็นสื่อแนบของบทเรียน
///
/// รูปโหลดมาแสดงในหน้าเลย ส่วนวิดีโอกับไฟล์เป็นการ์ดพร้อมปุ่มเปิด เพราะแอป
/// ยังไม่มีตัวเล่นวิดีโอในตัว — เขียนให้ตรงกับที่ทำได้จริง ดีกว่าโชว์กรอบ
/// วิดีโอที่กดแล้วไม่มีอะไรเกิดขึ้น
class _MediaBlock extends StatelessWidget {
  const _MediaBlock({
    required this.type,
    required this.material,
    required this.caption,
    required this.resolveUrl,
    required this.onOpen,
  });

  final ContentBlockType type;
  final LessonMaterial? material;
  final String caption;
  final Future<String> Function(String materialId)? resolveUrl;
  final void Function(LessonMaterial material)? onOpen;

  String get _label => switch (type) {
    ContentBlockType.image => 'รูปภาพ',
    ContentBlockType.video => 'วิดีโอ',
    _ => 'ไฟล์',
  };

  IconData get _icon => switch (type) {
    ContentBlockType.image => Icons.image_outlined,
    ContentBlockType.video => Icons.play_circle_outline_rounded,
    _ => Icons.insert_drive_file_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final mat = material;
    if (mat == null) {
      return _MissingMedia('$_label — ยังไม่ได้เลือกไฟล์');
    }

    if (type == ContentBlockType.image) {
      return _ImageBlock(
        material: mat,
        caption: caption,
        resolveUrl: resolveUrl,
      );
    }

    return _ActionCard(
      icon: _icon,
      title: caption.isEmpty ? (mat.title ?? _label) : caption,
      subtitle: _label,
      action: type == ContentBlockType.video ? 'เปิดวิดีโอ' : 'เปิดไฟล์',
      onTap: onOpen == null ? null : () => onOpen!(mat),
    );
  }
}

class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.material,
    required this.caption,
    required this.resolveUrl,
  });

  final LessonMaterial material;
  final String caption;
  final Future<String> Function(String materialId)? resolveUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: resolveUrl == null
              ? _ImageFrame(child: _ImageHint(material.title ?? 'รูปภาพ'))
              : FutureBuilder<String>(
                  future: resolveUrl!(material.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const _ImageFrame(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: SchoolPalette.deepGreen,
                          ),
                        ),
                      );
                    }
                    if (snap.hasError || snap.data == null) {
                      return const _ImageFrame(
                        child: _ImageHint('เปิดรูปไม่สำเร็จ ลองใหม่อีกครั้ง'),
                      );
                    }
                    return Image.network(
                      snap.data!,
                      fit: BoxFit.fitWidth,
                      width: double.infinity,
                      errorBuilder: (_, _, _) => const _ImageFrame(
                        child: _ImageHint('เปิดรูปไม่สำเร็จ ลองใหม่อีกครั้ง'),
                      ),
                    );
                  },
                ),
        ),
        if (caption.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              caption,
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: SchoolPalette.muted,
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageFrame extends StatelessWidget {
  const _ImageFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: 160,
    width: double.infinity,
    alignment: Alignment.center,
    color: SchoolPalette.softGreenBg,
    child: child,
  );
}

class _ImageHint extends StatelessWidget {
  const _ImageHint(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(
      text,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 12.5,
        height: 1.5,
        color: SchoolPalette.muted,
      ),
    ),
  );
}

/// ลิงก์ภายนอกที่ครูวางไว้ — ไม่ใช่ไฟล์ใน Storage จึงเปิดตรงได้เลย
class _LinkBlock extends StatelessWidget {
  const _LinkBlock({
    required this.url,
    required this.label,
    required this.onOpen,
  });

  final String url;
  final String label;
  final void Function(String url)? onOpen;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const _MissingMedia('ลิงก์ภายนอก — ยังไม่ได้ใส่ URL');
    }
    return _ActionCard(
      icon: Icons.link_rounded,
      title: label.isEmpty ? url : label,
      subtitle: url,
      action: 'เปิดลิงก์',
      onTap: onOpen == null ? null : () => onOpen!(url),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: SchoolPalette.softGreenBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: SchoolPalette.glassBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 21, color: SchoolPalette.deepGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontWeight: FontWeight.w800,
                    color: SchoolPalette.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: SchoolPalette.muted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: SchoolPalette.glassBorder, width: 1.2),
            ),
            child: Text(
              action,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: SchoolPalette.deepGreen,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class _MissingMedia extends StatelessWidget {
  const _MissingMedia(this.text);
  final String text;

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
            Icons.help_outline_rounded,
            size: 17,
            color: SchoolPalette.muted,
          ),
        ),
        Expanded(
          child: Text(
            text,
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
