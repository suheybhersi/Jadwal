import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

/// Handles local notification scheduling and persistence of notification preferences.
/// Notifies users about daily reading, hifdh, and reviews at a user-selected time.
class NotificationService {
  static final NotificationService instance = NotificationService._();
  NotificationService._();

  static const String _keyPushEnabled = 'notif_push_enabled';
  static const String _keyEmailEnabled = 'notif_email_enabled';
  static const String _keyTaskReminderEnabled = 'notif_task_reminder_enabled';
  static const String _keyEventAlertEnabled = 'notif_event_alert_enabled';
  static const String _keyWeeklySummaryEnabled = 'notif_weekly_summary_enabled';
  static const String _keyDailyHour = 'notif_daily_hour';
  static const String _keyDailyMinute = 'notif_daily_minute';
  static const String _keyWeeklySummaryWeekday = 'notif_weekly_weekday';

  static const int _idDailyReminder = 1;
  static const String _channelId = 'jadwal_daily_reminders';
  static const String _channelName = 'Daily reminders';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  /// When true, flutter_timezone wasn't available; we schedule using Dart DateTime (local time) and one-shot.
  bool _useLocalTimeFallback = false;
  /// When true, flutter_local_notifications plugin wasn't registered (e.g. hot restart or unsupported platform); scheduling is no-op.
  bool _pluginUnavailable = false;

  /// Initialize timezone, plugin, and request permissions. Call once at app startup.
  /// Handles MissingPluginException so the app does not crash when the plugin is not registered (e.g. hot restart).
  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      final String deviceTz = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTz));
    } on MissingPluginException catch (e) {
      debugPrint('NotificationService: flutter_timezone not available (e.g. need full rebuild): $e');
      _useLocalTimeFallback = true;
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    } catch (e) {
      debugPrint('NotificationService: timezone init error: $e');
      _useLocalTimeFallback = true;
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
      );
      const initSettings = InitializationSettings(android: android, iOS: ios);
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (Platform.isAndroid) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(
              const AndroidNotificationChannel(
                _channelId,
                _channelName,
                description: 'Reminders for daily reading, memorisation and reviews',
                importance: Importance.defaultImportance,
              ),
            );
      }

      if (Platform.isIOS) {
        await _plugin
            .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin>()
            ?.requestPermissions(alert: true, badge: true, sound: true);
      }

      await rescheduleFromPrefs();
    } on MissingPluginException catch (e) {
      debugPrint('NotificationService: flutter_local_notifications not available (do a full stop & run, not hot restart): $e');
      _pluginUnavailable = true;
    } catch (e) {
      debugPrint('NotificationService: plugin init error: $e');
      _pluginUnavailable = true;
    } finally {
      _initialized = true;
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // App opens when user taps notification; no extra routing needed for now
  }

  /// Load all notification preferences from SharedPreferences.
  Future<NotificationPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      pushNotificationsEnabled: prefs.getBool(_keyPushEnabled) ?? true,
      emailNotificationsEnabled: prefs.getBool(_keyEmailEnabled) ?? false,
      taskReminderEnabled: prefs.getBool(_keyTaskReminderEnabled) ?? true,
      eventAlertEnabled: prefs.getBool(_keyEventAlertEnabled) ?? true,
      weeklySummaryEnabled: prefs.getBool(_keyWeeklySummaryEnabled) ?? false,
      dailyNotificationHour: prefs.getInt(_keyDailyHour) ?? 8,
      dailyNotificationMinute: prefs.getInt(_keyDailyMinute) ?? 0,
      weeklySummaryWeekday: prefs.getInt(_keyWeeklySummaryWeekday) ?? 1,
    );
  }

  /// Save preferences and reschedule notifications accordingly.
  Future<void> savePreferences(NotificationPreferences prefs) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_keyPushEnabled, prefs.pushNotificationsEnabled);
    await p.setBool(_keyEmailEnabled, prefs.emailNotificationsEnabled);
    await p.setBool(_keyTaskReminderEnabled, prefs.taskReminderEnabled);
    await p.setBool(_keyEventAlertEnabled, prefs.eventAlertEnabled);
    await p.setBool(_keyWeeklySummaryEnabled, prefs.weeklySummaryEnabled);
    await p.setInt(_keyDailyHour, prefs.dailyNotificationHour);
    await p.setInt(_keyDailyMinute, prefs.dailyNotificationMinute);
    await p.setInt(_keyWeeklySummaryWeekday, prefs.weeklySummaryWeekday);
    await rescheduleFromPrefs();
  }

  /// Cancel all scheduled notifications, then schedule daily (and weekly) if enabled.
  Future<void> rescheduleFromPrefs() async {
    if (_pluginUnavailable) return;
    try {
      await _plugin.cancel(_idDailyReminder);
    } on MissingPluginException {
      return;
    }

    final prefs = await loadPreferences();
    if (!prefs.pushNotificationsEnabled || !prefs.taskReminderEnabled) return;

    await _scheduleDailyReminder(
      prefs.dailyNotificationHour,
      prefs.dailyNotificationMinute,
    );
  }

  Future<void> _scheduleDailyReminder(int hour, int minute) async {
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Reminders for daily reading, memorisation and reviews',
      ),
      iOS: DarwinNotificationDetails(),
    );

    if (_useLocalTimeFallback) {
      // flutter_timezone not available: compute next (hour, minute) in device local time
      // using Dart DateTime, then schedule a one-shot. Reschedule on next app open.
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }
      final tzScheduled = tz.TZDateTime.from(scheduled.toUtc(), tz.UTC);
      await _plugin.zonedSchedule(
        _idDailyReminder,
        'Jadwal',
        'Time for your daily reading, memorisation and reviews.',
        tzScheduled,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      _idDailyReminder,
      'Jadwal',
      'Time for your daily reading, memorisation and reviews.',
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Cancel all scheduled notifications (e.g. when user disables push or task reminders).
  Future<void> cancelAll() async {
    if (_pluginUnavailable) return;
    try {
      await _plugin.cancel(_idDailyReminder);
    } on MissingPluginException {
      // no-op
    }
  }
}

/// Stored notification preferences.
class NotificationPreferences {
  final bool pushNotificationsEnabled;
  final bool emailNotificationsEnabled;
  final bool taskReminderEnabled;
  final bool eventAlertEnabled;
  final bool weeklySummaryEnabled;
  final int dailyNotificationHour;
  final int dailyNotificationMinute;
  final int weeklySummaryWeekday;

  const NotificationPreferences({
    this.pushNotificationsEnabled = true,
    this.emailNotificationsEnabled = false,
    this.taskReminderEnabled = true,
    this.eventAlertEnabled = true,
    this.weeklySummaryEnabled = false,
    this.dailyNotificationHour = 8,
    this.dailyNotificationMinute = 0,
    this.weeklySummaryWeekday = 1,
  });

  String get dailyTimeFormatted {
    final h = dailyNotificationHour;
    final m = dailyNotificationMinute;
    final padM = m.toString().padLeft(2, '0');
    if (h == 0) return '12:$padM AM';
    if (h < 12) return '$h:$padM AM';
    if (h == 12) return '12:$padM PM';
    return '${h - 12}:$padM PM';
  }

  static const List<String> weekdayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday',
    'Friday', 'Saturday', 'Sunday',
  ];

  String get weeklySummaryDayName =>
      weekdayNames[weeklySummaryWeekday.clamp(0, 6)];
}
