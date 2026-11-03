/// Rutas de la app (ver docs/PLAN.md §4). Usar siempre estas constantes.
abstract final class Routes {
  static const splash = '/splash';

  static const login = '/auth/login';
  static const register = '/auth/register';
  static const verifyEmail = '/auth/verify-email';
  static const forgotPassword = '/auth/forgot';

  static const onboardingRole = '/onboarding/role';
  static const onboardingBusiness = '/onboarding/business';
  static const onboardingJoin = '/onboarding/join';

  static const home = '/home';
  static const payments = '/payments';
  static const products = '/products';
  static const reports = '/reports';

  static const newPayment = '/payment/new';
  static String paymentForm(String methodId, {bool withProducts = false}) =>
      '/payment/new/$methodId${withProducts ? '?products=1' : ''}';
  static String paymentDetail(String id) => '/payments/$id';
  static const collaborators = '/collaborators';
  static const cashRegister = '/cash-register';
  static const settings = '/settings';
  static const user = '/user';

  static const Set<String> authRoutes = {login, register, forgotPassword};
  static const Set<String> onboardingRoutes = {
    onboardingRole,
    onboardingBusiness,
    onboardingJoin,
  };

  /// Rutas a las que un colaborador no tiene acceso.
  static const Set<String> ownerOnly = {collaborators, reports};
}
