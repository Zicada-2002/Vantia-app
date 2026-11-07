import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/business/domain/business.dart';

abstract interface class BusinessRepository {
  Stream<UserProfile?> watchProfile(String uid);

  Stream<Business?> watchBusiness(String businessId);

  /// Crea el negocio y deja al usuario como dueño. Devuelve el id.
  Future<Result<String>> createBusiness(CreateBusinessInput input);

  /// Canjea un código de invitación. Devuelve el id del negocio.
  Future<Result<String>> redeemInvite(String code);

  /// F-81: nombre y celular del perfil.
  Future<Result<void>> updateProfile(
    String uid, {
    required String displayName,
    String? phone,
  });

  /// F-83: preferencias sincronizadas (p. ej. push de cobros del equipo).
  Future<Result<void>> updatePrefs(String uid, Map<String, Object> prefs);

  /// F-82: elimina la cuenta en el servidor.
  Future<Result<void>> deleteAccount();
}
