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
  final String gymId;
  final String deviceId;
  final String exerciseId;

  const DeviceScreen({
    Key? key,
    required this.gymId,
    required this.deviceId,
    required this.exerciseId,
  }) : super(key: key);

  @override
  State<DeviceScreen> createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Device + Session-Daten für diese Übung laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<DeviceProvider>().loadDevice(
        gymId:      widget.gymId,
        deviceId:   widget.deviceId,
        exerciseId: widget.exerciseId,
        userId:     auth.userId!,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov   = context.watch<DeviceProvider>();
    final locale = Localizations.localeOf(context).toString();

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

    // — Nur beim reinen Multi-Device-Entry (noch keine Übung gewählt)
    if (prov.device!.isMulti && widget.exerciseId == widget.deviceId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(
          context,
          AppRouter.exerciseList,
          arguments: <String, String>{
            'gymId':    widget.gymId,
            'deviceId': widget.deviceId,
          },
        );
      });
      return const Scaffold();
    }

    // — Jetzt echte Single-Exercise-View —
    return Scaffold(
      appBar: AppBar(
        title: Text(prov.device!.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Verlauf',
            onPressed: () => Navigator.of(context).pushNamed(
              AppRouter.history,
              arguments: widget.deviceId,
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: NoteButtonWidget(deviceId: widget.deviceId),
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
                    // Beschreibung
                    if (prov.device!.description.isNotEmpty) ...[
                      Text(
                        prov.device!.description,
                        style: const TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // — Letzte Session —
                    if (prov.lastSessionSets.isNotEmpty) ...[
                      Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                'Letzte Session: '
                                '${DateFormat.yMd(locale).add_Hm().format(prov.lastSessionDate!)}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              for (var set in prov.lastSessionSets)
                                Row(
                                  children: [
                                    SizedBox(width: 24, child: Text(set['number']!)),
                                    const SizedBox(width: 16),
                                    Expanded(child: Text('${set['weight']} kg')),
                                    const SizedBox(width: 16),
                                    Text('${set['reps']} x'),
                                  ],
                                ),
                              if (prov.lastSessionNote.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text('Notiz: ${prov.lastSessionNote}'),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Divider(),

                    // — Neue Session —
                    const Text(
                      'Neue Session',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),

                    // Eingabefelder für Sets
                    for (var entry in prov.sets.asMap().entries)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(width: 24, child: Text(entry.value['number']!)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                initialValue: entry.value['weight'],
                                decoration: const InputDecoration(
                                  labelText: 'kg',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) =>
                                    prov.updateSet(entry.key, v, entry.value['reps']!),
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
                                initialValue: entry.value['reps'],
                                decoration: const InputDecoration(
                                  labelText: 'x',
                                  isDense: true,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (v) =>
                                    prov.updateSet(entry.key, entry.value['weight']!, v),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Wdh.?';
                                  if (int.tryParse(v) == null) return 'Ganzzahl';
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () => prov.removeSet(entry.key),
                            ),
                          ],
                        ),
                      ),

                    TextButton.icon(
                      onPressed: prov.addSet,
                      icon: const Icon(Icons.add),
                      label: const Text('Set hinzufügen'),
                    ),

                    const Divider(),
                    const RestTimerWidget(),
                  ],
                ),
              ),
            ),
          ),

          // Footer: Abbrechen / Speichern
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
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
                            gymId: widget.gymId,
                            userId: context.read<AuthProvider>().userId!,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Session gespeichert')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
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
