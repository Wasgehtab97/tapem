import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/features/device/domain/models/device_session_snapshot.dart';
import 'package:tapem/features/device/presentation/widgets/read_only_snapshot_page.dart';
import 'package:tapem/l10n/app_localizations.dart';

class _FakeDeviceProvider extends ChangeNotifier implements DeviceProvider {
  @override
  bool get isBodyweightMode => false;

  @override
  DeviceSetFieldFocus? get focusedField => null;

  @override
  int? get focusedIndex => null;

  @override
  int? get focusedDropIndex => null;

  @override
  int get focusRequestId => 0;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('shows drop mini cards under main set', (tester) async {
    final snapshot = DeviceSessionSnapshot(
      sessionId: 's1',
      deviceId: 'd1',
      createdAt: DateTime(2024),
      userId: 'u1',
      sets: const [
        SetEntry(kg: 80, reps: 8),
        SetEntry(kg: 70, reps: 8, drops: [DropEntry(kg: 11, reps: 1)]),
      ],
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<DeviceProvider>(
        create: (_) => _FakeDeviceProvider(),
        child: MaterialApp(
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[
              AppBrandTheme.defaultTheme(),
            ],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: ReadOnlySnapshotPage(snapshot: snapshot),
        ),
      ),
    );
    expect(find.text('11 kg'), findsOneWidget);
    expect(find.text('1 ×'), findsOneWidget);
  });
}
