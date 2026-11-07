// Backend en memoria para el modo demo: la app funciona sin Firebase, con
// datos de ejemplo. Los datos se reinician al cerrar la app.
//
// Mismos contratos que los repositorios reales (ver features/*/domain).

import 'dart:async';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/money/money.dart';
import 'package:vantia/core/result/failure.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/auth/domain/auth_failure.dart';
import 'package:vantia/features/auth/domain/auth_repository.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/business/domain/business_failure.dart';
import 'package:vantia/features/business/domain/business_repository.dart';
import 'package:vantia/features/cash_register/domain/cash_session.dart';
import 'package:vantia/features/collaborators/domain/collaborators.dart';
import 'package:vantia/features/payments/domain/payment.dart';
import 'package:vantia/features/payments/domain/payment_method.dart';
import 'package:vantia/features/payments/domain/payment_repository.dart';
import 'package:vantia/features/products/domain/product.dart';

/// Auth en memoria con el mismo contrato que Firebase.
class DemoAuthRepository implements AuthRepository {
  DemoAuthRepository({AuthUser? initial}) : _user = initial;

  AuthUser? _user;
  final _changes = StreamController<AuthUser?>.broadcast();

  /// Cuentas registradas: email → password.
  final accounts = <String, String>{};

  /// Nombres por correo (para el usuario con sesión).
  final names = <String, String>{};
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
    names[email] = displayName;
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
    _emit(
      AuthUser(
        uid: 'uid-$email',
        email: email,
        emailVerified: true,
        displayName: names[email],
      ),
    );
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

class DemoBusinessRepository implements BusinessRepository {
  DemoBusinessRepository(this._auth);

  final DemoAuthRepository _auth;

  final _profiles = <String, UserProfile>{};
  final _businesses = <String, Business>{};
  final _profileCtl = StreamController<UserProfile>.broadcast();
  final _businessCtl = StreamController<Business>.broadcast();

  /// Códigos válidos: code → businessId.
  final invites = <String, String>{};

  /// uid del usuario con sesión (simula el token).
  String? get currentUid => _auth.currentUser?.uid;
  String get _name => _auth.currentUser?.displayName ?? '';
  String get _email => _auth.currentUser?.email ?? '';

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
        planTier: 'trial',
        trialEndsAt: DateTime.now().add(const Duration(days: 7)),
      ),
    );
    seedProfile(
      UserProfile(
        uid: uid,
        displayName: _name,
        email: _email,
        createdAt: DateTime.now(),
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
        displayName: _name,
        email: _email,
        createdAt: DateTime.now(),
        activeBusinessId: bid,
        role: MemberRole.collaborator,
      ),
    );
    return Ok(bid);
  }
}

/// Pagos en memoria con filtros de alcance y rango como Firestore.
class DemoPaymentRepository implements PaymentRepository {
  DemoPaymentRepository({DateTime Function()? clock})
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

class DemoCollaboratorRepository implements CollaboratorRepository {
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
    final expiresAt = DateTime.now().add(const Duration(hours: 48));
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

class DemoCashRepository implements CashRepository {
  DemoCashRepository(this.payments);

  final DemoPaymentRepository payments;
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

  /// Usuario que cierra la caja (por defecto, el dueño de ejemplo).
  String? uid;

  /// Usuario con sesión (quien cierra su caja).
  String? Function()? currentUid;

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
    final who = uid ?? currentUid?.call() ?? 'uid-owner';
    final mine = payments.payments.values.where(
      (p) => p.createdBy == who && p.dayKey == dayKey,
    );
    final count = CashCount.from(
      PaymentSummary.of(mine),
      opening: opening,
      counted: counted,
    );
    seed(
      CashSession(
        dayKey: dayKey,
        uid: who,
        displayName: 'Carlos',
        status: CashStatus.closed,
        opening: opening,
        counted: counted,
        total: PaymentSummary.of(mine).total,
        expected: count.expected,
        difference: count.difference,
        closedAt: DateTime.now(),
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

class DemoProductRepository implements ProductRepository {
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
