import 'package:flutter_test/flutter_test.dart';
import 'package:tapem/features/creatine/providers/creatine_provider.dart';
import 'package:tapem/features/creatine/data/creatine_repository.dart';

class FakeRepo implements CreatineRepository {
  Set<String> dates = {};
  @override
  Future<Set<String>> fetchDatesForYear(String uid, int year) async => dates;
  @override
  Future<void> setIntake(String uid, String dateKey) async {
    dates.add(dateKey);
  }
  @override
  Future<void> deleteIntake(String uid, String dateKey) async {
    dates.remove(dateKey);
  }
}

class ErrorRepo implements CreatineRepository {
  @override
  Future<Set<String>> fetchDatesForYear(String uid, int year) async => {};
  @override
  Future<void> setIntake(String uid, String dateKey) async => throw Exception('fail');
  @override
  Future<void> deleteIntake(String uid, String dateKey) async => throw Exception('fail');
}

void main() {
  test('setSelectedDate sets key', () {
    final prov = CreatineProvider(repository: FakeRepo());
    final d = DateTime(2024, 1, 1);
    prov.setSelectedDate(d);
    expect(prov.selectedDateKey, toDateKeyLocal(d));
  });

  test('canToggle only today or yesterday', () {
    final prov = CreatineProvider(repository: FakeRepo());
    final now = nowLocal();
    prov.setSelectedDate(now);
    expect(prov.canToggle, true);
    prov.setSelectedDate(now.subtract(const Duration(days: 1)));
    expect(prov.canToggle, true);
    prov.setSelectedDate(now.subtract(const Duration(days: 2)));
    expect(prov.canToggle, false);
    prov.setSelectedDate(now.add(const Duration(days: 1)));
    expect(prov.canToggle, false);
  });

  test('toggleIntake adds and removes date', () async {
    final repo = FakeRepo();
    final prov = CreatineProvider(repository: repo);
    await prov.loadIntakeDates('u1', 2024);
    expect(prov.intakeDates, isEmpty);
    final d = nowLocal();
    prov.setSelectedDate(d);
    final key = prov.selectedDateKey;
    await prov.toggleIntake('u1');
    expect(prov.intakeDates.contains(key), true);
    await prov.toggleIntake('u1');
    expect(prov.intakeDates.contains(key), false);
  });

  test('toggleIntake surfaces errors', () async {
    final prov = CreatineProvider(repository: ErrorRepo());
    await prov.loadIntakeDates('u1', 2024);
    expect(prov.intakeDates, isEmpty);
    prov.setSelectedDate(nowLocal());
    expect(() => prov.toggleIntake('u1'), throwsException);
  });

  test('toggleIntake refuses when not allowed', () async {
    final repo = FakeRepo();
    final prov = CreatineProvider(repository: repo);
    prov.setSelectedDate(DateTime(2000, 1, 1));
    expect(prov.canToggle, false);
    expect(() => prov.toggleIntake('u1'), throwsStateError);
    expect(repo.dates, isEmpty);
  });
}
