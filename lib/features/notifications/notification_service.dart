import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../core/router/app_router.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  static const String channelId = 'rent_reminders';
  static const String channelName = 'Rent Due Reminders';
  static const String channelDescription =
      'Daily alerts for rents due today and overdue balances';
  static const int reminderNotificationId = 1001;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initializes timezone data and notification plugin with Android channel.
  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Initialize time zones
    tz.initializeTimeZones();
    try {
      final tzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Karachi'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }

    // 2. Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
    );

    // 3. Initialize plugin with tap handler
    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // 4. Create channel on Android
    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.high,
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(channel);
    }

    _initialized = true;
  }

  /// Handles notification tap and navigates to the rent tab with the filter.
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      final context = rootNavigatorKey.currentContext;
      if (context != null && context.mounted) {
        context.go(payload);
      }
    }
  }

  /// Requests in-context notification permission on Android 13+ (API 33+).
  Future<bool> requestPermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      final granted = await androidPlugin.requestNotificationsPermission();
      return granted ?? false;
    }
    return true;
  }

  /// Calculates the next instance of 09:00 AM local time.
  tz.TZDateTime _nextInstanceOfNineAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 9, 0, 0);

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Schedules daily inexact reminder at 09:00 for rents due today and overdue.
  Future<void> scheduleDailyDueReminder({
    required int dueTodayCount,
    required int overdueCount,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    // If no rents are due or overdue, cancel any existing daily reminder
    if (dueTodayCount == 0 && overdueCount == 0) {
      await _plugin.cancel(id: reminderNotificationId);
      return;
    }

    final String title;
    final String body;
    final String payload;

    if (dueTodayCount > 0 && overdueCount > 0) {
      title = 'Rent Reminders: $dueTodayCount due, $overdueCount overdue';
      body = 'Tap to review balances and record payments.';
      payload = '/rent?filter=overdue';
    } else if (overdueCount > 0) {
      title = 'Rent Overdue: $overdueCount resident${overdueCount > 1 ? 's' : ''}';
      body = 'Tap to view overdue balances and send WhatsApp reminders.';
      payload = '/rent?filter=overdue';
    } else {
      title = 'Rent Due Today: $dueTodayCount resident${dueTodayCount > 1 ? 's' : ''}';
      body = 'Tap to review rents due today.';
      payload = '/rent?filter=pending';
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
    );

    final scheduledTime = _nextInstanceOfNineAM();

    await _plugin.zonedSchedule(
      id: reminderNotificationId,
      title: title,
      body: body,
      scheduledDate: scheduledTime,
      notificationDetails: notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: payload,
    );
  }

  /// Cancels all scheduled notifications (on account deletion or sign out).
  Future<void> cancelAllReminders() async {
    await _plugin.cancelAll();
  }
}
