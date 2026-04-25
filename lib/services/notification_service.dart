import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
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

  /// Schedule rest timer notification
  Future<void> scheduleRestTimer({
    required int seconds,
    String? exerciseName,
  }) async {
    await _plugin.cancel(restTimerId);

    final scheduledTime = tz.TZDateTime.now(
      tz.local,
    ).add(Duration(seconds: seconds));

    await _plugin.zonedSchedule(
      restTimerId,
      '💪 Rest selesai!',
      exerciseName != null
          ? 'Waktunya lanjut $exerciseName!'
          : 'Waktunya lanjut set berikutnya!',
      scheduledTime,
      NotificationDetails(
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
      androidScheduleMode: AndroidScheduleMode.inexact, // Tetap gunakan inexact
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Cancel rest timer notification
  Future<void> cancelRestTimer() async {
    await _plugin.cancel(restTimerId);
  }

  // ─────────────────────────── GYM REMINDER ────────────────────────────────

  /// Schedule daily gym reminder
  Future<void> scheduleDailyGymReminder({
    required int hour,
    required int minute,
  }) async {
    await cancelGymReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduledTime = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // If time already passed today, schedule for tomorrow
    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      gymReminderId,
      '🏋️ Waktunya Gym!',
      'Jangan skip hari ini bro, tetap konsisten!',
      scheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _gymReminderChannelId,
          'Gym Reminder',
          channelDescription: 'Daily gym reminder',
          importance: Importance.defaultImportance,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
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
