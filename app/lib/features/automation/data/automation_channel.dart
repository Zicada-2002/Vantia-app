import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vantia/features/automation/domain/parsers.dart';

/// Puente con el listener nativo de Android (F-71).
abstract interface class AutomationChannel {
  bool get isSupported;
  Future<bool> isPermissionGranted();
  Future<void> openPermissionSettings();
  Future<bool> isIgnoringBatteryOptimizations();
  Future<void> openBatterySettings();
  Future<void> setConfig({required bool enabled, required bool voice});
  Future<List<RawNotification>> drainQueue();
  Stream<RawNotification> get events;
}

class PlatformAutomationChannel implements AutomationChannel {
  static const _methods = MethodChannel('pe.vantia/automation');
  static const _events = EventChannel('pe.vantia/automation/events');

  @override
  bool get isSupported => defaultTargetPlatform == TargetPlatform.android;

  @override
  Future<bool> isPermissionGranted() async =>
      isSupported &&
      (await _methods.invokeMethod<bool>('isPermissionGranted') ?? false);

  @override
  Future<void> openPermissionSettings() =>
      _methods.invokeMethod<void>('openPermissionSettings');

  @override
  Future<bool> isIgnoringBatteryOptimizations() async =>
      isSupported &&
      (await _methods.invokeMethod<bool>('isIgnoringBatteryOptimizations') ??
          false);

  @override
  Future<void> openBatterySettings() =>
      _methods.invokeMethod<void>('openBatterySettings');

  @override
  Future<void> setConfig({required bool enabled, required bool voice}) async {
    if (!isSupported) return;
    await _methods.invokeMethod<void>('setConfig', {
      'enabled': enabled,
      'voice': voice,
    });
  }

  @override
  Future<List<RawNotification>> drainQueue() async {
    if (!isSupported) return const [];
    final raw = await _methods.invokeListMethod<Map<Object?, Object?>>(
      'drainQueue',
    );
    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        RawNotification.fromMap(m),
    ];
  }

  @override
  Stream<RawNotification> get events => isSupported
      ? _events.receiveBroadcastStream().map(
          (e) => RawNotification.fromMap(e as Map<Object?, Object?>),
        )
      : const Stream.empty();
}

/// Para iOS, web y tests.
class NoopAutomationChannel implements AutomationChannel {
  const NoopAutomationChannel();

  @override
  bool get isSupported => false;
  @override
  Future<bool> isPermissionGranted() async => false;
  @override
  Future<void> openPermissionSettings() async {}
  @override
  Future<bool> isIgnoringBatteryOptimizations() async => false;
  @override
  Future<void> openBatterySettings() async {}
  @override
  Future<void> setConfig({required bool enabled, required bool voice}) async {}
  @override
  Future<List<RawNotification>> drainQueue() async => const [];
  @override
  Stream<RawNotification> get events => const Stream.empty();
}
