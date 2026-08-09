import 'package:workmanager/workmanager.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../../data/models/daily_content.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/quote_repository.dart';
import '../../domain/services/daily_content_cache.dart';
import '../../domain/services/daily_content_resolver.dart';
import '../constants/settings_keys.dart';
import 'widget_sync_service.dart';

const String dailyQuoteTaskName = 'daily_quote_refresh_task';

@pragma('vm:entry-point')
void workmanagerCallbackDispatcher() {
  Workmanager().executeTask((
    String task,
    Map<String, dynamic>? inputData,
  ) async {
    if (task != dailyQuoteTaskName) {
      return true;
    }

    final settings = await _WidgetTaskSettings.resolve(inputData);

    // Show whatever the app has already picked for today instead of resolving
    // a second time — resolving independently is how the widget ended up on a
    // different quote than the home screen. Only when nothing is cached yet
    // (typically the first refresh after midnight) does this task resolve, and
    // it then publishes its pick so the app adopts the very same quote.
    final content =
        await DailyContentCache.read() ??
        await _resolveAndCacheDailyContent(settings);

    if (content == null) {
      return true;
    }

    await WidgetSyncService.syncDailyContent(
      content: content,
      streakCount: settings.streak,
      modeLabel: settings.appMode.name.toUpperCase(),
    );

    return true;
  });
}

Future<DailyContent?> _resolveAndCacheDailyContent(
  _WidgetTaskSettings settings,
) async {
  final db = AppDatabase();
  try {
    final quoteRepository = QuoteRepository(db);
    await quoteRepository.ensureSeeded();

    final content = await _resolveDailyContent(
      quoteRepository: quoteRepository,
      appMode: settings.appMode,
      profile: settings.profile,
    );

    if (content != null) {
      await DailyContentCache.write(
        content: content,
        ownerUserId: await DailyContentCache.readOwner(),
      );
    }

    return content;
  } finally {
    await db.close();
  }
}

/// Settings the widget refresh runs with.
class _WidgetTaskSettings {
  const _WidgetTaskSettings({
    required this.streak,
    required this.appMode,
    required this.profile,
  });

  final int streak;
  final AppMode appMode;
  final UserProfile profile;

  /// Reads the current settings, preferring the live stored values over the
  /// `inputData` copies. Those copies were captured when the periodic task was
  /// registered and go stale as soon as the user changes mode or profile —
  /// which made the widget resolve against a different profile than the app.
  /// The stored values stay optional so this keeps working even where the
  /// background (DartWorker) isolate cannot reach the preferences plugin.
  static Future<_WidgetTaskSettings> resolve(
    Map<String, dynamic>? inputData,
  ) async {
    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }

    return _WidgetTaskSettings(
      streak:
          prefs?.getInt(SettingsKeys.streak) ??
          _asInt(inputData?['streak']) ??
          0,
      appMode: _resolveAppMode(
        prefs?.getString('app_mode') ?? inputData?['app_mode'] as String?,
      ),
      profile: _resolveProfile(
        prefs?.getString(UserProfile.storageKey) ??
            inputData?['user_profile'] as String?,
      ),
    );
  }

  static int? _asInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value == null) {
      return null;
    }
    return int.tryParse('$value');
  }
}

Future<DailyContent?> _resolveDailyContent({
  required QuoteRepository quoteRepository,
  required AppMode appMode,
  required UserProfile profile,
}) async {
  final resolver = DailyContentResolver();
  try {
    final content = await resolver.resolveDailyContentFromRepository(
      quoteRepository: quoteRepository,
      appMode: appMode,
      profile: profile,
    );

    if (content != null) {
      return content;
    }
  } catch (_) {
    // Fall back below.
  }

  final quotes = await quoteRepository.watchAllQuotes().first;
  if (quotes.isNotEmpty) {
    return DailyContent.quote(quote: quotes.first);
  }

  return null;
}

AppMode _resolveAppMode(String? stored) {
  switch (stored) {
    case 'adminMarx':
    case 'godmode':
      return AppMode.adminMarx;
    case 'public':
    case 'marx':
    case 'history':
    case 'mixed':
    default:
      return AppMode.public;
  }
}

UserProfile _resolveProfile(String? raw) {
  if (raw == null || raw.isEmpty) {
    return UserProfile.initial();
  }

  try {
    return UserProfile.fromJsonString(raw);
  } catch (_) {
    return UserProfile.initial();
  }
}

abstract final class BackgroundTasksService {
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    // Collect small primitive preferences on the main isolate and pass them
    // to the background callback via `inputData` to avoid platform-channel
    // calls from the background (DartWorker) isolate.
    final prefs = await SharedPreferences.getInstance();
    final inputData = <String, dynamic>{
      'streak': prefs.getInt(SettingsKeys.streak) ?? 0,
      'app_mode': prefs.getString('app_mode') ?? '',
      'user_profile': prefs.getString(UserProfile.storageKey) ?? '',
    };

    await Workmanager().initialize(workmanagerCallbackDispatcher);

    await Workmanager().registerPeriodicTask(
      dailyQuoteTaskName,
      dailyQuoteTaskName,
      frequency: const Duration(hours: 24),
      constraints: Constraints(networkType: NetworkType.notRequired),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      inputData: inputData,
    );

    _initialized = true;
  }
}
