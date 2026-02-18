import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/features/admin/data/services/gym_member_directory_service.dart';
import 'package:tapem/features/admin/providers/admin_service_providers.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';

class AdminSymbolsScreen extends StatefulWidget {
  const AdminSymbolsScreen({
    super.key,
    this.firestore,
    this.memberDirectoryService,
  });

  final FirebaseFirestore? firestore;
  final GymMemberDirectoryService? memberDirectoryService;

  @override
  State<AdminSymbolsScreen> createState() => _AdminSymbolsScreenState();
}

class _AdminSymbolsScreenState extends State<AdminSymbolsScreen> {
  String _query = '';
  Timer? _debounce;
  late final GymMemberDirectoryService _memberDirectoryService;

  @override
  void initState() {
    super.initState();
    if (widget.memberDirectoryService != null) {
      _memberDirectoryService = widget.memberDirectoryService!;
      return;
    }
    if (widget.firestore != null) {
      _memberDirectoryService = GymMemberDirectoryService(
        firestore: widget.firestore,
      );
      return;
    }
    final container = riverpod.ProviderScope.containerOf(context, listen: false);
    _memberDirectoryService = container.read(gymMemberDirectoryServiceProvider);
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
        appBar: AppBar(title: Text(loc.admin_symbols_title)),
        body: Center(child: Text(loc.commonNoAccess)),
      );
    }
    final gymId = auth.gymCode ?? '';
    final stream = _memberDirectoryService.watchProfilesForGym(gymId);

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.admin_symbols_title),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.build),
              tooltip: loc.adminSymbolsBackfillTooltip,
              onPressed: () => _backfill(gymId),
            ),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: loc.admin_symbols_search_hint,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (v) {
                  _debounce?.cancel();
                  _debounce = Timer(const Duration(milliseconds: 350), () {
                    setState(() => _query = v.toLowerCase());
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<List<PublicProfile>>(
                stream: stream,
                builder: (context, snapshot) {
                  final profiles = (snapshot.data ?? const <PublicProfile>[])
                      .where((p) => p.safeLower.startsWith(_query))
                      .toList();
                  if (profiles.isEmpty) {
                    return Center(child: Text(loc.no_members_found));
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
                      return ListTile(
                        leading: CircleAvatar(backgroundImage: image.image),
                        title: Text(
                          profile.username.isNotEmpty
                              ? profile.username
                              : profile.uid,
                        ),
                        onTap: () {
                          debugPrint(
                            '[AdminSymbols] open uid=${profile.uid} gymId=$gymId',
                          );
                          Navigator.of(context).pushNamed(
                            AppRouter.userSymbols,
                            arguments: profile.uid,
                          );
                        },
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

  Future<void> _backfill(String gymId) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final updated = await _memberDirectoryService.backfillUsernameLower(
        gymId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(loc.adminSymbolsBackfillSuccess(updated))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${loc.errorPrefix}: $error')));
    }
  }
}
