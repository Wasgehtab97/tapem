import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
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
          child: _MembersTable(gymId: gymId),
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

        members.sort((a, b) => a.memberNumber.compareTo(b.memberNumber));

        if (members.isEmpty) {
          return Center(child: Text(loc.no_members_found));
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
        final counts = snapshot.data ?? const <String, int>{};
        final isLoading = snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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
              rows: widget.members
                  .map(
                    (member) => DataRow(
                      cells: [
                        DataCell(Text(member.memberNumber)),
                        DataCell(Text(_formatRole(member.role, widget.loc))),
                        DataCell(
                          Text(
                            isLoading && !counts.containsKey(member.id)
                                ? '…'
                                : (counts[member.id] ?? 0).toString(),
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
      },
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
