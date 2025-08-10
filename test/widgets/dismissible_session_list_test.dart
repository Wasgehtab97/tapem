import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import 'package:tapem/features/device/presentation/widgets/set_card.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/device/domain/usecases/get_devices_for_gym.dart';
import 'package:tapem/features/device/domain/repositories/device_repository.dart';
import 'package:tapem/features/device/domain/models/device.dart';

class _FakeRepo implements DeviceRepository {
  @override
  Future<List<Device>> getDevicesForGym(String gymId) async => [];
  @override
  Future<void> createDevice(String gymId, Device device) => throw UnimplementedError();
  @override
  Future<Device?> getDeviceByNfcCode(String gymId, String nfcCode) => throw UnimplementedError();
  @override
  Future<void> deleteDevice(String gymId, String deviceId) => throw UnimplementedError();
  @override
  Future<void> updateMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) => throw UnimplementedError();
  @override
  Future<void> setMuscleGroups(String gymId, String deviceId, List<String> primaryGroups, List<String> secondaryGroups) => throw UnimplementedError();
}

class _TestList extends StatelessWidget {
  const _TestList();
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<DeviceProvider>();
    final loc = AppLocalizations.of(context)!;
    return ListView(
      children: [
        for (var entry in prov.sets.asMap().entries)
          Dismissible(
            key: ValueKey('set-${entry.key}-${entry.value['number']}'),
            direction: DismissDirection.endToStart,
            background: const SizedBox.shrink(),
            secondaryBackground: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.red.withOpacity(0.15),
              child: const Icon(Icons.delete, semanticLabel: 'Löschen'),
            ),
            onDismissed: (_) {
              final removed = Map<String, dynamic>.from(entry.value);
              final removedIndex = entry.key;
              context.read<DeviceProvider>().removeSet(entry.key);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.setRemoved),
                  action: SnackBarAction(
                    label: loc.undo,
                    onPressed: () => context
                        .read<DeviceProvider>()
                        .insertSetAt(removedIndex, removed),
                  ),
                ),
              );
            },
            child: SetCard(index: entry.key, set: entry.value),
          ),
      ],
    );
  }
}

void main() {
  testWidgets('swipe left deletes set with undo', (tester) async {
    final provider = DeviceProvider(
      firestore: FakeFirebaseFirestore(),
      getDevicesForGym: GetDevicesForGym(_FakeRepo()),
      log: (_, [__]) {},
    );
    provider.addSet();
    provider.addSet();

    await tester.pumpWidget(
      ChangeNotifierProvider<DeviceProvider>.value(
        value: provider,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('de'),
          home: const Scaffold(body: _TestList()),
        ),
      ),
    );

    expect(find.text('Session bearbeiten'), findsNothing);

    final before = provider.sets.length;
    await tester.drag(find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(provider.sets.length, before - 1);
    expect(find.text('Satz entfernt'), findsOneWidget);

    await tester.tap(find.text('Rückgängig'));
    await tester.pumpAndSettle();

    expect(provider.sets.length, before);
  });
}
