import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'auth_provider.dart';
import 'api_config.dart';

// FCM Manager Provider
final fcmManagerProvider = Provider<FcmManager>((ref) {
  return FcmManager(ref);
});

class FcmManager {
  final Ref ref;
  bool _initialized = false;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'quickslot_channel', // id
    'QuickSlot Notifications', // name
    description: 'This channel is used for QuickSlot booking notifications.', // description
    importance: Importance.high,
  );

  FcmManager(this.ref);

  Future<void> init(BuildContext context) async {
    if (_initialized) return;

    // Guard against uninitialized Firebase app to prevent core/no-app crashes
    if (Firebase.apps.isEmpty) {
      debugPrint('FCM: Firebase has not been initialized. Skipping push alerts.');
      return;
    }

    _initialized = true;

    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permission from Firebase Messaging
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      // Request notification permission from local notifications (Android 13+)
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await _localNotificationsPlugin.initialize(settings: initializationSettings);

      // Create Android Notification Channel
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('FCM: User granted notification permission');
        
        // 2. Fetch active FCM registration token
        await uploadToken();

        // 3. Handle token refreshes dynamically
        messaging.onTokenRefresh.listen((newToken) async {
          debugPrint('FCM: Token refreshed: $newToken');
          await _registerTokenOnBackend(newToken);
        });
      } else {
        debugPrint('FCM: User denied notification permission');
      }

      // 4. Listen to foreground notification alerts
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM: Received a foreground message: ${message.notification?.title}');
        if (message.notification != null && context.mounted) {
          _showLocalNotification(message.notification!);
          _showInAppNotificationDialog(context, message.notification!);
        }
      });

      // 5. Handle user tapping notifications to open the app
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM: User tapped notification to open app: ${message.notification?.title}');
      });
    } catch (e) {
      debugPrint('FCM: Error during initialization: $e');
    }
  }

  // Upload the current active FCM token to our REST API
  Future<void> uploadToken() async {
    if (Firebase.apps.isEmpty) return;

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM: Active Registration Token: $token');
        await _registerTokenOnBackend(token);
      }
    } catch (e) {
      debugPrint('FCM: Error getting token: $e');
    }
  }

  // Upload token REST helper
  Future<void> _registerTokenOnBackend(String fcmToken) async {
    final sessionToken = ref.read(authSessionTokenProvider);
    if (sessionToken == null) {
      debugPrint('FCM: Cannot upload token, user not authenticated');
      return;
    }

    final url = Uri.parse('$baseUrl/users/fcm-token');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
        body: jsonEncode({
          'token': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM: Token successfully registered on backend');
      } else {
        debugPrint('FCM: Failed to register token on backend: ${response.statusCode} | ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM: Network error registering token: $e');
    }
  }

  // Delete token from backend REST endpoint on logout
  Future<void> deleteToken() async {
    // Reset initialized flag so that subsequent login flows can initialize FCM again
    _initialized = false;

    final sessionToken = ref.read(authSessionTokenProvider);
    if (sessionToken == null) {
      debugPrint('FCM: Cannot delete token, user not authenticated');
      return;
    }

    final url = Uri.parse('$baseUrl/users/fcm-token');
    try {
      final response = await http.delete(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $sessionToken',
        },
      );

      if (response.statusCode == 200) {
        debugPrint('FCM: Token successfully deleted from backend');
      } else {
        debugPrint('FCM: Failed to delete token from backend: ${response.statusCode} | ${response.body}');
      }
    } catch (e) {
      debugPrint('FCM: Network error deleting token: $e');
    }
  }

  // Render a beautiful modern custom Dialog for foreground push alerts
  void _showInAppNotificationDialog(BuildContext context, RemoteNotification notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        icon: const Icon(
          Icons.notifications_active,
          color: Color(0xFF00FF87),
          size: 40,
        ),
        title: Text(
          notification.title ?? 'Alert',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          notification.body ?? '',
          style: const TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00FF87),
              foregroundColor: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Great!'),
          ),
        ],
      ),
    );
  }

  // Show a standard system tray banner notification when the app is in the foreground
  Future<void> _showLocalNotification(RemoteNotification notification) async {
    final androidNotificationDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: notificationDetails,
    );
  }

  // Public helper to show a custom local notification from client code (e.g. after booking response)
  Future<void> showLocalNotification({required String title, required String body}) async {
    final androidNotificationDetails = AndroidNotificationDetails(
      _channel.id,
      _channel.name,
      channelDescription: _channel.description,
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    final notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
    );

    await _localNotificationsPlugin.show(
      id: title.hashCode ^ body.hashCode,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
    );
  }
}
