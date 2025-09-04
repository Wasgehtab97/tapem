import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/features/creatine/presentation/screens/creatine_screen.dart';
import 'package:tapem/features/creatine/providers/creatine_provider.dart';
import 'package:tapem/features/creatine/data/creatine_repository.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar.dart';
import 'package:tapem/features/profile/presentation/widgets/calendar_popup.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

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
    final dateKey = toDateKeyLocal(DateTime.now());
    final repo = FakeRepo({dateKey});
    final prov = CreatineProvider(repository: repo);
    await prov.loadIntakeDates('u1', DateTime.now().year);
    await pumpScreen(tester, prov);
    expect(find.text('Remove mark'), findsOneWidget);
  });

  testWidgets('opens popup and closes after selection', (tester) async {
    final repo = FakeRepo({});
    final prov = CreatineProvider(repository: repo);
    await prov.loadIntakeDates('u1', DateTime.now().year);
    await pumpScreen(tester, prov);
    await tester.tap(find.byType(Calendar));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPopup), findsOneWidget);
    await tester.tap(find.byType(Calendar).last);
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPopup), findsNothing);
  });

  testWidgets('taps link button', (tester) async {
    final repo = FakeRepo({});
    final prov = CreatineProvider(repository: repo);
    await prov.loadIntakeDates('u1', DateTime.now().year);

    final fakeLauncher = _FakeLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;

    await pumpScreen(tester, prov);
    await tester.tap(find.text('No creatine?'));
    await tester.pump();
    expect(fakeLauncher.launched, true);
  });
}

class _FakeLauncher extends UrlLauncherPlatform {
  bool launched = false;
  @override
  Future<bool> launchUrl(Uri url, LaunchOptions options) async {
    launched = true;
    return true;
  }

  @override
  Future<bool> canLaunchUrl(Uri url) async => true;
}
