import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/creatine/presentation/screens/creatine_screen.dart';
import 'package:tapem/features/creatine/providers/creatine_provider.dart';
import 'package:tapem/features/creatine/data/creatine_repository.dart';
import 'package:tapem/l10n/app_localizations.dart';

class FakeRepo implements CreatineRepository {
  Set<String> dates;
  FakeRepo(this.dates);
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

Future<void> pumpScreen(WidgetTester tester, CreatineProvider prov) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ChangeNotifierProvider.value(
        value: prov,
        child: const CreatineScreen(userId: 'u1'),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows taken today when not marked', (tester) async {
    final repo = FakeRepo({});
    final prov = CreatineProvider(repository: repo);
    await prov.loadIntakeDates('u1', DateTime.now().year);
    await pumpScreen(tester, prov);
    expect(find.text('Taken today'), findsOneWidget);
  });

  testWidgets('shows remove when marked', (tester) async {
    final dateKey = CreatineProvider.dateKeyFrom(DateTime.now());
    final repo = FakeRepo({dateKey});
    final prov = CreatineProvider(repository: repo);
    await prov.loadIntakeDates('u1', DateTime.now().year);
    await pumpScreen(tester, prov);
    expect(find.text('Remove mark'), findsOneWidget);
  });
}
