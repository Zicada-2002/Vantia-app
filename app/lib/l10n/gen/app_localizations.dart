import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('es')];

  /// No description provided for @navHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get navHome;

  /// No description provided for @navPayments.
  ///
  /// In es, this message translates to:
  /// **'Pagos'**
  String get navPayments;

  /// No description provided for @navProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get navProducts;

  /// No description provided for @navReports.
  ///
  /// In es, this message translates to:
  /// **'Reportes'**
  String get navReports;

  /// No description provided for @titleHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get titleHome;

  /// No description provided for @titlePayments.
  ///
  /// In es, this message translates to:
  /// **'Todos mis pagos'**
  String get titlePayments;

  /// No description provided for @titleProducts.
  ///
  /// In es, this message translates to:
  /// **'Productos'**
  String get titleProducts;

  /// No description provided for @titleReports.
  ///
  /// In es, this message translates to:
  /// **'Mis reportes'**
  String get titleReports;

  /// No description provided for @titleCollaborators.
  ///
  /// In es, this message translates to:
  /// **'Colaboradores'**
  String get titleCollaborators;

  /// No description provided for @titleCashRegister.
  ///
  /// In es, this message translates to:
  /// **'Cuadre de caja'**
  String get titleCashRegister;

  /// No description provided for @titleSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get titleSettings;

  /// No description provided for @titleUser.
  ///
  /// In es, this message translates to:
  /// **'Mi cuenta'**
  String get titleUser;

  /// No description provided for @titleNewPayment.
  ///
  /// In es, this message translates to:
  /// **'Registrar pago'**
  String get titleNewPayment;

  /// No description provided for @drawerHome.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get drawerHome;

  /// No description provided for @drawerCollaborators.
  ///
  /// In es, this message translates to:
  /// **'Colaboradores'**
  String get drawerCollaborators;

  /// No description provided for @drawerCashRegister.
  ///
  /// In es, this message translates to:
  /// **'Cuadre de caja'**
  String get drawerCashRegister;

  /// No description provided for @drawerSettings.
  ///
  /// In es, this message translates to:
  /// **'Ajustes'**
  String get drawerSettings;

  /// No description provided for @drawerSignOut.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get drawerSignOut;

  /// No description provided for @fabNewPayment.
  ///
  /// In es, this message translates to:
  /// **'Registrar pago'**
  String get fabNewPayment;

  /// No description provided for @productsMenuBarcode.
  ///
  /// In es, this message translates to:
  /// **'Código de barras'**
  String get productsMenuBarcode;

  /// No description provided for @productsMenuNoBarcode.
  ///
  /// In es, this message translates to:
  /// **'Producto sin código'**
  String get productsMenuNoBarcode;

  /// No description provided for @productsEmpty.
  ///
  /// In es, this message translates to:
  /// **'Aún no has registrado productos'**
  String get productsEmpty;

  /// No description provided for @newPaymentQuestion.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo pagó el cliente?'**
  String get newPaymentQuestion;

  /// No description provided for @newPaymentSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona el medio de pago para registrar el cobro.'**
  String get newPaymentSubtitle;

  /// No description provided for @newPaymentWithProducts.
  ///
  /// In es, this message translates to:
  /// **'Registrar productos vendidos'**
  String get newPaymentWithProducts;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Disponible pronto ({featureId})'**
  String comingSoon(String featureId);

  /// No description provided for @themeLight.
  ///
  /// In es, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeSystem.
  ///
  /// In es, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeDark.
  ///
  /// In es, this message translates to:
  /// **'Oscuro'**
  String get themeDark;

  /// No description provided for @settingsTheme.
  ///
  /// In es, this message translates to:
  /// **'Tema'**
  String get settingsTheme;

  /// No description provided for @routeNotFound.
  ///
  /// In es, this message translates to:
  /// **'No encontramos esta pantalla'**
  String get routeNotFound;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
