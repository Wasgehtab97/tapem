import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

import 'package:tapem/features/story_card/domain/session_story_data.dart';
import 'package:tapem/features/story_card/session_story_share_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionStoryShareService', () {
    late SessionStoryShareService service;
    late SessionStoryData data;

    setUp(() {
      service = SessionStoryShareService();
      data = SessionStoryData(
        sessionId: 'session-1',
        userId: 'user-1',
        gymId: 'gym-1',
        gymName: 'Tapem Gym',
        occurredAt: DateTime(2025, 10, 13, 12),
        xpTotal: 150,
        baseXp: 120,
        bonusXp: 30,
        setCount: 20,
        exerciseCount: 8,
        totalVolume: 1234,
        durationMinutes: 75,
        badges: const [],
        muscles: const [],
      );
    });

    test('resolvePixelRatioForSize keeps default ratio for modest surfaces', () {
      final ratio = service.debugResolvePixelRatioForSize(const ui.Size(400, 700));
      expect(ratio, 3.0);
    });

    test('resolvePixelRatioForSize clamps when exceeding target megapixels', () {
      final ratio = service.debugResolvePixelRatioForSize(const ui.Size(4000, 4000));
      expect(ratio, closeTo(1.5, 0.0001));
    });

    test('persistImage falls back to secondary directory on failure', () async {
      final fallback = await Directory.systemTemp.createTemp('story-share-test');
      addTearDown(() async {
        if (await fallback.exists()) {
          await fallback.delete(recursive: true);
        }
      });
      final path = await service.debugPersistImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        data: data,
        directories: [Directory('/dev/null'), fallback],
      );
      expect(File(path).existsSync(), isTrue);
      expect(path.startsWith(fallback.path), isTrue);
    });
  });
}
