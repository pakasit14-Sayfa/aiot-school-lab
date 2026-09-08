import 'package:flutter/foundation.dart';
import 'package:shared_core/models/notification_model.dart';
import 'package:shared_core/services/notification_service.dart';

class MeetingNoticesController extends ChangeNotifier {
  List<NotificationCategory> categories = [];
  List<AppNotification> notices = [];
  bool loading = true, _disposed = false;
  int _generation = 0;
  String? category, error;
  Future<void> load(String? filter) async {
    final generation = ++_generation;
    category = filter;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        NotificationService.listCategories(),
        NotificationService.listInCategory(filter),
      ]);
      if (_disposed || generation != _generation) return;
      categories = results[0] as List<NotificationCategory>;
      notices = results[1] as List<AppNotification>;
    } catch (_) {
      if (_disposed || generation != _generation) return;
      error = 'ไม่สามารถโหลดการแจ้งเตือนได้';
    }
    loading = false;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
