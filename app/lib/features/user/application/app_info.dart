import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Versión y build de la app.
final appInfoProvider = FutureProvider<({String version, String build})>((
  ref,
) async {
  final info = await PackageInfo.fromPlatform();
  return (version: info.version, build: info.buildNumber);
});

/// Número de WhatsApp de soporte (`--dart-define=SUPPORT_WHATSAPP=51987654321`).
const supportWhatsapp = String.fromEnvironment('SUPPORT_WHATSAPP');
