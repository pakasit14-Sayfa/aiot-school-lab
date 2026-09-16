import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

typedef SchoolAdminAlertsLoader =
    Future<List<SchoolSensorAlertRecord>> Function();
typedef SchoolAdminAlertAcknowledger = Future<void> Function(String alertId);
typedef SchoolAdminAlertResolver =
    Future<void> Function(String alertId, {String? note});

/// รับทราบทุกรายการที่ยังเป็น new — acknowledge_all_school_alerts คืนจำนวน
typedef SchoolAdminAlertsBulkAcknowledger = Future<int> Function();

final class SchoolAdminAlertsController extends ChangeNotifier {
  SchoolAdminAlertsController({
    required SchoolAdminAlertsLoader loadAlerts,
    required SchoolAdminAlertAcknowledger acknowledgeAlert,
    required SchoolAdminAlertResolver resolveAlert,
    SchoolAdminAlertsBulkAcknowledger? acknowledgeAllAlerts,
  }) : _loadAlerts = loadAlerts,
       _acknowledgeAlert = acknowledgeAlert,
       _resolveAlert = resolveAlert,
       _acknowledgeAllAlerts = acknowledgeAllAlerts;

  final SchoolAdminAlertsLoader _loadAlerts;
  final SchoolAdminAlertAcknowledger _acknowledgeAlert;
  final SchoolAdminAlertResolver _resolveAlert;
  final SchoolAdminAlertsBulkAcknowledger? _acknowledgeAllAlerts;

  bool _bulkBusy = false;
  bool get bulkBusy => _bulkBusy;

  /// รับทราบทั้งหมดได้เมื่อมีตัวรับทราบแบบกลุ่ม และมีรายการ new อยู่จริง
  bool get canAcknowledgeAll =>
      _acknowledgeAllAlerts != null &&
      !_bulkBusy &&
      (_lastConfirmedData ?? const []).any((a) => a.status == 'new');

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

  /// รับทราบทั้งหมด: เขียนทีเดียว แล้วอ่านรายการกลับ — สำเร็จก็ต่อเมื่อไม่เหลือ
  /// รายการสถานะ new (ไม่เชื่อตัวเลขที่ RPC คืนอย่างเดียว)
  Future<int?> acknowledgeAll() async {
    final bulk = _acknowledgeAllAlerts;
    if (_disposed || bulk == null || _bulkBusy) return null;
    final previousData = _lastConfirmedData;
    _bulkBusy = true;
    _notifySafely();
    try {
      final count = await bulk();
      final alerts = await _loadCanonicalAlerts();
      if (alerts.any((a) => a.status == 'new')) {
        throw StateError('backend_status_not_confirmed');
      }
      _publishCanonical(alerts);
      return count;
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError(
          message: 'รับทราบทั้งหมดไม่สำเร็จ',
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
      return null;
    } finally {
      _bulkBusy = false;
      _notifySafely();
    }
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
