import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart'
    show overlayNumericKeypadControllerProvider;
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/admin/data/services/challenge_admin_service.dart';

import '../../../../core/providers/auth_providers.dart';

class ChallengeAdminScreen extends StatefulWidget {
  const ChallengeAdminScreen({super.key, this.challengeService});

  final ChallengeAdminService? challengeService;

  @override
  State<ChallengeAdminScreen> createState() => _ChallengeAdminScreenState();
}

class _ChallengeAdminScreenState extends State<ChallengeAdminScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _setCtrl = TextEditingController();
  final _workoutCountCtrl = TextEditingController();
  final _xpCtrl = TextEditingController();
  late final ChallengeAdminService _challengeService;

  String _type = 'weekly';
  String _goalType = 'deviceSets';
  int? _week;
  int? _month;
  int _workoutWindowWeeks = 1;
  final Set<String> _deviceIds = {};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _challengeService = widget.challengeService ?? ChallengeAdminService();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _setCtrl.dispose();
    _workoutCountCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final loc = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final reqSets = int.tryParse(_setCtrl.text) ?? 0;
    final workoutCount = int.tryParse(_workoutCountCtrl.text) ?? 0;
    final xp = int.tryParse(_xpCtrl.text) ?? 0;
    final isWorkoutFrequency = _goalType == 'workoutFrequency';

    final periodInvalid = isWorkoutFrequency
        ? _week == null
        : (_type == 'weekly' && _week == null) ||
              (_type == 'monthly' && _month == null);
    final targetInvalid = isWorkoutFrequency ? workoutCount <= 0 : reqSets <= 0;
    final devicesInvalid = !isWorkoutFrequency && _deviceIds.isEmpty;

    if (title.isEmpty ||
        desc.isEmpty ||
        targetInvalid ||
        xp <= 0 ||
        devicesInvalid ||
        periodInvalid) {
      setState(() => _error = loc.challengeAdminErrorFillAllFields);
      return;
    }

    final gymId = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authControllerProvider).gymCode;
    if (gymId == null) {
      setState(() => _error = loc.invalidGymSelectionError);
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final actorUid = riverpod.ProviderScope.containerOf(
        context,
        listen: false,
      ).read(authControllerProvider).userId;
      final period = isWorkoutFrequency
          ? AdminChallengePeriod.weekly
          : _type == 'weekly'
          ? AdminChallengePeriod.weekly
          : AdminChallengePeriod.monthly;
      final periodValue = period == AdminChallengePeriod.weekly
          ? _week!
          : _month!;
      final goalType = isWorkoutFrequency
          ? AdminChallengeGoalType.workoutFrequency
          : AdminChallengeGoalType.deviceSets;
      final result = await _challengeService.createChallenge(
        ChallengeAdminCreateInput(
          gymId: gymId,
          actorUid: actorUid ?? '',
          title: title,
          description: desc,
          goalType: goalType,
          deviceIds: isWorkoutFrequency
              ? const <String>[]
              : _deviceIds.toList(growable: false),
          minSets: isWorkoutFrequency ? null : reqSets,
          targetWorkouts: isWorkoutFrequency ? workoutCount : null,
          durationWeeks: isWorkoutFrequency ? _workoutWindowWeeks : 1,
          xpReward: xp,
          period: period,
          periodValue: periodValue,
          year: DateTime.now().year,
        ),
      );
      debugPrint('Challenge created with id: ${result.challengeId}');
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() {
        _error = '${loc.errorPrefix}: $e';
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = riverpod.ProviderScope.containerOf(context);
    final devices = container.read(gymProvider).devices;
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(loc.challengeAdminTitle)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleCtrl,
              decoration: InputDecoration(labelText: loc.commonTitle),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              decoration: InputDecoration(labelText: loc.commonDescription),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _setCtrl,
              keyboardType: TextInputType.text,
              readOnly: _goalType != 'deviceSets',
              enabled: _goalType == 'deviceSets',
              autofocus: false,
              onTap: _goalType == 'deviceSets'
                  ? () {
                      final keypad = riverpod.ProviderScope.containerOf(
                        context,
                        listen: false,
                      ).read(overlayNumericKeypadControllerProvider);
                      keypad.openFor(_setCtrl, allowDecimal: false);
                    }
                  : null,
              decoration: InputDecoration(
                labelText: loc.challengeAdminFieldRequiredSets,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _workoutCountCtrl,
              keyboardType: TextInputType.text,
              readOnly: _goalType != 'workoutFrequency',
              enabled: _goalType == 'workoutFrequency',
              autofocus: false,
              onTap: _goalType == 'workoutFrequency'
                  ? () {
                      final keypad = riverpod.ProviderScope.containerOf(
                        context,
                        listen: false,
                      ).read(overlayNumericKeypadControllerProvider);
                      keypad.openFor(_workoutCountCtrl, allowDecimal: false);
                    }
                  : null,
              decoration: InputDecoration(
                labelText: loc.challengeAdminFieldWorkoutCount,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _xpCtrl,
              keyboardType: TextInputType.none,
              readOnly: true,
              autofocus: false,
              onTap: () {
                final keypad = riverpod.ProviderScope.containerOf(
                  context,
                  listen: false,
                ).read(overlayNumericKeypadControllerProvider);
                keypad.openFor(_xpCtrl, allowDecimal: false);
              },
              decoration: InputDecoration(
                labelText: loc.challengeAdminFieldXpReward,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _goalType,
              items: [
                DropdownMenuItem(
                  value: 'deviceSets',
                  child: Text(loc.challengeAdminGoalTypeDeviceSets),
                ),
                DropdownMenuItem(
                  value: 'workoutFrequency',
                  child: Text(loc.challengeAdminGoalTypeWorkoutFrequency),
                ),
              ],
              onChanged: (v) => setState(() {
                _goalType = v ?? 'deviceSets';
                if (_goalType == 'workoutFrequency') {
                  _type = 'weekly';
                  _month = null;
                  _deviceIds.clear();
                  _setCtrl.clear();
                } else {
                  _workoutCountCtrl.clear();
                }
              }),
              decoration: InputDecoration(
                labelText: loc.challengeAdminFieldGoalType,
              ),
            ),
            const SizedBox(height: 8),
            if (_goalType == 'deviceSets')
              DropdownButtonFormField<String>(
                value: _type,
                items: [
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(loc.challengeAdminTypeWeekly),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text(loc.challengeAdminTypeMonthly),
                  ),
                ],
                onChanged: (v) => setState(() {
                  _type = v ?? 'weekly';
                }),
                decoration: InputDecoration(
                  labelText: loc.challengeAdminFieldType,
                ),
              ),
            if (_goalType == 'workoutFrequency')
              TextFormField(
                initialValue: loc.challengeAdminTypeWeekly,
                enabled: false,
                decoration: InputDecoration(
                  labelText: loc.challengeAdminFieldType,
                ),
              ),
            const SizedBox(height: 8),
            if (_type == 'weekly' || _goalType == 'workoutFrequency')
              DropdownButtonFormField<int>(
                value: _week,
                items: [
                  for (var i = 1; i <= 53; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(loc.challengeAdminWeekLabel(i)),
                    ),
                ],
                onChanged: (v) => setState(() => _week = v),
                decoration: InputDecoration(
                  labelText: loc.challengeAdminFieldWeek,
                ),
              )
            else if (_goalType == 'deviceSets')
              DropdownButtonFormField<int>(
                value: _month,
                items: [
                  for (var i = 1; i <= 12; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text(loc.challengeAdminMonthLabel(i)),
                    ),
                ],
                onChanged: (v) => setState(() => _month = v),
                decoration: InputDecoration(
                  labelText: loc.challengeAdminFieldMonth,
                ),
              ),
            if (_goalType == 'workoutFrequency') ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                value: _workoutWindowWeeks,
                items: [
                  DropdownMenuItem(
                    value: 1,
                    child: Text(loc.challengeAdminWorkoutWindowOneWeek),
                  ),
                  DropdownMenuItem(
                    value: 4,
                    child: Text(loc.challengeAdminWorkoutWindowFourWeeks),
                  ),
                ],
                onChanged: (v) => setState(() => _workoutWindowWeeks = v ?? 1),
                decoration: InputDecoration(
                  labelText: loc.challengeAdminFieldWorkoutWindow,
                ),
              ),
            ],
            const SizedBox(height: 16),
            if (_goalType == 'deviceSets') ...[
              Text(
                loc.challengeAdminFieldDevices,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(
                height: 150,
                child: ListView(
                  children: [
                    for (final d in devices)
                      CheckboxListTile(
                        value: _deviceIds.contains(d.uid),
                        title: Text('${d.name} (${d.id})'),
                        onChanged: (v) => setState(() {
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
            ],
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
              child: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(loc.challengeAdminCreateButton),
            ),
          ],
        ),
      ),
    );
  }
}
