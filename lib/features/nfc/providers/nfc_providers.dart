// lib/features/nfc/providers/nfc_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/nfc_service.dart';
import '../domain/usecases/read_nfc_code.dart';
import '../domain/usecases/write_nfc_tag.dart';

final nfcServiceProvider = Provider<NfcService>((ref) {
  return NfcService();
});

final readNfcCodeProvider = Provider<ReadNfcCode>((ref) {
  return ReadNfcCode(ref.watch(nfcServiceProvider));
});

final writeNfcTagUseCaseProvider = Provider<WriteNfcTagUseCase>((ref) {
  return WriteNfcTagUseCase();
});
