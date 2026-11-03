import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:vantia/core/observability/analytics.dart';

/// F-06: Analytics + Crashlytics. Solo se usa con un proyecto real (no en
/// emuladores), ver `bootstrap`.
class FirebaseAnalyticsImpl implements Analytics {
  FirebaseAnalyticsImpl(this._analytics, this._crashlytics);

  final FirebaseAnalytics _analytics;
  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> log(AnalyticsEvent event, [Map<String, Object>? params]) =>
      _analytics.logEvent(name: event.name, parameters: params);

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) => _crashlytics.recordError(error, stack, fatal: fatal);

  @override
  Future<void> setUser(String? uid) async {
    await _analytics.setUserId(id: uid);
    await _crashlytics.setUserIdentifier(uid ?? '');
  }
}
