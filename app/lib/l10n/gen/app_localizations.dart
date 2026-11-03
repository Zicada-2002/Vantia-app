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

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'Vantia'**
  String get appName;

  /// No description provided for @fieldName.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get fieldName;

  /// No description provided for @fieldEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get fieldEmail;

  /// No description provided for @fieldPassword.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get fieldPassword;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In es, this message translates to:
  /// **'Confirmar contraseña'**
  String get fieldConfirmPassword;

  /// No description provided for @hintName.
  ///
  /// In es, this message translates to:
  /// **'Ej. Carlos Vásquez'**
  String get hintName;

  /// No description provided for @hintEmail.
  ///
  /// In es, this message translates to:
  /// **'tucorreo@ejemplo.com'**
  String get hintEmail;

  /// No description provided for @hintPassword.
  ///
  /// In es, this message translates to:
  /// **'Mínimo 8 caracteres y 1 número'**
  String get hintPassword;

  /// No description provided for @showPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get hidePassword;

  /// No description provided for @loginTitle.
  ///
  /// In es, this message translates to:
  /// **'Bienvenido a Vantia'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa para registrar tus cobros y cuadrar tu caja.'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get loginButton;

  /// No description provided for @loginForgot.
  ///
  /// In es, this message translates to:
  /// **'¿Olvidaste tu contraseña?'**
  String get loginForgot;

  /// No description provided for @loginNoAccount.
  ///
  /// In es, this message translates to:
  /// **'¿No tienes cuenta?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateAccount.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get loginCreateAccount;

  /// No description provided for @registerTitle.
  ///
  /// In es, this message translates to:
  /// **'Crea tu cuenta'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Te enviaremos un correo para verificar tu dirección.'**
  String get registerSubtitle;

  /// No description provided for @registerAcceptTerms.
  ///
  /// In es, this message translates to:
  /// **'Acepto los Términos y condiciones y la Política de privacidad'**
  String get registerAcceptTerms;

  /// No description provided for @registerTermsRequired.
  ///
  /// In es, this message translates to:
  /// **'Debes aceptar los términos para continuar'**
  String get registerTermsRequired;

  /// No description provided for @registerButton.
  ///
  /// In es, this message translates to:
  /// **'Crear cuenta'**
  String get registerButton;

  /// No description provided for @registerHaveAccount.
  ///
  /// In es, this message translates to:
  /// **'¿Ya tienes cuenta?'**
  String get registerHaveAccount;

  /// No description provided for @registerSignIn.
  ///
  /// In es, this message translates to:
  /// **'Ingresar'**
  String get registerSignIn;

  /// No description provided for @verifyTitle.
  ///
  /// In es, this message translates to:
  /// **'Revisa tu correo'**
  String get verifyTitle;

  /// No description provided for @verifyBody.
  ///
  /// In es, this message translates to:
  /// **'Enviamos un enlace de verificación a {email}. Ábrelo para activar tu cuenta.'**
  String verifyBody(String email);

  /// No description provided for @verifyHint.
  ///
  /// In es, this message translates to:
  /// **'Si no lo ves, revisa la carpeta de spam o promociones.'**
  String get verifyHint;

  /// No description provided for @verifyCheck.
  ///
  /// In es, this message translates to:
  /// **'Ya verifiqué mi correo'**
  String get verifyCheck;

  /// No description provided for @verifyResend.
  ///
  /// In es, this message translates to:
  /// **'Reenviar correo'**
  String get verifyResend;

  /// No description provided for @verifyResendIn.
  ///
  /// In es, this message translates to:
  /// **'Reenviar en {seconds} s'**
  String verifyResendIn(int seconds);

  /// No description provided for @verifyResent.
  ///
  /// In es, this message translates to:
  /// **'Te enviamos un nuevo correo de verificación'**
  String get verifyResent;

  /// No description provided for @verifyStillPending.
  ///
  /// In es, this message translates to:
  /// **'Tu correo aún no está verificado. Abre el enlace que te enviamos.'**
  String get verifyStillPending;

  /// No description provided for @verifyUseOtherEmail.
  ///
  /// In es, this message translates to:
  /// **'Usar otro correo'**
  String get verifyUseOtherEmail;

  /// No description provided for @forgotTitle.
  ///
  /// In es, this message translates to:
  /// **'Recupera tu contraseña'**
  String get forgotTitle;

  /// No description provided for @forgotSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Ingresa tu correo y te enviaremos un enlace para crear una nueva contraseña.'**
  String get forgotSubtitle;

  /// No description provided for @forgotButton.
  ///
  /// In es, this message translates to:
  /// **'Enviar enlace'**
  String get forgotButton;

  /// No description provided for @forgotSent.
  ///
  /// In es, this message translates to:
  /// **'Si existe una cuenta con ese correo, recibirás un enlace en unos minutos.'**
  String get forgotSent;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In es, this message translates to:
  /// **'Volver a ingresar'**
  String get forgotBackToLogin;

  /// No description provided for @roleTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cómo usarás la aplicación?'**
  String get roleTitle;

  /// No description provided for @roleSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu rol para personalizar tu experiencia en Vantia.'**
  String get roleSubtitle;

  /// No description provided for @roleOwnerTitle.
  ///
  /// In es, this message translates to:
  /// **'Dueño de negocio'**
  String get roleOwnerTitle;

  /// No description provided for @roleOwnerBody.
  ///
  /// In es, this message translates to:
  /// **'Gestiona tu negocio, colaboradores, pagos y reportes desde un solo lugar.'**
  String get roleOwnerBody;

  /// No description provided for @roleCollaboratorTitle.
  ///
  /// In es, this message translates to:
  /// **'Colaborador'**
  String get roleCollaboratorTitle;

  /// No description provided for @roleCollaboratorBody.
  ///
  /// In es, this message translates to:
  /// **'Colabora en un negocio registrando ventas y cerrando tu caja.'**
  String get roleCollaboratorBody;

  /// No description provided for @continueButton.
  ///
  /// In es, this message translates to:
  /// **'Continuar'**
  String get continueButton;

  /// No description provided for @businessTitle.
  ///
  /// In es, this message translates to:
  /// **'Datos de tu negocio'**
  String get businessTitle;

  /// No description provided for @businessSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Empezarás con 7 días de prueba gratis del plan Pro.'**
  String get businessSubtitle;

  /// No description provided for @fieldBusinessName.
  ///
  /// In es, this message translates to:
  /// **'Nombre del negocio'**
  String get fieldBusinessName;

  /// No description provided for @hintBusinessName.
  ///
  /// In es, this message translates to:
  /// **'Ej. Bodega Don Carlos'**
  String get hintBusinessName;

  /// No description provided for @fieldPhone.
  ///
  /// In es, this message translates to:
  /// **'Celular'**
  String get fieldPhone;

  /// No description provided for @hintPhone.
  ///
  /// In es, this message translates to:
  /// **'987 654 321'**
  String get hintPhone;

  /// No description provided for @fieldDepartment.
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get fieldDepartment;

  /// No description provided for @fieldProvince.
  ///
  /// In es, this message translates to:
  /// **'Provincia'**
  String get fieldProvince;

  /// No description provided for @hintProvince.
  ///
  /// In es, this message translates to:
  /// **'Ej. Lima'**
  String get hintProvince;

  /// No description provided for @businessCreate.
  ///
  /// In es, this message translates to:
  /// **'Crear negocio'**
  String get businessCreate;

  /// No description provided for @joinTitle.
  ///
  /// In es, this message translates to:
  /// **'Únete a un negocio'**
  String get joinTitle;

  /// No description provided for @joinSubtitle.
  ///
  /// In es, this message translates to:
  /// **'Pídele al dueño del negocio el código de invitación de 6 caracteres.'**
  String get joinSubtitle;

  /// No description provided for @fieldInviteCode.
  ///
  /// In es, this message translates to:
  /// **'Código de invitación'**
  String get fieldInviteCode;

  /// No description provided for @joinButton.
  ///
  /// In es, this message translates to:
  /// **'Unirme'**
  String get joinButton;

  /// No description provided for @signOutTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Cerrar sesión?'**
  String get signOutTitle;

  /// No description provided for @signOutBody.
  ///
  /// In es, this message translates to:
  /// **'Tendrás que volver a ingresar con tu correo y contraseña.'**
  String get signOutBody;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Volver'**
  String get back;

  /// No description provided for @errRequired.
  ///
  /// In es, this message translates to:
  /// **'Este campo es obligatorio'**
  String get errRequired;

  /// No description provided for @errInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un correo válido'**
  String get errInvalidEmail;

  /// No description provided for @errPasswordTooShort.
  ///
  /// In es, this message translates to:
  /// **'Debe tener al menos 8 caracteres'**
  String get errPasswordTooShort;

  /// No description provided for @errPasswordNeedsNumber.
  ///
  /// In es, this message translates to:
  /// **'Debe incluir al menos un número'**
  String get errPasswordNeedsNumber;

  /// No description provided for @errPasswordsDontMatch.
  ///
  /// In es, this message translates to:
  /// **'Las contraseñas no coinciden'**
  String get errPasswordsDontMatch;

  /// No description provided for @errInvalidPhone.
  ///
  /// In es, this message translates to:
  /// **'Ingresa un celular de 9 dígitos que empiece con 9'**
  String get errInvalidPhone;

  /// No description provided for @errInvalidInviteCode.
  ///
  /// In es, this message translates to:
  /// **'El código tiene 6 caracteres (letras y números)'**
  String get errInvalidInviteCode;

  /// No description provided for @errTooShort.
  ///
  /// In es, this message translates to:
  /// **'Es demasiado corto'**
  String get errTooShort;

  /// No description provided for @errAuthInvalidCredentials.
  ///
  /// In es, this message translates to:
  /// **'Correo o contraseña incorrectos'**
  String get errAuthInvalidCredentials;

  /// No description provided for @errAuthEmailInUse.
  ///
  /// In es, this message translates to:
  /// **'Ya existe una cuenta con este correo'**
  String get errAuthEmailInUse;

  /// No description provided for @errAuthWeakPassword.
  ///
  /// In es, this message translates to:
  /// **'La contraseña es muy débil'**
  String get errAuthWeakPassword;

  /// No description provided for @errAuthInvalidEmail.
  ///
  /// In es, this message translates to:
  /// **'El correo no es válido'**
  String get errAuthInvalidEmail;

  /// No description provided for @errAuthUserDisabled.
  ///
  /// In es, this message translates to:
  /// **'Esta cuenta está deshabilitada'**
  String get errAuthUserDisabled;

  /// No description provided for @errAuthTooManyRequests.
  ///
  /// In es, this message translates to:
  /// **'Demasiados intentos. Espera unos minutos e inténtalo de nuevo'**
  String get errAuthTooManyRequests;

  /// No description provided for @errNetwork.
  ///
  /// In es, this message translates to:
  /// **'Sin conexión. Revisa tu internet e inténtalo de nuevo'**
  String get errNetwork;

  /// No description provided for @errAuthRecentLogin.
  ///
  /// In es, this message translates to:
  /// **'Por seguridad, vuelve a iniciar sesión'**
  String get errAuthRecentLogin;

  /// No description provided for @errUnknown.
  ///
  /// In es, this message translates to:
  /// **'Ocurrió un error inesperado. Inténtalo de nuevo'**
  String get errUnknown;

  /// No description provided for @errInviteInvalid.
  ///
  /// In es, this message translates to:
  /// **'El código no existe o fue revocado'**
  String get errInviteInvalid;

  /// No description provided for @errInviteExpired.
  ///
  /// In es, this message translates to:
  /// **'El código venció. Pide uno nuevo al dueño'**
  String get errInviteExpired;

  /// No description provided for @errInviteUsed.
  ///
  /// In es, this message translates to:
  /// **'Este código ya fue usado'**
  String get errInviteUsed;

  /// No description provided for @errAlreadyMember.
  ///
  /// In es, this message translates to:
  /// **'Tu cuenta ya pertenece a un negocio'**
  String get errAlreadyMember;

  /// No description provided for @errEmailNotVerified.
  ///
  /// In es, this message translates to:
  /// **'Primero verifica tu correo'**
  String get errEmailNotVerified;

  /// No description provided for @errInvalidData.
  ///
  /// In es, this message translates to:
  /// **'Revisa los datos ingresados'**
  String get errInvalidData;
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
