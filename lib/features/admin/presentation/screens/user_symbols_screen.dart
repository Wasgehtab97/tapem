import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class UserSymbolsScreen extends StatelessWidget {
  const UserSymbolsScreen({super.key, required this.uid, this.firestore});

  final String uid;
  final FirebaseFirestore? firestore;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.user_symbols_title(''))),
        body: const Center(child: Text('Kein Zugriff')),
      );
    }
    final invProv = context.read<AvatarInventoryProvider>();
    final gymId = auth.gymCode ?? '';
    final fs = firestore ?? FirebaseFirestore.instance;
    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: fs.collection('users').doc(uid).snapshots(),
          builder: (context, snap) {
            final name = snap.data?.data()?['username'] as String? ?? uid;
            return Text(loc.user_symbols_title(name));
          },
        ),
      ),
      body: StreamBuilder<List<String>>(
        stream: invProv.inventoryKeys(uid),
        builder: (context, snapshot) {
          final inv = snapshot.data ?? const <String>[];
          if (inv.isEmpty) {
            return Center(child: Text(loc.empty_inventory_hint));
          }
          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: inv.length,
            itemBuilder: (context, index) {
              final key = inv[index];
              final path = AvatarCatalog.instance.resolvePath(key);
              return CircleAvatar(
                backgroundImage: AssetImage(path),
                radius: 40,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final currentInv = await invProv.inventoryKeys(uid).first;
          final allGymKeys = AvatarCatalog.instance.listForGym(gymId);
          final available = allGymKeys.where((k) => !currentInv.contains(k)).toList();
          if (available.isEmpty) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.empty_gym_library_hint)),
            );
            return;
          }
          final selected = await showModalBottomSheet<List<String>>(
            context: context,
            builder: (ctx) {
              final sel = <String>{};
              return StatefulBuilder(
                builder: (ctx2, setSt) {
                  return SafeArea(
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            padding: const EdgeInsets.all(16),
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 100,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: available.length,
                            itemBuilder: (context, index) {
                              final key = available[index];
                              final selectedKey = sel.contains(key);
                              final path = AvatarCatalog.instance.resolvePath(key);
                              return GestureDetector(
                                onTap: () => setSt(() {
                                  if (selectedKey) {
                                    sel.remove(key);
                                  } else {
                                    sel.add(key);
                                  }
                                }),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    CircleAvatar(
                                      backgroundImage: AssetImage(path),
                                      radius: 40,
                                    ),
                                    if (selectedKey)
                                      const Positioned(
                                        right: 4,
                                        bottom: 4,
                                        child: Icon(Icons.check_circle, color: Colors.green),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx2, sel.toList()),
                          child: Text(loc.add_symbols_cta + (sel.isEmpty ? '' : ' (${sel.length})')),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
          if (selected != null && selected.isNotEmpty) {
            await invProv.addKeys(uid, selected,
                source: 'gym:$gymId', addedBy: auth.userId ?? '');
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.saved_snackbar)),
            );
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

