import 'package:flutter/foundation.dart';
import 'package:shared_core/models/staff_request_model.dart';
import 'package:shared_core/services/staff_request_service.dart';

class MeetingRequestsController extends ChangeNotifier {
  MeetingRequestsController({StaffRequestService? service})
    : service = service ?? StaffRequestService();
  final StaffRequestService service;
  List<StaffRequest> records = [];
  Set<String> actionable = {};
  bool loading = true, _disposed = false;
  String? error;
  int _generation = 0;
  bool reviewing = false;
  Future<void> load() async {
    if (reviewing || _disposed) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        service.list(),
        service.list(pendingForMe: true),
      ]);
      if (_disposed || generation != _generation) return;
      records = result[0].where((r) => r.isMeeting).toList();
      actionable = result[1].where((r) => r.isMeeting).map((r) => r.id).toSet();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error = 'ไม่สามารถโหลดคำขอได้';
      records = [];
      actionable = {};
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  Future<void> review(StaffRequest request, bool approve, String note) async {
    if (reviewing || _disposed) throw StateError('review_in_progress');
    ++_generation;
    reviewing = true;
    loading = false;
    notifyListeners();
    try {
      final fresh = await service.review(request, approve, note);
      if (_disposed) return;
      records = records.map((r) => r.id == fresh.id ? fresh : r).toList();
      actionable.remove(fresh.id);
      error = null;
    } finally {
      reviewing = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
