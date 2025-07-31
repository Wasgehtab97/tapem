import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/providers/auth_provider.dart';
import '../../../../core/providers/gym_provider.dart';

class ChallengeAdminScreen extends StatefulWidget {
  const ChallengeAdminScreen({Key? key}) : super(key: key);

  @override
  State<ChallengeAdminScreen> createState() => _ChallengeAdminScreenState();
}

class _ChallengeAdminScreenState extends State<ChallengeAdminScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _setCtrl = TextEditingController();
  final _xpCtrl = TextEditingController();

  String _type = 'weekly';
  int? _week;
  int? _month;
  final Set<String> _deviceIds = {};
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _setCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  DateTime _startOfWeek(int year, int week) {
    final jan4 = DateTime(year, 1, 4);
    final startOfWeek1 = jan4.subtract(Duration(days: jan4.weekday - 1));
    return startOfWeek1.add(Duration(days: (week - 1) * 7));
  }

  Future<void> _create() async {
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final reqSets = int.tryParse(_setCtrl.text) ?? 0;
    final xp = int.tryParse(_xpCtrl.text) ?? 0;

    if (title.isEmpty ||
        desc.isEmpty ||
        reqSets <= 0 ||
        xp <= 0 ||
        _deviceIds.isEmpty ||
        (_type == 'weekly' && _week == null) ||
        (_type == 'monthly' && _month == null)) {
      setState(() => _error = 'Alle Felder ausfüllen');
      return;
    }

    final gymId = context.read<AuthProvider>().gymCode!;
    final year = DateTime.now().year;
    DateTime start;
    DateTime end;
    final data = <String, dynamic>{
      'title': title,
      'description': desc,
      'deviceIds': _deviceIds.toList(),
      'minSets': reqSets,
      'xpReward': xp,
    };

    if (_type == 'weekly') {
      start = _startOfWeek(year, _week!);
      end = start
          .add(const Duration(days: 7))
          .subtract(const Duration(milliseconds: 1));
      data['startWeek'] = _week;
      data['endWeek'] = _week;
    } else {
      start = DateTime(year, _month!, 1);
      end = DateTime(
        year,
        _month! + 1,
        1,
      ).subtract(const Duration(milliseconds: 1));
      data['startMonth'] = _month;
      data['endMonth'] = _month;
    }

    data['start'] = Timestamp.fromDate(start);
    data['end'] = Timestamp.fromDate(end);

    setState(() {
      _saving = true;
      _error = null;
    });

    final colName = _type == 'weekly' ? 'weekly' : 'monthly';
    final col = FirebaseFirestore.instance
        .collection('gyms')
        .doc(gymId)
        .collection('challenges')
        .doc(colName)
        .collection('items');
    try {
      print('Creating challenge in gym $gymId/$colName: $data');
      final docRef = await col.add(data);
      print('Challenge created with id: ${docRef.id}');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = 'Fehler: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = context.watch<GymProvider>().devices;
    return Scaffold(
      appBar: AppBar(title: const Text('Challenges verwalten')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titel'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Beschreibung'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _setCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Benötigte Sätze'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _xpCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'XP-Reward'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _type,
              items: const [
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged:
                  (v) => setState(() {
                    _type = v ?? 'weekly';
                  }),
              decoration: const InputDecoration(labelText: 'Typ'),
            ),
            const SizedBox(height: 8),
            if (_type == 'weekly')
              DropdownButtonFormField<int>(
                value: _week,
                items: [
                  for (var i = 1; i <= 53; i++)
                    DropdownMenuItem(value: i, child: Text('KW $i')),
                ],
                onChanged: (v) => setState(() => _week = v),
                decoration: const InputDecoration(labelText: 'Kalenderwoche'),
              )
            else
              DropdownButtonFormField<int>(
                value: _month,
                items: [
                  for (var i = 1; i <= 12; i++)
                    DropdownMenuItem(value: i, child: Text('Monat $i')),
                ],
                onChanged: (v) => setState(() => _month = v),
                decoration: const InputDecoration(labelText: 'Monat'),
              ),
            const SizedBox(height: 16),
            const Text('Geräte', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(
              height: 150,
              child: ListView(
                children: [
                  for (final d in devices)
                    CheckboxListTile(
                      value: _deviceIds.contains(d.uid),
                      title: Text('${d.name} (${d.id})'),
                      onChanged:
                          (v) => setState(() {
                            if (v == true) {
                              _deviceIds.add(d.uid);
                            } else {
                              _deviceIds.remove(d.uid);
                            }
                          }),
                    ),
                ],
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saving ? null : _create,
              child:
                  _saving
                      ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Challenge anlegen'),
            ),
          ],
        ),
      ),
    );
  }
}
