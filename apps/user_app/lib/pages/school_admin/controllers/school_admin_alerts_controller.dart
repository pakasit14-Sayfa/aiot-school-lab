import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

typedef SchoolAdminAlertsLoader =
    Future<List<SchoolSensorAlertRecord>> Function();
typedef SchoolAdminAlertAcknowledger = Future<void> Function(String alertId);
typedef SchoolAdminAlertResolver =
    Future<void> Function(String alertId, {String? note});

final class SchoolAdminAlertsController extends ChangeNotifier {
  SchoolAdminAlertsController({
    required SchoolAdminAlertsLoader loadAlerts,
    required SchoolAdminAlertAcknowledger acknowledgeAlert,
    required SchoolAdminAlertResolver resolveAlert,
  }) : _loadAlerts = loadAlerts,
       _acknowledgeAlert = acknowledgeAlert,
       _resolveAlert = resolveAlert;

  final SchoolAdminAlertsLoader _loadAlerts;
  final SchoolAdminAlertAcknowledger _acknowledgeAlert;
  final SchoolAdminAlertResolver _resolveAlert;

  SchoolAdminAsyncState<List<SchoolSensorAlertRecord>> _state =
      const SchoolAdminLoading<List<SchoolSensorAlertRecord>>();
  List<SchoolSensorAlertRecord>? _lastConfirmedData;
  final Set<String> _busyAlertIds = <String>{};
  bool _disposed = false;

  SchoolAdminAsyncState<List<SchoolSensorAlertRecord>> get state => _state;

  Set<String> get busyAlertIds => UnmodifiableSetView(_busyAlertIds);

  Future<void> load() async {
    final previousData = _lastConfirmedData;
    _publish(SchoolAdminLoading(previousData: previousData));

    try {
      final alerts = await _loadCanonicalAlerts();
      _publishCanonical(alerts);
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: 'โหลดข้อมูลการแจ้งเตือนไม่สำเร็จ',
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
    }
  }

  Future<bool> acknowledge(String alertId) {
    final normalizedId = alertId.trim();
    return _mutate(
      alertId: normalizedId,
      action: () => _acknowledgeAlert(normalizedId),
      confirmedStatuses: const <String>{'acknowledged', 'resolved'},
      failureMessage: 'รับทราบการแจ้งเตือนไม่สำเร็จ',
    );
  }

  Future<bool> resolve(String alertId, {String? note}) {
    final normalizedId = alertId.trim();
    return _mutate(
      alertId: normalizedId,
      action: () => _resolveAlert(normalizedId, note: note),
      confirmedStatuses: const <String>{'resolved'},
      failureMessage: 'แก้ไขการแจ้งเตือนไม่สำเร็จ',
    );
  }

  Future<bool> _mutate({
    required String alertId,
    required Future<void> Function() action,
    required Set<String> confirmedStatuses,
    required String failureMessage,
  }) async {
    final normalizedId = alertId.trim();
    if (_disposed ||
        normalizedId.isEmpty ||
        _busyAlertIds.contains(normalizedId)) {
      return false;
    }

    final previousData = _lastConfirmedData;
    _busyAlertIds.add(normalizedId);
    _notifySafely();

    try {
      await action();
      final alerts = await _loadCanonicalAlerts();
      final confirmed = alerts.any(
        (alert) =>
            alert.id == normalizedId &&
            confirmedStatuses.contains(alert.status),
      );
      if (!confirmed) {
        throw StateError('backend_status_not_confirmed');
      }

      _publishCanonical(alerts);
      return true;
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: failureMessage,
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
      return false;
    } finally {
      _busyAlertIds.remove(normalizedId);
      _notifySafely();
    }
  }

  Future<List<SchoolSensorAlertRecord>> _loadCanonicalAlerts() async {
    final alerts = await _loadAlerts();
    return List<SchoolSensorAlertRecord>.unmodifiable(alerts);
  }

  void _publishCanonical(List<SchoolSensorAlertRecord> alerts) {
    if (_disposed) return;
    _lastConfirmedData = alerts;
    if (alerts.isEmpty) {
      _publish(const SchoolAdminEmpty<List<SchoolSensorAlertRecord>>());
    } else {
      _publish(SchoolAdminData(alerts));
    }
  }

  void _publish(
    SchoolAdminAsyncState<List<SchoolSensorAlertRecord>> nextState,
  ) {
    if (_disposed) return;
    _state = nextState;
    notifyListeners();
  }

  void _notifySafely() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _busyAlertIds.clear();
    super.dispose();
  }
}
