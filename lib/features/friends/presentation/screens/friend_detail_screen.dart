import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/friend_calendar_provider.dart';
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
    context.read<FriendCalendarProvider>().setActiveFriend(widget.uid);
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final src = context.read<UserSearchSource>();
    try {
      final p = await src.getProfile(widget.uid);
      setState(() => _profile = p);
    } catch (_) {
      setState(() => _profile = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final calendar = context
        .read<FriendCalendarProvider>()
        .monthStream(_currentMonth());
    return Scaffold(
      appBar: AppBar(title: Text(_profile?.username ?? 'Freund')),
      body: StreamBuilder(
        stream: calendar,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Dieser Nutzer teilt seinen Kalender nicht.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final month = snapshot.data!;
          return ListView(
            children: month.days.entries
                .map((e) => ListTile(
                      title: Text('${e.key}: ${e.value.sessions}'),
                    ))
                .toList(),
          );
        },
      ),
    );
  }

  String _currentMonth() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';
  }
}
