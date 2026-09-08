import '../models/notification_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class NotificationService {
  Future<AppNotification> readAndVerify(String id) async {
    await markNotificationRead(id);
    final row = await supabase.rpc(
      'get_my_notification',
      params: {'p_token': AuthService.sessionToken, 'p_notification_id': id},
    );
    if (row is! Map) throw StateError('notification_read_not_confirmed');
    final item = AppNotification.fromRow(Map<String, dynamic>.from(row));
    if (item.id != id || item.isUnread) {
      throw StateError('notification_read_not_confirmed');
    }
    return item;
  }

  Future<void> readAllAndVerify() async {
    await supabase.rpc(
      'mark_all_my_notifications_read',
      params: {'p_token': AuthService.sessionToken},
    );
    final categories = await listCategories();
    if (categories.any((c) => c.unread > 0)) {
      throw StateError('notification_read_not_confirmed');
    }
  }

  Future<List<AppNotification>> loadInbox(String? category) =>
      listInCategory(category);
  Future<List<NotificationCategory>> loadCategories() => listCategories();
  static Future<List<NotificationCategory>> listCategories() async {
    final rows =
        await supabase.rpc(
              'list_my_notification_categories',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;
    return rows
        .map(
          (r) =>
              NotificationCategory.fromRow(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  static Future<List<AppNotification>> listInCategory(String? category) async {
    final rows =
        await supabase.rpc(
              'list_my_notifications_in_category',
              params: {
                'p_token': AuthService.sessionToken,
                'p_category': category,
                'p_limit': 50,
              },
            )
            as List;
    return rows
        .map(
          (r) => AppNotification.fromRow(Map<String, dynamic>.from(r as Map)),
        )
        .toList();
  }

  static Future<List<AppNotification>> listMyNotifications() async {
    final rows =
        await supabase.rpc(
              'list_my_notifications',
              params: {'p_token': AuthService.sessionToken},
            )
            as List;

    return rows
        .map((row) => AppNotification.fromRow(row as Map<String, dynamic>))
        .toList();
  }

  static Future<void> markNotificationRead(String notificationId) async {
    await supabase.rpc(
      'mark_notification_read',
      params: {
        'p_token': AuthService.sessionToken,
        'p_notification_id': notificationId,
      },
    );
  }
}
