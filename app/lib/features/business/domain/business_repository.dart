import 'package:vantia/core/result/result.dart';
import 'package:vantia/features/business/domain/business.dart';

abstract interface class BusinessRepository {
  Stream<UserProfile?> watchProfile(String uid);

  Stream<Business?> watchBusiness(String businessId);

  /// Crea el negocio y deja al usuario como dueño. Devuelve el id.
  Future<Result<String>> createBusiness(CreateBusinessInput input);

  /// Canjea un código de invitación. Devuelve el id del negocio.
  Future<Result<String>> redeemInvite(String code);
}
