import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vantia/app/firebase/firebase_env.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/features/auth/data/firebase_auth_repository.dart';
import 'package:vantia/features/auth/domain/auth_repository.dart';
import 'package:vantia/features/auth/domain/auth_user.dart';
import 'package:vantia/features/business/data/firestore_business_repository.dart';
import 'package:vantia/features/business/domain/business.dart';
import 'package:vantia/features/business/domain/business_repository.dart';

// ---------- Repositorios (se sobreescriben en tests) ----------

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => FirebaseAuthRepository(FirebaseAuth.instance),
);

final businessRepositoryProvider = Provider<BusinessRepository>(
  (ref) => FirestoreBusinessRepository(
    FirebaseFirestore.instance,
    FirebaseFunctions.instanceFor(region: FirebaseEnv.functionsRegion),
  ),
);

// ---------- Estado derivado ----------

final authUserProvider = StreamProvider<AuthUser?>(
  (ref) => ref.watch(authRepositoryProvider).userChanges(),
);

/// Perfil `users/{uid}`; solo se escucha con el correo verificado.
final userProfileProvider = StreamProvider<UserProfile?>((ref) {
  final key = ref.watch(
    authUserProvider.select((a) {
      final u = a.value;
      return u == null ? null : (uid: u.uid, verified: u.emailVerified);
    }),
  );
  if (key == null || !key.verified) return Stream.value(null);
  return ref.watch(businessRepositoryProvider).watchProfile(key.uid);
});

final currentBusinessProvider = StreamProvider<Business?>((ref) {
  final bid = ref.watch(
    userProfileProvider.select((p) => p.value?.activeBusinessId),
  );
  if (bid == null) return Stream.value(null);
  return ref.watch(businessRepositoryProvider).watchBusiness(bid);
});

final sessionProvider = Provider<SessionState>((ref) {
  final auth = ref.watch(authUserProvider);
  switch (auth) {
    case AsyncData(value: null):
    case AsyncError():
      return const SignedOut();
    case AsyncData(:final value?):
      if (!value.emailVerified) return const EmailUnverified();
      final profile = ref.watch(userProfileProvider);
      return switch (profile) {
        AsyncData(value: final p?) when p.hasBusiness => SessionReady(
          uid: p.uid,
          businessId: p.activeBusinessId!,
          role: p.role!,
        ),
        AsyncData() || AsyncError() => const NoBusiness(),
        _ => const SessionLoading(),
      };
    default:
      return const SessionLoading();
  }
});
