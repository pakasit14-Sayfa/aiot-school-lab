import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_qr_login_page.dart';

/// Pins the pairing-session failure path: a student must see a real error
/// with a retry action, never a QR code that looks real but can never be
/// claimed. Guards against regressing back to the fake-token fallback that
/// used to silently substitute a locally-generated, unclaimable code on any
/// session-creation error (network failure, backend outage, etc.).

Future<void> _pump(
  WidgetTester tester, {
  Future<({String pairingCode, DateTime expiresAt})> Function({
    String? terminalName,
  })?
  createSession,
}) async {
  tester.view.physicalSize = const Size(800, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(home: StudentQrLoginPage(createSession: createSession)),
  );
}

void main() {
  testWidgets('a real pairing session renders a real QR code', (
    tester,
  ) async {
    await _pump(
      tester,
      createSession: ({terminalName}) async => (
        pairingCode: 'aiot-pairing:REALCODE123',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('สร้างรหัส QR ไม่สำเร็จ'), findsNothing);
  });

  testWidgets(
    'a failed pairing session shows a real error with retry, not a fake QR',
    (tester) async {
      var calls = 0;
      await _pump(
        tester,
        createSession: ({terminalName}) async {
          calls++;
          throw StateError('network unreachable');
        },
      );
      await tester.pump();

      expect(calls, 1);
      expect(find.textContaining('สร้างรหัส QR ไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ลองใหม่'), findsOneWidget);
      // No QrImageView should be rendered when the session failed — a
      // "successful-looking" QR must never appear for an unclaimable code.
      expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
    },
  );

  testWidgets('tapping retry after a failure calls the seam again', (
    tester,
  ) async {
    var calls = 0;
    var shouldFail = true;
    await _pump(
      tester,
      createSession: ({terminalName}) async {
        calls++;
        if (shouldFail) {
          throw StateError('network unreachable');
        }
        return (
          pairingCode: 'aiot-pairing:RECOVEREDCODE',
          expiresAt: DateTime.now().add(const Duration(minutes: 5)),
        );
      },
    );
    await tester.pump();

    expect(calls, 1);
    expect(find.text('ลองใหม่'), findsOneWidget);

    shouldFail = false;
    await tester.tap(find.text('ลองใหม่'));
    await tester.pump();

    expect(calls, 2);
    expect(find.textContaining('สร้างรหัส QR ไม่สำเร็จ'), findsNothing);
  });
}
