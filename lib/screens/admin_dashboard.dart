// lib/screens/admin_dashboard.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/api_services.dart';
import '../widgets/device_create_form.dart';
import '../widgets/device_update_form.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();

  List<Map<String, dynamic>> _devices = [];
  String _filter = '';
  bool _loading = true;

  // Kompakte Kachelhöhen
  final List<double> _heights = [80, 90, 100];

  // ID‑Ranges und Sektionstitel
  final List<Map<String, int>> _ranges = [
    {'start': 1,   'end': 21},
    {'start': 22,  'end': 46},
    {'start': 47,  'end': 102},
    {'start': 103, 'end': 114},
    {'start': 115, 'end': 139},
    {'start': 140, 'end': 152},
  ];
  final List<String> _titles = [
    'Powerlifting',
    'Kurzhantel & Kabel',
    'Push & Pull',
    'Legpresses',
    'Legs',
    'Wiese',
  ];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() => _loading = true);
    try {
      final data = await _api.getDevices();
      final list = data
          .where((d) => d['deviceId'] != null && d['documentId'] != null)
          .toList()
            ..sort((a, b) {
              final ai = a['deviceId'] as int;
              final bi = b['deviceId'] as int;
              return ai.compareTo(bi);
            });
      if (!mounted) return;
      setState(() {
        _devices = list;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Admin: Fehler beim Laden: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final lower = _filter.toLowerCase();
    final seen = <int>{};
    return _devices.where((d) {
      final name = (d['name'] as String).toLowerCase();
      return name.contains(lower);
    }).where((d) {
      final id = d['deviceId'] as int;
      if (seen.contains(id)) return false;
      seen.add(id);
      return true;
    }).toList();
  }

  void _onSearch(String v) => setState(() => _filter = v);

  void _showCreate() {
    showDialog(
      context: context,
      builder: (_) => DeviceCreateForm(onCreated: (_) {
        Navigator.of(context).pop();
        _loadDevices();
      }),
    );
  }

  void _showEdit(Map<String, dynamic> dev) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Gerät bearbeiten', style: Theme.of(context).textTheme.titleLarge),
        content: DeviceUpdateForm(
          documentId: dev['documentId'] as String,
          currentName: dev['name'] as String,
          currentExerciseMode: dev['exercise_mode'] as String,
          currentSecretCode: dev['secret_code'] as String,
          onUpdated: (_) {
            Navigator.of(context).pop();
            _loadDevices();
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Schließen', style: TextStyle(color: Theme.of(context).colorScheme.secondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final list = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin‑Dashboard'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Column(
              children: [
                // Suchleiste
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    onChanged: _onSearch,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Gerät suchen…',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.search, size: 18, color: theme.colorScheme.secondary.withOpacity(0.7)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                          ? Center(child: Text('Keine Geräte.', style: theme.textTheme.bodyMedium))
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < _ranges.length; i++) ...[
                                    Builder(builder: (_) {
                                      final start = _ranges[i]['start']!;
                                      final end = _ranges[i]['end']!;
                                      final section = list.where((d) {
                                        final idNum = d['deviceId'] as int;
                                        return idNum >= start && idNum <= end;
                                      }).toList();
                                      if (section.isEmpty) return const SizedBox();
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 6),
                                            child: Text(
                                              _titles[i],
                                              style: theme.textTheme.titleSmall
                                                  ?.copyWith(color: theme.colorScheme.secondary),
                                            ),
                                          ),
                                          MasonryGridView.count(
                                            crossAxisCount: 4,
                                            mainAxisSpacing: 6,
                                            crossAxisSpacing: 6,
                                            shrinkWrap: true,
                                            physics: const NeverScrollableScrollPhysics(),
                                            itemCount: section.length,
                                            itemBuilder: (_, j) {
                                              final dev = section[j];
                                              final dmId = dev['deviceId'].toString();
                                              final height = _heights[(j + start) % _heights.length];
                                              return GestureDetector(
                                                onTap: () => _showEdit(dev),
                                                child: SizedBox(
                                                  height: height,
                                                  child: Stack(
                                                    children: [
                                                      // Hintergrund
                                                      Container(
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(8),
                                                          gradient: LinearGradient(
                                                            colors: [
                                                              theme.colorScheme.secondary.withOpacity(0.15),
                                                              theme.colorScheme.secondary.withOpacity(0.35),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      // Overlay
                                                      Positioned(
                                                        left: 0, right: 0, bottom: 0, height: 24,
                                                        child: Container(
                                                          decoration: const BoxDecoration(
                                                            borderRadius: BorderRadius.only(
                                                              bottomLeft: Radius.circular(8),
                                                              bottomRight: Radius.circular(8),
                                                            ),
                                                            gradient: LinearGradient(
                                                              colors: [Colors.transparent, Colors.black54],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      // Inhalt
                                                      Positioned.fill(
                                                        child: Padding(
                                                          padding: const EdgeInsets.all(4),
                                                          child: Column(
                                                            mainAxisAlignment: MainAxisAlignment.center,
                                                            children: [
                                                              const Spacer(),
                                                              const Icon(Icons.fitness_center, size: 16, color: Colors.white),
                                                              const SizedBox(height: 2),
                                                              Text(
                                                                dev['name']?.trim() ?? 'Gerät',
                                                                textAlign: TextAlign.center,
                                                                style: const TextStyle(
                                                                  fontSize: 8,
                                                                  fontWeight: FontWeight.bold,
                                                                  color: Colors.white,
                                                                ),
                                                                maxLines: 2,
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                              const SizedBox(height: 2),
                                                              Align(
                                                                alignment: Alignment.bottomRight,
                                                                child: Container(
                                                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                                                  decoration: BoxDecoration(
                                                                    color: Colors.white24,
                                                                    borderRadius: BorderRadius.circular(4),
                                                                  ),
                                                                  child: Text('#$dmId', style: const TextStyle(fontSize: 6, color: Colors.white)),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ],
                                      );
                                    }),
                                  ],
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(height: 40, color: theme.primaryColor),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreate,
        backgroundColor: theme.primaryColor,
        child: Icon(Icons.add, color: theme.colorScheme.secondary),
      ),
    );
  }
}
