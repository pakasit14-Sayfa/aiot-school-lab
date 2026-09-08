import 'package:flutter/foundation.dart';
import 'package:shared_core/models/meeting_model.dart';
import 'package:shared_core/services/meeting_service.dart';

class MeetingDetailController extends ChangeNotifier {
  MeetingDetailController(this.service, this.id);
  final MeetingService service;
  final String id;
  MeetingDetail? data;
  bool loading = true, busy = false, _disposed = false;
  String? error;
  int _generation = 0;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    if (busy) return;
    final generation = ++_generation;
    loading = true;
    error = null;
    _notify();
    try {
      final fresh = await service.detail(id);
      if (_disposed || generation != _generation) return;
      data = fresh;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error =
          'ไม่สามารถโหลดรายละเอียดประชุมได้ กรุณาตรวจสอบสิทธิ์และการเชื่อมต่อ';
      data = null;
    }
    loading = false;
    _notify();
  }

  Future<void> _change(Future<MeetingDetail> Function() operation) async {
    if (busy) throw StateError('meeting_busy');
    busy = true;
    _generation++;
    _notify();
    try {
      final fresh = await operation();
      if (!_disposed) {
        data = fresh;
        loading = false;
        error = null;
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  Future<void> attendance(List<String> users, List<String> guests) =>
      _change(() => service.takeAttendance(id, users, guests));
  Future<void> respond(String response, String? note) =>
      _change(() => service.respond(id, response, note: note));
  Future<void> cancel(String reason) =>
      _change(() => service.cancel(id, reason));
  Future<void> complete() => _change(() => service.complete(id));
  Future<void> agenda(
    String title,
    String detail,
    String? presenter,
    int order, {
    String? itemId,
  }) => _change(
    () => service.saveAgenda(
      id,
      title,
      detail: detail,
      presenterId: presenter,
      order: order,
      itemId: itemId,
    ),
  );
  Future<void> deleteAgenda(String itemId) =>
      _change(() => service.deleteAgenda(id, itemId));
  Future<void> minutes(String body) =>
      _change(() => service.saveMinutes(id, body));
  Future<void> finalize(String body) =>
      _change(() => service.finalizeMinutes(id, body));
  Future<void> addendum(String body) =>
      _change(() => service.addAddendum(id, body));
  Future<void> resolution(String body, String? assignee, String? dueDate) =>
      _change(
        () => service.addResolution(
          id,
          body,
          assigneeId: assignee,
          dueDate: dueDate,
        ),
      );
  Future<void> resolutionStatus(String resolutionId, String status) =>
      _change(() => service.setResolutionStatus(id, resolutionId, status));
  Future<void> guest(String name, String organization) =>
      _change(() => service.addGuest(id, name, organization: organization));
  Future<void> removeGuest(String guestId) =>
      _change(() => service.removeGuest(id, guestId));
  Future<void> attach(String name, Uint8List bytes) =>
      _change(() => service.attach(id, name, bytes));
  Future<Uri> download(String attachmentId) => service.download(attachmentId);
  Future<MeetingDetail> forDocument() => service.detail(id);
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
