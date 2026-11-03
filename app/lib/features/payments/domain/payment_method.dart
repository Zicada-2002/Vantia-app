import 'package:flutter/painting.dart';

/// Medios de pago soportados. El `id` es el valor persistido en Firestore:
/// no cambiarlo sin migración.
enum PaymentMethod {
  yape(id: 'yape', label: 'Yape', color: Color(0xFF742284), isDigital: true),
  plin(id: 'plin', label: 'Plin', color: Color(0xFF00C2CB), isDigital: true),
  bcp(id: 'bcp', label: 'BCP', color: Color(0xFF0A3D8F), isDigital: true),
  interbank(
    id: 'interbank',
    label: 'Interbank',
    color: Color(0xFF05BE50),
    isDigital: true,
  ),
  bbva(id: 'bbva', label: 'BBVA', color: Color(0xFF1464A5), isDigital: true),
  scotiabank(
    id: 'scotiabank',
    label: 'Scotiabank',
    color: Color(0xFFEC111A),
    isDigital: true,
  ),
  cash(
    id: 'cash',
    label: 'Efectivo',
    color: Color(0xFFF4B740),
    isDigital: false,
  );

  const PaymentMethod({
    required this.id,
    required this.label,
    required this.color,
    required this.isDigital,
  });

  final String id;
  final String label;
  final Color color;
  final bool isDigital;

  /// Métodos cuya captura automática por notificación es posible (Android).
  bool get supportsAutoVerification => this == yape || this == plin;

  static PaymentMethod? fromId(String id) {
    for (final m in values) {
      if (m.id == id) return m;
    }
    return null;
  }
}
