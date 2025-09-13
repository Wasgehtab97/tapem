import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/rank/domain/models/level_info.dart';
import 'package:tapem/features/rank/domain/services/level_service.dart';

void main() {
  final service = LevelService();
  group('LevelService.addXp', () {
    test('simple level up', () {
      final res = service.addXp(LevelInfo(level: 1, xp: 950), 50);
      expect(res.level, 2);
      expect(res.xp, 0);
    });

    test('multi overflow', () {
      final res = service.addXp(LevelInfo(level: 1, xp: 990), 30);
      expect(res.level, 2);
      expect(res.xp, 20);
    });

    test('max level cap', () {
      final res = service.addXp(LevelInfo(level: 30, xp: 0), 1000);
      expect(res.level, 30);
      expect(res.xp, 0);
    });
  });
}
