import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/user_search_source.dart';
import '../../domain/models/public_profile.dart';

class FriendDetailScreen extends StatefulWidget {
  const FriendDetailScreen({required this.uid, Key? key}) : super(key: key);
  final String uid;
  static Route<void> route(String uid) =>
      MaterialPageRoute(builder: (_) => FriendDetailScreen(uid: uid));
  @override
  State<FriendDetailScreen> createState() => _FriendDetailScreenState();
}

class _FriendDetailScreenState extends State<FriendDetailScreen> {
  PublicProfile? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final src = context.read<UserSearchSource>();
    try {
      final p = await src.getProfile(widget.uid);
      if (mounted) {
        setState(() => _profile = p);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _profile = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _profile?.username ?? 'Profil';
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Center(
        child: _profile == null
            ? const Text('Keine Daten')
            : Text('Profil von $name'),
      ),
    );
  }
}
