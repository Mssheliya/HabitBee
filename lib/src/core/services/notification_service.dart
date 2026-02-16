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
    
    // Set local timezone
    final String timeZoneName = DateTime.now().timeZoneName;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

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

    _isInitialized = true;
    debugPrint('NotificationService: Initialized successfully');
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

    // Ensure the date is in the future
    var targetDate = scheduledDate;
    final now = DateTime.now();
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
        matchDateTimeComponents: repeatDays != null && repeatDays.contains(true)
            ? DateTimeComponents.dayOfWeekAndTime
            : null,
      );
      debugPrint('NotificationService: Successfully scheduled notification #$id');
    } catch (e) {
      debugPrint('NotificationService: Error scheduling notification: $e');
      rethrow;
    }
  }

  Future<void> cancelNotification(int id) async {
    debugPrint('NotificationService: Cancelling notification #$id');
    await _notificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    debugPrint('NotificationService: Cancelling all notifications');
    await _notificationsPlugin.cancelAll();
  }

  Future<void> showImmediateNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
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
    return await _notificationsPlugin.pendingNotificationRequests();
  }
}
