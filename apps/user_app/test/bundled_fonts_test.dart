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
    for (final name in ['OFL-NotoSansThai.txt', 'OFL-PlusJakartaSans.txt']) {
      expect(File('${fontsDir.path}/$name').existsSync(), isTrue,
          reason: '$name is missing');
    }
  });

  test('pubspec declares the font directory', () {
    expect(File('pubspec.yaml').readAsStringSync(),
        contains('- assets/google_fonts/'));
  });

  test('runtime fetching stays off', () {
    expect(File('lib/main.dart').readAsStringSync(),
        contains('GoogleFonts.config.allowRuntimeFetching = false'));
  });
}
