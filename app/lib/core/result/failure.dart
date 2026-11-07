/// Error de dominio tipado. Nunca expone excepciones de infraestructura a la UI.
abstract class Failure {
  const Failure(this.message);

  /// Mensaje técnico (para logs). La UI traduce el tipo a un texto es-PE.
  final String message;

  @override
  String toString() => 'Failure($message)';
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión']);
}

final class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permiso denegado']);
}

final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'No encontrado']);
}

final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, [this.cause]);

  final Object? cause;
}
