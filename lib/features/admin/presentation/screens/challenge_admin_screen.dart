import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:intl/intl.dart';
import 'package:tapem/features/admin/data/services/challenge_admin_service.dart';
import 'package:tapem/features/challenges/domain/models/challenge.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/ui/numeric_keypad/overlay_numeric_keypad.dart'
    show overlayNumericKeypadControllerProvider;

import '../../../../core/providers/auth_providers.dart';

class ChallengeAdminScreen extends StatefulWidget {
  const ChallengeAdminScreen({super.key, this.challengeService});

  final ChallengeAdminService? challengeService;

  @override
  State<ChallengeAdminScreen> createState() => _ChallengeAdminScreenState();
}

class _ChallengeAdminScreenState extends State<ChallengeAdminScreen>
    with SingleTickerProviderStateMixin {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _setCtrl = TextEditingController();
  final _workoutCountCtrl = TextEditingController();
  final _repsCtrl = TextEditingController();
  final _volumeCtrl = TextEditingController();
  final _varietyCtrl = TextEditingController();
  final _xpCtrl = TextEditingController();

  late final ChallengeAdminService _challengeService;
  late final TabController _tabController;

  AdminChallengePeriod _period = AdminChallengePeriod.weekly;
  AdminChallengeGoalType _goalType = AdminChallengeGoalType.deviceSets;
  int? _week;
  int? _month;
  int _workoutWindowWeeks = 1;
  String? _selectedTemplateId;
  final Set<String> _deviceIds = {};
  bool _saving = false;
  String? _error;

  Future<List<AdminChallengeCampaign>>? _campaignsFuture;
  String? _lastLoadedGymId;

  @override
  void initState() {
    super.initState();
    _challengeService = widget.challengeService ?? ChallengeAdminService();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gymId = _readGymId();
    if (gymId != null && gymId != _lastLoadedGymId) {
      _lastLoadedGymId = gymId;
      _reloadCampaigns();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _setCtrl.dispose();
    _workoutCountCtrl.dispose();
    _repsCtrl.dispose();
    _volumeCtrl.dispose();
    _varietyCtrl.dispose();
    _xpCtrl.dispose();
    super.dispose();
  }

  String? _readGymId() {
    return riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(authControllerProvider).gymCode;
  }

  void _reloadCampaigns() {
    final gymId = _readGymId();
    if (gymId == null) {
      setState(() {
        _campaignsFuture = null;
      });
      return;
    }
    setState(() {
      _campaignsFuture = _challengeService.loadChallengeCampaigns(gymId: gymId);
    });
  }

  int _currentIsoWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final thursday = normalized.add(Duration(days: 4 - normalized.weekday));
    final firstThursday = DateTime(thursday.year, 1, 4);
    final firstWeekStart = firstThursday.subtract(
      Duration(days: firstThursday.weekday - 1),
    );
    return (thursday.difference(firstWeekStart).inDays / 7).floor() + 1;
  }

  void _openIntKeypad(TextEditingController controller) {
    final keypad = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    ).read(overlayNumericKeypadControllerProvider);
    keypad.openFor(controller, allowDecimal: false);
  }

  List<_ChallengeTemplate> _templatesForLocale(Locale locale) {
    final isDe = locale.languageCode.toLowerCase().startsWith('de');
    return [
      _ChallengeTemplate(
        id: 'week_2x',
        title: isDe ? 'Wochenstart (2x)' : 'Week Starter (2x)',
        description: isDe
            ? 'Trainiere 2x in einer Kalenderwoche.'
            : 'Train 2x in one calendar week.',
        goalType: AdminChallengeGoalType.workoutFrequency,
        targetWorkouts: 2,
        durationWeeks: 1,
        xpReward: 40,
      ),
      _ChallengeTemplate(
        id: 'week_4x',
        title: isDe ? 'Unstoppable (4x)' : 'Unstoppable (4x)',
        description: isDe
            ? 'Trainiere 4x in einer Kalenderwoche.'
            : 'Train 4x in one calendar week.',
        goalType: AdminChallengeGoalType.workoutFrequency,
        targetWorkouts: 4,
        durationWeeks: 1,
        xpReward: 90,
      ),
      _ChallengeTemplate(
        id: 'block_12x_4w',
        title: isDe ? 'Fokusblock (12x/4W)' : 'Focus Block (12x/4W)',
        description: isDe
            ? 'Trainiere 12x in 4 Kalenderwochen.'
            : 'Train 12x in 4 calendar weeks.',
        goalType: AdminChallengeGoalType.workoutFrequency,
        targetWorkouts: 12,
        durationWeeks: 4,
        xpReward: 170,
      ),
      _ChallengeTemplate(
        id: 'sets_35',
        title: isDe ? 'Satz-Jagd (35)' : 'Set Hunt (35)',
        description: isDe
            ? '35 Satze auf ausgewahlten Geraten.'
            : '35 sets on selected devices.',
        goalType: AdminChallengeGoalType.deviceSets,
        minSets: 35,
        xpReward: 110,
      ),
      _ChallengeTemplate(
        id: 'reps_1200',
        title: isDe ? 'Reps-Rush (1200)' : 'Reps Rush (1200)',
        description: isDe
            ? 'Sammle 1200 Wiederholungen im Zeitraum.'
            : 'Accumulate 1200 reps in the selected period.',
        goalType: AdminChallengeGoalType.totalReps,
        targetReps: 1200,
        xpReward: 130,
      ),
      _ChallengeTemplate(
        id: 'volume_12000',
        title: isDe ? 'Volume-Boost (12k)' : 'Volume Boost (12k)',
        description: isDe
            ? 'Bewege 12.000 kg Gesamtvolumen im Zeitraum.'
            : 'Move 12,000 kg of total volume in the selected period.',
        goalType: AdminChallengeGoalType.totalVolume,
        targetVolume: 12000,
        xpReward: 150,
      ),
      _ChallengeTemplate(
        id: 'variety_6',
        title: isDe ? 'Explorer (6 Gerate)' : 'Explorer (6 devices)',
        description: isDe
            ? 'Trainiere an 6 verschiedenen Geraten.'
            : 'Train on 6 different devices.',
        goalType: AdminChallengeGoalType.deviceVariety,
        targetDistinctDevices: 6,
        xpReward: 140,
      ),
    ];
  }

  void _applyTemplate(_ChallengeTemplate template) {
    final now = DateTime.now();
    final currentWeek = _currentIsoWeek(now).clamp(1, 53);
    setState(() {
      _selectedTemplateId = template.id;
      _titleCtrl.text = template.title;
      _descCtrl.text = template.description;
      _xpCtrl.text = template.xpReward.toString();
      _goalType = template.goalType;
      _period = AdminChallengePeriod.weekly;
      _week = currentWeek;
      _month = now.month;
      _workoutWindowWeeks = template.durationWeeks ?? 1;
      _error = null;

      _setCtrl.text = template.minSets?.toString() ?? '';
      _workoutCountCtrl.text = template.targetWorkouts?.toString() ?? '';
      _repsCtrl.text = template.targetReps?.toString() ?? '';
      _volumeCtrl.text = template.targetVolume?.toString() ?? '';
      _varietyCtrl.text = template.targetDistinctDevices?.toString() ?? '';

      if (_goalType == AdminChallengeGoalType.workoutFrequency) {
        _period = AdminChallengePeriod.weekly;
      }
    });
  }

  void _resetCreateForm() {
    final now = DateTime.now();
    setState(() {
      _titleCtrl.clear();
      _descCtrl.clear();
      _setCtrl.clear();
      _workoutCountCtrl.clear();
      _repsCtrl.clear();
      _volumeCtrl.clear();
      _varietyCtrl.clear();
      _xpCtrl.clear();
      _period = AdminChallengePeriod.weekly;
      _goalType = AdminChallengeGoalType.deviceSets;
      _week = _currentIsoWeek(now).clamp(1, 53);
      _month = now.month;
      _workoutWindowWeeks = 1;
      _selectedTemplateId = null;
      _deviceIds.clear();
      _error = null;
    });
  }

  String _createSuccessMessage(AppLocalizations loc) {
    final isDe = loc.localeName.toLowerCase().startsWith('de');
    if (isDe) {
      return 'Challenge erstellt.';
    }
    return 'Challenge created.';
  }

  AdminChallengePeriod get _effectivePeriod =>
      _goalType == AdminChallengeGoalType.workoutFrequency
      ? AdminChallengePeriod.weekly
      : _period;

  Future<void> _create() async {
    final loc = AppLocalizations.of(context)!;
    final title = _titleCtrl.text.trim();
    final desc = _descCtrl.text.trim();
    final minSets = int.tryParse(_setCtrl.text.trim()) ?? 0;
    final workouts = int.tryParse(_workoutCountCtrl.text.trim()) ?? 0;
    final reps = int.tryParse(_repsCtrl.text.trim()) ?? 0;
    final volume = int.tryParse(_volumeCtrl.text.trim()) ?? 0;
    final variety = int.tryParse(_varietyCtrl.text.trim()) ?? 0;
    final xp = int.tryParse(_xpCtrl.text.trim()) ?? 0;
    final period = _effectivePeriod;
    final periodValue = period == AdminChallengePeriod.weekly ? _week : _month;

    var targetValid = false;
    switch (_goalType) {
      case AdminChallengeGoalType.deviceSets:
        targetValid = minSets > 0 && _deviceIds.isNotEmpty;
        break;
      case AdminChallengeGoalType.workoutFrequency:
        targetValid = workouts > 0;
        break;
      case AdminChallengeGoalType.totalReps:
        targetValid = reps > 0;
        break;
      case AdminChallengeGoalType.totalVolume:
        targetValid = volume > 0;
        break;
      case AdminChallengeGoalType.deviceVariety:
        targetValid = variety > 1;
        break;
    }

    if (title.isEmpty ||
        desc.isEmpty ||
        xp <= 0 ||
        !targetValid ||
        periodValue == null) {
      setState(() => _error = loc.challengeAdminErrorFillAllFields);
      return;
    }

    final gymId = _readGymId();
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
      final result = await _challengeService.createChallenge(
        ChallengeAdminCreateInput(
          gymId: gymId,
          actorUid: actorUid ?? '',
          title: title,
          description: desc,
          goalType: _goalType,
          deviceIds: _goalType == AdminChallengeGoalType.deviceSets
              ? _deviceIds.toList(growable: false)
              : const <String>[],
          minSets: _goalType == AdminChallengeGoalType.deviceSets
              ? minSets
              : null,
          targetWorkouts: _goalType == AdminChallengeGoalType.workoutFrequency
              ? workouts
              : null,
          targetReps: _goalType == AdminChallengeGoalType.totalReps
              ? reps
              : null,
          targetVolume: _goalType == AdminChallengeGoalType.totalVolume
              ? volume
              : null,
          targetDistinctDevices:
              _goalType == AdminChallengeGoalType.deviceVariety
              ? variety
              : null,
          durationWeeks: _goalType == AdminChallengeGoalType.workoutFrequency
              ? _workoutWindowWeeks
              : 1,
          xpReward: xp,
          period: period,
          periodValue: periodValue,
          year: DateTime.now().year,
        ),
      );
      debugPrint('Challenge created with id: ${result.challengeId}');
      if (!mounted) return;
      setState(() {
        _saving = false;
      });
      _reloadCampaigns();
      _resetCreateForm();
      _tabController.animateTo(0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_createSuccessMessage(loc))));
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(loc.challengeAdminTitle)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _OverviewCard(
              future: _campaignsFuture,
              activeLabel: loc.challengeTabActive,
              completedLabel: loc.challengeTabCompleted,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withOpacity(0.35),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.onSurface.withOpacity(0.08),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: theme.colorScheme.primary.withOpacity(0.2),
                ),
                labelColor: theme.colorScheme.onSurface,
                unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(
                  0.6,
                ),
                tabs: [
                  Tab(text: loc.challengeTabActive),
                  Tab(text: loc.challengeTabCompleted),
                  Tab(text: loc.commonCreate),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _CampaignsTab(
                  future: _campaignsFuture,
                  showCompleted: false,
                  emptyText: loc.challengeEmptyActive,
                  goalLabelBuilder: (challenge) =>
                      _campaignGoalLabel(challenge: challenge, loc: loc),
                ),
                _CampaignsTab(
                  future: _campaignsFuture,
                  showCompleted: true,
                  emptyText: loc.challengeEmptyCompleted,
                  goalLabelBuilder: (challenge) =>
                      _campaignGoalLabel(challenge: challenge, loc: loc),
                ),
                _buildCreateTab(loc: loc, devices: devices),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateTab({
    required AppLocalizations loc,
    required List<dynamic> devices,
  }) {
    final templates = _templatesForLocale(Localizations.localeOf(context));

    return RefreshIndicator(
      onRefresh: () async => _reloadCampaigns(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
          _SectionCard(
            title: loc.challengeAdminTemplatesTitle,
            subtitle: loc.challengeAdminTemplatesHint,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final template in templates)
                  ChoiceChip(
                    label: Text(template.title),
                    selected: _selectedTemplateId == template.id,
                    onSelected: (_) => _applyTemplate(template),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: loc.commonTitle,
            child: Column(
              children: [
                TextField(
                  controller: _titleCtrl,
                  decoration: InputDecoration(labelText: loc.commonTitle),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descCtrl,
                  minLines: 2,
                  maxLines: 3,
                  decoration: InputDecoration(labelText: loc.commonDescription),
                ),
                const SizedBox(height: 8),
                _buildNumericField(
                  controller: _xpCtrl,
                  label: loc.challengeAdminFieldXpReward,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: loc.challengeAdminFieldGoalType,
            child: Column(
              children: [
                DropdownButtonFormField<AdminChallengeGoalType>(
                  value: _goalType,
                  items: [
                    DropdownMenuItem(
                      value: AdminChallengeGoalType.deviceSets,
                      child: Text(loc.challengeAdminGoalTypeDeviceSets),
                    ),
                    DropdownMenuItem(
                      value: AdminChallengeGoalType.workoutFrequency,
                      child: Text(loc.challengeAdminGoalTypeWorkoutFrequency),
                    ),
                    DropdownMenuItem(
                      value: AdminChallengeGoalType.totalReps,
                      child: Text(loc.challengeAdminGoalTypeTotalReps),
                    ),
                    DropdownMenuItem(
                      value: AdminChallengeGoalType.totalVolume,
                      child: Text(loc.challengeAdminGoalTypeTotalVolume),
                    ),
                    DropdownMenuItem(
                      value: AdminChallengeGoalType.deviceVariety,
                      child: Text(loc.challengeAdminGoalTypeDeviceVariety),
                    ),
                  ],
                  onChanged: (value) => setState(() {
                    _goalType = value ?? AdminChallengeGoalType.deviceSets;
                    if (_goalType == AdminChallengeGoalType.workoutFrequency) {
                      _period = AdminChallengePeriod.weekly;
                    }
                    _selectedTemplateId = null;
                  }),
                  decoration: InputDecoration(
                    labelText: loc.challengeAdminFieldGoalType,
                  ),
                ),
                const SizedBox(height: 8),
                if (_goalType == AdminChallengeGoalType.deviceSets)
                  _buildNumericField(
                    controller: _setCtrl,
                    label: loc.challengeAdminFieldRequiredSets,
                  ),
                if (_goalType == AdminChallengeGoalType.workoutFrequency) ...[
                  _buildNumericField(
                    controller: _workoutCountCtrl,
                    label: loc.challengeAdminFieldWorkoutCount,
                  ),
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
                    onChanged: (v) =>
                        setState(() => _workoutWindowWeeks = v ?? 1),
                    decoration: InputDecoration(
                      labelText: loc.challengeAdminFieldWorkoutWindow,
                    ),
                  ),
                ],
                if (_goalType == AdminChallengeGoalType.totalReps)
                  _buildNumericField(
                    controller: _repsCtrl,
                    label: loc.challengeAdminFieldTargetReps,
                  ),
                if (_goalType == AdminChallengeGoalType.totalVolume)
                  _buildNumericField(
                    controller: _volumeCtrl,
                    label: loc.challengeAdminFieldTargetVolume,
                  ),
                if (_goalType == AdminChallengeGoalType.deviceVariety)
                  _buildNumericField(
                    controller: _varietyCtrl,
                    label: loc.challengeAdminFieldTargetDistinctDevices,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SectionCard(
            title: loc.challengeAdminFieldType,
            child: Column(
              children: [
                if (_goalType == AdminChallengeGoalType.workoutFrequency)
                  TextFormField(
                    initialValue: loc.challengeAdminTypeWeekly,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: loc.challengeAdminFieldType,
                    ),
                  )
                else
                  DropdownButtonFormField<AdminChallengePeriod>(
                    value: _period,
                    items: [
                      DropdownMenuItem(
                        value: AdminChallengePeriod.weekly,
                        child: Text(loc.challengeAdminTypeWeekly),
                      ),
                      DropdownMenuItem(
                        value: AdminChallengePeriod.monthly,
                        child: Text(loc.challengeAdminTypeMonthly),
                      ),
                    ],
                    onChanged: (v) => setState(
                      () => _period = v ?? AdminChallengePeriod.weekly,
                    ),
                    decoration: InputDecoration(
                      labelText: loc.challengeAdminFieldType,
                    ),
                  ),
                const SizedBox(height: 8),
                if (_effectivePeriod == AdminChallengePeriod.weekly)
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
                else
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
              ],
            ),
          ),
          if (_goalType == AdminChallengeGoalType.deviceSets) ...[
            const SizedBox(height: 10),
            _SectionCard(
              title: loc.challengeAdminFieldDevices,
              subtitle:
                  '${_deviceIds.length} / ${devices.length} ${loc.challengeAdminFieldDevices.toLowerCase()}',
              child: SizedBox(
                height: 180,
                child: ListView(
                  children: [
                    for (final d in devices)
                      CheckboxListTile(
                        dense: true,
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
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _create,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_task_rounded),
              label: Text(loc.challengeAdminCreateButton),
            ),
          ),
        ],
      ),
    );
  }

  String _campaignGoalLabel({
    required Challenge challenge,
    required AppLocalizations loc,
  }) {
    switch (challenge.goalType) {
      case ChallengeGoalType.deviceSets:
        return loc.challengeDetailGoalDeviceSets(challenge.minSets);
      case ChallengeGoalType.workoutDays:
        return loc.challengeDetailGoalWorkoutFrequency(
          challenge.targetWorkouts,
          challenge.durationWeeks,
        );
      case ChallengeGoalType.totalReps:
        return loc.challengeDetailGoalTotalReps(challenge.targetReps);
      case ChallengeGoalType.totalVolume:
        return loc.challengeDetailGoalTotalVolume(challenge.targetVolume);
      case ChallengeGoalType.deviceVariety:
        return loc.challengeDetailGoalDeviceVariety(
          challenge.targetDistinctDevices,
        );
    }
  }

  Widget _buildNumericField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.none,
      readOnly: true,
      autofocus: false,
      onTap: () => _openIntKeypad(controller),
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _CampaignsTab extends StatelessWidget {
  const _CampaignsTab({
    required this.future,
    required this.showCompleted,
    required this.emptyText,
    required this.goalLabelBuilder,
  });

  final Future<List<AdminChallengeCampaign>>? future;
  final bool showCompleted;
  final String emptyText;
  final String Function(Challenge challenge) goalLabelBuilder;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return FutureBuilder<List<AdminChallengeCampaign>>(
      future: future,
      builder: (context, snapshot) {
        if (future == null) {
          return Center(
            child: Text(
              loc.invalidGymSelectionError,
              style: theme.textTheme.bodyMedium,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              '${loc.errorPrefix}: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final campaigns = List<AdminChallengeCampaign>.from(
          snapshot.data ?? const <AdminChallengeCampaign>[],
        );
        final now = DateTime.now();

        final filtered = campaigns
            .where((entry) {
              final challenge = entry.challenge;
              if (showCompleted) {
                return challenge.end.isBefore(now);
              }
              return !challenge.start.isAfter(now) &&
                  !challenge.end.isBefore(now);
            })
            .toList(growable: false);

        filtered.sort((a, b) {
          if (showCompleted) {
            return b.challenge.end.compareTo(a.challenge.end);
          }
          return a.challenge.end.compareTo(b.challenge.end);
        });

        if (filtered.isEmpty) {
          return Center(
            child: Text(
              emptyText,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
          itemBuilder: (context, index) => _CampaignCard(
            entry: filtered[index],
            goalLabel: goalLabelBuilder(filtered[index].challenge),
          ),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemCount: filtered.length,
        );
      },
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({required this.entry, required this.goalLabel});

  final AdminChallengeCampaign entry;
  final String goalLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = AppLocalizations.of(context)!;
    final challenge = entry.challenge;
    final now = DateTime.now();
    final completed = challenge.end.isBefore(now);
    final dateFormat = DateFormat.Md(loc.localeName);
    final periodLabel = entry.period == AdminChallengePeriod.weekly
        ? loc.challengeAdminTypeWeekly
        : loc.challengeAdminTypeMonthly;
    final rangeText =
        '${dateFormat.format(challenge.start.toLocal())} - ${dateFormat.format(challenge.end.toLocal())}';

    String statusText;
    if (completed) {
      final isDe = loc.localeName.toLowerCase().startsWith('de');
      statusText = isDe ? 'Abgeschlossen' : 'Completed';
    } else {
      final left = challenge.end.difference(now).inDays + 1;
      final isDe = loc.localeName.toLowerCase().startsWith('de');
      if (isDe) {
        statusText = 'Endet in ${left.clamp(0, 999)} Tagen';
      } else {
        statusText = 'Ends in ${left.clamp(0, 999)} days';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withOpacity(0.36),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: theme.colorScheme.primary.withOpacity(0.16),
                ),
                child: Text(
                  '+${challenge.xpReward} XP',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            goalLabel,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetaChip(label: periodLabel),
              _MetaChip(label: rangeText),
              _MetaChip(label: statusText),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surface.withOpacity(0.45),
        border: Border.all(color: theme.colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.future,
    required this.activeLabel,
    required this.completedLabel,
  });

  final Future<List<AdminChallengeCampaign>>? future;
  final String activeLabel;
  final String completedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FutureBuilder<List<AdminChallengeCampaign>>(
      future: future,
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <AdminChallengeCampaign>[];
        final now = DateTime.now();
        final activeCount = all
            .where(
              (entry) =>
                  !entry.challenge.start.isAfter(now) &&
                  !entry.challenge.end.isBefore(now),
            )
            .length;
        final completedCount = all
            .where((entry) => entry.challenge.end.isBefore(now))
            .length;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withOpacity(0.16),
                theme.colorScheme.secondary.withOpacity(0.08),
              ],
            ),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: _OverviewStat(
                  label: activeLabel,
                  value: activeCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewStat(
                  label: completedLabel,
                  value: completedCount.toString(),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _OverviewStat(
                  label: 'Total',
                  value: all.length.toString(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withOpacity(0.26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.66),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surface.withOpacity(0.34),
        border: Border.all(
          color: theme.colorScheme.onSurface.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.62),
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChallengeTemplate {
  const _ChallengeTemplate({
    required this.id,
    required this.title,
    required this.description,
    required this.goalType,
    required this.xpReward,
    this.minSets,
    this.targetWorkouts,
    this.targetReps,
    this.targetVolume,
    this.targetDistinctDevices,
    this.durationWeeks,
  });

  final String id;
  final String title;
  final String description;
  final AdminChallengeGoalType goalType;
  final int xpReward;
  final int? minSets;
  final int? targetWorkouts;
  final int? targetReps;
  final int? targetVolume;
  final int? targetDistinctDevices;
  final int? durationWeeks;
}
