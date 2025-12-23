import '../exceptions/gym_nfc_exceptions.dart';
import '../services/gym_nfc_token_service.dart';

export '../exceptions/gym_nfc_exceptions.dart';

class ValidateGymNfcToken {
  final GymNfcTokenService _service;

  ValidateGymNfcToken([GymNfcTokenService? service])
      : _service = service ?? GymNfcTokenService();

  Future<String> execute({
    required String gymId,
    required String token,
  }) {
    return _service.resolveGymCode(gymId: gymId, token: token);
  }
}
