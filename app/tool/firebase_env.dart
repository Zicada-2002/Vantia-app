// Genera env/<alias>.json a partir del google-services.json que entrega la
// consola de Firebase, y actualiza el alias en firebase/.firebaserc.
//
// Uso (desde app/):
//   dart run tool/firebase_env.dart <ruta/google-services.json> [dev|prod]
//
// - dev  → paquete pe.vantia.app.dev → env/dev.json
// - prod → paquete pe.vantia.app     → env/prod.json
// El archivo generado NO se versiona (ver app/.gitignore).
import 'dart:convert';
import 'dart:io';

const _packages = {'dev': 'pe.vantia.app.dev', 'prod': 'pe.vantia.app'};

void main(List<String> args) {
  if (args.isEmpty || args.length > 2) {
    stderr.writeln(
      'Uso: dart run tool/firebase_env.dart <google-services.json> [dev|prod]',
    );
    exit(64);
  }
  final alias = args.length == 2 ? args[1] : 'dev';
  final package = _packages[alias];
  if (package == null) {
    stderr.writeln('Alias inválido "$alias": usa dev o prod.');
    exit(64);
  }

  final Map<String, dynamic> gs;
  try {
    gs = jsonDecode(File(args[0]).readAsStringSync()) as Map<String, dynamic>;
  } on Object catch (e) {
    stderr.writeln('No se pudo leer ${args[0]}: $e');
    exit(66);
  }

  final info = gs['project_info'] as Map<String, dynamic>;
  final clients = (gs['client'] as List).cast<Map<String, dynamic>>();
  final client = clients.where((c) {
    final ci = c['client_info'] as Map<String, dynamic>;
    final android = ci['android_client_info'] as Map<String, dynamic>?;
    return android?['package_name'] == package;
  }).firstOrNull;
  if (client == null) {
    final found = clients
        .map(
          (c) =>
              ((c['client_info'] as Map)['android_client_info']
                  as Map?)?['package_name'],
        )
        .join(', ');
    stderr.writeln(
      'El archivo no tiene la app Android "$package" (tiene: $found).\n'
      'Registra esa app en Firebase y vuelve a descargar google-services.json.',
    );
    exit(65);
  }

  final projectId = info['project_id'] as String;
  final env = {
    'FIREBASE_PROJECT_ID': projectId,
    'FIREBASE_API_KEY':
        ((client['api_key'] as List).first as Map)['current_key'],
    'FIREBASE_MESSAGING_SENDER_ID': info['project_number'],
    'FIREBASE_ANDROID_APP_ID':
        (client['client_info'] as Map)['mobilesdk_app_id'],
    'FIREBASE_STORAGE_BUCKET': info['storage_bucket'],
    'USE_FIREBASE_EMULATOR': false,
  };
  final out = File('env/$alias.json')
    ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(env)}\n');
  stdout.writeln('✓ ${out.path} generado para "$projectId" ($package)');

  final rc = File('../firebase/.firebaserc');
  if (rc.existsSync()) {
    final json = jsonDecode(rc.readAsStringSync()) as Map<String, dynamic>;
    (json['projects'] as Map<String, dynamic>)[alias] = projectId;
    rc.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(json)}\n',
    );
    stdout.writeln('✓ firebase/.firebaserc: alias "$alias" → $projectId');
  }
}
