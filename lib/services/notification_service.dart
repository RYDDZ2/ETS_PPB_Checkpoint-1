import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Notification channel IDs
  static const String _restTimerChannelId = 'rest_timer';
  static const String _gymReminderChannelId = 'gym_reminder';
  static const String _motivationChannelId = 'motivation';

  // Notification IDs
  static const int restTimerId = 1;
  static const int gymReminderId = 2;
  static const int motivationId = 3;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    await _createChannels();
  }

  Future<void> _configureLocalTimezone() async {
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
  }

  Future<void> _createChannels() async {
    const restChannel = AndroidNotificationChannel(
      _restTimerChannelId,
      'Rest Timer',
      description: 'Notifikasi saat rest timer selesai',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      _gymReminderChannelId,
      'Gym Reminder',
      description: 'Reminder jadwal gym harian',
      importance: Importance.defaultImportance,
    );

    const motivationChannel = AndroidNotificationChannel(
      _motivationChannelId,
      'Motivasi',
      description: 'Notifikasi motivasi harian',
      importance: Importance.low,
    );

    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(restChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(motivationChannel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - could navigate to specific screen
  }

  // ─────────────────────────── REQUEST PERMISSION ──────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  // ─────────────────────────── REST TIMER ──────────────────────────────────

  /// Show notification when rest timer ends
  Future<void> showRestCompleteNotification({String? exerciseName}) async {
    await _plugin.show(
      restTimerId,
      '💪 Rest selesai!',
      exerciseName != null
          ? 'Waktunya lanjut $exerciseName bro!'
          : 'Waktunya lanjut set berikutnya bro!',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _restTimerChannelId,
          'Rest Timer',
          channelDescription: 'Rest timer notification',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color.fromARGB(255, 255, 107, 53),
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required NotificationDetails details,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    Future<void> schedule(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }

    try {
      await schedule(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  /// Schedule rest timer notification
  Future<void> scheduleRestTimer({
    required int seconds,
    String? exerciseName,
  }) async {
    await _plugin.cancel(restTimerId);

    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(seconds: seconds),
    );

    await _scheduleWithFallback(
      id: restTimerId,
      title: '💪 Rest selesai!',
      body: exerciseName != null
          ? 'Waktunya lanjut $exerciseName!'
          : 'Waktunya lanjut set berikutnya!',
      scheduledTime: scheduledTime,
      details: NotificationDetails(
        android: AndroidNotificationDetails(
          _restTimerChannelId,
          'Rest Timer',
          channelDescription: 'Rest timer notification',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Cancel rest timer notification
  Future<void> cancelRestTimer() async {
    await _plugin.cancel(restTimerId);
  }

  // ─────────────────────────── GYM REMINDER ────────────────────────────────

  /// Schedule a gym reminder after a custom duration.
  Future<void> scheduleGymReminderAfter({
    required int hours,
    required int minutes,
    required int seconds,
  }) async {
    await cancelGymReminder();

    final totalSeconds = (hours * 3600) + (minutes * 60) + seconds;
    if (totalSeconds <= 0) {
      throw ArgumentError.value(
        totalSeconds,
        'duration',
        'Reminder duration must be greater than zero',
      );
    }

    final scheduledTime = tz.TZDateTime.now(tz.local).add(
      Duration(seconds: totalSeconds),
    );

    await _scheduleWithFallback(
      id: gymReminderId,
      title: '🏋️ Waktunya Gym!',
      body: 'Jangan skip hari ini bro, tetap konsisten!',
      scheduledTime: scheduledTime,
      details: const NotificationDetails(
        android: AndroidNotificationDetails(
          _gymReminderChannelId,
          'Gym Reminder',
          channelDescription: 'Custom gym reminder',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  @Deprecated('Use scheduleGymReminderAfter instead.')
  Future<void> scheduleDailyGymReminder({
    required int hour,
    required int minute,
  }) {
    return scheduleGymReminderAfter(
      hours: hour,
      minutes: minute,
      seconds: 0,
    );
  }

  Future<void> cancelGymReminder() async {
    await _plugin.cancel(gymReminderId);
  }

  // ─────────────────────────── MOTIVATION ──────────────────────────────────

  Future<void> showMotivationNotification({int? daysSinceLastWorkout}) async {
    final messages = [
      'Kamu bisa! Satu set lagi! 🔥',
      'Consistency is key. Jangan berhenti! 💪',
      'Progress happens one rep at a time. 🏆',
      'Pain is temporary, gains are forever! ⚡',
    ];

    String title = '🔥 Jangan Lupa Gym!';
    String body = messages[DateTime.now().millisecond % messages.length];

    if (daysSinceLastWorkout != null && daysSinceLastWorkout > 0) {
      title = '😤 Udah $daysSinceLastWorkout hari belum gym nih!';
      body = 'Yuk balik ke gym, jangan sampai progress kamu hilang!';
    }

    await _plugin.show(
      motivationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _motivationChannelId,
          'Motivasi',
          channelDescription: 'Motivational notification',
          importance: Importance.low,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true),
      ),
    );
  }

  // ─────────────────────────── CANCEL ALL ──────────────────────────────────

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
