import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as riverpod;

import 'package:tapem/core/providers/auth_providers.dart';
import 'package:tapem/core/theme/design_tokens.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/friends/domain/models/public_profile.dart';
import 'package:tapem/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

class AdminRemoveUsersScreen extends StatefulWidget {
  const AdminRemoveUsersScreen({super.key, this.firestore});

  final FirebaseFirestore? firestore;

  @override
  State<AdminRemoveUsersScreen> createState() => _AdminRemoveUsersScreenState();
}

class _AdminRemoveUsersScreenState extends State<AdminRemoveUsersScreen> {
  String _query = '';
  Timer? _debounce;
  final Set<String> _deleting = {};

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = riverpod.ProviderScope.containerOf(context).read(
      authControllerProvider,
    );
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Nutzer entfernen'),
        ),
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
        title: const Text('Nutzer entfernen'),
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Nutzer suchen (Name)',
                  prefixIcon: Icon(Icons.search),
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
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  final profiles = docs
                      .map(
                        (d) => PublicProfile.fromMap(
                          d.id,
                          d.data(),
                        ),
                      )
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
                        leading: CircleAvatar(
                          backgroundImage: image.image,
                        ),
                        title: Text(
                          profile.username.isNotEmpty
                              ? profile.username
                              : profile.uid,
                        ),
                        subtitle: Text(
                          profile.createdAt != null
                              ? 'Mitglied seit: ${DateFormat('dd.MM.yyyy').format(profile.createdAt!)}'
                              : profile.uid,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.6),
                              ),
                        ),
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
                                  fs,
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
    FirebaseFirestore fs,
    String gymId,
    PublicProfile profile,
  ) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nutzer und Daten löschen?'),
        content: Text(
          'Der Nutzer "${profile.username.isNotEmpty ? profile.username : profile.uid}" '
          'und alle zugehörigen Daten in diesem Studio werden unwiderruflich gelöscht.\n\n'
          'Dieser Vorgang kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc.cancelButton),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _deleting.add(profile.uid);
    });

    try {
      await _deleteUserForGym(fs: fs, gymId: gymId, uid: profile.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nutzer ${profile.username} gelöscht'),
        ),
      );
    } catch (e, st) {
      debugPrint('Failed to delete user ${profile.uid}: $e');
      debugPrint('$st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Löschen: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _deleting.remove(profile.uid);
        });
      }
    }
  }

  Future<void> _deleteUserForGym({
    required FirebaseFirestore fs,
    required String gymId,
    required String uid,
  }) async {
    // Load user doc to inspect gymCodes.
    final userRef = fs.collection('users').doc(uid);
    final userSnap = await userRef.get();
    final userData = userSnap.data() ?? <String, dynamic>{};
    final gymCodes = (userData['gymCodes'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();

    // Delete gym-specific membership + rank/completedChallenges.
    final membershipRef =
        fs.collection('gyms').doc(gymId).collection('users').doc(uid);
    await _deleteCollection(fs, membershipRef.collection('rank'));
    await _deleteCollection(fs, membershipRef.collection('completedChallenges'));

    // Remove device leaderboard entries within this gym.
    final devicesSnap =
        await fs.collection('gyms').doc(gymId).collection('devices').get();
    for (final device in devicesSnap.docs) {
      final lbUserRef =
          device.reference.collection('leaderboard').doc(uid);
      await _deleteCollection(fs, lbUserRef.collection('sessions'));
      await _deleteCollection(fs, lbUserRef.collection('days'));
      await lbUserRef.delete().catchError((_) {});
    }

    // Finally delete membership entry in this gym.
    await membershipRef.delete().catchError((_) {});

    // Remove gymId from gymCodes.
    gymCodes.removeWhere((code) => code == gymId);
    // If der Nutzer nur in diesem Gym war, können wir hier
    // aus Sicherheitsgründen NICHT das User-Dokument selbst löschen,
    // da dies laut Security-Rules nur der Nutzer selbst darf.
    // Stattdessen bleiben globale User-Daten erhalten, der Nutzer
    // ist aber nicht mehr Mitglied dieses Gyms und taucht in den
    // gym-spezifischen Ranglisten nicht mehr auf.
  }
}

Future<void> _deleteCollection(
  FirebaseFirestore fs,
  CollectionReference<Map<String, dynamic>> col, {
  int batchSize = 200,
}) async {
  while (true) {
    final snap = await col.limit(batchSize).get();
    if (snap.docs.isEmpty) {
      break;
    }
    final batch = fs.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
    if (snap.docs.length < batchSize) {
      break;
    }
  }
}
