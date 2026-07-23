import '../models/notification_model.dart';
import 'auth_service.dart';
import 'supabase_config.dart';

class NotificationService {
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
