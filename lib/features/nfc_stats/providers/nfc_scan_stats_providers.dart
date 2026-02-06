import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tapem/features/nfc_stats/data/nfc_scan_stats_service.dart';
import 'package:tapem/features/nfc_stats/domain/models/nfc_scan_stats.dart';
import 'package:tapem/core/providers/auth_providers.dart';

final nfcScanStatsServiceProvider = Provider<NfcScanStatsService>((ref) {
  return NfcScanStatsService();
});

/// Liefert die NFC-Scan-Statistik für den aktuellen User.
final nfcScanStatsProvider = FutureProvider.autoDispose<NfcScanStats>((ref) async {
  final auth = ref.watch(authControllerProvider);
  final userId = auth.userId;
  if (userId == null) {
    return NfcScanStats.empty();
  }
  final service = ref.watch(nfcScanStatsServiceProvider);
  return service.fetchStats(userId: userId);
});
