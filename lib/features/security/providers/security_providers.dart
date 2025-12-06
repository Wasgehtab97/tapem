import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/services/encryption_service.dart';

final encryptionServiceProvider = Provider.family<EncryptionService, String>((ref, userId) {
  return EncryptionService(userId: userId);
});
