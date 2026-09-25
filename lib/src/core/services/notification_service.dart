import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
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

    // Set local timezone using the device's real IANA timezone (e.g. 'Asia/Kolkata').
    // DateTime.now().timeZoneName returns abbreviations like 'IST' or 'GMT+05:30'
    // on many devices, which caused notifications to fire at wrong times.
    try {
      final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
      tz.setLocalLocation(tz.getLocation(timeZoneName));
      debugPrint('NotificationService: Timezone set to $timeZoneName');
    } catch (e) {
      debugPrint('NotificationService: Could not detect timezone ($e), using UTC fallback');
      // Fallback: derive location from the device's UTC offset so notifications
      // still fire at the correct wall-clock time even if the zone is unknown.
      try {
        final offset = DateTime.now().timeZoneOffset;
        final etcName = _etcTimezoneForOffset(offset);
        tz.setLocalLocation(tz.getLocation(etcName));
        debugPrint('NotificationService: Fallback timezone set to $etcName');
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');

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

  /// Fallback helper: converts a UTC offset into a tz database location name.
  /// Etc/GMT zones have an inverted sign by convention (Etc/GMT-5 == UTC+5).
  /// For non-whole-hour offsets we map the most common zones explicitly.
  String _etcTimezoneForOffset(Duration offset) {
    final minutes = offset.inMinutes;
    const commonZones = {
      210: 'Asia/Tehran',      // UTC+3:30
      270: 'Asia/Kabul',       // UTC+4:30
      330: 'Asia/Kolkata',     // UTC+5:30 (India)
      345: 'Asia/Kathmandu',   // UTC+5:45
      390: 'Asia/Yangon',      // UTC+6:30
      570: 'Australia/Darwin', // UTC+9:30
      630: 'Australia/Adelaide', // UTC+10:30 (DST aside, closest fixed match)
      -210: 'America/St_Johns', // UTC-3:30 (Newfoundland)
    };
    if (commonZones.containsKey(minutes)) return commonZones[minutes]!;
    if (minutes == 0) return 'UTC';
    final hours = minutes ~/ 60;
    if (hours * 60 != minutes) {
      throw Exception('Unsupported offset: $minutes minutes');
    }
    // Sign inversion is intentional: Etc/GMT+N means UTC-N.
    return hours > 0 ? 'Etc/GMT-$hours' : 'Etc/GMT+${-hours}';
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
      final failedDays = <int>[];
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
            await _scheduleZoned(
              id: notificationId,
              title: title,
              body: body,
              scheduledDate: scheduledTZDate,
              details: notificationDetails,
              repeatWeekly: true,
            );
            debugPrint('NotificationService: Scheduled notification #$notificationId for day index $i');
          } catch (e) {
            failedDays.add(i);
            debugPrint('NotificationService: Error scheduling notification for day index $i: $e');
          }
        }
      }
      if (failedDays.isNotEmpty) {
        debugPrint('NotificationService: WARNING — ${failedDays.length} day(s) failed to schedule: $failedDays');
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
        await _scheduleZoned(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledTZDate,
          details: notificationDetails,
          repeatWeekly: false,
        );
        debugPrint('NotificationService: Successfully scheduled notification #$id');
      } catch (e) {
        debugPrint('NotificationService: Error scheduling notification: $e');
        rethrow;
      }
    }
  }

  /// Schedules a zoned notification, preferring exact alarms but gracefully
  /// falling back to inexact scheduling when exact alarms are not permitted
  /// (so the reminder still fires, possibly a few minutes late, instead of
  /// never firing at all).
  Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails details,
    required bool repeatWeekly,
  }) async {
    final AndroidScheduleMode mode = await _preferredScheduleMode();
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents:
            repeatWeekly ? DateTimeComponents.dayOfWeekAndTime : null,
      );
    } catch (e) {
      if (mode == AndroidScheduleMode.exactAllowWhileIdle) {
        debugPrint('NotificationService: Exact schedule failed for #$id ($e), retrying inexact');
        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          scheduledDate,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents:
              repeatWeekly ? DateTimeComponents.dayOfWeekAndTime : null,
        );
        debugPrint('NotificationService: #$id scheduled with inexact mode as fallback');
      } else {
        rethrow;
      }
    }
  }

  /// Returns the best available schedule mode: exact alarms when the OS
  /// allows them, inexact otherwise.
  Future<AndroidScheduleMode> _preferredScheduleMode() async {
    if (!Platform.isAndroid) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }
    try {
      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      final canExact = await androidPlugin?.canScheduleExactNotifications();
      if (canExact == false) {
        debugPrint('NotificationService: Exact alarms not permitted, using inexact mode');
        return AndroidScheduleMode.inexactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('NotificationService: Could not check exact alarm permission: $e');
    }
    return AndroidScheduleMode.exactAllowWhileIdle;
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

  // Cancels any pending (scheduled) notification whose id is NOT in
  // validIds. Used on app startup to purge reminders left behind by habits
  // that were deleted before the delete-time cancel fix existed.
  Future<void> cancelOrphanedNotifications(Set<int> validIds) async {
    await initialize();
    final pending = await getPendingNotifications();
    var cancelled = 0;
    for (final request in pending) {
      if (!validIds.contains(request.id)) {
        try {
          await _notificationsPlugin.cancel(request.id);
          cancelled++;
          debugPrint('NotificationService: Cancelled orphaned notification ${request.id}');
        } catch (e) {
          debugPrint('NotificationService: Error cancelling orphan ${request.id}: $e');
        }
      }
    }
    debugPrint('NotificationService: Orphan cleanup cancelled $cancelled notifications');
  }
}
