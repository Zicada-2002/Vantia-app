import 'package:vantia/app/bootstrap.dart';
import 'package:vantia/app/flavor.dart';

/// Versión de demostración: sin Firebase, con datos de ejemplo en memoria.
Future<void> main() => bootstrap(Flavor.demo, demo: true);
