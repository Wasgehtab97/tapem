import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tapem/app_router.dart';
import 'package:tapem/core/logging/firestore_read_logger.dart';
import 'package:tapem/core/providers/auth_provider.dart';
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
  static const int _pageSize = 50;

  String _query = '';
  Timer? _debounce;
  List<PublicProfile> _profiles = const [];
  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _loading = false;
  bool _hasLoadedOnce = false;
  bool _hasMore = true;
  String? _activeGymId;

  FirebaseFirestore get _firestore => widget.firestore ?? FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        unawaited(_refresh());
      }
    });
  }

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
    if (_activeGymId != auth.gymCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_refresh());
        }
      });
    }
    final gymId = auth.gymCode ?? '';
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.admin_symbols_title),
        actions: [
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.build),
              tooltip: 'backfill usernameLower',
              onPressed: () => _backfill(_firestore, gymId),
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
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _buildList(loc, gymId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(AppLocalizations loc, String gymId) {
    if (_loading && !_hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }
    if ((_activeGymId ?? '').isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(loc.no_members_found),
          ),
        ],
      );
    }
    final filtered = _filterProfiles();
    if (filtered.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(loc.no_members_found),
          ),
        ],
      );
    }
    return ListView.builder(
      itemCount: filtered.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= filtered.length) {
          if (_loading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: _hasMore ? _loadMore : null,
              child:
                  Text(MaterialLocalizations.of(context).moreButtonTooltip),
            ),
          );
        }
        final profile = filtered[index];
        final avatarKey = profile.avatarKey ?? 'default';
        final path = AvatarCatalog.instance.resolvePathOrFallback(
          avatarKey,
          gymId: gymId,
        );
        final image = Image.asset(path, errorBuilder: (_, __, ___) {
          if (kDebugMode) {
            debugPrint('[Avatar] failed to load $path');
          }
          return const Icon(Icons.person);
        });
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: image.image,
          ),
          title: Text(
            profile.username.isNotEmpty ? profile.username : profile.uid,
          ),
          onTap: () {
            debugPrint('[AdminSymbols] open uid=${profile.uid} gymId=$gymId');
            Navigator.of(context).pushNamed(
              AppRouter.userSymbols,
              arguments: profile.uid,
            );
          },
        );
      },
    );
  }

  List<PublicProfile> _filterProfiles() {
    final query = _query.trim();
    if (query.isEmpty) {
      return _profiles;
    }
    return _profiles
        .where((p) => p.safeLower.startsWith(query))
        .toList(growable: false);
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final gymId = auth.gymCode ?? '';
    setState(() {
      _activeGymId = gymId.isEmpty ? null : gymId;
      _lastDoc = null;
      _hasMore = true;
      _profiles = const [];
      _hasLoadedOnce = false;
    });
    if (_activeGymId == null) {
      setState(() {
        _loading = false;
      });
      return;
    }
    await _fetchPage(reset: true);
  }

  Future<void> _loadMore() async {
    if (!_hasMore || _loading) return;
    await _fetchPage();
  }

  Future<void> _fetchPage({bool reset = false}) async {
    final gymId = _activeGymId;
    if (gymId == null) return;
    setState(() {
      _loading = true;
    });
    List<PublicProfile> newProfiles = const [];
    DocumentSnapshot<Map<String, dynamic>>? newLastDoc = _lastDoc;
    var hasMore = _hasMore;
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('users')
          .where('gymCodes', arrayContains: gymId)
          .limit(_pageSize);
      if (_lastDoc != null && !reset) {
        query = query.startAfterDocument(_lastDoc!);
      }
      FirestoreReadLogger.logStart(
        scope: 'admin.symbols',
        path: 'users(gym=$gymId)',
        operation: 'get',
        reason: reset ? 'refresh' : 'paginate',
      );
      final snap = await query.get();
      FirestoreReadLogger.logResult(
        scope: 'admin.symbols',
        path: 'users(gym=$gymId)',
        count: snap.size,
        fromCache: snap.metadata.isFromCache,
      );
      newProfiles = snap.docs
          .map((d) => PublicProfile.fromMap(d.id, d.data()))
          .toList(growable: false);
      newLastDoc = snap.docs.isNotEmpty
          ? snap.docs.last
          : (reset ? null : _lastDoc);
      hasMore = snap.docs.length == _pageSize;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AdminSymbols] load failed: $e');
      }
      hasMore = false;
    } finally {
      if (!mounted) return;
      setState(() {
        if (reset) {
          _profiles = newProfiles;
        } else {
          _profiles = List.of(_profiles)..addAll(newProfiles);
        }
        _lastDoc = newLastDoc;
        _hasMore = hasMore;
        _loading = false;
        _hasLoadedOnce = true;
      });
    }
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

