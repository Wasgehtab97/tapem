import 'package:cloud_firestore/cloud_firestore.dart';
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
                  label: Text(loc.reportMembersMemberNumberColumn),
                ),
                DataColumn(
                  label: Text(loc.reportMembersRoleColumn),
                ),
                DataColumn(
                  label: Text(loc.reportMembersCreatedAtColumn),
                ),
              ],
              rows: members
                  .map(
                    (member) => DataRow(
                      cells: [
                        DataCell(Text(member.memberNumber)),
                        DataCell(Text(_formatRole(member.role, loc))),
                        DataCell(
                          Text(
                            _formatCreatedAt(member.createdAt, dateFormat),
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
    required this.memberNumber,
    required this.role,
    required this.createdAt,
  });

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
