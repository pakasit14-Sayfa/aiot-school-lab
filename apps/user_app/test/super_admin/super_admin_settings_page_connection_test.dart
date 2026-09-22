import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/super_admin_settings_page.dart';
import 'package:shared_core/shared_core.dart';

/// Pins loading / data / error apart for platform settings, and guards the
/// write path: saving must surface a visible failure (not a silent "saved")
/// when the RPC rejects, since this page's values gate real platform-wide
/// behavior (MFA enforcement flag, maintenance mode).

PlatformSettings _settings({
  double mq2Threshold = 2.2,
  double pm25Threshold = 35,
  double temperatureThreshold = 45,
  int offlineMinutes = 5,
  String mqttHost = '192.168.1.180',
  int mqttPort = 1883,
  bool lineNotify = true,
  bool emailNotify = true,
  bool pushNotify = true,
  bool automaticBackup = true,
  bool maintenanceMode = false,
  bool twoFactorRequired = true,
  bool auditLogEnabled = true,
  String language = 'ภาษาไทย',
  String timezone = 'Asia/Bangkok (UTC+7)',
  int logRetentionDays = 365,
  String backupTime = '02:00 น.',
}) => PlatformSettings(
  mq2Threshold: mq2Threshold,
  pm25Threshold: pm25Threshold,
  temperatureThreshold: temperatureThreshold,
  offlineMinutes: offlineMinutes,
  mqttHost: mqttHost,
  mqttPort: mqttPort,
  lineNotify: lineNotify,
  emailNotify: emailNotify,
  pushNotify: pushNotify,
  automaticBackup: automaticBackup,
  maintenanceMode: maintenanceMode,
  twoFactorRequired: twoFactorRequired,
  auditLogEnabled: auditLogEnabled,
  language: language,
  timezone: timezone,
  logRetentionDays: logRetentionDays,
  backupTime: backupTime,
  updatedAt: DateTime(2026, 9, 1),
);

Future<void> _pump(
  WidgetTester tester, {
  Future<PlatformSettings> Function()? loadSettings,
  Future<List<SchoolAdminAuditLog>> Function()? loadAuditLogs,
  Future<PlatformSettings> Function({
    double? mq2Threshold,
    double? pm25Threshold,
    double? temperatureThreshold,
    int? offlineMinutes,
    String? mqttHost,
    int? mqttPort,
    bool? lineNotify,
    bool? emailNotify,
    bool? pushNotify,
    bool? automaticBackup,
    bool? maintenanceMode,
    bool? twoFactorRequired,
    bool? auditLogEnabled,
    String? language,
    String? timezone,
    int? logRetentionDays,
    String? backupTime,
  })?
  saveSettings,
}) async {
  tester.view.physicalSize = const Size(1200, 3600);
  tester.view.devicePixelRatio = 1;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    MaterialApp(
      home: SuperAdminSettingsPage(
        loadSettings: loadSettings ?? () async => _settings(),
        loadAuditLogs: loadAuditLogs ?? () async => <SchoolAdminAuditLog>[],
        saveSettings: saveSettings,
      ),
    ),
  );
}

void main() {
  testWidgets(
    'only the enforced setting is offered; the 16 unenforced ones are gone',
    (tester) async {
      await _pump(
        tester,
        loadSettings: () async =>
            _settings(offlineMinutes: 12, mqttHost: '10.0.0.5'),
      );
      await tester.pumpAndSettle();

      expect(find.text('12'), findsOneWidget);
      expect(
        find.textContaining('ค่าที่บันทึกในระบบตอนนี้: 12 นาที'),
        findsOneWidget,
      );
      // Sensor thresholds / MQTT / alert channels / security policy / backup —
      // saved "for reference", read by nothing. Not shown any more.
      expect(find.text('10.0.0.5'), findsNothing);
      expect(find.textContaining('MQTT'), findsNothing);
      expect(find.textContaining('Sensor Thresholds'), findsNothing);
      expect(find.textContaining('Alert Channels'), findsNothing);
      expect(find.textContaining('Security & Policy'), findsNothing);
      expect(find.textContaining('System & Maintenance'), findsNothing);
      expect(find.textContaining('ยังไม่มีการบังคับใช้'), findsNothing);
      expect(find.byType(Switch), findsNothing);
    },
  );

  testWidgets('a failed settings load falls back to defaults, visibly', (
    tester,
  ) async {
    await _pump(
      tester,
      loadSettings: () async => throw StateError('backend detail'),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('โหลดค่าที่บันทึกไว้ไม่สำเร็จ'), findsOneWidget);
  });

  testWidgets('no audit logs says so, not an error', (tester) async {
    await _pump(tester);
    await tester.pumpAndSettle();

    expect(find.text('ยังไม่มีประวัติการแก้ไข'), findsOneWidget);
  });

  testWidgets('audit logs are rendered when present', (tester) async {
    await _pump(
      tester,
      loadAuditLogs: () async => [
        SchoolAdminAuditLog(
          id: 1,
          action: 'แก้ไขค่าตั้งค่าระบบ',
          target: 'platform_settings',
          detail: 'เปลี่ยนเกณฑ์ PM2.5',
          actorName: 'ผู้ดูแลระบบ',
          actorRole: 'super_admin',
          createdAt: DateTime(2026, 9, 1, 10, 30),
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(find.text('แก้ไขค่าตั้งค่าระบบ'), findsOneWidget);
  });

  testWidgets('save shows an error instead of a false "saved" on failure', (
    tester,
  ) async {
    var calls = 0;
    await _pump(
      tester,
      saveSettings:
          ({
            mq2Threshold,
            pm25Threshold,
            temperatureThreshold,
            offlineMinutes,
            mqttHost,
            mqttPort,
            lineNotify,
            emailNotify,
            pushNotify,
            automaticBackup,
            maintenanceMode,
            twoFactorRequired,
            auditLogEnabled,
            language,
            timezone,
            logRetentionDays,
            backupTime,
          }) async {
            calls++;
            throw StateError('rpc rejected');
          },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('บันทึกการตั้งค่า'));
    await tester.pumpAndSettle();

    expect(calls, 1);
    expect(find.textContaining('บันทึกไม่สำเร็จ'), findsOneWidget);
    expect(find.textContaining('rpc rejected'), findsNothing);
  });

  testWidgets(
    'save sends the typed minutes and trusts only the row the backend returns',
    (tester) async {
      int? sent;
      await _pump(
        tester,
        saveSettings:
            ({
              mq2Threshold,
              pm25Threshold,
              temperatureThreshold,
              offlineMinutes,
              mqttHost,
              mqttPort,
              lineNotify,
              emailNotify,
              pushNotify,
              automaticBackup,
              maintenanceMode,
              twoFactorRequired,
              auditLogEnabled,
              language,
              timezone,
              logRetentionDays,
              backupTime,
            }) async {
              sent = offlineMinutes;
              return _settings(offlineMinutes: 5); // backend did not change
            },
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '20');
      await tester.tap(find.text('บันทึกการตั้งค่า'));
      await tester.pumpAndSettle();

      expect(sent, 20);
      expect(find.textContaining('ค่าในระบบยังเป็น 5 นาที'), findsOneWidget);
      expect(find.textContaining('บันทึกแล้ว —'), findsNothing);
    },
  );

  testWidgets('save shows a confirmation once the RPC resolves', (
    tester,
  ) async {
    await _pump(
      tester,
      saveSettings:
          ({
            mq2Threshold,
            pm25Threshold,
            temperatureThreshold,
            offlineMinutes,
            mqttHost,
            mqttPort,
            lineNotify,
            emailNotify,
            pushNotify,
            automaticBackup,
            maintenanceMode,
            twoFactorRequired,
            auditLogEnabled,
            language,
            timezone,
            logRetentionDays,
            backupTime,
          }) async => _settings(offlineMinutes: offlineMinutes ?? 5),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '20');
    await tester.tap(find.text('บันทึกการตั้งค่า'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('บันทึกแล้ว — อุปกรณ์ที่เงียบเกิน 20 นาที'),
      findsOneWidget,
    );
  });

  /// เดิม `catch (_)` แค่ปิดสถานะโหลด — "อ่าน audit log ไม่ได้" จึงอ่านเหมือน
  /// "ยังไม่มีใครแก้ไขค่าอะไรเลย" บนหน้าตั้งค่าระดับแพลตฟอร์ม
  testWidgets(
    'ประวัติการแก้ไขโหลดพัง ต้องบอกตรง ๆ ไม่ใช่ "ยังไม่มีประวัติการแก้ไข"',
    (tester) async {
      await _pump(
        tester,
        loadAuditLogs: () async => throw Exception('logs_unreachable'),
      );
      await tester.pumpAndSettle();

      expect(find.text('โหลดประวัติการแก้ไขไม่สำเร็จ'), findsOneWidget);
      expect(find.text('ยังไม่มีประวัติการแก้ไข'), findsNothing);
      expect(find.textContaining('logs_unreachable'), findsNothing);
    },
  );
}
