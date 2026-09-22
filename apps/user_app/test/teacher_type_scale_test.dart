import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/teacher_redesign_prototype/teacher_airy_kit.dart';

/// เลนครูเคยใช้ขนาดตัวอักษร 35 ขนาดตั้งแต่ 8.5 ถึง 42 (2026-09-22) รวม
/// ครึ่งหน่วยอย่าง 10.8 / 12.5 / 16.5 ที่ตาแยกไม่ออกแต่ทำให้ไม่มีใครรู้ว่า
/// ควรหยิบอันไหน — ยุบเหลือ [TeacherType] 8 ค่า เทสต์นี้กันไม่ให้ค่อย ๆ
/// งอกกลับมาอีก
///
/// `teacher_storybook_page.dart` ยกเว้นไว้ — เป็นหน้าตัวอย่างสำหรับนักพัฒนา
/// ไม่ใช่ UI ที่ครูเห็น และจงใจโชว์ขนาดแปลก ๆ เพื่อเทียบ
void main() {
  const excluded = {'teacher_storybook_page.dart'};

  test('ทุก fontSize ในเลนครูอยู่ในสเกล TeacherType', () {
    final dir = Directory('lib/pages/teacher_redesign_prototype');
    final offenders = <String>[];
    final pattern = RegExp(r'fontSize: ([0-9]+(?:\.[0-9]+)?)');

    for (final file in dir.listSync().whereType<File>()) {
      if (!file.path.endsWith('.dart')) continue;
      if (excluded.contains(file.uri.pathSegments.last)) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        for (final m in pattern.allMatches(lines[i])) {
          final size = double.parse(m.group(1)!);
          if (!TeacherType.all.contains(size)) {
            offenders.add('${file.uri.pathSegments.last}:${i + 1} → $size');
          }
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'ขนาดนอกสเกล ${TeacherType.all.toList()..sort()} — '
          'เลือกระดับที่ใกล้ที่สุดใน TeacherType แทนการตั้งค่าใหม่:\n'
          '${offenders.join('\n')}',
    );
  });

  test('สเกลไม่มีค่าซ้ำและเรียงจากใหญ่ไปเล็ก', () {
    const ordered = [
      TeacherType.figure,
      TeacherType.hero,
      TeacherType.title,
      TeacherType.cardTitle,
      TeacherType.body,
      TeacherType.secondary,
      TeacherType.label,
      TeacherType.caption,
    ];
    expect(ordered.toSet().length, ordered.length, reason: 'มีค่าซ้ำในสเกล');
    for (var i = 1; i < ordered.length; i++) {
      expect(ordered[i], lessThan(ordered[i - 1]));
    }
    expect(TeacherType.all.length, ordered.length);
  });
}
