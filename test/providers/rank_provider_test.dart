import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';

class FakeRankRepository implements RankRepository {
  final deviceCtrl = StreamController<List<Map<String, dynamic>>>.broadcast();
  int addCalls = 0;

  @override
  Stream<List<Map<String, dynamic>>> watchLeaderboard(
    String gymId,
    String deviceId,
  ) =>
      deviceCtrl.stream;

  @override
  Future<void> addXp(String gymId, String userId, String deviceId,
      String sessionId, bool showInLeaderboard) async {
    addCalls++;
  }

  void dispose() {
    deviceCtrl.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RankProvider', () {
    test('watchDevice updates entries', () async {
      final repo = FakeRankRepository();
      final provider = RankProvider(repository: repo);
      provider.watchDevice('g1', 'd1');
      repo.deviceCtrl.add([
        {'userId': 'u1', 'xp': 10}
      ]);
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.deviceEntries.length, 1);
      repo.dispose();
    });

    test('addXp delegates to repository', () async {
      final repo = FakeRankRepository();
      final provider = RankProvider(repository: repo);
      await provider.addXp('g1', 'u1', 'd1', 's1', true);
      expect(repo.addCalls, 1);
      repo.dispose();
    });
  });
}
