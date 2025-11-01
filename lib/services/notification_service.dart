// lib/services/notification_service.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:rxdart/rxdart.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../main.dart'; // navigatorKey
import '../models/medicine.dart';
import '../screens/reminder_screen.dart';

class ReceivedNotification {
  final int id;
  final String? payload;
  ReceivedNotification({required this.id, required this.payload});
}

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // FIX: Declare subjects as static members inside the class
  static final BehaviorSubject<ReceivedNotification>
      didReceiveLocalNotificationSubject =
      BehaviorSubject<ReceivedNotification>();
  static final BehaviorSubject<String?> selectNotificationSubject =
      BehaviorSubject<String?>();

  // Android channel info
  static const String channelId = 'medicine_reminders_channel';
  static const String channelName = 'Medicine Reminders';

  /// Initialize notifications (call once from main before runApp)
  static Future<void> initializeNotifications() async {
    // Timezone setup
    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(await tz.local.name));
    } catch (_) {
      // fallback - often tz.local.name may not return as expected on some envs
      tz.setLocalLocation(tz.getLocation('Etc/UTC'));
    }

    // Android init
    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS/macOS init
    const DarwinInitializationSettings darwinInit =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
      macOS: darwinInit,
    );

    // Initialize plugin and set up response handler
    await _notificationsPlugin.initialize(initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
      // When notification is tapped (foreground/background)
      final payload = response.payload;
      if (payload != null) {
        onSelectNotification(payload);
      }
      selectNotificationSubject.add(response.payload);
    });

    // iOS permission (just in case)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// Handle navigation when a notification is tapped
  static void onSelectNotification(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      final medicine = Medicine.fromJson(data['medicine']);
      final alarmTime = data['alarmTime'];

      // Use the global navigatorKey defined in main.dart
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => ReminderScreen(
            medicine: medicine,
            alarmTime: alarmTime,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('Error decoding payload or navigating: $e\n$st');
    }
  }

  /// Schedule a repeating daily reminder at a given time (HH:mm in 24h)
  static Future<void> scheduleMedicineReminder({
    required int id,
    required Medicine medicine,
    required String time24h, // "08:00"
    required String alarmTime, // display label e.g. "8:00 AM"
  }) async {
    // Parse time
    final parts = time24h.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);

    // If time is already passed today, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // Payload to send with notification
    final payload = jsonEncode({
      'medicine': medicine.toJson(),
      'alarmTime': alarmTime,
    });

    // Android notification details (non-const to avoid const-related problems)
    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Reminders for medication intake.',
      importance: Importance.max,
      priority: Priority.high,
      // If you don't have a raw sound resource, remove the sound setting or use null
      sound: RawResourceAndroidNotificationSound('alarm'),
      ticker: 'ticker',
      fullScreenIntent: true,
      playSound: true,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    // Schedule using zonedSchedule (repeat daily at same time)
    await _notificationsPlugin.zonedSchedule(
      id,
      'Time for your medicine!',
      'Take ${medicine.dosage} of ${medicine.name}',
      scheduledDate,
      notificationDetails,
      // This param is required in recent versions: choose exactAllowWhileIdle for alarms
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Cancel all notifications (useful for testing / sign-out)
  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
