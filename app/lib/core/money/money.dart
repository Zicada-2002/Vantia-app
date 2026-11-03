import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Monto en soles representado en **céntimos** (entero) para evitar errores
/// de punto flotante. Es la única forma en que la app maneja dinero.
@immutable
class Money implements Comparable<Money> {
  const Money(this.cents);

  const Money.zero() : cents = 0;

  factory Money.fromSoles(num soles) => Money((soles * 100).round());

  /// Interpreta lo que escribe el usuario: `"10"`, `"10.5"`, `"1,234.50"`,
  /// `"10,50"`. Devuelve `null` si no es un monto válido (o tiene más de 2
  /// decimales).
  static Money? tryParse(String input) {
    var text = input.trim().replaceAll(RegExp(r'[S/\s]'), '');
    if (text.isEmpty) return null;

    final lastDot = text.lastIndexOf('.');
    final lastComma = text.lastIndexOf(',');
    if (lastDot >= 0 && lastComma >= 0) {
      // El último separador es el decimal; el otro, de miles.
      final thousands = lastDot > lastComma ? ',' : '.';
      text = text.replaceAll(thousands, '');
      text = text.replaceAll(',', '.');
    } else if (lastComma >= 0) {
      // Solo comas: decimal si hay 1-2 dígitos después de la última coma.
      final decimals = text.length - lastComma - 1;
      text = (decimals <= 2 && text.indexOf(',') == lastComma)
          ? text.replaceAll(',', '.')
          : text.replaceAll(',', '');
    }

    final match = RegExp(r'^(\d+)(?:\.(\d{0,2}))?$').firstMatch(text);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return Money(whole * 100 + int.parse(fraction));
  }

  final int cents;

  bool get isZero => cents == 0;
  bool get isNegative => cents < 0;
  bool get isPositive => cents > 0;

  Money operator +(Money other) => Money(cents + other.cents);
  Money operator -(Money other) => Money(cents - other.cents);
  Money operator -() => Money(-cents);
  Money operator *(int factor) => Money(cents * factor);
  bool operator >(Money other) => cents > other.cents;
  bool operator <(Money other) => cents < other.cents;
  bool operator >=(Money other) => cents >= other.cents;
  bool operator <=(Money other) => cents <= other.cents;

  Money abs() => Money(cents.abs());

  // Agregación sobre una colección; se lee mejor como `Money.sum(...)`.
  // ignore: prefer_constructors_over_static_methods
  static Money sum(Iterable<Money> values) =>
      values.fold(const Money.zero(), (a, b) => a + b);

  static final NumberFormat _format = NumberFormat('#,##0.00', 'en_US');

  /// `S/ 1,234.50` (formato usual en Perú). Negativos: `-S/ 5.00`.
  String format({bool withSymbol = true}) {
    final body = _format.format(cents.abs() / 100);
    final sign = isNegative ? '-' : '';
    return withSymbol ? '${sign}S/ $body' : '$sign$body';
  }

  @override
  int compareTo(Money other) => cents.compareTo(other.cents);

  @override
  bool operator ==(Object other) => other is Money && other.cents == cents;

  @override
  int get hashCode => cents.hashCode;

  @override
  String toString() => format();
}
