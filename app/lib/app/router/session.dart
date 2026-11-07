enum MemberRole { owner, collaborator }

/// Estado de sesión que deciden los guards del router.
sealed class SessionState {
  const SessionState();
}

/// Aún resolviendo (arranque).
final class SessionLoading extends SessionState {
  const SessionLoading();
}

final class SignedOut extends SessionState {
  const SignedOut();
}

/// Autenticado pero con el correo sin verificar.
final class EmailUnverified extends SessionState {
  const EmailUnverified();
}

/// Verificado pero sin negocio (falta onboarding).
final class NoBusiness extends SessionState {
  const NoBusiness();
}

final class SessionReady extends SessionState {
  const SessionReady({
    required this.uid,
    required this.businessId,
    required this.role,
  });

  final String uid;
  final String businessId;
  final MemberRole role;

  bool get isOwner => role == MemberRole.owner;
}
