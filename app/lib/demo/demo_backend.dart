import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:vantia/app/providers.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/time/lima_time.dart';
import 'package:vantia/demo/demo_repositories.dart';
import 'package:vantia/features/automation/application/receipt_providers.dart';
import 'package:vantia/features/automation/data/receipt_scanner.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/cash_register/application/cash_providers.dart';
import 'package:vantia/features/collaborators/application/collaborator_providers.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';
import 'package:vantia/features/notifications/push_service.dart';
import 'package:vantia/features/payments/application/payment_providers.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/payments/domain/payment_repository.dart';
import 'package:vantia/features/products/application/product_providers.dart';
import 'package:vantia/features/products/domain/product.dart';
import 'package:vantia/features/reports/application/report_providers.dart';
import 'package:vantia/features/reports/data/reports_repository.dart';
import 'package:vantia/features/reports/domain/report.dart';

/// `true` cuando la app corre en modo demo (sin Firebase).
final demoModeProvider = Provider<bool>((ref) => false);

/// Cuenta de demostración precargada.
const demoEmail = 'demo@vantia.pe';
const demoPassword = 'demo1234';
const _ownerUid = 'uid-$demoEmail';
const _anaUid = 'uid-ana@vantia.pe';
const _bid = 'demo-biz';

/// Reportes calculados en vivo a partir de los pagos en memoria.
class DemoReportsRepository implements ReportsRepository {
  DemoReportsRepository(this._payments);

  final DemoPaymentRepository _payments;

  @override
  Stream<List<DailyStat>> watchDailyStats(
    String businessId, {
    required String fromKey,
    required String toKey,
  }) => _payments
      .watchRecent(PaymentScope(businessId: businessId), limit: 1 << 30)
      .map((all) {
        final byDay = <String, List<Payment>>{};
        for (final p in all) {
          if (p.dayKey.compareTo(fromKey) < 0 ||
              p.dayKey.compareTo(toKey) >= 0) {
            continue;
          }
          byDay.putIfAbsent(p.dayKey, () => []).add(p);
        }
        return [
          for (final e in byDay.entries)
            () {
              final s = PaymentSummary.of(e.value);
              return DailyStat(
                dayKey: e.key,
                total: s.total,
                count: s.count,
                cashCount: s.cashCount,
                digitalCount: s.digitalCount,
                byMethod: s.byMethod,
              );
            }(),
        ];
      });
}

class _NoReceiptStorage implements ReceiptStorage {
  @override
  Future<String?> upload(String businessId, String localPath) async => null;
}

/// Crea el backend demo con datos de ejemplo y devuelve los overrides.
List<Override> demoOverrides() {
  final now = DateTime.now();
  final auth = DemoAuthRepository()
    ..verifyOnNextReload = true
    ..accounts[demoEmail] = demoPassword
    ..names[demoEmail] = 'Carlos Demo';
  final business = DemoBusinessRepository(auth)
    ..seedBusiness(
      Business(
        id: _bid,
        name: 'Bodega Demo',
        ownerUid: _ownerUid,
        phone: '987654321',
        department: 'Lima',
        province: 'Lima',
        planTier: 'trial',
        trialEndsAt: now.add(const Duration(days: 7)),
      ),
    )
    ..seedProfile(
      UserProfile(
        uid: _ownerUid,
        displayName: 'Carlos Demo',
        email: demoEmail,
        phone: '987654321',
        activeBusinessId: _bid,
        role: MemberRole.owner,
        createdAt: now.subtract(const Duration(days: 40)),
      ),
    );

  final payments = DemoPaymentRepository();
  _seedPayments(payments, now);

  final collaborators = DemoCollaboratorRepository()
    ..members.addAll([
      Member(
        uid: _ownerUid,
        displayName: 'Carlos Demo',
        role: MemberRole.owner,
        active: true,
        joinedAt: now.subtract(const Duration(days: 40)),
      ),
      Member(
        uid: _anaUid,
        displayName: 'Ana Torres',
        role: MemberRole.collaborator,
        active: true,
        joinedAt: now.subtract(const Duration(days: 20)),
      ),
    ]);

  final products = DemoProductRepository();
  for (final (i, (name, cents, barcode, stock, cat)) in const [
    ('Gaseosa 500 ml', 250, '7750182000123', 24, 'Bebidas'),
    ('Agua 625 ml', 150, '7750182000456', 30, 'Bebidas'),
    ('Pan francés', 50, null, null, 'Panadería'),
    ('Galletas soda', 120, '7751271000789', 18, 'Snacks'),
    ('Arroz 1 kg', 450, '7751271000111', 12, 'Abarrotes'),
    ('Aceite 1 L', 1090, '7751271000222', 8, 'Abarrotes'),
    ('Leche evaporada', 420, '7751271000333', 20, 'Lácteos'),
    ('Menú del día', 1200, null, null, 'Comidas'),
  ].indexed) {
    products.seed(
      Product(
        id: 'prod-$i',
        name: name,
        price: Money(cents),
        barcode: barcode,
        stock: stock,
        category: cat,
      ),
    );
  }

  final cash = DemoCashRepository(payments)
    ..currentUid = () => auth.currentUser?.uid;

  return [
    demoModeProvider.overrideWithValue(true),
    authRepositoryProvider.overrideWithValue(auth),
    businessRepositoryProvider.overrideWithValue(business),
    paymentRepositoryProvider.overrideWithValue(payments),
    collaboratorRepositoryProvider.overrideWithValue(collaborators),
    cashRepositoryProvider.overrideWithValue(cash),
    productRepositoryProvider.overrideWithValue(products),
    reportsRepositoryProvider.overrideWithValue(
      DemoReportsRepository(payments),
    ),
    receiptStorageProvider.overrideWithValue(_NoReceiptStorage()),
    pushServiceProvider.overrideWithValue(const NoopPushService()),
  ];
}

/// ~5 semanas de ventas variadas (deterministas) para que Inicio, Pagos,
/// Caja y Reportes tengan datos.
void _seedPayments(DemoPaymentRepository repo, DateTime now) {
  final rnd = Random(42);
  final todayStart = LimaTime.startOfDay(now);
  const methods = [
    PaymentMethod.yape,
    PaymentMethod.yape,
    PaymentMethod.yape,
    PaymentMethod.plin,
    PaymentMethod.plin,
    PaymentMethod.cash,
    PaymentMethod.cash,
    PaymentMethod.cash,
    PaymentMethod.bcp,
    PaymentMethod.interbank,
    PaymentMethod.bbva,
    PaymentMethod.scotiabank,
  ];
  const payers = [
    'Juan Pérez',
    'María Rojas',
    'Luis Quispe',
    'Rosa Díaz',
    'Pedro Huamán',
  ];
  var n = 0;
  for (var d = 35; d >= 0; d--) {
    final dayStart = todayStart.subtract(Duration(days: d));
    final count = d == 0 ? 4 : 3 + rnd.nextInt(6);
    for (var i = 0; i < count; i++) {
      final at = dayStart.add(
        Duration(hours: 13 + rnd.nextInt(11), minutes: rnd.nextInt(60)),
      );
      if (at.isAfter(now)) continue;
      final method = methods[rnd.nextInt(methods.length)];
      final cents = (300 + rnd.nextInt(7700)) ~/ 10 * 10;
      final byAna = rnd.nextInt(3) == 0;
      final change = method == PaymentMethod.cash && rnd.nextBool()
          ? (rnd.nextInt(5) + 1) * 100
          : 0;
      repo.seed(
        Payment(
          id: 'seed-${n++}',
          method: method,
          amount: Money(cents),
          received: method == PaymentMethod.cash ? Money(cents + change) : null,
          change: method == PaymentMethod.cash ? Money(change) : null,
          payerName: method.isDigital
              ? payers[rnd.nextInt(payers.length)]
              : null,
          operationNumber: method.isDigital
              ? '${10000000 + rnd.nextInt(89999999)}'
              : null,
          occurredAt: at,
          createdBy: byAna ? _anaUid : _ownerUid,
          createdByName: byAna ? 'Ana Torres' : 'Carlos Demo',
          source: method.supportsAutoVerification && rnd.nextBool()
              ? PaymentSource.notification
              : PaymentSource.manual,
          verified: method.supportsAutoVerification,
          createdAt: at,
        ),
      );
    }
  }
}
