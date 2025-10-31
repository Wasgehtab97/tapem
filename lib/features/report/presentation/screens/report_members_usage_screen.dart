import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';

import '../../data/training_day_repository.dart';
import '../../domain/gym_member.dart';

class ReportMembersUsageScreen extends StatelessWidget {
  const ReportMembersUsageScreen({super.key, required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportMembersUsageTitle),
        centerTitle: true,
        foregroundColor: brandColor,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: _UsageContent(gymId: gymId),
        ),
      ),
    );
  }
}

class _UsageContent extends StatelessWidget {
  const _UsageContent({required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final query = FirebaseFirestore.instance
        .collection('gyms')
        .doc(gymId)
        .collection('users')
        .orderBy('memberNumber');

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              loc.reportMembersLoadError,
              textAlign: TextAlign.center,
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data?.docs
                .map(GymMember.fromSnapshot)
                .whereType<GymMember>()
                .where((member) => member.memberNumber.isNotEmpty)
                .toList() ??
            [];

        if (members.isEmpty) {
          return Center(
            child: Text(
              loc.reportMembersUsageNoMembers,
              textAlign: TextAlign.center,
            ),
          );
        }

        return _UsageDistribution(members: members);
      },
    );
  }
}

class _UsageDistribution extends StatefulWidget {
  const _UsageDistribution({required this.members});

  final List<GymMember> members;

  @override
  State<_UsageDistribution> createState() => _UsageDistributionState();
}

class _UsageDistributionState extends State<_UsageDistribution> {
  final _trainingDayRepository = TrainingDayRepository();
  Future<Map<String, int>>? _trainingDayCountsFuture;
  List<String> _memberIds = const [];

  @override
  void initState() {
    super.initState();
    _scheduleLoad(widget.members);
  }

  @override
  void didUpdateWidget(covariant _UsageDistribution oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextIds = _extractIds(widget.members);
    if (!listEquals(_memberIds, nextIds)) {
      setState(() {
        _scheduleLoad(widget.members);
      });
    }
  }

  void _scheduleLoad(List<GymMember> members) {
    final ids = _extractIds(members);
    _memberIds = ids;
    _trainingDayCountsFuture = ids.isEmpty
        ? Future.value(const {})
        : _trainingDayRepository.fetchTrainingDayCounts(members);
  }

  List<String> _extractIds(List<GymMember> members) {
    return members.map((member) => member.id).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, int>>(
      future: _trainingDayCountsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final counts = snapshot.data ?? const <String, int>{};
        final results = _calculateUsageBuckets(widget.members, counts);

        final percentFormat = NumberFormat.decimalPatternDigits(
          locale: loc.localeName,
          decimalDigits: 1,
        );
        final totalMembers = widget.members.length;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                loc.reportMembersUsageDescription,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              AspectRatio(
                aspectRatio: 1.3,
                child: _UsageBarChart(results: results),
              ),
              const SizedBox(height: AppSpacing.lg),
              ...results.map((result) {
                final percentageLabel = percentFormat.format(result.percentage);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs / 2),
                  child: Text(
                    loc.reportMembersUsageBucketSummary(
                      result.label,
                      percentageLabel,
                      result.memberCount,
                      totalMembers,
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<_UsageBucketResult> _calculateUsageBuckets(
    List<GymMember> members,
    Map<String, int> counts,
  ) {
    const buckets = <_UsageBucket>[
      _UsageBucket(label: '<1', predicate: _UsagePredicates.lessThanOne),
      _UsageBucket(label: '≥1', predicate: _UsagePredicates.greaterThanOrEqualOne),
      _UsageBucket(label: '>3', predicate: _UsagePredicates.greaterThanThree),
      _UsageBucket(label: '>7', predicate: _UsagePredicates.greaterThanSeven),
      _UsageBucket(label: '>20', predicate: _UsagePredicates.greaterThanTwenty),
      _UsageBucket(label: '>30', predicate: _UsagePredicates.greaterThanThirty),
    ];

    final total = members.length;
    if (total == 0) {
      return const [];
    }

    return buckets.map((bucket) {
      final matched = members.where((member) {
        final count = counts[member.id] ?? 0;
        return bucket.predicate(count);
      }).length;
      final percentage = total == 0 ? 0.0 : (matched / total) * 100;
      return _UsageBucketResult(
        label: bucket.label,
        percentage: percentage,
        memberCount: matched,
      );
    }).toList(growable: false);
  }
}

class _UsageBarChart extends StatelessWidget {
  const _UsageBarChart({required this.results});

  static const _yAxisTicks = [100, 75, 50, 25, 0];

  final List<_UsageBucketResult> results;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceVariant = theme.colorScheme.surfaceVariant;
    final primary = theme.colorScheme.primary;
    final onPrimary = theme.colorScheme.onPrimary;
    final locale = Localizations.localeOf(context).toString();
    final tooltipFormat = NumberFormat.decimalPatternDigits(
      locale: locale,
      decimalDigits: 1,
    );

    return LayoutBuilder(
      builder: (context, _) {
        final gradientColors = [
          primary.withOpacity(0.9),
          primary.withOpacity(0.6),
        ];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: _yAxisTicks.map((value) {
                        return Text(
                          '$value%',
                          style: theme.textTheme.bodySmall,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: _yAxisTicks.map((value) {
                              return Container(
                                height: 1,
                                color: surfaceVariant,
                              );
                            }).toList(),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: results.map((result) {
                              final heightFactor =
                                  (result.percentage / 100).clamp(0.0, 1.0);
                              final tooltipMessage =
                                  '${result.label}\n${tooltipFormat.format(result.percentage)}%';
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs / 2,
                                  ),
                                  child: Tooltip(
                                    message: tooltipMessage,
                                    decoration: BoxDecoration(
                                      color: primary,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.card,
                                      ),
                                    ),
                                    textStyle:
                                        theme.textTheme.bodyMedium?.copyWith(
                                      color: onPrimary,
                                    ),
                                    verticalOffset: AppSpacing.sm,
                                    preferBelow: false,
                                    child: _UsageBar(
                                      heightFactor: heightFactor,
                                      gradientColors: gradientColors,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: theme.textTheme.bodySmall?.fontSize != null
                  ? theme.textTheme.bodySmall!.fontSize! * 2
                  : 28,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(width: 40),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Row(
                      children: results.map((result) {
                        return Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Text(
                              result.label,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UsageBar extends StatelessWidget {
  const _UsageBar({
    required this.heightFactor,
    required this.gradientColors,
  });

  final double heightFactor;
  final List<Color> gradientColors;

  @override
  Widget build(BuildContext context) {
    final clampedFactor = heightFactor.clamp(0.0, 1.0);
    return Align(
      alignment: Alignment.bottomCenter,
      child: FractionallySizedBox(
        heightFactor: clampedFactor == 0 ? 0 : clampedFactor,
        widthFactor: 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
        ),
      ),
    );
  }
}

class _UsageBucket {
  const _UsageBucket({required this.label, required this.predicate});

  final String label;
  final bool Function(int count) predicate;
}

class _UsageBucketResult {
  const _UsageBucketResult({
    required this.label,
    required this.percentage,
    required this.memberCount,
  });

  final String label;
  final double percentage;
  final int memberCount;
}

class _UsagePredicates {
  const _UsagePredicates._();

  static bool lessThanOne(int count) => count < 1;

  static bool greaterThanOrEqualOne(int count) => count >= 1;

  static bool greaterThanThree(int count) => count > 3;

  static bool greaterThanSeven(int count) => count > 7;

  static bool greaterThanTwenty(int count) => count > 20;

  static bool greaterThanThirty(int count) => count > 30;
}
