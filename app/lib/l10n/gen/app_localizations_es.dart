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

  @override
  String get appName => 'Vantia';

  @override
  String get fieldName => 'Nombre completo';

  @override
  String get fieldEmail => 'Correo electrónico';

  @override
  String get fieldPassword => 'Contraseña';

  @override
  String get fieldConfirmPassword => 'Confirmar contraseña';

  @override
  String get hintName => 'Ej. Carlos Vásquez';

  @override
  String get hintEmail => 'tucorreo@ejemplo.com';

  @override
  String get hintPassword => 'Mínimo 8 caracteres y 1 número';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get loginTitle => 'Bienvenido a Vantia';

  @override
  String get loginSubtitle =>
      'Ingresa para registrar tus cobros y cuadrar tu caja.';

  @override
  String get loginButton => 'Ingresar';

  @override
  String get loginForgot => '¿Olvidaste tu contraseña?';

  @override
  String get loginNoAccount => '¿No tienes cuenta?';

  @override
  String get loginCreateAccount => 'Crear cuenta';

  @override
  String get registerTitle => 'Crea tu cuenta';

  @override
  String get registerSubtitle =>
      'Te enviaremos un correo para verificar tu dirección.';

  @override
  String get registerAcceptTerms =>
      'Acepto los Términos y condiciones y la Política de privacidad';

  @override
  String get registerTermsRequired =>
      'Debes aceptar los términos para continuar';

  @override
  String get registerButton => 'Crear cuenta';

  @override
  String get registerHaveAccount => '¿Ya tienes cuenta?';

  @override
  String get registerSignIn => 'Ingresar';

  @override
  String get verifyTitle => 'Revisa tu correo';

  @override
  String verifyBody(String email) {
    return 'Enviamos un enlace de verificación a $email. Ábrelo para activar tu cuenta.';
  }

  @override
  String get verifyHint =>
      'Si no lo ves, revisa la carpeta de spam o promociones.';

  @override
  String get verifyCheck => 'Ya verifiqué mi correo';

  @override
  String get verifyResend => 'Reenviar correo';

  @override
  String verifyResendIn(int seconds) {
    return 'Reenviar en $seconds s';
  }

  @override
  String get verifyResent => 'Te enviamos un nuevo correo de verificación';

  @override
  String get verifyStillPending =>
      'Tu correo aún no está verificado. Abre el enlace que te enviamos.';

  @override
  String get verifyUseOtherEmail => 'Usar otro correo';

  @override
  String get forgotTitle => 'Recupera tu contraseña';

  @override
  String get forgotSubtitle =>
      'Ingresa tu correo y te enviaremos un enlace para crear una nueva contraseña.';

  @override
  String get forgotButton => 'Enviar enlace';

  @override
  String get forgotSent =>
      'Si existe una cuenta con ese correo, recibirás un enlace en unos minutos.';

  @override
  String get forgotBackToLogin => 'Volver a ingresar';

  @override
  String get roleTitle => '¿Cómo usarás la aplicación?';

  @override
  String get roleSubtitle =>
      'Selecciona tu rol para personalizar tu experiencia en Vantia.';

  @override
  String get roleOwnerTitle => 'Dueño de negocio';

  @override
  String get roleOwnerBody =>
      'Gestiona tu negocio, colaboradores, pagos y reportes desde un solo lugar.';

  @override
  String get roleCollaboratorTitle => 'Colaborador';

  @override
  String get roleCollaboratorBody =>
      'Colabora en un negocio registrando ventas y cerrando tu caja.';

  @override
  String get continueButton => 'Continuar';

  @override
  String get businessTitle => 'Datos de tu negocio';

  @override
  String get businessSubtitle =>
      'Empezarás con 7 días de prueba gratis del plan Pro.';

  @override
  String get fieldBusinessName => 'Nombre del negocio';

  @override
  String get hintBusinessName => 'Ej. Bodega Don Carlos';

  @override
  String get fieldPhone => 'Celular';

  @override
  String get hintPhone => '987 654 321';

  @override
  String get fieldDepartment => 'Departamento';

  @override
  String get fieldProvince => 'Provincia';

  @override
  String get hintProvince => 'Ej. Lima';

  @override
  String get businessCreate => 'Crear negocio';

  @override
  String get joinTitle => 'Únete a un negocio';

  @override
  String get joinSubtitle =>
      'Pídele al dueño del negocio el código de invitación de 6 caracteres.';

  @override
  String get fieldInviteCode => 'Código de invitación';

  @override
  String get joinButton => 'Unirme';

  @override
  String get signOutTitle => '¿Cerrar sesión?';

  @override
  String get signOutBody =>
      'Tendrás que volver a ingresar con tu correo y contraseña.';

  @override
  String get cancel => 'Cancelar';

  @override
  String get back => 'Volver';

  @override
  String get errRequired => 'Este campo es obligatorio';

  @override
  String get errInvalidEmail => 'Ingresa un correo válido';

  @override
  String get errPasswordTooShort => 'Debe tener al menos 8 caracteres';

  @override
  String get errPasswordNeedsNumber => 'Debe incluir al menos un número';

  @override
  String get errPasswordsDontMatch => 'Las contraseñas no coinciden';

  @override
  String get errInvalidPhone =>
      'Ingresa un celular de 9 dígitos que empiece con 9';

  @override
  String get errInvalidInviteCode =>
      'El código tiene 6 caracteres (letras y números)';

  @override
  String get errTooShort => 'Es demasiado corto';

  @override
  String get errAuthInvalidCredentials => 'Correo o contraseña incorrectos';

  @override
  String get errAuthEmailInUse => 'Ya existe una cuenta con este correo';

  @override
  String get errAuthWeakPassword => 'La contraseña es muy débil';

  @override
  String get errAuthInvalidEmail => 'El correo no es válido';

  @override
  String get errAuthUserDisabled => 'Esta cuenta está deshabilitada';

  @override
  String get errAuthTooManyRequests =>
      'Demasiados intentos. Espera unos minutos e inténtalo de nuevo';

  @override
  String get errNetwork =>
      'Sin conexión. Revisa tu internet e inténtalo de nuevo';

  @override
  String get errAuthRecentLogin => 'Por seguridad, vuelve a iniciar sesión';

  @override
  String get errUnknown => 'Ocurrió un error inesperado. Inténtalo de nuevo';

  @override
  String get errInviteInvalid => 'El código no existe o fue revocado';

  @override
  String get errInviteExpired => 'El código venció. Pide uno nuevo al dueño';

  @override
  String get errInviteUsed => 'Este código ya fue usado';

  @override
  String get errAlreadyMember => 'Tu cuenta ya pertenece a un negocio';

  @override
  String get errEmailNotVerified => 'Primero verifica tu correo';

  @override
  String get errInvalidData => 'Revisa los datos ingresados';
}
