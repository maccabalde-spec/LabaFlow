import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ═══════════════════════════════════════════════════════════
//  NOTIFICATION SERVICE
//  Handles Firebase Cloud Messaging (FCM) so push
//  notifications arrive even when the app is closed.
//
//  Architecture:
//   • Each user's device subscribes to FCM topic "user_{id}"
//   • Sellers/admins also subscribe to topic "orders"
//   • When app is OPEN → onMessage fires → flutter_local_notifications
//     shows a heads-up system notification
//   • When app is BACKGROUND/CLOSED → FCM delivers automatically
//     via the Android system notification tray
//   • Tap on notification → app opens → onMessageOpenedApp fires
//     → navigates to correct screen
//
//  To send a push from Firebase Console (for testing/demo):
//   1. Go to: https://console.firebase.google.com/project/labaflow-71e13/messaging
//   2. Click "Send your first message"
//   3. Enter title + body
//   4. Under "Target", choose "Topic" and enter "user_3" (for Juan)
//      or "orders" for all sellers/admins
//   5. Send — all subscribed devices receive it instantly
//
//  For production: use Cloud Functions Firestore trigger to
//  automatically send FCM when a Notif doc is created.
// ═══════════════════════════════════════════════════════════

/// Top-level handler — MUST be a top-level function (not a closure/method).
/// Called when FCM delivers a data-only message while app is terminated/background.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification payload messages are shown automatically by FCM on Android.
  // For data-only messages, show via flutter_local_notifications:
  final data = message.data;
  if (message.notification == null && data.isNotEmpty) {
    final title = data['title'] as String? ?? 'LabaFlow';
    final body  = data['body']  as String? ?? data['msg'] as String? ?? '';
    final plugin = FlutterLocalNotificationsPlugin();
    await plugin.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'labaflow_notif',
          'LabaFlow Notifications',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }
}

class NotificationService {
  NotificationService._();

  static final _messaging  = FirebaseMessaging.instance;
  static final _localNotif = FlutterLocalNotificationsPlugin();

  /// Android notification channel used for all LabaFlow notifications.
  static const _channel = AndroidNotificationChannel(
    'labaflow_notif',
    'LabaFlow Notifications',
    description: 'Order status updates and messages from LabaFlow',
    importance: Importance.high,
  );

  /// Initialize — called once from main() before runApp().
  static Future<void> init() async {
    // Register the background handler FIRST
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Create the high-importance Android notification channel
    if (Platform.isAndroid) {
      await _localNotif
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
    }

    // Initialize flutter_local_notifications
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _localNotif.initialize(initSettings);

    // Request permission (Android 13+ needs explicit permission)
    final settings = await _messaging.requestPermission(
      alert:       true,
      badge:       true,
      sound:       true,
      provisional: false,
    );
    final granted =
        settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!granted) return;

    // Tell FCM to always deliver to the notification tray even when
    // the app is in the foreground (Android default skips tray in fg)
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground messages — show as heads-up local notification
    FirebaseMessaging.onMessage.listen((msg) {
      final n = msg.notification;
      if (n != null) {
        _localNotif.show(
          n.hashCode,
          n.title,
          n.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority:   Priority.high,
              icon:        '@mipmap/ic_launcher',
              // Show as heads-up banner
              styleInformation: const BigTextStyleInformation(''),
            ),
          ),
        );
      }
    });
  }

  /// Get the FCM registration token for this device.
  /// Save this to Firestore so Cloud Functions can target this specific device.
  static Future<String?> getToken() => _messaging.getToken();

  /// Subscribe this device to a topic (e.g. 'user_3', 'orders').
  static Future<void> subscribeToTopic(String topic) =>
      _messaging.subscribeToTopic(topic);

  /// Unsubscribe this device from a topic.
  static Future<void> unsubscribeFromTopic(String topic) =>
      _messaging.unsubscribeFromTopic(topic);

  /// Show a local notification immediately (no FCM — for in-app events).
  static Future<void> showLocal({
    required String title,
    required String body,
    String? payload,
  }) async {
    await _localNotif.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority:   Priority.high,
          icon:        '@mipmap/ic_launcher',
        ),
      ),
      payload: payload,
    );
  }
}
