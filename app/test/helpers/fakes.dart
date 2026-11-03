import 'dart:async';

import 'package:vantia/app/router/session.dart';
import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/auth/domain/auth_failure.dart';
import 'package:vantia/features/auth/domain/auth_repository.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/business/domain/business_failure.dart';
import 'package:vantia/features/business/domain/business_repository.dart';

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

const demoBusiness = Business(
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
