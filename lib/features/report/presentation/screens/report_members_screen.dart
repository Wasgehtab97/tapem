import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:tapem/core/auth/role_utils.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/services/admin_audit_logger.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_chip.dart';
import 'package:tapem/core/widgets/app_empty_state.dart';
import 'package:tapem/core/widgets/app_error_state.dart';
import 'package:tapem/core/widgets/app_loading_view.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/report/providers/report_providers.dart'
    as report_providers;

import '../../data/training_day_repository.dart';
import '../../domain/gym_member.dart';
import 'report_members_usage_screen.dart';

class ReportMembersScreen extends StatelessWidget {
  const ReportMembersScreen({super.key, required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final brandColor =
        theme.extension<AppBrandTheme>()?.outline ??
        theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportMembersTitle),
        centerTitle: true,
        foregroundColor: brandColor,
        actions: [
          Tooltip(
            message: loc.reportMembersUsageButton,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ReportMembersUsageScreen(gymId: gymId),
                  ),
                );
              },
              child: Text(loc.reportMembersUsageButton),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FocusTraversalGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.reportMembersButtonSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Expanded(child: _MembersTable(gymId: gymId)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MembersTable extends ConsumerWidget {
  const _MembersTable({required this.gymId});

  final String gymId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context)!;
    final trainingDayRepository = ref.watch(
      report_providers.trainingDayRepositoryProvider,
    );

    return StreamBuilder<List<GymMember>>(
      stream: trainingDayRepository.watchGymMembers(gymId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppErrorState(message: loc.reportMembersLoadError);
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppLoadingView(message: loc.reportMembersLoading);
        }

        final members = (snapshot.data ?? const <GymMember>[]).toList(
          growable: true,
        );

        members.sort((a, b) => a.memberNumber.compareTo(b.memberNumber));

        if (members.isEmpty) {
          return AppEmptyState(
            icon: Icons.people_outline,
            message: loc.no_members_found,
            secondaryMessage: loc.reportMembersNoRegisteredMembers,
          );
        }

        final dateFormat = DateFormat.yMMMd(loc.localeName).add_Hm();

        return _MembersTableContent(
          gymId: gymId,
          members: members,
          dateFormat: dateFormat,
          loc: loc,
          trainingDayRepository: trainingDayRepository,
        );
      },
    );
  }
}

class _MembersTableContent extends ConsumerStatefulWidget {
  const _MembersTableContent({
    required this.gymId,
    required this.members,
    required this.dateFormat,
    required this.loc,
    required this.trainingDayRepository,
  });

  final String gymId;
  final List<GymMember> members;
  final DateFormat dateFormat;
  final AppLocalizations loc;
  final TrainingDayRepository trainingDayRepository;

  @override
  ConsumerState<_MembersTableContent> createState() =>
      _MembersTableContentState();
}

class _MembersTableContentState extends ConsumerState<_MembersTableContent> {
  Future<Map<String, int>>? _trainingDayCountsFuture;
  List<String> _memberIds = const [];

  MemberEngagementSegment _segment = MemberEngagementSegment.all;

  @override
  void initState() {
    super.initState();
    _scheduleTrainingDayLoad(widget.members);
  }

  @override
  void didUpdateWidget(covariant _MembersTableContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(_memberIds, _extractIds(widget.members))) {
      setState(() {
        _scheduleTrainingDayLoad(widget.members);
      });
    }
  }

  void _scheduleTrainingDayLoad(List<GymMember> members) {
    final ids = _extractIds(members);
    _memberIds = ids;
    _trainingDayCountsFuture = ids.isEmpty
        ? Future.value(const {})
        : widget.trainingDayRepository.fetchTrainingDayCounts(members);
  }

  List<String> _extractIds(List<GymMember> members) {
    return members.map((member) => member.id).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _trainingDayCountsFuture,
      builder: (context, snapshot) {
        final auth = ProviderScope.containerOf(
          context,
          listen: false,
        ).read(authControllerProvider);
        final error = snapshot.error;
        final isAccessDenied = error is TrainingDayAccessDenied;

        if (snapshot.hasError && !isAccessDenied) {
          return AppErrorState(message: widget.loc.reportMembersLoadError);
        }

        final counts = snapshot.data ?? const <String, int>{};
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        final totalMembers = widget.members.length;
        final totalTrainingDays = counts.values.fold<int>(
          0,
          (total, value) => total + value,
        );
        final activeMembers = counts.values.where((value) => value > 0).length;
        final inactiveMembers = totalMembers - activeMembers;
        final atRiskMembers = widget.members.where((member) {
          final risk = _riskForMember(member, counts);
          return risk == MemberRisk.high;
        }).length;
        final newMembers = widget.members
            .where(
              (member) =>
                  _riskForMember(member, counts) == MemberRisk.newMember,
            )
            .length;
        final loyalMembers = widget.members
            .where((member) => _isLoyalMember(member, counts))
            .length;

        final filteredMembers = _filterMembersBySegment(
          widget.members,
          counts,
          _segment,
        );
        final useCompactMembersList = MediaQuery.sizeOf(context).width < 900;

        final table = useCompactMembersList
            ? ListView.separated(
                padding: EdgeInsets.only(
                  top: isAccessDenied ? AppSpacing.lg : 0,
                  bottom: AppSpacing.lg,
                ),
                itemCount: filteredMembers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, index) {
                  final member = filteredMembers[index];
                  final trainings = isLoading && !counts.containsKey(member.id)
                      ? '…'
                      : _formatTrainingDaysWithRisk(member, counts, widget.loc);
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.08),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.memberNumber,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(_formatRole(member.role, widget.loc)),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${widget.loc.reportMembersTrainingDaysColumn}: $trainings',
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${widget.loc.reportMembersCreatedAtColumn}: '
                            '${_formatCreatedAt(member.createdAt, widget.dateFormat)}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: isAccessDenied ? AppSpacing.lg : 0,
                  bottom: AppSpacing.lg,
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: AppSpacing.lg,
                    headingRowColor: MaterialStateProperty.resolveWith<Color?>(
                      (states) => Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    columns: [
                      DataColumn(
                        label: Text(widget.loc.reportMembersMemberNumberColumn),
                      ),
                      DataColumn(
                        label: Text(widget.loc.reportMembersRoleColumn),
                      ),
                      DataColumn(
                        label: Text(widget.loc.reportMembersTrainingDaysColumn),
                      ),
                      DataColumn(
                        label: Text(widget.loc.reportMembersCreatedAtColumn),
                      ),
                    ],
                    rows: filteredMembers
                        .map(
                          (member) => DataRow(
                            cells: [
                              DataCell(Text(member.memberNumber)),
                              DataCell(
                                Text(_formatRole(member.role, widget.loc)),
                              ),
                              DataCell(
                                Text(
                                  isLoading && !counts.containsKey(member.id)
                                      ? '…'
                                      : _formatTrainingDaysWithRisk(
                                          member,
                                          counts,
                                          widget.loc,
                                        ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  _formatCreatedAt(
                                    member.createdAt,
                                    widget.dateFormat,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ),
              );

        final tableWithAdminHint = !isAccessDenied
            ? table
            : Stack(
                children: [
                  table,
                  const Positioned(top: 0, right: 0, child: _AdminOnlyHint()),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MembersSummaryRow(
              loc: widget.loc,
              totalMembers: totalMembers,
              activeMembers: activeMembers,
              inactiveMembers: inactiveMembers,
              totalTrainingDays: totalTrainingDays,
              atRiskMembers: atRiskMembers,
              newMembers: newMembers,
              loyalMembers: loyalMembers,
            ),
            const SizedBox(height: AppSpacing.md),
            _MembersSegmentFilter(
              loc: widget.loc,
              current: _segment,
              onChanged: (segment) {
                setState(() {
                  _segment = segment;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _MembersSegmentActions(
              loc: widget.loc,
              gymId: widget.gymId,
              actorUid: auth.userId ?? '',
              members: filteredMembers,
              segment: _segment,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: tableWithAdminHint),
          ],
        );
      },
    );
  }
}

class _MembersSummaryRow extends StatelessWidget {
  const _MembersSummaryRow({
    required this.loc,
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.totalTrainingDays,
    required this.atRiskMembers,
    required this.newMembers,
    required this.loyalMembers,
  });

  final AppLocalizations loc;
  final int totalMembers;
  final int activeMembers;
  final int inactiveMembers;
  final int totalTrainingDays;
  final int atRiskMembers;
  final int newMembers;
  final int loyalMembers;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildChip(String label, String value) {
      return Semantics(
        container: true,
        label: '$label: $value',
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(color: colorScheme.onSurface.withOpacity(0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildChip(loc.reportMembersSummaryTotal, '$totalMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip(loc.reportMembersSummaryActive, '$activeMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip(loc.reportMembersSummaryInactive, '$inactiveMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip(loc.reportMembersSummaryAtRisk, '$atRiskMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip(loc.reportMembersSummaryNewMembers, '$newMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip(loc.reportMembersSummaryLoyal, '$loyalMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip(loc.reportMembersSummaryTrainingDays, '$totalTrainingDays'),
        ],
      ),
    );
  }
}

enum MemberEngagementSegment {
  all,
  active,
  inactive,
  atRisk,
  newMembers,
  loyal,
}

enum MemberRisk { low, medium, high, newMember }

class _MembersSegmentActions extends StatelessWidget {
  const _MembersSegmentActions({
    required this.loc,
    required this.gymId,
    required this.actorUid,
    required this.members,
    required this.segment,
  });

  final AppLocalizations loc;
  final String gymId;
  final String actorUid;
  final List<GymMember> members;
  final MemberEngagementSegment segment;
  static final AdminAuditLogger _auditLogger = AdminAuditLogger();

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: Tooltip(
        message: loc.reportMembersSegmentActions,
        child: Semantics(
          button: true,
          label: loc.reportMembersSegmentActions,
          hint: _segmentLabel(segment),
          child: TextButton.icon(
            onPressed: () async => _showActionsSheet(context),
            icon: const Icon(Icons.campaign_outlined),
            label: Text(loc.reportMembersSegmentActions),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.secondary,
            ),
          ),
        ),
      ),
    );
  }

  String _segmentLabel(MemberEngagementSegment segment) {
    switch (segment) {
      case MemberEngagementSegment.all:
        return loc.reportMembersSegmentAll;
      case MemberEngagementSegment.active:
        return loc.reportMembersSegmentActive;
      case MemberEngagementSegment.inactive:
        return loc.reportMembersSegmentInactive;
      case MemberEngagementSegment.atRisk:
        return loc.reportMembersSegmentAtRisk;
      case MemberEngagementSegment.newMembers:
        return loc.reportMembersSegmentNewMembers;
      case MemberEngagementSegment.loyal:
        return loc.reportMembersSegmentLoyal;
    }
  }

  Future<void> _showActionsSheet(BuildContext context) async {
    final segmentName = _segmentLabel(segment);
    final memberNumbers = members
        .map((m) => m.memberNumber)
        .where((n) => n.isNotEmpty)
        .toList();
    if (memberNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.reportMembersSegmentNoNumbers)),
      );
      return;
    }

    if (segment == MemberEngagementSegment.all && memberNumbers.length > 150) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(loc.reportMembersSegmentLargeExportTitle),
          content: Text(loc.reportMembersSegmentLargeExportBody(memberNumbers.length)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(loc.commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(loc.reportMembersSegmentLargeExportConfirm),
            ),
          ],
        ),
      );
      if (proceed != true) {
        return;
      }
    }

    await showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.reportMembersSegmentActionsFor(segmentName),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loc.reportMembersSegmentCount(memberNumbers.length),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: Text(loc.reportMembersSegmentCopy),
                  onTap: () async {
                    final text = memberNumbers.join(', ');
                    await Clipboard.setData(ClipboardData(text: text));
                    await _logBulkAction(
                      action: 'report_members_segment_copy',
                      segmentName: segmentName,
                      memberCount: memberNumbers.length,
                    );
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(loc.reportMembersSegmentCopied)),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: Text(loc.reportMembersSegmentShare),
                  onTap: () async {
                    final text = loc.reportMembersSegmentShareBody(
                      segmentName,
                      memberNumbers.length,
                      memberNumbers.join(', '),
                    );
                    Share.share(
                      text,
                      subject: loc.reportMembersSegmentShareSubject,
                    );
                    await _logBulkAction(
                      action: 'report_members_segment_share',
                      segmentName: segmentName,
                      memberCount: memberNumbers.length,
                    );
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logBulkAction({
    required String action,
    required String segmentName,
    required int memberCount,
  }) async {
    if (gymId.isEmpty || actorUid.isEmpty) {
      return;
    }
    await _auditLogger.logGymAction(
      gymId: gymId,
      action: action,
      actorUid: actorUid,
      metadata: <String, dynamic>{
        'segment': segment.name,
        'segmentLabel': segmentName,
        'memberCount': memberCount,
      },
    );
  }
}

class _MembersSegmentFilter extends StatelessWidget {
  const _MembersSegmentFilter({
    required this.loc,
    required this.current,
    required this.onChanged,
  });

  final AppLocalizations loc;
  final MemberEngagementSegment current;
  final ValueChanged<MemberEngagementSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget buildChip(MemberEngagementSegment segment, String label) {
      final selected = current == segment;
      return Tooltip(
        message: label,
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            child: AppChip(
              label: label,
              selected: selected,
              onSelected: (_) => onChanged(segment),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildChip(MemberEngagementSegment.all, loc.reportMembersSegmentAllShort),
          buildChip(
            MemberEngagementSegment.active,
            loc.reportMembersSegmentActiveShort,
          ),
          buildChip(
            MemberEngagementSegment.inactive,
            loc.reportMembersSegmentInactiveShort,
          ),
          buildChip(
            MemberEngagementSegment.atRisk,
            loc.reportMembersSegmentAtRiskShort,
          ),
          buildChip(
            MemberEngagementSegment.newMembers,
            loc.reportMembersSegmentNewMembersShort,
          ),
          buildChip(
            MemberEngagementSegment.loyal,
            loc.reportMembersSegmentLoyalShort,
          ),
        ],
      ),
    );
  }
}

List<GymMember> _filterMembersBySegment(
  List<GymMember> members,
  Map<String, int> counts,
  MemberEngagementSegment segment,
) {
  if (segment == MemberEngagementSegment.all) {
    return members;
  }

  return members.where((member) {
    final days = counts[member.id] ?? 0;
    switch (segment) {
      case MemberEngagementSegment.active:
        return days > 0;
      case MemberEngagementSegment.inactive:
        return days == 0;
      case MemberEngagementSegment.atRisk:
        return _riskForMember(member, counts) == MemberRisk.high;
      case MemberEngagementSegment.newMembers:
        return _riskForMember(member, counts) == MemberRisk.newMember;
      case MemberEngagementSegment.loyal:
        return _isLoyalMember(member, counts);
      case MemberEngagementSegment.all:
        return true;
    }
  }).toList();
}

MemberRisk _riskForMember(GymMember member, Map<String, int> counts) {
  final trainings = counts[member.id] ?? 0;
  final createdAt = member.createdAt;
  final now = DateTime.now();

  // Wenn kein Erstellungsdatum vorhanden ist, anhand der Trainingsanzahl schätzen.
  if (createdAt == null) {
    if (trainings == 0) {
      return MemberRisk.high;
    }
    if (trainings <= 3) {
      return MemberRisk.medium;
    }
    return MemberRisk.low;
  }

  final ageDays = now.difference(createdAt).inDays.clamp(1, 3650);

  // Neue Mitglieder (unter 30 Tagen) gesondert behandeln.
  if (ageDays < 30) {
    if (trainings == 0) {
      // Neu und noch nicht aktiv – im Blick behalten, aber nicht direkt "hoch".
      return MemberRisk.medium;
    }
    return MemberRisk.newMember;
  }

  if (trainings == 0) {
    return MemberRisk.high;
  }

  final months = ageDays / 30.0;
  final trainingsPerMonth = trainings / months;

  if (trainingsPerMonth < 1) {
    return MemberRisk.high;
  }
  if (trainingsPerMonth < 2) {
    return MemberRisk.medium;
  }
  return MemberRisk.low;
}

bool _isLoyalMember(GymMember member, Map<String, int> counts) {
  final createdAt = member.createdAt;
  if (createdAt == null) {
    return false;
  }
  final trainings = counts[member.id] ?? 0;
  final now = DateTime.now();
  final ageDays = now.difference(createdAt).inDays;
  if (ageDays < 180) {
    return false;
  }
  final months = ageDays / 30.0;
  final trainingsPerMonth = months > 0 ? trainings / months : 0.0;
  return trainingsPerMonth >= 2;
}

String _formatTrainingDaysWithRisk(
  GymMember member,
  Map<String, int> counts,
  AppLocalizations loc,
) {
  final trainings = counts[member.id] ?? 0;
  final risk = _riskForMember(member, counts);
  final riskLabel = _riskLabel(risk, loc);
  return '$trainings · $riskLabel';
}

String _riskLabel(MemberRisk risk, AppLocalizations loc) {
  switch (risk) {
    case MemberRisk.low:
      return loc.reportMembersRiskLow;
    case MemberRisk.medium:
      return loc.reportMembersRiskMedium;
    case MemberRisk.high:
      return loc.reportMembersRiskHigh;
    case MemberRisk.newMember:
      return loc.reportMembersRiskNewMember;
  }
}

class _AdminOnlyHint extends StatelessWidget {
  const _AdminOnlyHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(AppSpacing.sm),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.info_outline,
                size: 16,
                color: colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                loc.reportMembersAdminOnlyHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatRole(String? role, AppLocalizations loc) {
  if (role == null || role.isEmpty) {
    return '—';
  }
  switch (role) {
    case 'member':
      return loc.reportMembersRoleMember;
    case 'admin':
    case kRoleGymOwner:
      return loc.reportMembersRoleAdmin;
    default:
      return toBeginningOfSentenceCase(role) ?? role;
  }
}

String _formatCreatedAt(DateTime? createdAt, DateFormat format) {
  if (createdAt == null) {
    return '—';
  }
  return format.format(createdAt.toLocal());
}
