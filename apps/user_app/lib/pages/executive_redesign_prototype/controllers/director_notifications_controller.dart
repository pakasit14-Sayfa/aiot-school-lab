import 'package:flutter/foundation.dart';
import 'package:shared_core/models/notification_model.dart';
import 'package:shared_core/services/notification_service.dart';

class DirectorNotificationsController extends ChangeNotifier {
  DirectorNotificationsController(this.service);
  final NotificationService service;
  List<AppNotification> items = [];
  List<NotificationCategory> categories = [];
  String? category, error, actionError;
  bool loading = true, busy = false, _disposed = false;
  int _generation = 0;
  int get total => categories.fold(0, (n, c) => n + c.total);
  int get unread => categories.fold(0, (n, c) => n + c.unread);

  Future<void> load({String? filter}) async {
    if (busy) return;
    category = filter;
    final generation = ++_generation;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final result = await Future.wait([
        service.loadInbox(filter),
        service.loadCategories(),
      ]);
      if (_disposed || generation != _generation) return;
      items = result[0] as List<AppNotification>;
      categories = result[1] as List<NotificationCategory>;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error = 'โหลดการแจ้งเตือนไม่สำเร็จ กรุณาลองอีกครั้ง';
      items = [];
      categories = [];
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  Future<bool> markRead([String? id]) async {
    if (busy || loading) return false;
    busy = true;
    actionError = null;
    notifyListeners();
    bool confirmed = false;
    try {
      if (id == null) {
        await service.readAllAndVerify();
      } else {
        await service.readAndVerify(id);
      }
      confirmed = true;
    } catch (_) {
      actionError =
          'ยังยืนยันสถานะอ่านไม่ได้ กรุณาโหลดข้อมูลใหม่แล้วลองอีกครั้ง';
    }
    if (_disposed) return false;
    busy = false;
    await load(filter: category);
    return confirmed && error == null && !_disposed;
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
