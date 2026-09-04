import 'package:flutter_test/flutter_test.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_alerts_controller.dart';
import 'package:my_first_app/pages/school_admin/controllers/school_admin_async_state.dart';
import 'package:shared_core/shared_core.dart';

void main() {
  test(
    'acknowledge persists through backend and exposes refetched canonical alert',
    () async {
      var backendAlerts = <SchoolSensorAlertRecord>[_alert(status: 'new')];
      final acknowledgedIds = <String>[];
      var loadCount = 0;

      final controller = SchoolAdminAlertsController(
        loadAlerts: () async {
          loadCount += 1;
          return List<SchoolSensorAlertRecord>.unmodifiable(backendAlerts);
        },
        acknowledgeAlert: (alertId) async {
          acknowledgedIds.add(alertId);
          backendAlerts = <SchoolSensorAlertRecord>[
            _alert(status: 'acknowledged'),
          ];
        },
        resolveAlert: (alertId, {note}) async {},
      );

      await controller.load();
      final succeeded = await controller.acknowledge('alert-1');

      expect(succeeded, isTrue);
      expect(acknowledgedIds, const <String>['alert-1']);
      expect(loadCount, 2);
      expect(
        controller.state,
        isA<SchoolAdminData<List<SchoolSensorAlertRecord>>>(),
      );
      final data =
          controller.state as SchoolAdminData<List<SchoolSensorAlertRecord>>;
      expect(data.value.single.status, 'acknowledged');
    },
  );
  test(
    'acknowledge fails when refetched backend status is unchanged',
    () async {
      final backendAlerts = <SchoolSensorAlertRecord>[_alert(status: 'new')];

      final controller = SchoolAdminAlertsController(
        loadAlerts: () async =>
            List<SchoolSensorAlertRecord>.unmodifiable(backendAlerts),
        acknowledgeAlert: (alertId) async {},
        resolveAlert: (alertId, {note}) async {},
      );

      await controller.load();
      final succeeded = await controller.acknowledge('alert-1');

      expect(succeeded, isFalse);
      expect(
        controller.state,
        isA<SchoolAdminError<List<SchoolSensorAlertRecord>>>(),
      );
      final error =
          controller.state as SchoolAdminError<List<SchoolSensorAlertRecord>>;
      expect(error.previousData?.single.status, 'new');
      expect(controller.busyAlertIds, isEmpty);
    },
  );
}

SchoolSensorAlertRecord _alert({required String status}) {
  return SchoolSensorAlertRecord(
    id: 'alert-1',
    deviceId: 'device-1',
    deviceName: 'Air Sensor 1',
    deviceCode: 'AIR-001',
    schoolId: 'school-1',
    metric: 'pm25',
    value: 42,
    triggeredAt: DateTime.utc(2026, 9, 4, 8),
    status: status,
  );
}
