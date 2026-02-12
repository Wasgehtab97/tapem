import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:tapem/core/auth/role_utils.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/app_chip.dart';
import 'package:tapem/core/widgets/app_empty_state.dart';
import 'package:tapem/core/widgets/app_error_state.dart';
import 'package:tapem/core/widgets/app_loading_view.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
        theme.extension<AppBrandTheme>()?.outline ?? theme.colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.reportMembersTitle),
        centerTitle: true,
        foregroundColor: brandColor,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ReportMembersUsageScreen(gymId: gymId),
                ),
              );
            },
            child: Text(loc.reportMembersUsageButton),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
              Expanded(
                child: _MembersTable(gymId: gymId),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersTable extends StatelessWidget {
  const _MembersTable({required this.gymId});

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
          return AppErrorState(
            message: loc.reportMembersLoadError,
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AppLoadingView(
            message: 'Lade Mitglieder...',
          );
        }

        final members = snapshot.data?.docs
                .map(GymMember.fromSnapshot)
                .whereType<GymMember>()
                .where((member) => member.memberNumber.isNotEmpty)
                .toList() ??
            [];

        members.sort((a, b) => a.memberNumber.compareTo(b.memberNumber));

        if (members.isEmpty) {
          return AppEmptyState(
            icon: Icons.people_outline,
            message: loc.no_members_found,
            secondaryMessage: 'Es wurden noch keine Mitglieder registriert.',
          );
        }

        final dateFormat = DateFormat.yMMMd(loc.localeName).add_Hm();

        return _MembersTableContent(
          members: members,
          dateFormat: dateFormat,
          loc: loc,
        );
      },
    );
  }
}

class _MembersTableContent extends StatefulWidget {
  const _MembersTableContent({
    required this.members,
    required this.dateFormat,
    required this.loc,
  });

  final List<GymMember> members;
  final DateFormat dateFormat;
  final AppLocalizations loc;

  @override
  State<_MembersTableContent> createState() => _MembersTableContentState();
}

class _MembersTableContentState extends State<_MembersTableContent> {
  Future<Map<String, int>>? _trainingDayCountsFuture;
  List<String> _memberIds = const [];
  final _trainingDayRepository = TrainingDayRepository();

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
        : _trainingDayRepository.fetchTrainingDayCounts(members);
  }

  List<String> _extractIds(List<GymMember> members) {
    return members.map((member) => member.id).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: _trainingDayCountsFuture,
      builder: (context, snapshot) {
        final error = snapshot.error;
        final isAccessDenied = error is TrainingDayAccessDenied;

        if (snapshot.hasError && !isAccessDenied) {
          return AppErrorState(
            message: widget.loc.reportMembersLoadError,
          );
        }

        final counts = snapshot.data ?? const <String, int>{};
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        final totalMembers = widget.members.length;
        final totalTrainingDays =
            counts.values.fold<int>(0, (total, value) => total + value);
        final activeMembers =
            counts.values.where((value) => value > 0).length;
        final inactiveMembers = totalMembers - activeMembers;
        final atRiskMembers = widget.members.where((member) {
          final risk = _riskForMember(member, counts);
          return risk == MemberRisk.high;
        }).length;
        final newMembers = widget.members
            .where((member) => _riskForMember(member, counts) == MemberRisk.newMember)
            .length;
        final loyalMembers =
            widget.members.where((member) => _isLoyalMember(member, counts)).length;

        final filteredMembers = _filterMembersBySegment(
          widget.members,
          counts,
          _segment,
        );

        final table = SingleChildScrollView(
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
                        DataCell(Text(_formatRole(member.role, widget.loc))),
                        DataCell(
                          Text(
                            isLoading && !counts.containsKey(member.id)
                                ? '…'
                                : _formatTrainingDaysWithRisk(
                                    member,
                                    counts,
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
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: _AdminOnlyHint(),
                  ),
                ],
              );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MembersSummaryRow(
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
              current: _segment,
              onChanged: (segment) {
                setState(() {
                  _segment = segment;
                });
              },
            ),
            const SizedBox(height: AppSpacing.md),
            _MembersSegmentActions(
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
    required this.totalMembers,
    required this.activeMembers,
    required this.inactiveMembers,
    required this.totalTrainingDays,
    required this.atRiskMembers,
    required this.newMembers,
    required this.loyalMembers,
  });

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
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.06),
          ),
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
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildChip('Mitglieder', '$totalMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip('Aktive Mitglieder', '$activeMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip('Inaktiv', '$inactiveMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip('Gefährdet (hohes Risiko)', '$atRiskMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip('Neu im Studio', '$newMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip('Stammkunden', '$loyalMembers'),
          const SizedBox(width: AppSpacing.sm),
          buildChip('Trainingstage gesamt', '$totalTrainingDays'),
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

enum MemberRisk {
  low,
  medium,
  high,
  newMember,
}

class _MembersSegmentActions extends StatelessWidget {
  const _MembersSegmentActions({
    required this.members,
    required this.segment,
  });

  final List<GymMember> members;
  final MemberEngagementSegment segment;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => _showActionsSheet(context),
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Aktionen für Gruppe'),
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.secondary,
        ),
      ),
    );
  }

  String _segmentLabel(MemberEngagementSegment segment) {
    switch (segment) {
      case MemberEngagementSegment.all:
        return 'Alle Mitglieder';
      case MemberEngagementSegment.active:
        return 'Aktive Mitglieder';
      case MemberEngagementSegment.inactive:
        return 'Inaktive Mitglieder';
      case MemberEngagementSegment.atRisk:
        return 'Gefährdete Mitglieder';
      case MemberEngagementSegment.newMembers:
        return 'Neue Mitglieder';
      case MemberEngagementSegment.loyal:
        return 'Stammkunden';
    }
  }

  void _showActionsSheet(BuildContext context) {
    final segmentName = _segmentLabel(segment);
    final memberNumbers =
        members.map((m) => m.memberNumber).where((n) => n.isNotEmpty).toList();
    if (memberNumbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Keine Mitgliedsnummern in dieser Gruppe.'),
        ),
      );
      return;
    }

    showModalBottomSheet(
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
                  'Aktionen für $segmentName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${memberNumbers.length} Mitglieder in dieser Gruppe.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                ListTile(
                  leading: const Icon(Icons.copy),
                  title: const Text('Mitgliedsnummern kopieren'),
                  onTap: () async {
                    final text = memberNumbers.join(', ');
                    await Clipboard.setData(ClipboardData(text: text));
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mitgliedsnummern kopiert.'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text('Mitgliedsnummern teilen'),
                  onTap: () {
                    final text =
                        '$segmentName (${memberNumbers.length} Mitglieder)\n\n'
                        'Mitgliedsnummern:\n${memberNumbers.join(', ')}';
                    Share.share(
                      text,
                      subject: 'Mitgliedergruppe aus dem Report',
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
}

class _MembersSegmentFilter extends StatelessWidget {
  const _MembersSegmentFilter({
    required this.current,
    required this.onChanged,
  });

  final MemberEngagementSegment current;
  final ValueChanged<MemberEngagementSegment> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Widget buildChip(MemberEngagementSegment segment, String label) {
      final selected = current == segment;
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: AppChip(
          label: label,
          selected: selected,
          onSelected: (_) => onChanged(segment),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          buildChip(MemberEngagementSegment.all, 'Alle'),
          buildChip(MemberEngagementSegment.active, 'Aktiv'),
          buildChip(MemberEngagementSegment.inactive, 'Inaktiv'),
          buildChip(MemberEngagementSegment.atRisk, 'Gefährdet'),
          buildChip(MemberEngagementSegment.newMembers, 'Neu im Studio'),
          buildChip(MemberEngagementSegment.loyal, 'Stammkunden'),
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

MemberRisk _riskForMember(
  GymMember member,
  Map<String, int> counts,
) {
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

bool _isLoyalMember(
  GymMember member,
  Map<String, int> counts,
) {
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
) {
  final trainings = counts[member.id] ?? 0;
  final risk = _riskForMember(member, counts);
  final riskLabel = _riskLabel(risk);
  return '$trainings · $riskLabel';
}

String _riskLabel(MemberRisk risk) {
  switch (risk) {
    case MemberRisk.low:
      return 'niedriges Risiko';
    case MemberRisk.medium:
      return 'mittleres Risiko';
    case MemberRisk.high:
      return 'hohes Risiko';
    case MemberRisk.newMember:
      return 'neu im Studio';
  }
}

class _AdminOnlyHint extends StatelessWidget {
  const _AdminOnlyHint();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
                'Nur Admins dieses Gyms sehen Trainingstage.',
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
