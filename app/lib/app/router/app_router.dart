import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:vantia/app/router/guards.dart';
import 'package:vantia/app/router/routes.dart';
import 'package:vantia/app/router/session.dart';
import 'package:vantia/app/shell/home_shell.dart';
import 'package:vantia/core/widgets/placeholder_screen.dart';
import 'package:vantia/features/cash_register/presentation/cash_register_screen.dart';
import 'package:vantia/features/collaborators/presentation/collaborators_screen.dart';
import 'package:vantia/features/home/presentation/home_screen.dart';
import 'package:vantia/features/payments/presentation/new_payment_screen.dart';
import 'package:vantia/features/payments/presentation/payments_screen.dart';
import 'package:vantia/features/products/presentation/products_screen.dart';
import 'package:vantia/features/reports/presentation/reports_screen.dart';
import 'package:vantia/features/settings/presentation/settings_screen.dart';
import 'package:vantia/features/user/presentation/user_screen.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// Notifica a go_router cuando cambia la sesión para re-evaluar guards.
class _SessionListenable extends ChangeNotifier {
  void notify() => notifyListeners();
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionListenable();
  ref
    ..listen(sessionProvider, (_, _) => refresh.notify())
    ..onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.home,
    refreshListenable: refresh,
    redirect: (context, state) =>
        resolveRedirect(ref.read(sessionProvider), state.uri.toString()),
    errorBuilder: (context, state) =>
        const PlaceholderScreen(title: 'Vantia', featureId: '404'),
    routes: [
      GoRoute(
        path: Routes.splash,
        builder: (_, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      // M1: autenticación y onboarding.
      for (final (path, title, id) in const [
        (Routes.login, 'Iniciar sesión', 'F-12'),
        (Routes.register, 'Crear cuenta', 'F-10'),
        (Routes.verifyEmail, 'Verifica tu correo', 'F-11'),
        (Routes.forgotPassword, 'Recuperar contraseña', 'F-13'),
        (Routes.onboardingRole, 'Bienvenido a Vantia', 'F-15'),
        (Routes.onboardingBusiness, 'Tu negocio', 'F-16'),
        (Routes.onboardingJoin, 'Unirme a un negocio', 'F-17'),
      ])
        GoRoute(
          path: path,
          builder: (_, _) => PlaceholderScreen(title: title, featureId: id),
        ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.payments,
                builder: (_, _) => const PaymentsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.products,
                builder: (_, _) => const ProductsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.reports,
                builder: (_, _) => const ReportsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: Routes.newPayment,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const NewPaymentScreen(),
      ),
      GoRoute(
        path: Routes.collaborators,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CollaboratorsScreen(),
      ),
      GoRoute(
        path: Routes.cashRegister,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const CashRegisterScreen(),
      ),
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.user,
        parentNavigatorKey: _rootKey,
        builder: (_, _) => const UserScreen(),
      ),
    ],
  );
});
