import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuración de Firebase leída de `--dart-define-from-file=env/<x>.json`.
///
/// - `env/emulator.json` (versionado): proyecto `demo-vantia` contra los
///   emuladores locales; no requiere un proyecto real.
/// - `env/dev.json` / `env/prod.json` (NO versionados): valores reales de la
///   consola de Firebase. Ver `env/dev.json.example`.
abstract final class FirebaseEnv {
  static const projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'demo-vantia',
  );
  static const apiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: 'demo-api-key',
  );
  static const messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '000000000000',
  );
  static const androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
    defaultValue: '1:000000000000:android:0000000000000000',
  );
  static const iosAppId = String.fromEnvironment(
    'FIREBASE_IOS_APP_ID',
    defaultValue: '1:000000000000:ios:0000000000000000',
  );
  static const storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );

  /// Por defecto se usan emuladores si el proyecto es `demo-*`.
  static const useEmulator = bool.fromEnvironment(
    'USE_FIREBASE_EMULATOR',
    defaultValue: projectId == 'demo-vantia',
  );

  /// `10.0.2.2` = la PC vista desde el emulador de Android. En un celular
  /// físico, usar la IP local de la PC (p. ej. `192.168.1.20`).
  static const emulatorHost = String.fromEnvironment(
    'FIREBASE_EMULATOR_HOST',
    defaultValue: '10.0.2.2',
  );

  static const functionsRegion = 'southamerica-east1';

  static FirebaseOptions get options => FirebaseOptions(
    apiKey: apiKey,
    appId: defaultTargetPlatform == TargetPlatform.iOS
        ? iosAppId
        : androidAppId,
    messagingSenderId: messagingSenderId,
    projectId: projectId,
    storageBucket: storageBucket.isEmpty ? null : storageBucket,
    iosBundleId: 'pe.vantia.app',
  );

  static Future<void> initialize() async {
    await Firebase.initializeApp(options: options);
    if (useEmulator) {
      await FirebaseAuth.instance.useAuthEmulator(emulatorHost, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(emulatorHost, 8080);
      FirebaseFunctions.instanceFor(
        region: functionsRegion,
      ).useFunctionsEmulator(emulatorHost, 5001);
    }
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }
}
