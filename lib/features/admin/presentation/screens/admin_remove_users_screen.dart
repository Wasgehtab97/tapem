import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:tapem/core/services/admin_audit_logger.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/core/widgets/destructive_action.dart';
import 'package:tapem/features/admin/data/services/gym_member_directory_service.dart';
import 'package:tapem/features/admin/data/services/gym_user_removal_service.dart';
import 'package:tapem/features/admin/providers/admin_service_providers.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AdminRemoveUsersScreen extends StatefulWidget {
  const AdminRemoveUsersScreen({
    super.key,
    this.firestore,
    this.memberDirectoryService,
    this.removalService,
  });

  final FirebaseFirestore? firestore;
  final GymMemberDirectoryService? memberDirectoryService;
  final GymUserRemovalService? removalService;

  @override
  State<AdminRemoveUsersScreen> createState() => _AdminRemoveUsersScreenState();
}

class _AdminRemoveUsersScreenState extends State<AdminRemoveUsersScreen> {
  String _query = '';
  Timer? _debounce;
  final Set<String> _deleting = {};
  late final GymUserRemovalService _removalService;
  late final GymMemberDirectoryService _memberDirectoryService;

  @override
  void initState() {
    super.initState();
    final container = riverpod.ProviderScope.containerOf(
      context,
      listen: false,
    );
    final firestore = widget.firestore;

    _removalService = firestore != null
        ? GymUserRemovalService(
            firestore: firestore,
            auditLogger: AdminAuditLogger(firestore: firestore),
          )
        : (widget.removalService ??
              container.read(gymUserRemovalServiceProvider));

    _memberDirectoryService = firestore != null
        ? GymMemberDirectoryService(firestore: firestore)
        : (widget.memberDirectoryService ??
              container.read(gymMemberDirectoryServiceProvider));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = riverpod.ProviderScope.containerOf(
      context,
    ).read(authControllerProvider);
    if (!auth.canManageGym) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.adminRemoveUsersTitle)),
        body: Center(child: Text(loc.adminNoAccess)),
      );
    }
    final gymId = auth.gymCode ?? '';
    final stream = _memberDirectoryService.watchProfilesForGym(gymId);

    return Scaffold(
      appBar: AppBar(title: Text(loc.adminRemoveUsersTitle)),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: TextField(
                decoration: InputDecoration(
                  hintText: loc.adminSearchUsersHint,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                  ),
                ),
                onChanged: (value) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 300), () {
                    setState(() => _query = value.toLowerCase());
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<PublicProfile>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final profiles = (snapshot.data ?? const <PublicProfile>[])
                      .where(
                        (p) =>
                            _query.isEmpty ||
                            p.safeLower.contains(_query) ||
                            p.uid.toLowerCase().contains(_query),
                      )
                      .toList();

                  if (profiles.isEmpty) {
                    return Center(
                      child: Text(
                        loc.no_members_found,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: profiles.length,
                    itemBuilder: (context, index) {
                      final profile = profiles[index];
                      final avatarKey = profile.avatarKey ?? 'default';
                      final path = AvatarCatalog.instance.resolvePathOrFallback(
                        avatarKey,
                        gymId: gymId,
                      );
                      final image = Image.asset(
                        path,
                        errorBuilder: (_, __, ___) {
                          if (kDebugMode) {
                            debugPrint('[Avatar] failed to load $path');
                          }
                          return const Icon(Icons.person);
                        },
                      );
                      final isDeleting = _deleting.contains(profile.uid);

                      return ListTile(
                        leading: CircleAvatar(backgroundImage: image.image),
                        title: Text(
                          profile.username.isNotEmpty
                              ? profile.username
                              : profile.uid,
                        ),
                        subtitle: profile.createdAt != null
                            ? Text(
                                loc.adminMemberSince(
                                  DateFormat('dd.MM.yyyy').format(
                                    profile.createdAt!,
                                  ),
                                ),
                              )
                            : Text(profile.uid),
                        trailing: isDeleting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : IconButton(
                                icon: const Icon(Icons.delete_forever),
                                color: Theme.of(context).colorScheme.error,
                                onPressed: () => _confirmAndDeleteUser(
                                  context,
                                  gymId,
                                  profile,
                                ),
                              ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndDeleteUser(
    BuildContext context,
    String gymId,
    PublicProfile profile,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDestructiveActionDialog(
      context: context,
      title: loc.adminDeleteUserTitle,
      message: loc.adminDeleteUserMessage(
        profile.username.isNotEmpty ? profile.username : profile.uid,
      ),
      confirmLabel: loc.commonDelete,
      cancelLabel: loc.cancelButton,
      auditHint: loc.adminDeleteUserAuditHint,
    );
    if (!confirmed) return;

    setState(() {
      _deleting.add(profile.uid);
    });

    try {
      final actorUid = riverpod.ProviderScope.containerOf(
        context,
        listen: false,
      ).read(authControllerProvider).userId;
      final result = await _removalService.removeUserFromGym(
        gymId: gymId,
        targetUid: profile.uid,
        actorUid: actorUid ?? '',
      );
      if (!mounted) return;
      final warningText = result.hasCleanupWarnings
          ? ' (mit ${result.cleanupErrors.length} Cleanup-Warnungen)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            loc.adminDeleteUserSuccess(profile.username, warningText),
          ),
        ),
      );
    } catch (e) {
      final loc = AppLocalizations.of(context)!;
      debugPrint('Failed to delete user ${profile.uid}: $e');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.adminDeleteUserError(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting.remove(profile.uid);
        });
      }
    }
  }
}
