import 'package:cloud_firestore/cloud_firestore.dart';

import '../exceptions/gym_nfc_exceptions.dart';
import '../models/gym_nfc_token.dart';

class GymNfcTokenService {
  final FirebaseFirestore _firestore;

  GymNfcTokenService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<GymNfcToken> getToken({
    required String gymId,
    required String token,
  }) async {
    final doc = await _firestore
        .collection('gyms')
        .doc(gymId)
        .collection('nfc_tokens')
        .doc(token)
        .get();
    if (!doc.exists) {
      throw GymNfcTokenNotFoundException();
    }
    return GymNfcToken.fromMap(doc.id, doc.data()!);
  }

  Future<String> resolveGymCode({
    required String gymId,
    required String token,
  }) async {
    final nfcToken = await getToken(gymId: gymId, token: token);
    if (!nfcToken.isActive) {
      throw GymNfcTokenInactiveException();
    }
    if (nfcToken.gymCode.length != 6) {
      throw GymNfcTokenInvalidException();
    }
    return nfcToken.gymCode;
  }
}
