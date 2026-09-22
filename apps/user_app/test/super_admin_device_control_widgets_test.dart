import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/super_admin/models/device_control_models.dart';
import 'package:my_first_app/pages/super_admin/widgets/device_control_sections.dart';

void main() {
  group('DeviceControlDeviceCard', () {
    DeviceItem buildDevice({
      bool online = true,
      bool isOn = false,
      bool autoMode = false,
      String commandStatus = 'idle',
    }) {
      return DeviceItem(
        databaseId: 'db-1',
        schoolId: 'school-1',
        id: 'DEV-001',
        name: 'ไฟแสงสว่าง โถงทางเดิน ชั้น 1',
        school: 'โรงเรียนทดสอบ',
        building: 'อาคาร 1',
        room: 'โถงทางเดิน',
        type: 'RLY',
        categoryCode: 'RLY',
        icon: Icons.electrical_services_rounded,
        online: online,
        isOn: isOn,
        autoMode: autoMode,
        reading: 'ค่าล่าสุด: -',
        updated: '4/9 10:00',
        commandStatus: commandStatus,
        metadata: const <String, dynamic>{},
      );
    }

    Future<void> pumpCard(
      WidgetTester tester, {
      required DeviceItem item,
      void Function(DeviceItem item)? onShowDetails,
      void Function(DeviceItem item, bool autoMode)? onChangeMode,
      void Function(DeviceItem item, bool value)? onToggle,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceControlDeviceCard(
              item: item,
              onShowDetails: onShowDetails ?? (_) {},
              onChangeMode: onChangeMode ?? (_, _) {},
              onToggle: onToggle ?? (_, _) {},
            ),
          ),
        ),
      );
    }

    testWidgets('tapping the power switch reports the device and new value', (
      tester,
    ) async {
      final DeviceItem device = buildDevice(isOn: false);
      DeviceItem? toggledItem;
      bool? toggledValue;

      await pumpCard(
        tester,
        item: device,
        onToggle: (item, value) {
          toggledItem = item;
          toggledValue = value;
        },
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(toggledItem, same(device));
      expect(toggledValue, isTrue);
    });

    testWidgets(
      'a command already pending disables the switch so it cannot be tapped again',
      (tester) async {
        final DeviceItem device = buildDevice(commandStatus: 'pending');
        bool toggled = false;

        await pumpCard(
          tester,
          item: device,
          onToggle: (_, _) => toggled = true,
        );

        final Switch switchWidget = tester.widget<Switch>(find.byType(Switch));
        expect(switchWidget.onChanged, isNull);

        await tester.tap(find.byType(Switch), warnIfMissed: false);
        await tester.pump();

        expect(toggled, isFalse);
      },
    );

    testWidgets('changing the mode dropdown reports auto mode correctly', (
      tester,
    ) async {
      final DeviceItem device = buildDevice(autoMode: false);
      DeviceItem? changedItem;
      bool? changedAuto;

      await pumpCard(
        tester,
        item: device,
        onChangeMode: (item, autoMode) {
          changedItem = item;
          changedAuto = autoMode;
        },
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('อัตโนมัติ').last);
      await tester.pumpAndSettle();

      expect(changedItem, same(device));
      expect(changedAuto, isTrue);
    });

    testWidgets('tapping the overflow icon opens the detail callback', (
      tester,
    ) async {
      final DeviceItem device = buildDevice();
      DeviceItem? detailsItem;

      await pumpCard(
        tester,
        item: device,
        onShowDetails: (item) => detailsItem = item,
      );

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pump();

      expect(detailsItem, same(device));
    });

    testWidgets('an offline device shows the offline badge and warning note', (
      tester,
    ) async {
      final DeviceItem device = buildDevice(online: false);

      await pumpCard(tester, item: device);

      expect(find.text('ออฟไลน์'), findsOneWidget);
      expect(find.textContaining('ยังส่งคำขอเปิด–ปิดได้'), findsOneWidget);
    });
  });

  group('DeviceControlApprovalTile', () {
    ApprovalItem buildApproval({String status = 'pending'}) {
      return ApprovalItem(
        databaseId: 'approval-1',
        schoolId: 'school-1',
        schoolName: 'โรงเรียนทดสอบ',
        scope: 'main',
        action: 'power_on',
        reason: 'ทดสอบ',
        targetCount: 1,
        status: status,
        requestedBy: 'user-1',
        requesterName: 'Super Admin',
        requestedAt: DateTime(2026, 9, 4, 10),
        expiresAt: DateTime(2026, 9, 5, 10),
        approverName: null,
        decisionNote: '',
      );
    }

    Future<void> pumpTile(
      WidgetTester tester, {
      required ApprovalItem item,
      required bool canDecide,
      void Function(ApprovalItem item)? onReject,
      void Function(ApprovalItem item)? onApprove,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeviceControlApprovalTile(
              item: item,
              canDecide: canDecide,
              onReject: onReject ?? (_) {},
              onApprove: onApprove ?? (_) {},
            ),
          ),
        ),
      );
    }

    testWidgets('tapping the approve button reports the exact request', (
      tester,
    ) async {
      final ApprovalItem approval = buildApproval();
      ApprovalItem? approvedItem;

      await pumpTile(
        tester,
        item: approval,
        canDecide: true,
        onApprove: (item) => approvedItem = item,
      );

      await tester.tap(find.text('ยืนยันด้วยรหัสผ่าน'));
      await tester.pump();

      expect(approvedItem, same(approval));
    });

    testWidgets('tapping the reject button reports the exact request', (
      tester,
    ) async {
      final ApprovalItem approval = buildApproval();
      ApprovalItem? rejectedItem;

      await pumpTile(
        tester,
        item: approval,
        canDecide: true,
        onReject: (item) => rejectedItem = item,
      );

      await tester.tap(find.text('ไม่อนุมัติ'));
      await tester.pump();

      expect(rejectedItem, same(approval));
    });

    testWidgets('canDecide false hides the approve/reject actions entirely', (
      tester,
    ) async {
      await pumpTile(tester, item: buildApproval(), canDecide: false);

      expect(find.text('ยืนยันด้วยรหัสผ่าน'), findsNothing);
      expect(find.text('ไม่อนุมัติ'), findsNothing);
    });

    testWidgets('an already-approved request shows the approved label', (
      tester,
    ) async {
      await pumpTile(
        tester,
        item: buildApproval(status: 'approved'),
        canDecide: false,
      );

      expect(find.text('อนุมัติแล้ว'), findsOneWidget);
    });
  });
}
