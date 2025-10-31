import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:tapem/core/theme/app_brand_theme.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/l10n/app_localizations.dart';

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
                .map(_GymMember.fromSnapshot)
                .whereType<_GymMember>()
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

  final List<_GymMember> members;
  final DateFormat dateFormat;
  final AppLocalizations loc;

  @override
  State<_MembersTableContent> createState() => _MembersTableContentState();
}

class _MembersTableContentState extends State<_MembersTableContent> {
  Future<Map<String, int>>? _trainingDayCountsFuture;
  List<String> _memberIds = const [];

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

  void _scheduleTrainingDayLoad(List<_GymMember> members) {
    final ids = _extractIds(members);
    _memberIds = ids;
    _trainingDayCountsFuture =
        ids.isEmpty ? Future.value(const {}) : _loadTrainingDayCounts(members);
  }

  List<String> _extractIds(List<_GymMember> members) {
    return members.map((member) => member.id).toList(growable: false);
  }

  Future<Map<String, int>> _loadTrainingDayCounts(
    List<_GymMember> members,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final entries = await Future.wait(
      members.map((member) async {
        try {
          final snapshot = await firestore
              .collection('users')
              .doc(member.id)
              .collection('trainingDayXP')
              .count()
              .get();
          return MapEntry(member.id, snapshot.count);
        } on FirebaseException catch (error, stackTrace) {
          debugPrint(
            'Failed to load training day count for ${member.id}: ${error.message ?? error.code}',
          );
          debugPrintStack(stackTrace: stackTrace);
          return MapEntry(member.id, 0);
        } catch (error, stackTrace) {
          debugPrint(
            'Failed to load training day count for ${member.id}: $error',
          );
          debugPrintStack(stackTrace: stackTrace);
          return MapEntry(member.id, 0);
        }
      }),
    );

    return {for (final entry in entries) entry.key: entry.value};
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

class _GymMember {
  _GymMember({
    required this.id,
    required this.memberNumber,
    required this.role,
    required this.createdAt,
  });

  final String id;
  final String memberNumber;
  final String? role;
  final DateTime? createdAt;

  static _GymMember? fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      return null;
    }

    final memberNumber = (data['memberNumber'] as String? ?? '').trim();
    final role = data['role'] as String?;
    final createdAt = _parseDateTime(data['createdAt']);

    return _GymMember(
      id: snapshot.id,
      memberNumber: memberNumber,
      role: role,
      createdAt: createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
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
