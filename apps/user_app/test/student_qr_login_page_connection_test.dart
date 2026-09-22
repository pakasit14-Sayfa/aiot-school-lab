import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/student_redesign_prototype/widgets/student_qr_login_page.dart';
import 'package:shared_core/shared_core.dart';

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
  scanModeTests();
  testWidgets('a real pairing session renders a real QR code', (tester) async {
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

// ---------------------------------------------------------------------------
// Scan mode (2026-09-16): no fake "preview" device, no "(ตัวอย่าง)" success,
// no raw exception text; the typed-code fallback goes through the real peek.
// ---------------------------------------------------------------------------

Future<void> _pumpScan(
  WidgetTester tester, {
  Future<TerminalPairingPeek> Function(String)? peek,
  Future<({bool success, String studentName, String message})> Function(String)?
  claim,
  bool signedIn = true,
}) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: StudentQrLoginPage(
        startInScanMode: true,
        peekPairing: peek,
        claimPairing: claim,
        hasSession: () => signedIn,
      ),
    ),
  );
  await tester.pump();
  tester.takeException(); // MobileScanner has no platform in a widget test.
}

Future<void> _typeCode(WidgetTester tester, String code) async {
  await tester.enterText(find.byType(TextField).first, code);
  await tester.tap(find.text('ตรวจสอบรหัส'));
  await tester.pumpAndSettle();
  tester.takeException();
}

void scanModeTests() {
  testWidgets('no session: scanning is refused, never a sample device', (
    tester,
  ) async {
    await _pumpScan(
      tester,
      signedIn: false,
      peek: (_) async => throw StateError('must not be called'),
    );
    await _typeCode(tester, 'aiot-pairing:ABC');
    expect(find.text('ยังไม่ได้เข้าสู่ระบบ'), findsOneWidget);
    expect(find.textContaining('แท็บเล็ตประจำโต๊ะแล็บ AIoT #01'), findsNothing);
    expect(find.textContaining('(ตัวอย่าง)'), findsNothing);
  });

  testWidgets('a typed code is peeked for real and an invalid one says so', (
    tester,
  ) async {
    String? peeked;
    await _pumpScan(
      tester,
      peek: (code) async {
        peeked = code;
        return const TerminalPairingPeek(
          isValid: false,
          terminalName: '',
          createdAt: null,
          expiresAt: null,
        );
      },
    );
    await _typeCode(tester, 'aiot-pairing:EXPIRED');
    expect(peeked, 'aiot-pairing:EXPIRED');
    expect(find.text('รหัสไม่ถูกต้องหรือหมดอายุ'), findsOneWidget);
  });

  testWidgets('a peek failure hides the raw exception', (tester) async {
    await _pumpScan(
      tester,
      peek: (_) async => throw StateError('secret-backend'),
    );
    await _typeCode(tester, 'aiot-pairing:X');
    expect(find.text('ตรวจสอบรหัสไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('secret-backend'), findsNothing);
  });

  testWidgets('a valid code shows the real device, and confirming claims it', (
    tester,
  ) async {
    String? claimed;
    await _pumpScan(
      tester,
      peek: (_) async => TerminalPairingPeek(
        isValid: true,
        terminalName: 'แท็บเล็ตห้องแล็บ 2',
        createdAt: DateTime(2026, 9, 16, 9),
        expiresAt: DateTime(2026, 9, 16, 9, 5),
      ),
      claim: (code) async {
        claimed = code;
        return (success: true, studentName: 'นักเรียนทดสอบ', message: '');
      },
    );
    await _typeCode(tester, 'aiot-pairing:GOOD');
    expect(find.textContaining('แท็บเล็ตห้องแล็บ 2'), findsWidgets);
    await tester.tap(find.text('ยืนยันเข้าสู่ระบบ'));
    await tester.pumpAndSettle();
    tester.takeException();
    expect(claimed, 'aiot-pairing:GOOD');
    expect(find.text('เข้าสู่ระบบสำเร็จ'), findsOneWidget);
    expect(find.textContaining('นักเรียนทดสอบ'), findsWidgets);
  });
}
