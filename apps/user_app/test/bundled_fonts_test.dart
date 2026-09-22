import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 2026-09-21: the phone app was slow to first paint because google_fonts
/// fetched NotoSansThai and PlusJakartaSans from fonts.gstatic.com on every
/// cold start — one request per weight, text unstyled until they arrived.
/// The fix is to ship the weights and forbid the fetch; these tests fail if
/// either half is undone.
void main() {
  final fontsDir = Directory('assets/google_fonts');

  test('every weight the UI asks for is bundled', () {
    // PlusJakartaSans has no Black upstream — code asking for w900 gets
    // ExtraBold, which is what it already got before this change.
    const expected = [
      // มีหัว — ฟอนต์หลักของ UI ตั้งแต่ 2026-09-22
      'NotoSansThaiLooped-Regular.ttf',
      'NotoSansThaiLooped-Medium.ttf',
      'NotoSansThaiLooped-SemiBold.ttf',
      'NotoSansThaiLooped-Bold.ttf',
      'NotoSansThaiLooped-ExtraBold.ttf',
      'NotoSansThaiLooped-Black.ttf',
      // ไม่มีหัว — ยังเก็บไว้ เผื่อหน้าไหนอยากได้โทนโมเดิร์นเป็นการเฉพาะ
      'NotoSansThai-Regular.ttf',
      'NotoSansThai-Medium.ttf',
      'NotoSansThai-SemiBold.ttf',
      'NotoSansThai-Bold.ttf',
      'NotoSansThai-ExtraBold.ttf',
      'NotoSansThai-Black.ttf',
      'PlusJakartaSans-Regular.ttf',
      'PlusJakartaSans-Medium.ttf',
      'PlusJakartaSans-SemiBold.ttf',
      'PlusJakartaSans-Bold.ttf',
      'PlusJakartaSans-ExtraBold.ttf',
    ];
    for (final name in expected) {
      final file = File('${fontsDir.path}/$name');
      expect(file.existsSync(), isTrue, reason: '$name is missing');
      expect(file.lengthSync(), greaterThan(1000), reason: '$name looks empty');
    }
  });

  test('the font licences ship with the fonts', () {
    // Both families are SIL OFL; redistributing them means shipping these.
    for (final name in [
      'OFL-NotoSansThai.txt',
      'OFL-NotoSansThaiLooped.txt',
      'OFL-PlusJakartaSans.txt',
    ]) {
      expect(
        File('${fontsDir.path}/$name').existsSync(),
        isTrue,
        reason: '$name is missing',
      );
    }
  });

  test('pubspec declares the font directory', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('- assets/google_fonts/'),
    );
  });

  /// ฟอนต์ที่ธีมขอต้องเป็นตัวที่ bundle ไว้จริง — runtime fetching ปิดอยู่
  /// ขอชื่อผิดตัวเดียวคือข้อความไทยหายทั้งแอปโดยไม่มี error
  test('ธีมขอฟอนต์มีหัว ไม่ใช่ตัวไม่มีหัว', () {
    expect(
      File('lib/theme/app_theme.dart').readAsStringSync(),
      contains('GoogleFonts.notoSansThaiLooped()'),
    );
    for (final p in [
      'lib/pages/super_admin/theme/app_palette.dart',
      '../../packages/shared_ui/lib/theme/role_theme.dart',
    ]) {
      expect(
        File(p).readAsStringSync(),
        contains("fontFamily: 'NotoSansThaiLooped'"),
        reason: '$p ยังชี้ฟอนต์เก่า',
      );
    }
  });

  test('runtime fetching stays off', () {
    expect(
      File('lib/main.dart').readAsStringSync(),
      contains('GoogleFonts.config.allowRuntimeFetching = false'),
    );
  });
}
