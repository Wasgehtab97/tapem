// lib/features/device/presentation/screens/device_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/providers/device_provider.dart';
import '../widgets/rest_timer_widget.dart';
import '../widgets/note_button_widget.dart';

class DeviceScreen extends StatefulWidget {
  final String deviceId;
  const DeviceScreen({Key? key, required this.deviceId}) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProv = context.read<AuthProvider>();
      final gymId  = authProv.gymCode;
      final userId = authProv.userId;
      if (gymId != null && userId != null) {
        context.read<DeviceProvider>().loadDevice(
          gymId: gymId,
          deviceId: widget.deviceId,
          userId: userId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext c) {
    final prov   = c.watch<DeviceProvider>();
    final auth   = c.read<AuthProvider>();
    final locale = Localizations.localeOf(c).toString();
    final dateStr = DateFormat.yMMMEd(locale).format(DateTime.now());

    if (prov.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (prov.error != null || prov.device == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Gerät nicht gefunden')),
        body: Center(child: Text('Fehler: ${prov.error ?? "Unbekannt"}')),
      );
    }

    return Scaffold(
      // 1) FAB anheben + nach rechts einrücken
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0, right: 16.0),
        child: NoteButtonWidget(deviceId: widget.deviceId),
      ),

      appBar: AppBar(
        leading: BackButton(onPressed: () => Navigator.pop(c)),
        title: Row(
          children: [
            const FlutterLogo(size: 28),
            const SizedBox(width: 12),
            Expanded(child: Text(dateStr, textAlign: TextAlign.center)),
            const SizedBox(width: 32),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Verlauf',
            onPressed: () => Navigator.of(c).pushNamed(
              AppRouter.history,
              arguments: widget.deviceId,
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Gerätedaten
                    Text(
                      prov.device!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (prov.device!.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4, bottom: 12),
                        child: Text(
                          prov.device!.description,
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                    const Divider(),

                    // Letzte Session
                    if (prov.lastSessionSets.isNotEmpty) ...[
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Letzte Session: ${DateFormat.yMd(locale).add_Hm().format(prov.lastSessionDate!)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...prov.lastSessionSets.map((set) {
                                return Row(
                                  children: [
                                    SizedBox(
                                      width: 24,
                                      child: Text(set['number']!),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text('${set['weight']} kg')),
                                    const SizedBox(width: 16),
                                    Text('${set['reps']} x'),
                                  ],
                                );
                              }),
                              if (prov.lastSessionNote.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Notiz: ${prov.lastSessionNote}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    // Neue Session
                    const Text(
                      'Neue Session',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...prov.sets.asMap().entries.map((e) {
                      final i = e.key;
                      final set = e.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 24, child: Text(set['number']!)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: set['weight'],
                                decoration: const InputDecoration(
                                  labelText: 'kg',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => prov.updateSet(i, v, set['reps']!),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Gewicht?';
                                  if (double.tryParse(v) == null) return 'Zahl eingeben';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: set['reps'],
                                decoration: const InputDecoration(
                                  labelText: 'x',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) => prov.updateSet(i, set['weight']!, v),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Wdh.?';
                                  if (int.tryParse(v) == null) return 'Ganzzahl';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => prov.removeSet(i),
                            ),
                          ],
                        ),
                      );
                    }),
                    TextButton.icon(
                      onPressed: prov.addSet,
                      icon: const Icon(Icons.add),
                      label: const Text('Set hinzufügen'),
                    ),
                    const Divider(),

                    // Rest-Timer
                    const RestTimerWidget(),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(c),
                    child: const Text('Abbrechen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        try {
                          await prov.saveSession(
                            gymId: auth.gymCode!,
                            userId: auth.userId!,
                          );
                          ScaffoldMessenger.of(c).showSnackBar(
                            const SnackBar(content: Text('Session gespeichert')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(c).showSnackBar(
                            SnackBar(content: Text('Fehler: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Speichern'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
