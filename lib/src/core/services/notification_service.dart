import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin = 
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    tz.initializeTimeZones();
    
    // Set local timezone - use 'UTC' as fallback to avoid invalid timezone names
    try {
      final String timeZoneName = DateTime.now().timeZoneName;
      // Only use timezone name if it's a valid IANA name (contains /)
      if (timeZoneName.contains('/')) {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } else {
        // Common timezone name mappings
        final Map<String, String> tzMapping = {
          'IST': 'Asia/Kolkata',
          'PST': 'America/Los_Angeles',
          'EST': 'America/New_York',
          'CST': 'America/Chicago',
          'MST': 'America/Denver',
          'GMT': 'Europe/London',
          'BST': 'Europe/London',
          'JST': 'Asia/Tokyo',
          'CST_CHINA': 'Asia/Shanghai',
        };
        
        if (tzMapping.containsKey(timeZoneName)) {
          tz.setLocalLocation(tz.getLocation(tzMapping[timeZoneName]!));
        } else {
          // Default to UTC
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }
    } catch (e) {
      // Fallback to UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Create notification channel for Android (required for Android 8.0+)
    if (Platform.isAndroid) {
      await _createNotificationChannel();
    }

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');
  }

  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'habit_reminders',
      'Habit Reminders',
      description: 'Reminders for your daily habits',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<bool> requestPermissions() async {
    debugPrint('NotificationService: Requesting permissions...');
    
    // Request notification permission
    final notificationStatus = await Permission.notification.request();
    debugPrint('NotificationService: Notification permission status: $notificationStatus');
    
    if (Platform.isAndroid) {
      // For Android 12+ (API 31+), request exact alarm permission
      if (await _isAndroid12OrHigher()) {
        final alarmStatus = await Permission.scheduleExactAlarm.request();
        debugPrint('NotificationService: Exact alarm permission status: $alarmStatus');
      }
    }
    
    return notificationStatus.isGranted;
  }

  Future<bool> _isAndroid12OrHigher() async {
    if (!Platform.isAndroid) return false;
    // Check Android version using Platform
    try {
      final version = Platform.operatingSystemVersion;
      // Parse version string to check if API level >= 31
      // For now, request permission on all Android devices to be safe
      return true;
    } catch (e) {
      return true;
    }
  }

  Future<void> showTestNotification() async {
    await initialize();
    await showImmediateNotification(
      title: 'Test Notification',
      body: 'If you see this, notifications are working!',
    );
  }

  Future<bool> checkPermissions() async {
    final notificationStatus = await Permission.notification.status;
    debugPrint('NotificationService: Notification permission: $notificationStatus');
    return notificationStatus.isGranted;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    List<bool>? repeatDays,
  }) async {
    await initialize();
    
    debugPrint('NotificationService: Scheduling notification #$id');
    debugPrint('NotificationService: Title: $title');
    debugPrint('NotificationService: Scheduled for: $scheduledDate');
    debugPrint('NotificationService: Repeat days: $repeatDays');
    
    // Check permissions first
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      debugPrint('NotificationService: No permission granted, requesting...');
      final granted = await requestPermissions();
      if (!granted) {
        debugPrint('NotificationService: Permission denied, cannot schedule');
        throw Exception('Notification permission not granted');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Reminders for your daily habits',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
      enableLights: true,
      styleInformation: const DefaultStyleInformation(true, true),
      category: AndroidNotificationCategory.reminder,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.active,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final now = DateTime.now();

    // If repeatDays is provided and has any true values, schedule separate notifications for each day
    if (repeatDays != null && repeatDays.contains(true)) {
      for (int i = 0; i < 7; i++) {
        if (repeatDays[i]) {
          // Calculate next occurrence of this day of week
          var targetDate = _getNextDayOfWeek(scheduledDate, i);
          
          // If the calculated date is in the past, add a week
          if (targetDate.isBefore(now)) {
            targetDate = targetDate.add(const Duration(days: 7));
          }
          
          final notificationId = id + i; // Unique ID for each day's notification
          
          final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
            targetDate,
            tz.local,
          );

          try {
            await _notificationsPlugin.zonedSchedule(
              notificationId,
              title,
              body,
              scheduledTZDate,
              notificationDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );
            debugPrint('NotificationService: Scheduled notification #$notificationId for day index $i');
          } catch (e) {
            debugPrint('NotificationService: Error scheduling notification for day index $i: $e');
          }
        }
      }
      debugPrint('NotificationService: Successfully scheduled all repeat notifications for habit');
    } else {
      // Single notification (no repeat)
      var targetDate = scheduledDate;
      if (targetDate.isBefore(now)) {
        targetDate = targetDate.add(const Duration(days: 1));
        debugPrint('NotificationService: Adjusted to tomorrow: $targetDate');
      }

      final tz.TZDateTime scheduledTZDate = tz.TZDateTime.from(
        targetDate,
        tz.local,
      );

      try {
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledTZDate,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('NotificationService: Successfully scheduled notification #$id');
      } catch (e) {
        debugPrint('NotificationService: Error scheduling notification: $e');
        rethrow;
      }
    }
  }

  DateTime _getNextDayOfWeek(DateTime date, int dayIndex) {
    // dayIndex: 0 = Monday, 6 = Sunday
    // DateTime.weekday: 1 = Monday, 7 = Sunday
    final currentWeekday = date.weekday;
    final targetWeekday = dayIndex + 1; // Convert 0-6 to 1-7
    
    int daysToAdd = targetWeekday - currentWeekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7; // Move to next week
    }
    
    return DateTime(
      date.year,
      date.month,
      date.day,
      date.hour,
      date.minute,
    ).add(Duration(days: daysToAdd));
  }

  Future<void> cancelNotification(int id) async {
    debugPrint('NotificationService: Cancelling notification #$id');
    try {
      // Cancel the base notification and all 7 possible day-specific notifications
      await _notificationsPlugin.cancel(id);
      for (int i = 0; i < 7; i++) {
        await _notificationsPlugin.cancel(id + i);
      }
    } catch (e) {
      debugPrint('NotificationService: Error cancelling notification: $e');
    }
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('NotificationService: Cancelling all notifications');
    try {
      await _notificationsPlugin.cancelAll();
    } catch (e) {
      debugPrint('NotificationService: Error cancelling all notifications: $e');
    }
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await initialize();
    
    // Check permissions first
    final hasPermission = await checkPermissions();
    if (!hasPermission) {
      final granted = await requestPermissions();
      if (!granted) {
        throw Exception('Notification permission not granted');
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'habit_reminders',
      'Habit Reminders',
      channelDescription: 'Reminders for your daily habits',
      importance: Importance.max,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    final iosDetails = const DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('NotificationService: Error getting pending notifications: $e');
      return [];
    }
  }
}
