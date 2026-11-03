import 'package:flutter/foundation.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

enum PaymentSource { manual, ocr, notification }

enum PaymentStatus { active, voided }

@immutable
class PaymentItem {
  const PaymentItem({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  factory PaymentItem.fromJson(Map<String, dynamic> j) => PaymentItem(
    productId: j['productId'] as String? ?? '',
    name: j['name'] as String? ?? '',
    quantity: (j['qty'] as num?)?.toInt() ?? 1,
    unitPrice: Money((j['unitPriceCents'] as num?)?.toInt() ?? 0),
  );

  final String productId;
  final String name;
  final int quantity;
  final Money unitPrice;

  Money get subtotal => unitPrice * quantity;

  Map<String, Object> toJson() => {
    'productId': productId,
    'name': name,
    'qty': quantity,
    'unitPriceCents': unitPrice.cents,
  };
}

/// Un cobro registrado. `amount` es la **venta neta**; en efectivo
/// `amount = received - change`.
@immutable
class Payment {
  const Payment({
    required this.id,
    required this.method,
    required this.amount,
    required this.occurredAt,
    required this.createdBy,
    required this.createdByName,
    this.received,
    this.change,
    this.description,
    this.operationNumber,
    this.payerName,
    this.source = PaymentSource.manual,
    this.verified = false,
    this.status = PaymentStatus.active,
    this.voidReason,
    this.items = const [],
    this.createdAt,
    this.pendingSync = false,
  });

  final String id;
  final PaymentMethod method;
  final Money amount;
  final Money? received;
  final Money? change;
  final String? description;
  final String? operationNumber;
  final String? payerName;
  final DateTime occurredAt;
  final String createdBy;
  final String createdByName;
  final PaymentSource source;
  final bool verified;
  final PaymentStatus status;
  final String? voidReason;
  final List<PaymentItem> items;
  final DateTime? createdAt;

  /// Escrito localmente pero aún no confirmado por el servidor (offline).
  final bool pendingSync;

  bool get isActive => status == PaymentStatus.active;
  bool get isCash => method == PaymentMethod.cash;
  String get dayKey => LimaTime.dayKey(occurredAt);
}

/// Datos que la UI envía para registrar un pago.
@immutable
class PaymentDraft {
  const PaymentDraft({
    required this.method,
    required this.received,
    required this.occurredAt,
    this.change = const Money.zero(),
    this.description,
    this.operationNumber,
    this.payerName,
    this.source = PaymentSource.manual,
    this.verified = false,
    this.items = const [],
  });

  final PaymentMethod method;

  /// Monto que entregó/transfirió el cliente.
  final Money received;

  /// Solo efectivo: vuelto entregado.
  final Money change;
  final DateTime occurredAt;
  final String? description;
  final String? operationNumber;
  final String? payerName;
  final PaymentSource source;
  final bool verified;
  final List<PaymentItem> items;

  Money get net => method.isDigital ? received : received - change;

  /// Devuelve un error de validación o `null`.
  PaymentDraftError? validate({required DateTime now}) {
    if (!received.isPositive) return PaymentDraftError.amountRequired;
    if (change.isNegative) return PaymentDraftError.changeInvalid;
    if (method.isDigital && !change.isZero) {
      return PaymentDraftError.changeInvalid;
    }
    if (change >= received) return PaymentDraftError.changeTooBig;
    if (occurredAt.isAfter(now.add(const Duration(minutes: 5)))) {
      return PaymentDraftError.futureDate;
    }
    return null;
  }
}

enum PaymentDraftError {
  amountRequired,
  changeInvalid,
  changeTooBig,
  futureDate,
}

/// Resumen de un conjunto de pagos (solo activos).
@immutable
class PaymentSummary {
  const PaymentSummary({
    required this.total,
    required this.count,
    required this.cash,
    required this.digital,
    required this.cashCount,
    required this.digitalCount,
    required this.byMethod,
    required this.cashReceived,
    required this.changeGiven,
  });

  factory PaymentSummary.of(Iterable<Payment> payments) {
    var total = const Money.zero();
    var cash = const Money.zero();
    var received = const Money.zero();
    var change = const Money.zero();
    var count = 0;
    var cashCount = 0;
    final byMethod = <PaymentMethod, Money>{};
    for (final p in payments) {
      if (!p.isActive) continue;
      count++;
      total += p.amount;
      byMethod[p.method] =
          (byMethod[p.method] ?? const Money.zero()) + p.amount;
      if (p.isCash) {
        cashCount++;
        cash += p.amount;
        received += p.received ?? p.amount;
        change += p.change ?? const Money.zero();
      }
    }
    return PaymentSummary(
      total: total,
      count: count,
      cash: cash,
      digital: total - cash,
      cashCount: cashCount,
      digitalCount: count - cashCount,
      byMethod: byMethod,
      cashReceived: received,
      changeGiven: change,
    );
  }

  static const empty = PaymentSummary(
    total: Money.zero(),
    count: 0,
    cash: Money.zero(),
    digital: Money.zero(),
    cashCount: 0,
    digitalCount: 0,
    byMethod: {},
    cashReceived: Money.zero(),
    changeGiven: Money.zero(),
  );

  final Money total;
  final int count;
  final Money cash;
  final Money digital;
  final int cashCount;
  final int digitalCount;
  final Map<PaymentMethod, Money> byMethod;

  /// Efectivo bruto recibido y vueltos entregados (para el cuadre de caja).
  final Money cashReceived;
  final Money changeGiven;
}
