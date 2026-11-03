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

  @override
  String get homeSummary => 'Resumen del día';

  @override
  String get homeIncomeToday => 'INGRESOS DE HOY';

  @override
  String get homePaymentsCount => 'PAGOS';

  @override
  String get homeCash => 'EFECTIVO';

  @override
  String get homeDigital => 'DIGITAL';

  @override
  String get homeLatest => 'Últimos pagos';

  @override
  String get homeNoPayments =>
      'Aún no hay pagos hoy. Toca + para registrar el primero.';

  @override
  String get homeMyIncomeToday => 'MIS INGRESOS DE HOY';

  @override
  String paymentBy(String method) {
    return 'Pago por $method';
  }

  @override
  String get paymentByMe => 'Tú';

  @override
  String get paymentPending => 'Pendiente de sincronizar';

  @override
  String get paymentVoided => 'Anulado';

  @override
  String get paymentVerified => 'Verificado';

  @override
  String get offlineBanner =>
      'Sin conexión. Tus cobros se guardan y se sincronizarán al volver.';

  @override
  String get paymentsWeekIncome => 'Ingreso semanal';

  @override
  String paymentsToday(String date) {
    return 'HOY, $date';
  }

  @override
  String paymentsYesterday(String date) {
    return 'AYER, $date';
  }

  @override
  String get paymentsEmptyWeek => 'No hay pagos en esta semana';

  @override
  String get paymentsPrevWeek => 'Semana anterior';

  @override
  String get paymentsNextWeek => 'Semana siguiente';

  @override
  String get paymentsExport => 'Exportar';

  @override
  String get confirmPaymentTitle => 'Confirmar pago';

  @override
  String get fieldDate => 'Fecha';

  @override
  String get fieldTime => 'Hora';

  @override
  String get fieldAmount => 'Monto';

  @override
  String get fieldAmountReceived => 'Monto recibido';

  @override
  String get hintAmount => 'Ingresa el monto';

  @override
  String get fieldChange => 'Cambio';

  @override
  String get hintChange => 'Vuelto entregado';

  @override
  String get fieldDescription => 'Descripción';

  @override
  String get hintDescription => 'Opcional';

  @override
  String get fieldOperation => 'Nº de operación';

  @override
  String get fieldPayer => 'Nombre del cliente';

  @override
  String get hintOptional => 'Opcional';

  @override
  String get netSale => 'Venta registrada';

  @override
  String get registerPayment => 'Registrar pago';

  @override
  String paymentRegistered(String amount) {
    return 'Pago registrado: $amount';
  }

  @override
  String get errAmountRequired => 'Ingresa un monto mayor a 0';

  @override
  String get errChangeInvalid => 'El cambio no es válido';

  @override
  String get errChangeTooBig => 'El cambio debe ser menor al monto recibido';

  @override
  String get errFutureDate => 'La fecha no puede ser futura';

  @override
  String get errInvalidAmount => 'Monto no válido (máx. 2 decimales)';

  @override
  String get duplicateTitle => '¿Pago duplicado?';

  @override
  String duplicateBody(String method, String number) {
    return 'Ya existe un pago por $method con el nº de operación $number. ¿Registrarlo de todos modos?';
  }

  @override
  String get registerAnyway => 'Registrar igual';

  @override
  String get scanReceipt => 'Escanear comprobante';

  @override
  String get paymentDetail => 'Detalle del pago';

  @override
  String get detailMethod => 'Medio de pago';

  @override
  String get detailDate => 'Fecha y hora';

  @override
  String get detailRegisteredBy => 'Registrado por';

  @override
  String get detailReceived => 'Recibido';

  @override
  String get detailChange => 'Cambio';

  @override
  String get detailSource => 'Origen';

  @override
  String get sourceManual => 'Manual';

  @override
  String get sourceOcr => 'Comprobante escaneado';

  @override
  String get sourceNotification => 'Notificación automática';

  @override
  String get detailProducts => 'Productos';

  @override
  String get detailVoidReason => 'Motivo de anulación';

  @override
  String get voidPayment => 'Anular pago';

  @override
  String get voidTitle => 'Anular pago';

  @override
  String get voidBody =>
      'El pago no se borra: queda registrado como anulado y no suma en los totales.';

  @override
  String get voidReasonLabel => 'Motivo';

  @override
  String get voidReasonHint => 'Ej. Registrado por error';

  @override
  String get voidConfirm => 'Anular';

  @override
  String get voidDone => 'Pago anulado';

  @override
  String get voidNotAllowed => 'No tienes permiso para anular este pago';

  @override
  String get voidWindowExpired =>
      'Solo puedes anular tus pagos durante los primeros 15 minutos';

  @override
  String get notFound => 'No encontramos este pago';

  @override
  String get collabGenerate => 'Generar código de invitación';

  @override
  String get collabEmptyInvites => 'Aún no has generado códigos de invitación';

  @override
  String get collabInvites => 'Códigos de invitación';

  @override
  String get collabMembers => 'Equipo';

  @override
  String get collabNoMembers =>
      'Todavía no hay colaboradores. Comparte un código para invitar.';

  @override
  String get collabCodeTitle => 'Código de invitación';

  @override
  String get collabCodeBody =>
      'Compártelo con tu colaborador. Vence en 48 horas y sirve una sola vez.';

  @override
  String get collabCopy => 'Copiar';

  @override
  String get collabCopied => 'Código copiado';

  @override
  String get collabShare => 'Compartir';

  @override
  String collabShareText(String business, String code) {
    return 'Únete a $business en Vantia con el código $code. Descarga la app, crea tu cuenta y elige \"Colaborador\".';
  }

  @override
  String inviteActive(int hours) {
    return 'Vigente · vence en $hours h';
  }

  @override
  String inviteUsedBy(String name) {
    return 'Usado por $name';
  }

  @override
  String get inviteUsed => 'Usado';

  @override
  String get inviteExpired => 'Vencido';

  @override
  String get inviteRevoked => 'Revocado';

  @override
  String get inviteRevoke => 'Revocar';

  @override
  String inviteRevokeTitle(String code) {
    return '¿Revocar el código $code?';
  }

  @override
  String get inviteRevokeBody => 'Nadie podrá usarlo para unirse a tu negocio.';

  @override
  String get inviteRevoked2 => 'Código revocado';

  @override
  String get memberOwner => 'Dueño';

  @override
  String memberSince(String date) {
    return 'Desde $date';
  }

  @override
  String memberTodaySales(String amount) {
    return 'Hoy: $amount';
  }

  @override
  String get memberInactive => 'Desactivado';

  @override
  String get memberDeactivate => 'Desactivar';

  @override
  String get memberActivate => 'Reactivar';

  @override
  String memberDeactivateTitle(String name) {
    return '¿Desactivar a $name?';
  }

  @override
  String get memberDeactivateBody =>
      'Perderá el acceso al negocio. Sus pagos registrados se conservan.';

  @override
  String get memberUpdated => 'Colaborador actualizado';

  @override
  String cashViewing(String date) {
    return 'Viendo: $date';
  }

  @override
  String get cashMine => 'Mi caja';

  @override
  String get cashGeneral => 'Resumen general';

  @override
  String get cashToday => '(hoy)';

  @override
  String get cashPickDate => 'Elegir fecha';

  @override
  String get cashShiftTotal => 'Total de tu turno';

  @override
  String get cashGeneralTotal => 'Total del negocio';

  @override
  String get cashPhysical => 'Caja física';

  @override
  String get cashOpening => 'Fondo inicial';

  @override
  String get cashReceived => '+ Efectivo recibido';

  @override
  String get cashChangeGiven => '− Cambios dados';

  @override
  String get cashExpected => 'Esperado en caja';

  @override
  String get cashCounted => 'Total contado';

  @override
  String get cashDifference => 'Diferencia';

  @override
  String get cashClose => 'Cerrar caja';

  @override
  String get cashCloseTitle => '¿Cerrar la caja?';

  @override
  String cashCloseBody(String difference) {
    return 'Diferencia: $difference. Después de cerrar no podrás registrar ni anular pagos de este día.';
  }

  @override
  String get cashClosed => 'Caja cerrada';

  @override
  String cashClosedAt(String date) {
    return 'Caja cerrada el $date';
  }

  @override
  String cashReopened(String reason) {
    return 'Caja reabierta: $reason';
  }

  @override
  String get cashReopen => 'Reabrir caja';

  @override
  String get cashReopenTitle => 'Reabrir caja';

  @override
  String get cashReopenReason => 'Motivo';

  @override
  String get cashReopenDone => 'Caja reabierta';

  @override
  String get cashNoPayments => 'Sin pagos';

  @override
  String get cashStatusOpen => 'Abierta';

  @override
  String get cashStatusClosed => 'Cerrada';

  @override
  String get cashStatusNone => 'Sin abrir';

  @override
  String get cashTeam => 'Cajas del equipo';

  @override
  String get cashOver => 'Sobra';

  @override
  String get cashShort => 'Falta';

  @override
  String get cashExact => 'Cuadra';

  @override
  String get reportWeek => 'Semana';

  @override
  String get reportMonth => 'Mes';

  @override
  String get reportYear => 'Año';

  @override
  String get reportThisWeek => 'Esta semana';

  @override
  String get reportThisMonth => 'Este mes';

  @override
  String get reportThisYear => 'Este año';

  @override
  String reportVsPrevious(String percent) {
    return '$percent vs. periodo anterior';
  }

  @override
  String get reportIncome => 'Ingresos';

  @override
  String get reportCash => 'EFECTIVO';

  @override
  String get reportDigital => 'DIGITALES';

  @override
  String get reportBest => 'MEJOR';

  @override
  String get reportAvgTicket => 'Ticket promedio';

  @override
  String get reportMethods => 'Métodos de pago';

  @override
  String get reportNoData => 'Aún no hay ventas en este periodo';

  @override
  String get reportOwnerOnly =>
      'Solo el dueño del negocio puede ver los reportes.';

  @override
  String get exportTitle => 'Selecciona rango de fechas';

  @override
  String get exportButton => 'Exportar';

  @override
  String get exportFormat => '¿En qué formato?';

  @override
  String get exportExcel => 'Excel (.xlsx)';

  @override
  String get exportPdf => 'PDF';

  @override
  String get exportEmpty => 'No hay pagos en ese rango';

  @override
  String get exportTooLong => 'El rango máximo es de 1 año';

  @override
  String exportSubject(String range) {
    return 'Pagos $range';
  }
}
