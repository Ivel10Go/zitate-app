import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/settings_keys.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/home_content_mode.dart';
import '../../data/models/user_profile.dart';

enum DifficultyFilter { all, beginnerOnly, noBeginner }

class SettingsState {
  const SettingsState({
    required this.languageCode,
    required this.difficultyFilter,
    required this.notificationHour,
    required this.notificationMinute,
    required this.notificationEnabled,
    required this.homeContentMode,
    required this.streak,
    required this.onboardingSeen,
  });

  final String languageCode;
  final DifficultyFilter difficultyFilter;
  final int notificationHour;
  final int notificationMinute;
  final bool notificationEnabled;
  final HomeContentMode homeContentMode;
  final int streak;
  final bool onboardingSeen;

  SettingsState copyWith({
    String? languageCode,
    DifficultyFilter? difficultyFilter,
    int? notificationHour,
    int? notificationMinute,
    bool? notificationEnabled,
    HomeContentMode? homeContentMode,
    int? streak,
    bool? onboardingSeen,
  }) {
    return SettingsState(
      languageCode: languageCode ?? this.languageCode,
      difficultyFilter: difficultyFilter ?? this.difficultyFilter,
      notificationHour: notificationHour ?? this.notificationHour,
      notificationMinute: notificationMinute ?? this.notificationMinute,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      homeContentMode: homeContentMode ?? this.homeContentMode,
      streak: streak ?? this.streak,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
    );
  }
}

class SettingsController extends AsyncNotifier<SettingsState> {
  @override
  Future<SettingsState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final profileRaw = prefs.getString(UserProfile.storageKey);
    final onboardingSeen = profileRaw == null || profileRaw.isEmpty
        ? false
        : UserProfile.fromJsonString(profileRaw).onboardingCompleted;
    return SettingsState(
      languageCode: prefs.getString(SettingsKeys.languageCode) ?? 'de',
      difficultyFilter: _fromDifficultyKey(
        prefs.getString(SettingsKeys.difficulty) ?? DifficultyFilter.all.name,
      ),
      notificationHour: prefs.getInt(SettingsKeys.notificationHour) ?? 7,
      notificationMinute: prefs.getInt(SettingsKeys.notificationMinute) ?? 0,
      notificationEnabled:
          prefs.getBool(SettingsKeys.notificationEnabled) ?? true,
      homeContentMode: HomeContentMode.fromStorage(
        prefs.getString(SettingsKeys.homeContentMode),
      ),
      streak: prefs.getInt(SettingsKeys.streak) ?? 0,
      onboardingSeen:
          onboardingSeen ||
          (prefs.getBool('settings_onboarding_seen') ?? false),
    );
  }

  Future<void> setHomeContentMode(HomeContentMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.homeContentMode, mode.name);
    state = AsyncData(state.requireValue.copyWith(homeContentMode: mode));
  }

  Future<void> setLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.languageCode, code);
    state = AsyncData(state.requireValue.copyWith(languageCode: code));
  }

  Future<void> setDifficultyFilter(DifficultyFilter filter) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(SettingsKeys.difficulty, filter.name);
    state = AsyncData(state.requireValue.copyWith(difficultyFilter: filter));
  }

  Future<void> setNotificationTime(TimeOfDay time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.notificationHour, time.hour);
    await prefs.setInt(SettingsKeys.notificationMinute, time.minute);
    state = AsyncData(
      state.requireValue.copyWith(
        notificationHour: time.hour,
        notificationMinute: time.minute,
      ),
    );

    await NotificationService.instance.scheduleDailyReminder(
      hour: time.hour,
      minute: time.minute,
      enabled: state.requireValue.notificationEnabled,
    );
  }

  Future<void> setNotificationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.notificationEnabled, enabled);
    state = AsyncData(
      state.requireValue.copyWith(notificationEnabled: enabled),
    );

    if (!enabled) {
      await NotificationService.instance.cancelDailyReminder();
      return;
    }

    await NotificationService.instance.scheduleDailyReminder(
      hour: state.requireValue.notificationHour,
      minute: state.requireValue.notificationMinute,
      enabled: true,
    );
  }

  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(SettingsKeys.streak, 0);
    state = AsyncData(state.requireValue.copyWith(streak: 0));
  }

  Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_onboarding_seen', true);
    state = AsyncData(state.requireValue.copyWith(onboardingSeen: true));
  }

  DifficultyFilter _fromDifficultyKey(String key) {
    return DifficultyFilter.values.firstWhere(
      (DifficultyFilter value) => value.name == key,
      orElse: () => DifficultyFilter.all,
    );
  }
}

final settingsControllerProvider =
    AsyncNotifierProvider<SettingsController, SettingsState>(
      SettingsController.new,
    );
