import 'package:flutter/foundation.dart';

enum StaffEmergencySource { incident, hardware }
enum StaffEmergencyResult { confirmed, failed, unconfirmed, busy }

/// One guarded write followed by a fresh read of the same source and ID.
/// An unconfirmed write is deliberately distinct from a rejected write.
class StaffEmergencyActions extends ChangeNotifier {
  StaffEmergencyActions({
    required this.acknowledgeIncident,
    required this.acknowledgeHardware,
    required this.escalateIncident,
    required this.closeIncident,
    required this.closeHardware,
    required this.readStatus,
  });

  final Future<void> Function(String id) acknowledgeIncident;
  final Future<void> Function(String id) acknowledgeHardware;
  final Future<void> Function(String id) escalateIncident;
  final Future<void> Function(String id, String note, String resolutionType)
      closeIncident;
  final Future<void> Function(String id, String note) closeHardware;
  final Future<String?> Function(StaffEmergencySource source, String id) readStatus;
  final Set<String> _pending = {};
  bool _disposed = false;

  bool get isBusy => _pending.isNotEmpty;

  Future<StaffEmergencyResult> acknowledge(StaffEmergencySource source, String id) =>
      _run(source, id, () => source == StaffEmergencySource.incident
          ? acknowledgeIncident(id) : acknowledgeHardware(id),
          const {'acknowledged', 'in_progress'});

  /// Escalation only applies to `incident_reports` rows — a hardware
  /// `emergency_events` row is already the escalated form, there is nothing
  /// further to escalate it to.
  Future<StaffEmergencyResult> escalate(String id) => _run(
      StaffEmergencySource.incident, id, () => escalateIncident(id),
      const {'escalated'});

  Future<StaffEmergencyResult> close(
      StaffEmergencySource source, String id, String note,
      {String resolutionType = 'resolved'}) {
    if (note.trim().isEmpty) return Future.value(StaffEmergencyResult.failed);
    return _run(source, id,
        () => source == StaffEmergencySource.incident
            ? closeIncident(id, note.trim(), resolutionType)
            : closeHardware(id, note.trim()),
        source == StaffEmergencySource.incident
            ? {resolutionType} : const {'closed'});
  }

  Future<StaffEmergencyResult> _run(StaffEmergencySource source, String id,
      Future<void> Function() write, Set<String> expected) async {
    if (_disposed || id.trim().isEmpty) return StaffEmergencyResult.failed;
    final key = '${source.name}:$id';
    if (!_pending.add(key)) return StaffEmergencyResult.busy;
    notifyListeners();
    try {
      try {
        await write();
      } catch (_) {
        return StaffEmergencyResult.failed;
      }
      try {
        final status = await readStatus(source, id);
        return expected.contains(status)
            ? StaffEmergencyResult.confirmed : StaffEmergencyResult.unconfirmed;
      } catch (_) {
        return StaffEmergencyResult.unconfirmed;
      }
    } finally {
      _pending.remove(key);
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

