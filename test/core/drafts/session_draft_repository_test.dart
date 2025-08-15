import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tapem/core/drafts/session_draft.dart';
import 'package:tapem/core/drafts/session_draft_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SessionDraftRepositoryImpl repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repo = SessionDraftRepositoryImpl();
  });

  test('put/get/delete cycle', () async {
    final key = buildDraftKey(
      gymId: 'g1',
      userId: 'u1',
      deviceId: 'd1',
      exerciseId: 'e1',
      isMulti: true,
    );
    final draft = SessionDraft(
      deviceId: 'd1',
      exerciseId: 'e1',
      createdAt: 1,
      updatedAt: 1,
      note: 'hi',
      sets: [SetDraft(index: 1, weight: '10', reps: '5')],
    );
    await repo.put(key, draft);
    final loaded = await repo.get(key);
    expect(loaded?.note, 'hi');
    await repo.delete(key);
    final missing = await repo.get(key);
    expect(missing, isNull);
  });

  test('deleteExpired removes outdated drafts', () async {
    final key = buildDraftKey(
      gymId: 'g1',
      userId: 'u1',
      deviceId: 'd1',
      exerciseId: '-',
      isMulti: false,
    );
    final oldDraft = SessionDraft(
      deviceId: 'd1',
      createdAt: 0,
      updatedAt: 0,
      note: '',
    );
    await repo.put(key, oldDraft);
    await repo.deleteExpired(kDeviceDraftTtlMs + 1);
    final loaded = await repo.get(key);
    expect(loaded, isNull);
  });

  test('draftKey scoping for multi vs single device', () {
    final k1 = buildDraftKey(
      gymId: 'g',
      userId: 'u',
      deviceId: 'd',
      isMulti: false,
    );
    final k2 = buildDraftKey(
      gymId: 'g',
      userId: 'u',
      deviceId: 'd',
      exerciseId: 'e',
      isMulti: true,
    );
    expect(k1, 'g:u:d:-');
    expect(k2, 'g:u:d:e');
    expect(k1 == k2, isFalse);
  });
}
