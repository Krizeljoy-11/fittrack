import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local notification foundation for workout reminders.
///
/// FitTrack uses **local** notifications only (no Firebase Cloud Messaging).
/// Phase 0 wires up initialization, permissions, schedule, cancel and update;
/// the reminder UI that calls these methods arrives in a later phase.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;

  bool get isInitialized => _initialized;

  static const String channelId = 'fittrack_reminders';
  static const String channelName = 'Workout reminders';
  static const String channelDescription =
      'Reminders for workouts scheduled in FitTrack.';

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
  );

  /// Loads the IANA time-zone database and registers the notification plugin.
  ///
  /// Safe to call more than once; failures (unsupported platform, tests) are
  /// logged instead of crashing the app.
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();
      const AndroidInitializationSettings android =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iOS = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings settings = InitializationSettings(
        android: android,
        iOS: iOS,
      );
      await _plugin.initialize(settings: settings);
      _initialized = true;
    } on Object catch (error) {
      debugPrint('NotificationService: initialization failed: $error');
    }
  }

  /// Pins reminders to the device's IANA time zone, e.g. `Asia/Manila`.
  ///
  /// Required before scheduling *recurring* reminders so the weekday is
  /// computed in local time. One-off reminders already use the correct
  /// absolute instant.
  void useTimeZone(String ianaName) {
    try {
      tz.setLocalLocation(tz.getLocation(ianaName));
    } on Object catch (error) {
      debugPrint('NotificationService: unknown time zone "$ianaName": $error');
    }
  }

  /// Requests the `POST_NOTIFICATIONS` permission (Android 13+).
  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final bool? granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  /// Requests the `SCHEDULE_EXACT_ALARM` permission (Android 12+).
  Future<bool> requestExactAlarmPermission() async {
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return true;
    final bool? granted = await android.requestExactAlarmsPermission();
    return granted ?? false;
  }

  /// Schedules a notification and returns the id used to cancel/update it.
  Future<int> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    if (!_initialized) await initialize();
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: tz.TZDateTime.from(at, tz.local),
      notificationDetails: _details,
      androidScheduleMode: scheduleMode,
      payload: payload,
      matchDateTimeComponents: matchDateTimeComponents,
    );
    return id;
  }

  /// Replaces an existing reminder with a new time.
  Future<int> update({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    String? payload,
    AndroidScheduleMode scheduleMode = AndroidScheduleMode.exactAllowWhileIdle,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    await cancel(id);
    return schedule(
      id: id,
      title: title,
      body: body,
      at: at,
      payload: payload,
      scheduleMode: scheduleMode,
      matchDateTimeComponents: matchDateTimeComponents,
    );
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id: id);
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
