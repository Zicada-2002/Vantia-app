import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';

/// Decide la redirección para [location] según la sesión. Función pura
/// (testeable). Orden de los guards: sesión → verificación → negocio → rol.
String? resolveRedirect(SessionState session, String location) {
  final path = Uri.parse(location).path;
  final isAuth = Routes.authRoutes.contains(path);
  final isVerify = path == Routes.verifyEmail;
  final isOnboarding = Routes.onboardingRoutes.contains(path);
  final isSplash = path == Routes.splash;

  switch (session) {
    case SessionLoading():
      return isSplash ? null : Routes.splash;
    case SignedOut():
      return isAuth ? null : Routes.login;
    case EmailUnverified():
      return isVerify ? null : Routes.verifyEmail;
    case NoBusiness():
      return isOnboarding ? null : Routes.onboardingRole;
    case SessionReady(:final role):
      if (isAuth || isVerify || isOnboarding || isSplash) return Routes.home;
      if (role == MemberRole.collaborator && Routes.ownerOnly.contains(path)) {
        return Routes.home;
      }
      return null;
  }
}
