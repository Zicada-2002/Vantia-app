import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reloj inyectable (los tests fijan la hora).
typedef Clock = DateTime Function();

final clockProvider = Provider<Clock>((ref) => DateTime.now);
