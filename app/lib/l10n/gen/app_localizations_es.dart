// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get navHome => 'Inicio';

  @override
  String get navPayments => 'Pagos';

  @override
  String get navProducts => 'Productos';

  @override
  String get navReports => 'Reportes';

  @override
  String get titleHome => 'Inicio';

  @override
  String get titlePayments => 'Todos mis pagos';

  @override
  String get titleProducts => 'Productos';

  @override
  String get titleReports => 'Mis reportes';

  @override
  String get titleCollaborators => 'Colaboradores';

  @override
  String get titleCashRegister => 'Cuadre de caja';

  @override
  String get titleSettings => 'Ajustes';

  @override
  String get titleUser => 'Mi cuenta';

  @override
  String get titleNewPayment => 'Registrar pago';

  @override
  String get drawerHome => 'Inicio';

  @override
  String get drawerCollaborators => 'Colaboradores';

  @override
  String get drawerCashRegister => 'Cuadre de caja';

  @override
  String get drawerSettings => 'Ajustes';

  @override
  String get drawerSignOut => 'Cerrar sesión';

  @override
  String get fabNewPayment => 'Registrar pago';

  @override
  String get productsMenuBarcode => 'Código de barras';

  @override
  String get productsMenuNoBarcode => 'Producto sin código';

  @override
  String get productsEmpty => 'Aún no has registrado productos';

  @override
  String get newPaymentQuestion => '¿Cómo pagó el cliente?';

  @override
  String get newPaymentSubtitle =>
      'Selecciona el medio de pago para registrar el cobro.';

  @override
  String get newPaymentWithProducts => 'Registrar productos vendidos';

  @override
  String comingSoon(String featureId) {
    return 'Disponible pronto ($featureId)';
  }

  @override
  String get themeLight => 'Claro';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get routeNotFound => 'No encontramos esta pantalla';
}
