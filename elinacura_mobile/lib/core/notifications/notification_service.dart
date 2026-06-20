import 'dart:io' show Platform;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../api/api_client.dart';
import '../auth/auth_providers.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService(this._api);

  final ApiClient _api;
  final _local = FlutterLocalNotificationsPlugin();
  final _messaging = FirebaseMessaging.instance;

  static const _channels = {
    'medications': ('Medications', 'Medication reminders', Importance.high),
    'refills': ('Refills', 'Refill alerts', Importance.defaultImportance),
    'safety': ('Safety', 'Safety alerts', Importance.high),
    'appointments': ('Appointments', 'Appointment reminders', Importance.defaultImportance),
  };

  Future<void> initialize() async {
    if (kIsWeb) return;

    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    if (!kIsWeb && Platform.isAndroid) {
      for (final entry in _channels.entries) {
        await _local
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              AndroidNotificationChannel(
                entry.key,
                entry.value.$1,
                description: entry.value.$2,
                importance: entry.value.$3,
              ),
            );
      }
    }

    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _registerDevice(token);
      }
      _messaging.onTokenRefresh.listen(_registerDevice);
    } catch (e) {
      // iOS Simulator has no APNS token — push registration is optional in dev.
      debugPrint('FCM token unavailable (simulator?): $e');
    }
  }

  Future<void> _registerDevice(String token) async {
    try {
      await _api.post<Map<String, dynamic>>('/devices/register', data: {
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      });
    } catch (e) {
      debugPrint('Device registration failed: $e');
    }
  }

  Future<void> scheduleMedicationReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
  }) async {
    await _local.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime, tz.local),
      NotificationDetails(
        android: AndroidNotificationDetails(
          'medications',
          _channels['medications']!.$1,
          channelDescription: _channels['medications']!.$2,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(apiClientProvider));
});
