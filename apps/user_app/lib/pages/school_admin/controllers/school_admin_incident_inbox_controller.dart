import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

import 'school_admin_async_state.dart';

typedef SchoolAdminIncidentListLoader =
    Future<List<TeacherIncidentReport>> Function();
typedef SchoolAdminIncidentDetailLoader =
    Future<IncidentReportDetail> Function(String incidentId);
typedef SchoolAdminIncidentAcknowledger =
    Future<void> Function(String incidentId);
typedef SchoolAdminIncidentCloser =
    Future<void> Function({
      required String id,
      required String resolutionType,
      required String resolutionNote,
    });

final class SchoolAdminIncidentInboxController extends ChangeNotifier {
  SchoolAdminIncidentInboxController({
    required SchoolAdminIncidentListLoader loadIncidents,
    required SchoolAdminIncidentDetailLoader loadDetail,
    required SchoolAdminIncidentAcknowledger acknowledgeIncident,
    required SchoolAdminIncidentCloser closeIncident,
    List<TeacherIncidentReport>? initialIncidents,
  }) : _loadIncidents = loadIncidents,
       _loadDetail = loadDetail,
       _acknowledgeIncident = acknowledgeIncident,
       _closeIncident = closeIncident,
       _lastConfirmedData = initialIncidents == null
           ? null
           : List<TeacherIncidentReport>.unmodifiable(initialIncidents),
       _state = initialIncidents == null
           ? const SchoolAdminLoading<List<TeacherIncidentReport>>()
           : initialIncidents.isEmpty
           ? const SchoolAdminEmpty<List<TeacherIncidentReport>>()
           : SchoolAdminData<List<TeacherIncidentReport>>(
               List<TeacherIncidentReport>.unmodifiable(initialIncidents),
             );

  final SchoolAdminIncidentListLoader _loadIncidents;
  final SchoolAdminIncidentDetailLoader _loadDetail;
  final SchoolAdminIncidentAcknowledger _acknowledgeIncident;
  final SchoolAdminIncidentCloser _closeIncident;

  SchoolAdminAsyncState<List<TeacherIncidentReport>> _state;
  List<TeacherIncidentReport>? _lastConfirmedData;
  final Map<String, SchoolAdminAsyncState<IncidentReportDetail>> _detailStates =
      <String, SchoolAdminAsyncState<IncidentReportDetail>>{};
  final Set<String> _mutatingIncidentIds = <String>{};
  bool _disposed = false;

  SchoolAdminAsyncState<List<TeacherIncidentReport>> get state => _state;

  SchoolAdminAsyncState<IncidentReportDetail>? detailStateFor(
    String incidentId,
  ) => _detailStates[incidentId.trim()];

  bool isMutating(String incidentId) =>
      _mutatingIncidentIds.contains(incidentId.trim());

  Future<void> load() async {
    final previousData = _lastConfirmedData;
    _publish(SchoolAdminLoading(previousData: previousData));
    try {
      _publishCanonical(await _loadIncidents());
    } catch (error, stackTrace) {
      _publish(
        SchoolAdminError<List<TeacherIncidentReport>>(
          message: 'โหลดรายการเหตุการณ์ไม่สำเร็จ',
          error: error,
          stackTrace: stackTrace,
          previousData: previousData,
        ),
      );
    }
  }

  Future<void> loadDetail(String incidentId) async {
    final normalizedId = incidentId.trim();
    if (_disposed || normalizedId.isEmpty) return;
    final previousState = _detailStates[normalizedId];
    final previousData = switch (previousState) {
      SchoolAdminData<IncidentReportDetail>(value: final value) => value,
      SchoolAdminLoading<IncidentReportDetail>(previousData: final value) =>
        value,
      SchoolAdminError<IncidentReportDetail>(previousData: final value) =>
        value,
      _ => null,
    };
    _detailStates[normalizedId] = SchoolAdminLoading(
      previousData: previousData,
    );
    _notifySafely();
    try {
      final detail = await _loadDetail(normalizedId);
      if (_disposed) return;
      _detailStates[normalizedId] = SchoolAdminData(detail);
      notifyListeners();
    } catch (error, stackTrace) {
      if (_disposed) return;
      _detailStates[normalizedId] = SchoolAdminError<IncidentReportDetail>(
        message: 'โหลดรายละเอียดเหตุการณ์ไม่สำเร็จ',
        error: error,
        stackTrace: stackTrace,
        previousData: previousData,
      );
      notifyListeners();
    }
  }

  Future<bool> acknowledge(String incidentId) async {
    final normalizedId = incidentId.trim();
    if (!_beginMutation(normalizedId)) return false;
    final previousData = _lastConfirmedData;
    try {
      await _acknowledgeIncident(normalizedId);
      final canonical = await _loadCanonical();
      final confirmed = canonical.any(
        (incident) =>
            incident.id == normalizedId && incident.status == 'acknowledged',
      );
      if (!confirmed) throw StateError('backend_acknowledge_not_confirmed');
      _publishCanonical(canonical);
      return true;
    } catch (error, stackTrace) {
      _publishMutationError(
        message: 'รับเรื่องเหตุการณ์ไม่สำเร็จ',
        error: error,
        stackTrace: stackTrace,
        previousData: previousData,
      );
      return false;
    } finally {
      _finishMutation(normalizedId);
    }
  }

  Future<bool> close(
    String incidentId,
    String resolutionNote, {
    String resolutionType = 'resolved',
  }) async {
    final normalizedId = incidentId.trim();
    final normalizedNote = resolutionNote.trim();
    if (normalizedNote.isEmpty || !_beginMutation(normalizedId)) return false;
    final previousData = _lastConfirmedData;
    try {
      await _closeIncident(
        id: normalizedId,
        resolutionType: resolutionType,
        resolutionNote: normalizedNote,
      );
      final canonical = await _loadCanonical();
      final confirmed = canonical.any(
        (incident) =>
            incident.id == normalizedId &&
            incident.status == resolutionType,
      );
      if (!confirmed) throw StateError('backend_close_not_confirmed');
      _publishCanonical(canonical);
      return true;
    } catch (error, stackTrace) {
      _publishMutationError(
        message: 'ปิดเหตุการณ์ไม่สำเร็จ',
        error: error,
        stackTrace: stackTrace,
        previousData: previousData,
      );
      return false;
    } finally {
      _finishMutation(normalizedId);
    }
  }

  bool _beginMutation(String incidentId) {
    if (_disposed ||
        incidentId.isEmpty ||
        !_mutatingIncidentIds.add(incidentId)) {
      return false;
    }
    notifyListeners();
    return true;
  }

  void _finishMutation(String incidentId) {
    _mutatingIncidentIds.remove(incidentId);
    _notifySafely();
  }

  Future<List<TeacherIncidentReport>> _loadCanonical() async =>
      List<TeacherIncidentReport>.unmodifiable(await _loadIncidents());

  void _publishCanonical(List<TeacherIncidentReport> incidents) {
    if (_disposed) return;
    final canonical = List<TeacherIncidentReport>.unmodifiable(incidents);
    _lastConfirmedData = canonical;
    if (canonical.isEmpty) {
      _publish(const SchoolAdminEmpty<List<TeacherIncidentReport>>());
    } else {
      _publish(SchoolAdminData<List<TeacherIncidentReport>>(canonical));
    }
  }

  void _publishMutationError({
    required String message,
    required Object error,
    required StackTrace stackTrace,
    required List<TeacherIncidentReport>? previousData,
  }) {
    _publish(
      SchoolAdminError<List<TeacherIncidentReport>>(
        message: message,
        error: error,
        stackTrace: stackTrace,
        previousData: previousData,
      ),
    );
  }

  void _publish(SchoolAdminAsyncState<List<TeacherIncidentReport>> nextState) {
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
    super.dispose();
  }
}
