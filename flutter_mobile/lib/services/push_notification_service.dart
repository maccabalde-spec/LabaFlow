import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Supabase-backed in-app notifications. Mobile OS push delivery needs a
/// separate push provider; Firebase is reserved for static web hosting.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  SupabaseClient get _client => Supabase.instance.client;

  Future<void> initializeForUser(AppUser user) async {}
  Future<void> stopListening() async {}
  Future<void> removeCurrentDevice(AppUser user) async {}

  Stream<List<Notif>> watchNotifications(AppUser user) => _client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('user_id', user.authUid)
      .order('created_at', ascending: false)
      .map((rows) => rows.map((row) => _fromRow(row, user.id)).toList());

  Future<void> markRead(AppUser user, Notif notification) async {
    if (notification.docId.isEmpty) return;
    await _client.from('notifications').update({'read': true})
        .eq('id', notification.docId).eq('user_id', user.authUid);
  }

  Future<void> markAllRead(AppUser user) async {
    await _client.from('notifications').update({'read': true})
        .eq('user_id', user.authUid).eq('read', false);
  }

  Future<void> notifyUser({
    required String recipientUid,
    required String type,
    required String title,
    required String body,
    String icon = '🔔',
  }) async {
    await _client.functions.invoke('send-notification', body: {
      'recipientUid': recipientUid,
      'type': type,
      'title': title,
      'body': body,
      'icon': icon,
    });
  }

  Notif _fromRow(Map<String, dynamic> row, int userId) => Notif(
    id: row['id'].toString().hashCode,
    docId: row['id'].toString(),
    toId: userId,
    type: row['type'] as String? ?? 'GENERAL',
    title: row['title'] as String? ?? '',
    msg: row['body'] as String? ?? '',
    icon: row['icon'] as String? ?? '🔔',
    read: row['read'] == true,
    date: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
  );
}
