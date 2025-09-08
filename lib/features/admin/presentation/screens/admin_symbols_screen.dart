import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/core/utils/avatar_assets.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';

class AdminSymbolsScreen extends StatefulWidget {
  const AdminSymbolsScreen({super.key, this.firestore});

  final FirebaseFirestore? firestore;

  @override
  State<AdminSymbolsScreen> createState() => _AdminSymbolsScreenState();
}

class _AdminSymbolsScreenState extends State<AdminSymbolsScreen> {
  String _query = '';
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.admin_symbols_title)),
        body: const Center(child: Text('Kein Zugriff')),
      );
    }
    final gymId = auth.gymCode ?? '';
    final fs = widget.firestore ?? FirebaseFirestore.instance;
    final stream = fs
        .collection('users')
        .where('gymCodes', arrayContains: gymId)
        .snapshots();
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.admin_symbols_title),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.build),
              tooltip: 'backfill usernameLower',
              onPressed: () => _backfill(fs, gymId),
            ),
        ],
      ),
      body: Column(
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
            child: StreamBuilder<QuerySnapshot>(
              stream: stream,
              builder: (context, snapshot) {
                final docs = snapshot.data?.docs ?? [];
                final profiles = docs
                    .map((d) =>
                        PublicProfile.fromMap(d.id, d.data() as Map<String, dynamic>))
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
                    final path = AvatarCatalog.instance
                        .pathForKey(
                            AvatarAssets.normalizeAvatarKey(avatarKey,
                                currentGymId: gymId));
                    final image = Image.asset(path, errorBuilder:
                        (_, __, ___) {
                      if (kDebugMode) {
                        debugPrint('[Avatar] failed to load $path');
                      }
                      return const Icon(Icons.person);
                    });
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: image.image,
                        child: const Icon(Icons.person),
                      ),
                      title: Text(profile.username.isNotEmpty
                          ? profile.username
                          : profile.uid),
                      onTap: () {
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
    );
  }

  Future<void> _backfill(FirebaseFirestore fs, String gymId) async {
    final query = await fs
        .collection('users')
        .where('gymCodes', arrayContains: gymId)
        .where('usernameLower', isNull: true)
        .get();
    for (final doc in query.docs) {
      final data = doc.data();
      final name = data['username'] as String? ?? '';
      await doc.reference.update({'usernameLower': name.toLowerCase()});
      await Future.delayed(const Duration(milliseconds: 50));
    }
  }
}

