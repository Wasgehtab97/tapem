// lib/screens/gym.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/api_services.dart';

class GymScreen extends StatefulWidget {
  const GymScreen({Key? key}) : super(key: key);

  @override
  State<GymScreen> createState() => _GymScreenState();
}

class _GymScreenState extends State<GymScreen> {
  List<Map<String, dynamic>> devices = [];
  String filterQuery = '';
  bool isLoading = true;
  final ApiService apiService = ApiService();

  // Kleinere, kompakte Höhen für die Masonry-Kacheln
  final List<double> _heights = [80, 90, 100];

  // ID‑Ranges und Titel
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
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    try {
      final data = await apiService.getDevices();
      if (!mounted) return;
      final fetched = data.where((d) => d['deviceId'] != null).toList();
      fetched.sort((a, b) {
        final ai = int.tryParse(a['deviceId'].toString()) ?? 0;
        final bi = int.tryParse(b['deviceId'].toString()) ?? 0;
        return ai.compareTo(bi);
      });
      setState(() {
        devices = fetched;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      debugPrint('Fehler beim Abrufen der Geräte: $e');
    }
  }

  void _showExerciseSelection(Map<String, dynamic> device) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (_) => Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Wähle Übung',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Theme.of(context).colorScheme.secondary)),
            const SizedBox(height: 8),
            for (final ex in ['Bankdrücken', 'Kniebeugen', 'Kreuzheben'])
              ListTile(
                dense: true,
                leading: Icon(Icons.fitness_center,
                    size: 18, color: Theme.of(context).colorScheme.secondary),
                title: Text(ex,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/dashboard', arguments: {
                    'deviceId': device['deviceId'].toString(),
                    'exercise': ex,
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter & deduplizieren
    final filtered = devices
        .where((d) => (d['name'] as String?)
            ?.toLowerCase()
            .contains(filterQuery.toLowerCase()) ??
        false)
        .toList();
    final seen = <String>{};
    final list = <Map<String, dynamic>>[];
    for (var d in filtered) {
      final id = d['deviceId'].toString();
      if (seen.add(id)) list.add(d);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Geräteübersicht',
            style: Theme.of(context).appBarTheme.titleTextStyle),
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
                // Kompakte Suchleiste
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: TextField(
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Suchen…',
                      hintStyle: TextStyle(
                          color: Colors.white54, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      prefixIcon: Icon(Icons.search,
                          size: 18,
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.7)),
                    ),
                    onChanged: (v) => setState(() => filterQuery = v),
                  ),
                ),
                const SizedBox(height: 8),

                // Gerätelisten nach Bereichen
                Expanded(
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : list.isEmpty
                          ? Center(
                              child: Text('Keine Geräte.',
                                  style: Theme.of(context).textTheme.bodyMedium),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (var i = 0; i < _ranges.length; i++) ...[
                                    Builder(builder: (_) {
                                      final start = _ranges[i]['start']!;
                                      final end = _ranges[i]['end']!;
                                      final section = list
                                          .where((d) {
                                            final idNum = int.tryParse(
                                                    d['deviceId'].toString()) ??
                                                0;
                                            return idNum >= start && idNum <= end;
                                          })
                                          .toList();
                                      if (section.isEmpty) return const SizedBox();
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            child: Text(_titles[i],
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .secondary)),
                                          ),
                                          MasonryGridView.count(
                                            shrinkWrap: true,
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            crossAxisCount: 4,
                                            mainAxisSpacing: 6,
                                            crossAxisSpacing: 6,
                                            itemCount: section.length,
                                            itemBuilder: (_, j) {
                                              final device = section[j];
                                              final dmId = device['deviceId']
                                                  .toString();
                                              final height = _heights[
                                                  (j + start) %
                                                      _heights.length];
                                              return GestureDetector(
                                                onTap: () {
                                                  if (device['exercise_mode'] ==
                                                      'multiple') {
                                                    _showExerciseSelection(
                                                        device);
                                                  } else {
                                                    Navigator.pushNamed(
                                                        context, '/dashboard',
                                                        arguments: {
                                                          'deviceId': dmId
                                                        });
                                                  }
                                                },
                                                child: SizedBox(
                                                  height: height,
                                                  child: Stack(
                                                    children: [
                                                      // Hintergrund
                                                      Container(
                                                        decoration:
                                                            BoxDecoration(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(8),
                                                          gradient:
                                                              LinearGradient(
                                                            colors: [
                                                              Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary
                                                                  .withOpacity(
                                                                      0.15),
                                                              Theme.of(
                                                                      context)
                                                                  .colorScheme
                                                                  .secondary
                                                                  .withOpacity(
                                                                      0.35),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      // Overlay-Balken
                                                      Positioned(
                                                        left: 0,
                                                        right: 0,
                                                        bottom: 0,
                                                        height: 24,
                                                        child: Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius.only(
                                                              bottomLeft:
                                                                  Radius.circular(
                                                                      8),
                                                              bottomRight:
                                                                  Radius.circular(
                                                                      8),
                                                            ),
                                                            gradient:
                                                                LinearGradient(
                                                              colors: [
                                                                Colors.transparent,
                                                                Colors.black54,
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      // Icon, Text & Badge
                                                      Positioned.fill(
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(4),
                                                          child: Column(
                                                            mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                            children: [
                                                              const Spacer(),
                                                              Icon(
                                                                Icons
                                                                    .fitness_center,
                                                                size: 16,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              const SizedBox(
                                                                  height: 2),
                                                              Text(
                                                                device['name']
                                                                        ?.trim() ??
                                                                    'Gerät',
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                style: const TextStyle(
                                                                    fontSize:
                                                                        8,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    color: Colors
                                                                        .white),
                                                                maxLines: 2,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                              ),
                                                              const SizedBox(
                                                                  height: 2),
                                                              Align(
                                                                alignment:
                                                                    Alignment
                                                                        .bottomRight,
                                                                child:
                                                                    Container(
                                                                  padding: const EdgeInsets
                                                                          .symmetric(
                                                                      horizontal:
                                                                          3,
                                                                      vertical:
                                                                          1),
                                                                  decoration:
                                                                      BoxDecoration(
                                                                    color: Colors
                                                                        .white24,
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            4),
                                                                  ),
                                                                  child: Text(
                                                                    '#$dmId',
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            6,
                                                                        color: Colors
                                                                            .white),
                                                                  ),
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
      bottomNavigationBar:
          Container(height: 40, color: Theme.of(context).primaryColor),
    );
  }
}
