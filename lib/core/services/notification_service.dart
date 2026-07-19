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
  bool _permissionGranted = false;

  /// Whether the OS-level notification permission is currently granted.
  bool get permissionGranted => _permissionGranted;

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      );

  static const NotificationDetails _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

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

    // Explicitly (re)create the Android channel so scheduled notifications
    // always have a valid, high-importance channel to post to.
    await _android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );

    _initialized = true;

    // Bewusst KEINE Berechtigungsabfrage hier. `initialize()` läuft beim
    // Bootstrap jedes Kaltstarts — eine Abfrage an dieser Stelle erscheint
    // ohne jeden Kontext und noch bevor das Onboarding erklärt hat, wofür sie
    // gebraucht wird. Gefragt wird nur dort, wo der Nutzer es ausgelöst hat
    // (Onboarding-Seite, Einstellungen).
    await refreshPermissionStatus();
  }

  /// Liest den tatsächlichen Systemzustand der Benachrichtigungs-Berechtigung.
  ///
  /// Vorher spiegelte [_permissionGranted] nur das Ergebnis einer Abfrage
  /// innerhalb derselben Sitzung — nach einem Neustart stand es wieder auf
  /// `false`, obwohl die Berechtigung erteilt war.
  Future<bool> refreshPermissionStatus() async {
    final android = _android;
    if (android != null) {
      try {
        _permissionGranted = await android.areNotificationsEnabled() ?? false;
      } catch (error) {
        debugPrint('[Notification] Permission status check failed: $error');
      }
      return _permissionGranted;
    }

    // iOS kennt keine synchrone Statusabfrage über dieses Plugin; dort bleibt
    // der zuletzt bekannte Wert stehen.
    return _permissionGranted;
  }

  /// Fordert die Benachrichtigungs-Berechtigung an.
  ///
  /// Nur aus einem Nutzer-ausgelösten Kontext aufrufen.
  Future<bool> requestPermission() async {
    await initialize();

    final android = _android;
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      _permissionGranted = granted ?? _permissionGranted;
    } else {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted = granted ?? true;
    }

    return _permissionGranted;
  }

  /// Sends an immediate notification so users can verify delivery works.
  Future<void> showTestNotification() async {
    await initialize();
    await _plugin.show(
      _instantDailyQuoteId,
      'Quotidian',
      'Benachrichtigungen sind aktiv – so sieht dein Tageszitat aus.',
      _details,
      payload: 'route:/',
    );
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

    // Trotzdem planen, wenn die Berechtigung fehlt: erteilt der Nutzer sie
    // später, wird der bereits eingeplante Alarm zugestellt. Der Hinweis im
    // Log macht aber sichtbar, warum nichts ankommt.
    if (!await refreshPermissionStatus()) {
      debugPrint(
        '[Notification] Reminder wird geplant, aber die '
        'Benachrichtigungs-Berechtigung fehlt — es wird nichts angezeigt.',
      );
    }

    final nextTrigger = _nextInstanceOfTime(hour: hour, minute: minute);

    // Bewusst inexakte Alarme.
    //
    // Exakte Alarme (`exactAllowWhileIdle`) verlangen auf Android 12+ die
    // Berechtigung SCHEDULE_EXACT_ALARM bzw. USE_EXACT_ALARM. Google beschränkt
    // die auf Wecker- und Kalender-Apps; ein Zitat-Reminder erfüllt das
    // Kriterium nicht und würde bei der Play-Prüfung beanstandet. Ein täglicher
    // Reminder braucht auch keine Sekundengenauigkeit — Android darf ihn im
    // Doze-Modus um einige Minuten verschieben.
    try {
      await _plugin.zonedSchedule(
        _dailyReminderId,
        'Zitatatlas - Tageszitat',
        'Dein nächstes Tageszitat wartet auf dich.',
        nextTrigger,
        _details,
        payload: 'route:/',
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[Notification] Daily reminder scheduled for $nextTrigger');
    } catch (error, stackTrace) {
      // Nicht schlucken: schlägt das Planen fehl, kommt nie eine
      // Benachrichtigung, und ohne Log ist die Ursache nicht auffindbar.
      debugPrint('[Notification] Daily reminder scheduling failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
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
