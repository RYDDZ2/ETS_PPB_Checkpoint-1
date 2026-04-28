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

  // Multiple one-shot alarm slots untuk gym reminder
  static const int _gymReminderBaseId = 200;
  static const int _gymReminderSlots = 10;

  // Track apakah sudah diinisialisasi
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

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
      // ✅ FIX: Handle notifikasi yang muncul saat app di foreground (Android 14+)
      onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTap,
    );

    await _createChannels();
    _initialized = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneInfo.identifier));
    } catch (e) {
      // Fallback ke UTC jika gagal
      debugPrint('Timezone config failed, falling back to UTC: $e');
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<void> _createChannels() async {
    // ✅ FIX: enableLights, showBadge, dan sound wajib di-set
    //         untuk memastikan notifikasi muncul di foreground & lockscreen
    const restChannel = AndroidNotificationChannel(
      _restTimerChannelId,
      'Rest Timer',
      description: 'Notifikasi saat rest timer selesai',
      importance: Importance.max, // ✅ max agar heads-up notification muncul
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    const reminderChannel = AndroidNotificationChannel(
      _gymReminderChannelId,
      'Gym Reminder',
      description: 'Reminder jadwal gym harian',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      showBadge: true,
    );

    const motivationChannel = AndroidNotificationChannel(
      _motivationChannelId,
      'Motivasi',
      description: 'Notifikasi motivasi harian',
      importance: Importance.low,
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(restChannel);
    await androidPlugin?.createNotificationChannel(reminderChannel);
    await androidPlugin?.createNotificationChannel(motivationChannel);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap - navigasi ke screen terkait jika perlu
    debugPrint(
        'Notification tapped: ${response.id} payload: ${response.payload}');
  }

  // ─────────────────────────── REQUEST PERMISSION ──────────────────────────

  Future<bool> requestPermission() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<bool> requestReminderPermissions() async {
    final notificationGranted = await requestPermission();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      try {
        final exactGranted = await android.requestExactAlarmsPermission();
        if (exactGranted == false) {
          debugPrint(
            'Exact alarm permission not granted; falling back to inexact scheduling.',
          );
        }
      } catch (e) {
        debugPrint('requestExactAlarmsPermission error: $e');
      }
    }

    return notificationGranted;
  }

  // ─────────────────────────── REST TIMER ──────────────────────────────────

  /// ✅ FIX: Detail notifikasi rest timer dengan Importance.max
  ///         agar muncul sebagai heads-up notification saat app di foreground
  NotificationDetails get _restTimerDetails => const NotificationDetails(
        android: AndroidNotificationDetails(
          _restTimerChannelId,
          'Rest Timer',
          channelDescription: 'Rest timer notification',
          importance: Importance.max, // ✅ heads-up
          priority: Priority.max, // ✅ heads-up
          icon: '@mipmap/ic_launcher',
          color: Color.fromARGB(255, 255, 107, 53),
          // ✅ FIX: fullScreenIntent memastikan notifikasi muncul
          //         bahkan saat layar mati atau app di foreground
          fullScreenIntent: true,
          // ✅ FIX: visibility PUBLIC agar muncul di lockscreen
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          // ✅ FIX: ticker untuk aksesibilitas
          ticker: 'Rest timer selesai',
          // ✅ FIX: autoCancel = true agar hilang saat di-tap
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        ),
      );

  /// ✅ Tampilkan notifikasi REST SELESAI langsung (immediate show)
  /// Digunakan sebagai primary trigger saat in-app timer habis
  Future<void> showRestCompleteNotification({String? exerciseName}) async {
    // Pastikan izin sudah ada
    await requestPermission();

    await _plugin.show(
      restTimerId,
      '💪 Rest selesai!',
      exerciseName != null
          ? 'Waktunya lanjut $exerciseName bro!'
          : 'Waktunya lanjut set berikutnya bro!',
      _restTimerDetails,
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
      debugPrint('Exact alarm not permitted, using inexact: ${e.message}');
      await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  /// ✅ Schedule rest timer notification (backup saat app di background)
  Future<void> scheduleRestTimer({
    required int seconds,
    String? exerciseName,
  }) async {
    await _plugin.cancel(restTimerId);

    if (seconds <= 0) return;

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
      details: _restTimerDetails,
    );

    debugPrint('Rest timer scheduled for $seconds seconds from now');
  }

  /// Cancel rest timer notification
  Future<void> cancelRestTimer() async {
    await _plugin.cancel(restTimerId);
  }

  // ─────────────────────────── GYM REMINDER ────────────────────────────────

  /// Tampilkan notifikasi gym reminder sekarang (untuk foreground / manual trigger)
  Future<void> showGymReminderNotification() async {
    await _plugin.show(
      gymReminderId,
      '🏋️ Waktunya Gym!',
      'Jangan skip hari ini bro, tetap konsisten!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _gymReminderChannelId,
          'Gym Reminder',
          channelDescription: 'Custom gym reminder',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          visibility: NotificationVisibility.public,
          playSound: true,
          enableVibration: true,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentSound: true,
        ),
      ),
    );
  }

  /// Schedule [_gymReminderSlots] one-shot alarms masing-masing berjarak
  /// [interval] dari yang sebelumnya — dimulai dari sekarang + interval.
  Future<void> scheduleGymReminderPeriodically({
    required Duration interval,
  }) async {
    await cancelGymReminder();

    if (interval.inSeconds <= 0) {
      throw ArgumentError.value(
        interval,
        'interval',
        'Reminder interval must be greater than zero',
      );
    }

    final now = tz.TZDateTime.now(tz.local);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _gymReminderChannelId,
        'Gym Reminder',
        channelDescription: 'Custom gym reminder',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        visibility: NotificationVisibility.public,
        playSound: true,
        enableVibration: true,
        autoCancel: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
      ),
    );

    for (int i = 1; i <= _gymReminderSlots; i++) {
      final scheduledTime = now.add(interval * i);
      await _scheduleWithFallback(
        id: _gymReminderBaseId + i,
        title: '🏋️ Waktunya Gym!',
        body: 'Jangan skip hari ini bro, tetap konsisten!',
        scheduledTime: scheduledTime,
        details: details,
      );
    }

    debugPrint(
        'Scheduled $_gymReminderSlots gym reminders every ${interval.inSeconds}s');
  }

  /// Schedule a gym reminder after a custom duration.
  Future<void> scheduleGymReminderAfter({
    required int hours,
    required int minutes,
    required int seconds,
  }) {
    return scheduleGymReminderPeriodically(
      interval: Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
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

  /// Cancel semua slot gym reminder (termasuk legacy single ID).
  Future<void> cancelGymReminder() async {
    await _plugin.cancel(gymReminderId);
    for (int i = 1; i <= _gymReminderSlots; i++) {
      await _plugin.cancel(_gymReminderBaseId + i);
    }
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
          autoCancel: true,
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

// ✅ Top-level function wajib untuk background notification handler
@pragma('vm:entry-point')
void _onBackgroundNotificationTap(NotificationResponse response) {
  debugPrint('Background notification tapped: ${response.id}');
}
