import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/core/providers/auth_provider.dart';
import 'package:tapem/features/avatars/domain/services/avatar_catalog.dart';
import 'package:tapem/features/avatars/presentation/providers/avatar_inventory_provider.dart';
import 'package:tapem/l10n/app_localizations.dart';

class UserSymbolsScreen extends StatefulWidget {
  const UserSymbolsScreen({super.key, required this.uid, this.firestore});

  final String uid;
  final FirebaseFirestore? firestore;

  @override
  State<UserSymbolsScreen> createState() => _UserSymbolsScreenState();
}

class _UserSymbolsScreenState extends State<UserSymbolsScreen> {
  late final AvatarInventoryProvider _inventory;
  late final FirebaseFirestore _fs;
  late final String _gymId;
  bool _permitted = false;
  bool _loading = true;
  Set<String> _keys = <String>{};

  @override
  void initState() {
    super.initState();
    _inventory = context.read<AvatarInventoryProvider>();
    final auth = context.read<AuthProvider>();
    _gymId = auth.gymCode ?? '';
    _fs = widget.firestore ?? FirebaseFirestore.instance;
    _init();
  }

  Future<void> _init() async {
    debugPrint('[UserSymbols] init uid=${widget.uid} gymId=$_gymId');
    try {
      final membership = await _fs
          .collection('gyms')
          .doc(_gymId)
          .collection('users')
          .doc(widget.uid)
          .get();
      debugPrint('[UserSymbols] membership exists=${membership.exists}');
    } catch (e) {
      debugPrint('[UserSymbols] membership fetch error: $e');
    }
    _permitted = context.read<AuthProvider>().isAdmin;
    if (_permitted) {
      try {
        final inv = await _inventory
            .inventoryKeys(widget.uid, currentGymId: _gymId)
            .first;
        _keys = inv.toSet();
      } catch (e) {
        debugPrint('[UserSymbols] inventory error: $e');
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggle(String key, String source) async {
    final has = _keys.contains(key);
    setState(() {
      if (has) {
        _keys.remove(key);
      } else {
        _keys.add(key);
      }
    });
    try {
      if (has) {
        await _inventory.removeKey(widget.uid, key);
      } else {
        await _inventory.addKeys(widget.uid, [key],
            source: source,
            createdBy: context.read<AuthProvider>().userId ?? '',
            gymId: _gymId);
      }
    } on FirebaseException catch (e) {
      setState(() {
        if (has) {
          _keys.add(key);
        } else {
          _keys.remove(key);
        }
      });
      if (e.code == 'permission-denied') {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.no_permission_symbols)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.user_symbols_title(''))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (!_permitted) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.user_symbols_title(''))),
        body: const Center(child: Text('Kein Zugriff')),
      );
    }
    final catalog = AvatarCatalog.instance.allForContext(_gymId);
    final inventoryItems = _keys
        .map((k) => AvatarItem(k, AvatarCatalog.instance.pathForKey(k)))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final globalItems = catalog.global
        .where((item) => !_keys.contains(item.key))
        .toList();
    final gymItems = catalog.gym
        .where((item) => !_keys.contains(item.key))
        .toList();

    Widget buildSection(String title, List<AvatarItem> items,
        {bool allowRemove = false}) {
      if (items.isEmpty) return const SizedBox.shrink();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('$title (${items.length})',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final selected = _keys.contains(item.key);
              final image = Image.asset(item.path, errorBuilder: (_, __, ___) {
                if (kDebugMode) {
                  debugPrint('[Avatar] failed to load ${item.path}');
                }
                return const Icon(Icons.person);
              });
              final ns = item.key.split('/').first;
              return GestureDetector(
                onTap: allowRemove
                    ? null
                    : () => _toggle(item.key, 'admin/manual'),
                onLongPress: allowRemove
                    ? () => _toggle(item.key, 'admin/manual')
                    : null,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      backgroundImage: image.image,
                      radius: 40,
                      child: const Icon(Icons.person),
                    ),
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(ns,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 10)),
                      ),
                    ),
                    if (selected)
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
        ],
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _fs.collection('users').doc(widget.uid).snapshots(),
      builder: (context, snap) {
        final name = snap.data?.data()?['username'] as String? ?? widget.uid;
        return Scaffold(
          appBar: AppBar(title: Text(loc.user_symbols_title(name))),
          body: SingleChildScrollView(
            child: Column(
              children: [
                buildSection('Inventar von $name', inventoryItems,
                    allowRemove: true),
                buildSection('Global', globalItems),
                buildSection(_gymId, gymItems),
              ],
            ),
          ),
        );
      },
    );
  }
}
