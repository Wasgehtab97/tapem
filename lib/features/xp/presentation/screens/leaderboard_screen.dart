import 'package:flutter/material.dart';
import '../widgets/xp_time_series_chart.dart';

/// A simple model representing a single leaderboard entry. This can be
/// expanded later to include avatar URLs, rank icons and badges.
class LeaderboardEntry {
  final String userId;
  final String username;
  final int xp;

  LeaderboardEntry({required this.userId, required this.username, required this.xp});
}

/// A configurable leaderboard screen modelled after e-sport ranking pages.
///
/// [fetchEntries] is a callback that returns a future list of entries for the
/// given period. Only users with `showInLeaderboard` set to true should be
/// returned by the callback.
class LeaderboardScreen extends StatefulWidget {
  final String title;
  final Future<List<LeaderboardEntry>> Function(XpPeriod period) fetchEntries;

  const LeaderboardScreen({Key? key, required this.title, required this.fetchEntries}) : super(key: key);

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  XpPeriod _period = XpPeriod.last7Days;
  List<LeaderboardEntry>? _entries;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() {
      _loading = true;
    });
    final data = await widget.fetchEntries(_period);
    data.sort((a, b) => b.xp.compareTo(a.xp));
    setState(() {
      _entries = data;
      _loading = false;
    });
  }

  void _onPeriodChanged(XpPeriod? value) {
    if (value != null && value != _period) {
      setState(() {
        _period = value;
      });
      _loadEntries();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text('Zeitraum:', style: TextStyle(color: Colors.white70)),
                const SizedBox(width: 8),
                DropdownButton<XpPeriod>(
                  value: _period,
                  dropdownColor: const Color(0xFF1E1E1E),
                  style: const TextStyle(color: Colors.white),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: XpPeriod.last7Days, child: Text('7 Tage')),
                    DropdownMenuItem(value: XpPeriod.last30Days, child: Text('30 Tage')),
                    DropdownMenuItem(value: XpPeriod.total, child: Text('Gesamt')),
                  ],
                  onChanged: _onPeriodChanged,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _entries == null
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        itemCount: _entries!.length,
                        itemBuilder: (context, index) {
                          final entry = _entries![index];
                          final maxXp = _entries!.first.xp;
                          final fraction = maxXp > 0 ? entry.xp / maxXp : 0.0;
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey.shade700,
                              child: Text('${index + 1}', style: const TextStyle(color: Colors.white)),
                            ),
                            title: Text(
                              entry.username.isNotEmpty ? entry.username : entry.userId,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: LinearProgressIndicator(
                                value: fraction.clamp(0.0, 1.0),
                                minHeight: 6,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color.lerp(const Color(0xFF00E676), const Color(0xFFFFC107), fraction)!,
                                ),
                                backgroundColor: Colors.grey.shade800,
                              ),
                            ),
                            trailing: Text(
                              '${entry.xp} XP',
                              style: const TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
