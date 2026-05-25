import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_profile.dart';
import '../../data/repositories/quote_repository.dart';
import '../constants/settings_keys.dart';
import 'notification_service.dart';
import 'supabase_auth_service.dart';

class AccountPrivacyService {
  Future<String> buildExportJson({
    required AuthUser? authUser,
    required List<String> favoriteIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final profileRaw = prefs.getString(UserProfile.storageKey);
    final profile = profileRaw == null || profileRaw.isEmpty
        ? UserProfile.initial()
        : UserProfile.fromJsonString(profileRaw);

    final payload = <String, dynamic>{
      'exported_at': DateTime.now().toIso8601String(),
      'account': <String, dynamic>{
        'user_id': authUser?.id,
        'email': authUser?.email,
        'display_name': authUser?.displayName,
      },
      'profile': profile.toJson(),
      'settings': <String, dynamic>{
        'language_code': prefs.getString(SettingsKeys.languageCode) ?? 'de',
        'difficulty': prefs.getString(SettingsKeys.difficulty) ?? 'all',
        'notification_hour': prefs.getInt(SettingsKeys.notificationHour) ?? 7,
        'notification_minute':
            prefs.getInt(SettingsKeys.notificationMinute) ?? 0,
        'notification_enabled':
            prefs.getBool(SettingsKeys.notificationEnabled) ?? true,
        'crash_reporting_enabled':
            prefs.getBool(SettingsKeys.crashReportingEnabled) ?? false,
        'home_content_mode':
            prefs.getString(SettingsKeys.homeContentMode) ?? 'mixed',
        'streak': prefs.getInt(SettingsKeys.streak) ?? 0,
        'onboarding_seen': prefs.getBool('settings_onboarding_seen') ?? false,
        'app_mode': prefs.getString('app_mode'),
      },
      'favorites': favoriteIds,
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> clearLocalUserData({
    required QuoteRepository quoteRepository,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await quoteRepository.clearUserData();

    await prefs.remove(UserProfile.storageKey);
    await prefs.remove(SettingsKeys.languageCode);
    await prefs.remove(SettingsKeys.difficulty);
    await prefs.remove(SettingsKeys.notificationHour);
    await prefs.remove(SettingsKeys.notificationMinute);
    await prefs.remove(SettingsKeys.notificationEnabled);
    await prefs.remove(SettingsKeys.crashReportingEnabled);
    await prefs.remove(SettingsKeys.homeContentMode);
    await prefs.remove(SettingsKeys.streak);
    await prefs.remove('settings_onboarding_seen');
    await prefs.remove('app_mode');

    await NotificationService.instance.cancelDailyReminder();
  }
}
