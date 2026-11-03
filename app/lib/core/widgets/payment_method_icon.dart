import 'package:flutter/material.dart';
import 'package:vantia/app/theme/tokens.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

/// Ícono de un medio de pago.
///
/// Usa un distintivo con el color de la marca y sus iniciales. Los logos
/// oficiales se añadirán en `assets/payment_methods/` cuando se confirme el
/// uso permitido según los lineamientos de marca de cada entidad.
class PaymentMethodIcon extends StatelessWidget {
  const PaymentMethodIcon(this.method, {super.key, this.size = 48});

  final PaymentMethod method;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.22);
    if (method == PaymentMethod.cash) {
      return Semantics(
        label: method.label,
        excludeSemantics: true,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: method.color.withValues(alpha: 0.18),
            borderRadius: radius,
          ),
          child: Icon(
            Icons.payments_rounded,
            color: method.color,
            size: size * 0.6,
          ),
        ),
      );
    }
    return Semantics(
      label: method.label,
      excludeSemantics: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: method.color, borderRadius: radius),
        child: Text(
          _monogram(method),
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: size * 0.28,
            fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
          ),
        ),
      ),
    );
  }

  static String _monogram(PaymentMethod m) => switch (m) {
    PaymentMethod.yape => 'yape',
    PaymentMethod.plin => 'plin',
    PaymentMethod.bcp => 'BCP',
    PaymentMethod.interbank => 'IBK',
    PaymentMethod.bbva => 'BBVA',
    PaymentMethod.scotiabank => 'SCO',
    PaymentMethod.cash => 'S/',
  };
}

/// Tile del selector "¿Cómo pagó el cliente?".
class PaymentMethodTile extends StatelessWidget {
  const PaymentMethodTile({
    required this.method,
    required this.onTap,
    super.key,
  });

  final PaymentMethod method;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(VantiaRadius.lg),
      child: InkWell(
        borderRadius: BorderRadius.circular(VantiaRadius.lg),
        onTap: onTap,
        child: Center(child: PaymentMethodIcon(method, size: 64)),
      ),
    );
  }
}
