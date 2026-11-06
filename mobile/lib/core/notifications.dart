import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final _fcm = FirebaseMessaging.instance;
  static final _supabase = Supabase.instance.client;

  static Future<void> initialize() async {
    // 1. Request Permission (Crucial for iOS/Android 13+)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted notification permissions.');

      // 2. Get the device token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _syncTokenToSupabase(token);
      }

      // 3. Listen for token refreshes
      _fcm.onTokenRefresh.listen(_syncTokenToSupabase);
    }
  }

  static Future<void> _syncTokenToSupabase(String fcmToken) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return; // Only sync if logged in

    try {
      await _supabase.from('notification_tokens').upsert({
        'user_id': user.id,
        'fcm_token': fcmToken,
        'device_platform': Platform.operatingSystem,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'fcm_token');
      print('FCM Token synced to database.');
    } catch (e) {
      print('Error syncing FCM token: $e');
    }
  }
}