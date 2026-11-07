import 'package:vantia/core/result/failure.dart';

enum BusinessErrorCode {
  inviteInvalid,
  inviteExpired,
  inviteUsed,
  alreadyMember,
  emailNotVerified,
  invalidData,
  network,
  unknown,
}

class BusinessFailure extends Failure {
  const BusinessFailure(this.code, [String message = '']) : super(message);

  final BusinessErrorCode code;
}
