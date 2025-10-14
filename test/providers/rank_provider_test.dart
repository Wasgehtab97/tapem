import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/core/providers/rank_provider.dart';
import 'package:tapem/features/rank/domain/rank_repository.dart';

class FakeRankRepository implements RankRepository {
  List<Map<String, dynamic>> leaderboard = [];
  int addCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchLeaderboard(
    String gymId,
    String deviceId,
  ) async =>
      leaderboard;

  @override
  Future<void> addXp(String gymId, String userId, String deviceId,
      String sessionId, bool showInLeaderboard) async {
    addCalls++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RankProvider', () {
    test('watchDevice updates entries', () async {
      final repo = FakeRankRepository();
      final provider = RankProvider(repository: repo);
      repo.leaderboard = [
        {'userId': 'u1', 'xp': 10}
      ];
      provider.watchDevice('g1', 'd1');
      await Future.delayed(const Duration(milliseconds: 10));
      expect(provider.deviceEntries.length, 1);
    });

    test('addXp delegates to repository', () async {
      final repo = FakeRankRepository();
      final provider = RankProvider(repository: repo);
      await provider.addXp('g1', 'u1', 'd1', 's1', true);
      expect(repo.addCalls, 1);
    });
  });
}
