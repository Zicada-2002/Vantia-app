import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vantia/app/app.dart';
import 'package:vantia/app/firebase/firebase_env.dart';
import 'package:vantia/app/flavor.dart';
import 'package:vantia/app/theme/theme_mode_controller.dart';
import 'package:vantia/core/observability/analytics.dart';
import 'package:vantia/core/observability/firebase_analytics_impl.dart';

final flavorProvider = Provider<Flavor>((ref) => Flavor.dev);

/// Punto de arranque común a todos los flavors.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  Intl.defaultLocale = 'es';
  await initializeDateFormatting('es');
  final prefs = await SharedPreferences.getInstance();
  await FirebaseEnv.initialize();

  // F-06: con emuladores (proyecto demo) se usa el logger de depuración.
  final analytics = FirebaseEnv.useEmulator
      ? const DebugAnalytics()
      : FirebaseAnalyticsImpl(
          FirebaseAnalytics.instance,
          FirebaseCrashlytics.instance,
        );
  if (!FirebaseEnv.useEmulator) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      !kDebugMode,
    );
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(analytics.recordError(details.exception, details.stack));
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(analytics.recordError(error, stack, fatal: true));
    return true;
  };

  runApp(
    ProviderScope(
      overrides: [
        flavorProvider.overrideWithValue(flavor),
        sharedPreferencesProvider.overrideWithValue(prefs),
        analyticsProvider.overrideWithValue(analytics),
      ],
      child: const VantiaApp(),
    ),
  );
}
