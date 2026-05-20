import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../constants/settings_keys.dart';
import '../../data/models/quote.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const _channelId = 'daily_quote_channel';
  static const _channelName = 'Tägliches Zitat';
  static const _channelDescription = 'Benachrichtigungen für das Tageszitat.';
  static const _dailyReminderId = 120001;
  static const _instantDailyQuoteId = 120002;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  String? _launchQuoteId;
  String? _launchRoute;
  bool _initialized = false;
  bool _timeZonesInitialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    await _initializeTimeZonesIfNeeded();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _storeLaunchPayload(response.payload);
      },
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp ?? false) {
      _storeLaunchPayload(launchDetails?.notificationResponse?.payload);
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  String consumeLaunchRoute() {
    final route = _launchRoute;
    _launchRoute = null;
    if (route != null && route.isNotEmpty) {
      return route;
    }

    final id = _launchQuoteId;
    _launchQuoteId = null;
    if (id == null || id.isEmpty) {
      return '/';
    }
    return '/detail/$id';
  }

  Future<void> showDailyQuote(Quote quote) async {
    await initialize();

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    await _plugin.cancel(_instantDailyQuoteId);
    final firstSentence = _extractFirstSentence(quote.textDe);
    await _plugin.show(
      _instantDailyQuoteId,
      'Zitatatlas - Tageszitat',
      firstSentence,
      details,
      payload: 'quote:${quote.id}',
    );
  }

  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    bool enabled = true,
  }) async {
    await initialize();
    await _plugin.cancel(_dailyReminderId);

    if (!enabled) {
      return;
    }

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );

    final nextTrigger = _nextInstanceOfTime(hour: hour, minute: minute);

    await _plugin.zonedSchedule(
      _dailyReminderId,
      'Zitatatlas - Tageszitat',
      'Dein nächstes Tageszitat wartet auf dich.',
      nextTrigger,
      details,
      payload: 'route:/',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelDailyReminder() async {
    await initialize();
    await _plugin.cancel(_dailyReminderId);
  }

  Future<void> scheduleDailyReminderFromSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(SettingsKeys.notificationHour) ?? 7;
    final minute = prefs.getInt(SettingsKeys.notificationMinute) ?? 0;
    final enabled = prefs.getBool(SettingsKeys.notificationEnabled) ?? true;
    await scheduleDailyReminder(hour: hour, minute: minute, enabled: enabled);
  }

  String _extractFirstSentence(String text) {
    final trimmed = text.trim();
    final index = trimmed.indexOf('.');
    if (index == -1) {
      return trimmed;
    }
    return trimmed.substring(0, index + 1);
  }

  String? _payloadToQuoteId(String? payload) {
    if (payload == null || !payload.startsWith('quote:')) {
      return null;
    }
    return payload.substring('quote:'.length);
  }

  String? _payloadToRoute(String? payload) {
    if (payload == null || !payload.startsWith('route:')) {
      return null;
    }
    return payload.substring('route:'.length);
  }

  void _storeLaunchPayload(String? payload) {
    _launchQuoteId = _payloadToQuoteId(payload);
    _launchRoute = _payloadToRoute(payload);
  }

  Future<void> _initializeTimeZonesIfNeeded() async {
    if (_timeZonesInitialized) {
      return;
    }

    tz_data.initializeTimeZones();

    try {
      final localTimeZone = await FlutterTimezone.getLocalTimezone();
      final localLocation = tz.getLocation(localTimeZone);
      tz.setLocalLocation(localLocation);
    } catch (error) {
      // Keep defaults when timezone lookup fails so notifications still work.
      debugPrint('[Notification] Failed to resolve local timezone: $error');
    }

    _timeZonesInitialized = true;
  }

  tz.TZDateTime _nextInstanceOfTime({required int hour, required int minute}) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }
}
