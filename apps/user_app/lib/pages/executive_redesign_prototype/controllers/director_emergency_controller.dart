import 'package:shared_core/shared_core.dart';

typedef EmergencyEventsLoader = Future<List<EmergencyEventItem>> Function();
typedef IncidentSummaryLoader = Future<List<IncidentSummaryItem>> Function();
typedef IncidentReportsLoader = Future<List<TeacherIncidentReport>> Function();
typedef IncidentReportCloser =
    Future<void> Function(
      String id, {
      required String resolutionType,
      required String resolutionNote,
    });
typedef EmergencyEventCloser =
    Future<void> Function({
      required String eventId,
      required String reviewNote,
    });

/// Owns the write/read/confirm state transition for the director emergency UI.
/// The page only renders the canonical lists exposed after a confirmed write.
final class DirectorEmergencyController {
  DirectorEmergencyController({
    IncidentReportsLoader? loadIncidentReports,
    EmergencyEventsLoader? loadEmergencyEvents,
    IncidentReportCloser? closeIncidentReport,
    EmergencyEventCloser? closeEmergencyEvent,
  }) : _loadIncidentReports =
           loadIncidentReports ?? IncidentService.listTeacherIncidentReports,
       _loadEmergencyEvents =
           loadEmergencyEvents ?? EmergencyService.listEmergencyEvents,
       _closeIncidentReport =
           closeIncidentReport ?? IncidentService.closeIncidentReport,
       _closeEmergencyEvent =
           closeEmergencyEvent ?? EmergencyService.closeEmergencyEvent;

  final IncidentReportsLoader _loadIncidentReports;
  final EmergencyEventsLoader _loadEmergencyEvents;
  final IncidentReportCloser _closeIncidentReport;
  final EmergencyEventCloser _closeEmergencyEvent;

  List<TeacherIncidentReport> incidentReports = const [];
  List<EmergencyEventItem> emergencyEvents = const [];

  void replaceCanonicalData({
    required List<TeacherIncidentReport> incidents,
    required List<EmergencyEventItem> events,
  }) {
    incidentReports = incidents;
    emergencyEvents = events;
  }

  Future<void> closeAndConfirm({
    TeacherIncidentReport? incident,
    EmergencyEventItem? emergencyEvent,
    required String resolutionNote,
  }) async {
    if (incident != null) {
      await _closeIncidentReport(
        incident.id,
        resolutionType: 'resolved',
        resolutionNote: resolutionNote,
      );
      final fresh = await _loadIncidentReports();
      final canonical = fresh
          .where((item) => item.id == incident.id)
          .firstOrNull;
      if (canonical == null ||
          (canonical.status != 'resolved' && canonical.status != 'cancelled')) {
        throw StateError('backend_close_not_confirmed');
      }
      incidentReports = fresh;
      return;
    }

    if (emergencyEvent != null) {
      await _closeEmergencyEvent(
        eventId: emergencyEvent.id,
        reviewNote: resolutionNote,
      );
      final fresh = await _loadEmergencyEvents();
      final canonical = fresh
          .where((item) => item.id == emergencyEvent.id)
          .firstOrNull;
      if (canonical == null || canonical.status != 'closed') {
        throw StateError('backend_close_not_confirmed');
      }
      emergencyEvents = fresh;
      return;
    }

    throw StateError('backend_close_target_missing');
  }

  bool get sosResolved =>
      activeSosIncident == null && activeEmergencyEvent == null;

  bool get sosAccepted {
    final incident = activeSosIncident;
    if (incident != null) {
      return incident.status == 'acknowledged' ||
          incident.status == 'in_progress';
    }
    return activeEmergencyEvent?.status == 'acknowledged';
  }

  TeacherIncidentReport? get activeSosIncident => incidentReports
      .where(
        (item) =>
            item.category == IncidentCategory.sos &&
            item.status != 'resolved' &&
            item.status != 'cancelled',
      )
      .firstOrNull;

  EmergencyEventItem? get activeEmergencyEvent =>
      emergencyEvents.where((item) => item.status != 'closed').firstOrNull;
}
