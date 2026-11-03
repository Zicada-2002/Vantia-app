import 'package:flutter/foundation.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';

/// Notificación cruda capturada en Android.
@immutable
class RawNotification {
  const RawNotification({
    required this.packageName,
    required this.title,
    required this.text,
    required this.postedAt,
  });

  factory RawNotification.fromMap(Map<Object?, Object?> m) => RawNotification(
    packageName: m['package'] as String? ?? '',
    title: m['title'] as String? ?? '',
    text: m['text'] as String? ?? '',
    postedAt: DateTime.fromMillisecondsSinceEpoch(
      (m['postedAt'] as num?)?.toInt() ?? 0,
    ),
  );

  final String packageName;
  final String title;
  final String text;
  final DateTime postedAt;
}

/// Pago detectado en una notificación o comprobante.
@immutable
class DetectedPayment {
  const DetectedPayment({
    required this.method,
    required this.amount,
    this.payerName,
    this.operationNumber,
    this.occurredAt,
  });

  final PaymentMethod method;
  final Money amount;
  final String? payerName;
  final String? operationNumber;
  final DateTime? occurredAt;
}

/// Patrón versionado de una app. Los textos de Yape/Plin cambian con el
/// tiempo: los patrones son datos (se podrán actualizar por Remote Config).
@immutable
class NotificationPattern {
  const NotificationPattern({
    required this.packages,
    required this.method,
    required this.regex,
  });

  /// Paquetes Android que publican la notificación.
  final Set<String> packages;
  final PaymentMethod method;

  /// Debe tener los grupos con nombre `amount` y, opcionalmente, `name`.
  final RegExp regex;
}

/// Paquetes conocidos (Plin vive dentro de las apps bancarias).
abstract final class KnownPackages {
  static const yape = 'com.bcp.innovacxion.yapeapp';
  static const interbank = 'pe.com.interbank.mobilebanking';
  static const bbva = 'com.bbva.nxt_peru';
  static const scotiabank = 'pe.com.scotiabank.blpm.android.client';
  static const bcp = 'com.bcp.bank.bcp';

  static const Set<String> all = {yape, interbank, bbva, scotiabank, bcp};
}

const _amount =
    r'S\/\.?\s*(?<amount>\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)';

/// Patrones v1 (2026-11). Fixtures en test/fixtures/notifications/.
final defaultNotificationPatterns = <NotificationPattern>[
  NotificationPattern(
    packages: const {KnownPackages.yape},
    method: PaymentMethod.yape,
    regex: RegExp(
      '(?:Yape!\\s*)?(?<name>[^!\\n]+?) te envi[oó] un pago por $_amount',
      caseSensitive: false,
    ),
  ),
  NotificationPattern(
    packages: const {
      KnownPackages.interbank,
      KnownPackages.bbva,
      KnownPackages.scotiabank,
    },
    method: PaymentMethod.plin,
    regex: RegExp(
      '(?<name>[^!\\n]+?) te (?:ha )?(?:plineado|envi[oó] un plin(?: por)?|transfiri[oó] por plin)\\s*$_amount',
      caseSensitive: false,
    ),
  ),
  NotificationPattern(
    packages: const {KnownPackages.bcp},
    method: PaymentMethod.bcp,
    regex: RegExp(
      '(?:recibiste|te transfiri[oó]|abono de)\\s+$_amount(?:\\s+de\\s+(?<name>[^.\\n]+))?',
      caseSensitive: false,
    ),
  ),
];

abstract final class NotificationParser {
  static DetectedPayment? parse(
    RawNotification n, {
    List<NotificationPattern>? patterns,
  }) {
    final text = '${n.title}\n${n.text}'.replaceAll(' ', ' ');
    for (final p in patterns ?? defaultNotificationPatterns) {
      if (!p.packages.contains(n.packageName)) continue;
      final m = p.regex.firstMatch(text);
      if (m == null) continue;
      final amount = parseAmount(m.namedGroup('amount') ?? '');
      if (amount == null || !amount.isPositive) continue;
      return DetectedPayment(
        method: p.method,
        amount: amount,
        payerName: _cleanName(_group(m, 'name')),
        occurredAt: n.postedAt,
      );
    }
    return null;
  }

  static String? _group(RegExpMatch m, String name) =>
      m.groupNames.contains(name) ? m.namedGroup(name) : null;
}

/// `10`, `10.5`, `1,234.50`, `1.234,50` → Money.
Money? parseAmount(String raw) => Money.tryParse(raw.trim());

String? _cleanName(String? raw) {
  final t = raw?.trim().replaceAll(RegExp(r'\s+'), ' ');
  if (t == null || t.isEmpty) return null;
  return t.length > 60 ? t.substring(0, 60) : t;
}

/// F-70: extrae datos de un comprobante a partir del texto del OCR.
abstract final class ReceiptParser {
  static final _amountRe = RegExp(_amount);
  static final _operationRe = RegExp(
    r'(?:n(?:ro|°|º|úmero)?\.?\s*(?:de\s*)?operaci[oó]n|c[oó]d(?:igo|\.)?\s*(?:de\s*)?operaci[oó]n|operaci[oó]n\s*n[°º]?)\s*[:#]?\s*(?<op>\d{5,20})',
    caseSensitive: false,
  );
  static final _dateRe = RegExp(
    r'(?<d>\d{1,2})\s*(?:de\s+)?(?<m>ene|feb|mar|abr|may|jun|jul|ago|set|sep|oct|nov|dic)[a-z]*\.?\s*(?:de\s+)?(?<y>\d{4})?(?:\s*[-,]?\s*(?<h>\d{1,2}):(?<min>\d{2})\s*(?<ampm>[ap]\.?\s*m\.?)?)?',
    caseSensitive: false,
  );
  static final _numericDateRe = RegExp(
    r'(?<d>\d{1,2})/(?<m>\d{1,2})/(?<y>\d{4})(?:\s+(?<h>\d{1,2}):(?<min>\d{2})\s*(?<ampm>[ap]\.?\s*m\.?)?)?',
    caseSensitive: false,
  );
  static const _months = {
    'ene': 1,
    'feb': 2,
    'mar': 3,
    'abr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'ago': 8,
    'set': 9,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dic': 12,
  };

  /// [limaYear] completa fechas sin año. La fecha devuelta es hora de pared
  /// de Lima (UTC sin conversión).
  static ({
    PaymentMethod? method,
    Money? amount,
    String? operationNumber,
    String? payerName,
    DateTime? limaDateTime,
  })
  parse(String ocrText, {required int limaYear}) {
    final text = ocrText.replaceAll(' ', ' ');
    final lower = text.toLowerCase();

    final method = lower.contains('yape')
        ? PaymentMethod.yape
        : lower.contains('plin')
        ? PaymentMethod.plin
        : lower.contains('interbank')
        ? PaymentMethod.interbank
        : lower.contains('bbva')
        ? PaymentMethod.bbva
        : lower.contains('scotiabank')
        ? PaymentMethod.scotiabank
        : lower.contains('bcp')
        ? PaymentMethod.bcp
        : null;

    // El monto más grande del comprobante suele ser el importe pagado.
    Money? amount;
    for (final m in _amountRe.allMatches(text)) {
      final v = parseAmount(m.namedGroup('amount')!);
      if (v != null && (amount == null || v > amount)) amount = v;
    }

    final op = _operationRe.firstMatch(text)?.namedGroup('op');

    DateTime? when;
    final dm = _dateRe.firstMatch(text) ?? _numericDateRe.firstMatch(text);
    if (dm != null) {
      final mRaw = dm.namedGroup('m')!.toLowerCase();
      final month = int.tryParse(mRaw) ?? _months[mRaw.substring(0, 3)];
      final day = int.parse(dm.namedGroup('d')!);
      final year = int.tryParse(dm.namedGroup('y') ?? '') ?? limaYear;
      var hour = int.tryParse(dm.namedGroup('h') ?? '') ?? 12;
      final minute = int.tryParse(dm.namedGroup('min') ?? '') ?? 0;
      final ampm = dm
          .namedGroup('ampm')
          ?.toLowerCase()
          .replaceAll(RegExp(r'[.\s]'), '');
      if (ampm == 'pm' && hour < 12) hour += 12;
      if (ampm == 'am' && hour == 12) hour = 0;
      if (month != null && day >= 1 && day <= 31) {
        when = DateTime.utc(year, month, day, hour, minute);
      }
    }

    String? payer;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    for (var i = 0; i < lines.length; i++) {
      final l = lines[i].toLowerCase();
      if (RegExp(
        r'^(nombre|de|enviado por|yapeaste a|te yape[oó]|destino|origen)\b',
      ).hasMatch(l)) {
        final sameLine = lines[i].split(':').skip(1).join(':').trim();
        final candidate = sameLine.isNotEmpty
            ? sameLine
            : (i + 1 < lines.length ? lines[i + 1] : '');
        if (candidate.isNotEmpty && !_amountRe.hasMatch(candidate)) {
          payer = _cleanName(candidate);
          break;
        }
      }
    }

    return (
      method: method,
      amount: amount,
      operationNumber: op,
      payerName: payer,
      limaDateTime: when,
    );
  }
}
