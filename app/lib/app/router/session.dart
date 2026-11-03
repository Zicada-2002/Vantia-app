import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  const SessionReady({required this.role});

  final MemberRole role;
}

/// Sesión actual. En M0 la app arranca como dueño listo para poder navegar
/// por el shell.
// TODO(F-12): reemplazar por la sesión real (FirebaseAuth + miembro).
class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() => const SessionReady(role: MemberRole.owner);

  // Solo para pruebas y depuración; un setter ocultaría la intención.
  // ignore: use_setters_to_change_properties
  void debugSet(SessionState value) => state = value;
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);
