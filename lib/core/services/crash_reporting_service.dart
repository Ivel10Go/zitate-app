import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/settings_keys.dart';

/// Optional Crashlytics bootstrap.
///
/// This service is fail-safe by design: if Firebase is not configured yet,
/// initialization errors are logged and app startup continues.
class CrashReportingService {
  CrashReportingService._();

  static final CrashReportingService _instance = CrashReportingService._();
  factory CrashReportingService() => _instance;

  bool _enabled = false;
  bool _firebaseReady = false;
  Future<void>? _initializationFuture;

  Future<void> initialize() async {
    final pendingInitialization = _initializationFuture;
    if (pendingInitialization != null) {
      return pendingInitialization;
    }

    final future = _initializeInternal();
    _initializationFuture = future;
    try {
      await future;
    } finally {
      _initializationFuture = null;
    }
  }

  Future<void> _initializeInternal() async {
    if (!kReleaseMode) {
      debugPrint('[CrashReporting] Skipping Crashlytics in non-release mode');
      return;
    }

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;

      final prefs = await SharedPreferences.getInstance();
      final consentEnabled =
          prefs.getBool(SettingsKeys.crashReportingEnabled) ?? false;
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        consentEnabled,
      );
      _enabled = consentEnabled;

      final previousFlutterOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        if (_enabled) {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        }
        previousFlutterOnError?.call(details);
      };

      final previousOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        if (_enabled) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        }
        return previousOnError?.call(error, stack) ?? false;
      };

      debugPrint('[CrashReporting] Crashlytics initialized');
    } catch (e, st) {
      _enabled = false;
      debugPrint('[CrashReporting] Initialization skipped: $e');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> recordUnhandled(Object error, StackTrace stackTrace) async {
    if (!_enabled) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stackTrace,
      fatal: true,
    );
  }

  Future<void> setUserConsent(bool enabled) async {
    final pendingInitialization = _initializationFuture;
    if (pendingInitialization != null) {
      await pendingInitialization;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(SettingsKeys.crashReportingEnabled, enabled);
    if (_firebaseReady) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        enabled,
      );
    }
    _enabled = enabled;
  }
}
