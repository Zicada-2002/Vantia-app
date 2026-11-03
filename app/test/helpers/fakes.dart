import 'dart:async';

import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/result/failure.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/auth/domain/auth_failure.dart';
import 'package:vantia/features/auth/domain/auth_repository.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';
import 'package:vantia/features/automation/data/automation_channel.dart';
import 'package:vantia/features/automation/data/receipt_scanner.dart';
import 'package:vantia/features/automation/domain/parsers.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/business/domain/business_failure.dart';
import 'package:vantia/features/business/domain/business_repository.dart';
import 'package:vantia/features/cash_register/domain/cash_session.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/payments/domain/payment_repository.dart';
import 'package:vantia/features/products/domain/product.dart';
import 'package:vantia/features/reports/data/reports_repository.dart';
import 'package:vantia/features/reports/domain/report.dart';
import 'package:vantia/features/subscription/data/subscription_service.dart';

/// Auth en memoria con el mismo contrato que Firebase.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthUser? initial}) : _user = initial;

  AuthUser? _user;
  final _changes = StreamController<AuthUser?>.broadcast();

  /// Cuentas registradas: email → password.
  final accounts = <String, String>{};
  int verificationEmailsSent = 0;
  final passwordResets = <String>[];

  /// Simula que el usuario abrió el enlace del correo.
  bool verifyOnNextReload = false;

  void _emit(AuthUser? u) {
    _user = u;
    _changes.add(u);
  }

  @override
  Stream<AuthUser?> userChanges() async* {
    yield _user;
    yield* _changes.stream;
  }

  @override
  AuthUser? get currentUser => _user;

  @override
  Future<Result<void>> signUp({
    required String displayName,
    required String email,
    required String password,
  }) async {
    if (accounts.containsKey(email)) {
      return const Err(AuthFailure(AuthErrorCode.emailAlreadyInUse));
    }
    accounts[email] = password;
    verificationEmailsSent++;
    _emit(
      AuthUser(
        uid: 'uid-$email',
        email: email,
        emailVerified: false,
        displayName: displayName,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> signIn({
    required String email,
    required String password,
  }) async {
    if (accounts[email] != password) {
      return const Err(AuthFailure(AuthErrorCode.invalidCredentials));
    }
    _emit(AuthUser(uid: 'uid-$email', email: email, emailVerified: true));
    return const Ok(null);
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    verificationEmailsSent++;
    return const Ok(null);
  }

  @override
  Future<Result<AuthUser?>> reload() async {
    final u = _user;
    if (u != null && verifyOnNextReload) {
      _emit(
        AuthUser(
          uid: u.uid,
          email: u.email,
          emailVerified: true,
          displayName: u.displayName,
        ),
      );
    }
    return Ok(_user);
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    passwordResets.add(email);
    return const Ok(null);
  }

  @override
  Future<void> signOut() async => _emit(null);

  final passwordChanges = <String>[];
  final emailChanges = <String>[];

  bool _checkPassword(String p) =>
      accounts.isEmpty ||
      accounts[_user?.email] == null ||
      accounts[_user!.email] == p;

  @override
  Future<Result<void>> reauthenticate(String password) async =>
      _checkPassword(password)
      ? const Ok(null)
      : const Err(AuthFailure(AuthErrorCode.invalidCredentials));

  @override
  Future<Result<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (!_checkPassword(currentPassword)) {
      return const Err(AuthFailure(AuthErrorCode.invalidCredentials));
    }
    passwordChanges.add(newPassword);
    return const Ok(null);
  }

  @override
  Future<Result<void>> changeEmail({
    required String currentPassword,
    required String newEmail,
  }) async {
    if (!_checkPassword(currentPassword)) {
      return const Err(AuthFailure(AuthErrorCode.invalidCredentials));
    }
    emailChanges.add(newEmail);
    return const Ok(null);
  }

  @override
  Future<Result<void>> updateDisplayName(String name) async => const Ok(null);
}

class FakeBusinessRepository implements BusinessRepository {
  final _profiles = <String, UserProfile>{};
  final _businesses = <String, Business>{};
  final _profileCtl = StreamController<UserProfile>.broadcast();
  final _businessCtl = StreamController<Business>.broadcast();

  /// Códigos válidos: code → businessId.
  final invites = <String, String>{};

  /// uid que usarán createBusiness/redeemInvite (simula el token).
  String? currentUid;

  void seedProfile(UserProfile p) {
    _profiles[p.uid] = p;
    _profileCtl.add(p);
  }

  void seedBusiness(Business b) {
    _businesses[b.id] = b;
    _businessCtl.add(b);
  }

  @override
  Stream<UserProfile?> watchProfile(String uid) async* {
    yield _profiles[uid];
    yield* _profileCtl.stream.where((p) => p.uid == uid);
  }

  @override
  Stream<Business?> watchBusiness(String businessId) async* {
    yield _businesses[businessId];
    yield* _businessCtl.stream.where((b) => b.id == businessId);
  }

  @override
  Future<Result<String>> createBusiness(CreateBusinessInput input) async {
    final uid = currentUid!;
    final id = 'biz-${_businesses.length + 1}';
    seedBusiness(
      Business(
        id: id,
        name: input.name,
        ownerUid: uid,
        phone: input.phone,
        department: input.department,
        province: input.province,
      ),
    );
    seedProfile(
      UserProfile(
        uid: uid,
        displayName: 'Dueño',
        email: '',
        activeBusinessId: id,
        role: MemberRole.owner,
      ),
    );
    return Ok(id);
  }

  final profileUpdates = <(String, String?)>[];
  final prefsUpdates = <Map<String, Object>>[];
  bool deleted = false;

  @override
  Future<Result<void>> updateProfile(
    String uid, {
    required String displayName,
    String? phone,
  }) async {
    profileUpdates.add((displayName, phone));
    final p = _profiles[uid]!;
    seedProfile(
      UserProfile(
        uid: uid,
        displayName: displayName,
        email: p.email,
        phone: phone,
        activeBusinessId: p.activeBusinessId,
        role: p.role,
        createdAt: p.createdAt,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<Result<void>> updatePrefs(
    String uid,
    Map<String, Object> prefs,
  ) async {
    prefsUpdates.add(prefs);
    return const Ok(null);
  }

  @override
  Future<Result<void>> deleteAccount() async {
    deleted = true;
    return const Ok(null);
  }

  @override
  Future<Result<String>> redeemInvite(String code) async {
    final bid = invites.remove(code);
    if (bid == null) {
      return const Err(BusinessFailure(BusinessErrorCode.inviteInvalid));
    }
    seedProfile(
      UserProfile(
        uid: currentUid!,
        displayName: 'Colaborador',
        email: '',
        activeBusinessId: bid,
        role: MemberRole.collaborator,
      ),
    );
    return Ok(bid);
  }
}

/// Negocio de ejemplo en prueba Pro (vence en 7 días desde [fixedNow]).
final demoBusiness = Business(
  id: 'biz-demo',
  name: 'Vantia Peru',
  ownerUid: 'uid-owner',
  phone: '917926826',
  department: 'Lima',
  province: 'Lima',
  planTier: 'trial',
  trialEndsAt: fixedNow.add(const Duration(days: 7)),
);

const freeBusiness = Business(
  id: 'biz-demo',
  name: 'Vantia Peru',
  ownerUid: 'uid-owner',
  phone: '917926826',
  department: 'Lima',
  province: 'Lima',
);

/// Repos con un dueño ya logueado, verificado y con negocio.
({FakeAuthRepository auth, FakeBusinessRepository business}) readyOwnerRepos() {
  final auth = FakeAuthRepository(
    initial: const AuthUser(
      uid: 'uid-owner',
      email: 'owner@vantia.pe',
      emailVerified: true,
    ),
  );
  final business = FakeBusinessRepository()
    ..currentUid = 'uid-owner'
    ..seedBusiness(demoBusiness)
    ..seedProfile(
      const UserProfile(
        uid: 'uid-owner',
        displayName: 'Carlos',
        email: 'owner@vantia.pe',
        activeBusinessId: 'biz-demo',
        role: MemberRole.owner,
      ),
    );
  return (auth: auth, business: business);
}

/// Pagos en memoria con filtros de alcance y rango como Firestore.
class FakePaymentRepository implements PaymentRepository {
  FakePaymentRepository({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final payments = <String, Payment>{};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  void seed(Payment p) {
    payments[p.id] = p;
    _changes.add(null);
  }

  Iterable<Payment> _scoped(PaymentScope s) => payments.values.where(
    (p) => s.onlyCreatedBy == null || p.createdBy == s.onlyCreatedBy,
  );

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  List<Payment> _sorted(Iterable<Payment> it) =>
      it.toList()..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  @override
  Stream<List<Payment>> watchRange(
    PaymentScope scope, {
    required DateTime from,
    required DateTime to,
  }) => _live(
    () => _sorted(
      _scoped(
        scope,
      ).where((p) => !p.occurredAt.isBefore(from) && p.occurredAt.isBefore(to)),
    ),
  );

  @override
  Stream<List<Payment>> watchRecent(PaymentScope scope, {int limit = 10}) =>
      _live(() => _sorted(_scoped(scope)).take(limit).toList());

  @override
  Stream<Payment?> watch(String businessId, String paymentId) =>
      _live(() => payments[paymentId]);

  @override
  Future<Result<String>> create({
    required String businessId,
    required String userId,
    required String userName,
    required PaymentDraft draft,
    String? id,
  }) async {
    if (id != null && payments.containsKey(id)) {
      return const Err(PermissionFailure('ya existe'));
    }
    final pid = id ?? 'pay-${++_seq}';
    seed(
      Payment(
        id: pid,
        method: draft.method,
        amount: draft.net,
        payerName: draft.payerName,
        receiptPath: draft.receiptPath,
        received: draft.method == PaymentMethod.cash ? draft.received : null,
        change: draft.method == PaymentMethod.cash ? draft.change : null,
        description: draft.description?.trim().isEmpty ?? true
            ? null
            : draft.description,
        operationNumber: draft.operationNumber?.trim().isEmpty ?? true
            ? null
            : draft.operationNumber,
        occurredAt: draft.occurredAt,
        createdBy: userId,
        createdByName: userName,
        source: draft.source,
        verified: draft.verified,
        items: draft.items,
        createdAt: _clock(),
      ),
    );
    return Ok(pid);
  }

  @override
  Future<Result<void>> voidPayment({
    required String businessId,
    required String paymentId,
    required String userId,
    required String reason,
  }) async {
    final p = payments[paymentId]!;
    seed(
      Payment(
        id: p.id,
        method: p.method,
        amount: p.amount,
        received: p.received,
        change: p.change,
        occurredAt: p.occurredAt,
        createdBy: p.createdBy,
        createdByName: p.createdByName,
        status: PaymentStatus.voided,
        voidReason: reason,
        createdAt: p.createdAt,
      ),
    );
    return const Ok(null);
  }

  @override
  Future<bool> existsOperation(
    PaymentScope scope, {
    required String method,
    required String operationNumber,
  }) async => _scoped(
    scope,
  ).any((p) => p.method.id == method && p.operationNumber == operationNumber);
}

/// 2 nov 2026 21:46 en Lima (lunes).
final fixedNow = DateTime.utc(2026, 11, 3, 2, 46);

Payment fakePayment({
  required String id,
  required int cents,
  PaymentMethod method = PaymentMethod.yape,
  DateTime? at,
  String createdBy = 'uid-owner',
  String createdByName = 'Carlos',
  int? receivedCents,
  int? changeCents,
}) => Payment(
  id: id,
  method: method,
  amount: Money(cents),
  received: receivedCents == null ? null : Money(receivedCents),
  change: changeCents == null ? null : Money(changeCents),
  occurredAt: at ?? fixedNow,
  createdBy: createdBy,
  createdByName: createdByName,
  createdAt: at ?? fixedNow,
);

class FakeCollaboratorRepository implements CollaboratorRepository {
  final invites = <Invite>[];
  final members = <Member>[];
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;
  final setActiveCalls = <(String, bool)>[];

  void _notify() => _changes.add(null);

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<List<Invite>> watchInvites(String businessId) =>
      _live(() => List.of(invites.reversed));

  @override
  Stream<List<Member>> watchMembers(String businessId) =>
      _live(() => List.of(members));

  @override
  Future<Result<({String code, DateTime expiresAt})>> generateInvite() async {
    final code = 'ABC23${++_seq}';
    final expiresAt = fixedNow.add(const Duration(hours: 48));
    invites.add(
      Invite(code: code, status: InviteStatus.active, expiresAt: expiresAt),
    );
    _notify();
    return Ok((code: code, expiresAt: expiresAt));
  }

  @override
  Future<Result<void>> revokeInvite(String code) async {
    final i = invites.indexWhere((x) => x.code == code);
    invites[i] = Invite(
      code: code,
      status: InviteStatus.revoked,
      expiresAt: invites[i].expiresAt,
    );
    _notify();
    return const Ok(null);
  }

  @override
  Future<Result<void>> setMemberActive(
    String uid, {
    required bool active,
  }) async {
    setActiveCalls.add((uid, active));
    final i = members.indexWhere((m) => m.uid == uid);
    final m = members[i];
    members[i] = Member(
      uid: m.uid,
      displayName: m.displayName,
      role: m.role,
      active: active,
      joinedAt: m.joinedAt,
    );
    _notify();
    return const Ok(null);
  }
}

class FakeCashRepository implements CashRepository {
  FakeCashRepository(this.payments);

  final FakePaymentRepository payments;
  final sessions = <String, CashSession>{};
  final _changes = StreamController<void>.broadcast();
  final drafts = <({Money? opening, Money? counted})>[];

  void seed(CashSession s) {
    sessions[CashSession.idFor(s.dayKey, s.uid)] = s;
    _changes.add(null);
  }

  Stream<T> _live<T>(T Function() read) async* {
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Stream<CashSession?> watchSession(String b, String dayKey, String uid) =>
      _live(() => sessions[CashSession.idFor(dayKey, uid)]);

  @override
  Stream<List<CashSession>> watchDay(String b, String dayKey) =>
      _live(() => sessions.values.where((s) => s.dayKey == dayKey).toList());

  String uid = 'uid-owner';

  @override
  Future<Result<void>> saveDraft({
    required String businessId,
    required String dayKey,
    required String uid,
    required String displayName,
    required bool exists,
    Money? opening,
    Money? counted,
  }) async {
    drafts.add((opening: opening, counted: counted));
    return const Ok(null);
  }

  @override
  Future<Result<void>> close({
    required String dayKey,
    required Money opening,
    required Money counted,
  }) async {
    final mine = payments.payments.values.where(
      (p) => p.createdBy == uid && p.dayKey == dayKey,
    );
    final count = CashCount.from(
      PaymentSummary.of(mine),
      opening: opening,
      counted: counted,
    );
    seed(
      CashSession(
        dayKey: dayKey,
        uid: uid,
        displayName: 'Carlos',
        status: CashStatus.closed,
        opening: opening,
        counted: counted,
        total: PaymentSummary.of(mine).total,
        expected: count.expected,
        difference: count.difference,
        closedAt: fixedNow,
      ),
    );
    return const Ok(null);
  }

  final reopened = <(String, String, String)>[];

  @override
  Future<Result<void>> reopen({
    required String dayKey,
    required String uid,
    required String reason,
  }) async {
    reopened.add((dayKey, uid, reason));
    final s = sessions[CashSession.idFor(dayKey, uid)]!;
    seed(
      CashSession(
        dayKey: dayKey,
        uid: uid,
        displayName: s.displayName,
        status: CashStatus.reopened,
        opening: s.opening,
        counted: s.counted,
        reopenReason: reason,
      ),
    );
    return const Ok(null);
  }
}

FakeAuthRepository collaboratorAuth() => FakeAuthRepository(
  initial: const AuthUser(
    uid: 'uid-ana',
    email: 'ana@vantia.pe',
    emailVerified: true,
  ),
);

FakeBusinessRepository collaboratorBusiness() => FakeBusinessRepository()
  ..currentUid = 'uid-ana'
  ..seedBusiness(demoBusiness)
  ..seedProfile(
    const UserProfile(
      uid: 'uid-ana',
      displayName: 'Ana',
      email: 'ana@vantia.pe',
      activeBusinessId: 'biz-demo',
      role: MemberRole.collaborator,
    ),
  );

class FakeReportsRepository implements ReportsRepository {
  FakeReportsRepository([this.stats = const []]);

  final List<DailyStat> stats;

  @override
  Stream<List<DailyStat>> watchDailyStats(
    String businessId, {
    required String fromKey,
    required String toKey,
  }) => Stream.value([
    for (final s in stats)
      if (s.dayKey.compareTo(fromKey) >= 0 && s.dayKey.compareTo(toKey) < 0) s,
  ]);
}

class FakeProductRepository implements ProductRepository {
  final products = <String, Product>{};
  final _changes = StreamController<void>.broadcast();
  int _seq = 0;

  void seed(Product p) {
    products[p.id] = p;
    _changes.add(null);
  }

  @override
  Stream<List<Product>> watchActive(String businessId) async* {
    List<Product> read() =>
        products.values.where((p) => p.active).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    yield read();
    yield* _changes.stream.map((_) => read());
  }

  @override
  Future<Product?> findByBarcode(String businessId, String barcode) async =>
      products.values.where((p) => p.barcode == barcode).firstOrNull;

  @override
  Future<Result<String>> save(
    String businessId,
    ProductDraft draft, {
    String? id,
  }) async {
    final pid = id ?? 'prod-${++_seq}';
    seed(
      Product(
        id: pid,
        name: draft.name.trim(),
        price: draft.price,
        barcode: draft.barcode?.trim().isEmpty ?? true ? null : draft.barcode,
        category: draft.category?.trim().isEmpty ?? true
            ? null
            : draft.category,
        stock: draft.stock,
      ),
    );
    return Ok(pid);
  }

  @override
  Future<Result<void>> deactivate(String businessId, String id) async {
    seed(products[id]!.copyWith(active: false));
    return const Ok(null);
  }
}

class FakeAutomationChannel implements AutomationChannel {
  FakeAutomationChannel({this.permission = false, this.supported = true});

  bool permission;
  final bool supported;
  final queue = <RawNotification>[];
  final _events = StreamController<RawNotification>.broadcast();
  ({bool enabled, bool voice})? lastConfig;
  int permissionOpened = 0;

  void emit(RawNotification n) => _events.add(n);

  @override
  bool get isSupported => supported;
  @override
  Future<bool> isPermissionGranted() async => permission;
  @override
  Future<void> openPermissionSettings() async => permissionOpened++;
  @override
  Future<bool> isIgnoringBatteryOptimizations() async => false;
  @override
  Future<void> openBatterySettings() async {}
  @override
  Future<void> setConfig({required bool enabled, required bool voice}) async =>
      lastConfig = (enabled: enabled, voice: voice);
  @override
  Future<List<RawNotification>> drainQueue() async {
    final out = List.of(queue);
    queue.clear();
    return out;
  }

  @override
  Stream<RawNotification> get events => _events.stream;
}

class FakeReceiptStorage implements ReceiptStorage {
  final uploads = <String>[];

  @override
  Future<String?> upload(String businessId, String localPath) async {
    uploads.add(localPath);
    return 'receipts/$businessId/test.jpg';
  }
}

RawNotification yapeNotification({int soles = 10, DateTime? at}) =>
    RawNotification(
      packageName: KnownPackages.yape,
      title: 'Confirmación de Pago',
      text: 'Yape! Juan Pérez te envió un pago por S/ $soles.',
      postedAt: at ?? fixedNow,
    );

class FakeSubscriptionService implements SubscriptionService {
  FakeSubscriptionService({this.available = true});

  final bool available;
  final purchased = <String>[];

  @override
  bool get isAvailable => available;
  @override
  Future<void> identify(String businessId) async {}
  @override
  Future<List<SubscriptionOption>> options() async => const [
    SubscriptionOption(id: 'monthly', title: 'Mensual', price: 'S/ 19.90'),
    SubscriptionOption(id: 'annual', title: 'Anual', price: 'S/ 199.00'),
  ];
  @override
  Future<bool> purchase(SubscriptionOption option) async {
    purchased.add(option.id);
    return true;
  }

  @override
  Future<bool> restore() async => false;
}
