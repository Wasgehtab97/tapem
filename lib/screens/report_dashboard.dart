// lib/screens/report_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/feedback_overview.dart';

class ReportDashboardScreen extends StatefulWidget {
  const ReportDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ReportDashboardScreen> createState() => _ReportDashboardScreenState();
}

class _ReportDashboardScreenState extends State<ReportDashboardScreen> {
  List<Map<String, dynamic>> _reportData = [];
  List<Map<String, dynamic>> _devices = [];
  String _selectedDevice = "";
  bool _isLoading = false;
  bool _sortDescending = true;
  String _selectedDateRange = "Zeitraum auswählen";
  final Map<String, Color> _deviceFeedbackColors = {};
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    try {
      // Geräte, Feedback und Report parallel laden
      await Future.wait([
        _fetchDevices(),
        _fetchAllFeedbackStatus(),
      ]);
      await _fetchReportData();
    } catch (e) {
      debugPrint("Initialisierung fehlgeschlagen: $e");
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  /// 1) Alle Geräte aus Firestore holen
  Future<void> _fetchDevices() async {
    final snap = await FirebaseFirestore.instance.collection('devices').get();
    _devices = snap.docs.map((d) {
      final m = Map<String, dynamic>.from(d.data());
      m['id'] = d.id;
      return m;
    }).toList();
    if (mounted) setState(() {});
  }

  /// 2) Ein einziger Request auf feedback, danach gruppieren wir client‑seitig
  Future<void> _fetchAllFeedbackStatus() async {
    final snap = await FirebaseFirestore.instance.collection('feedback').get();
    // deviceId → Liste aller Feedback‐Dokumente
    final Map<String, List<QueryDocumentSnapshot>> byDevice = {};
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final id = data['device_id'].toString();
      byDevice.putIfAbsent(id, () => []).add(doc);
    }
    // Farben bestimmen
    for (var dev in _devices) {
      final id = dev['id'] as String;
      final list = byDevice[id] ?? [];
      Color c;
      if (list.isEmpty) {
        c = Colors.yellow;
      } else if (list.any((d) => (d.data() as Map<String, dynamic>)['status'] == 'neu')) {
        c = Colors.red;
      } else {
        c = Colors.green;
      }
      _deviceFeedbackColors[id] = c;
    }
    if (mounted) setState(() {});
  }

  /// 3) Trainingshistorie abrufen und Häufigkeiten zählen
  Future<void> _fetchReportData() async {
    Query q = FirebaseFirestore.instance.collection('training_history');

    if (_rangeStart != null && _rangeEnd != null) {
      q = q
          .where('training_date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(_rangeStart!))
          .where('training_date',
              isLessThanOrEqualTo: Timestamp.fromDate(_rangeEnd!));
    }
    if (_selectedDevice.isNotEmpty) {
      q = q.where('device_id', isEqualTo: _selectedDevice);
    }

    final snap = await q.get();
    final usageMap = <String, int>{};
    for (var doc in snap.docs) {
      final d = doc.data() as Map<String, dynamic>;
      final id = d['device_id'].toString();
      usageMap[id] = (usageMap[id] ?? 0) + 1;
    }

    _reportData = _devices.map((dev) {
      final id = dev['id'] as String;
      return {
        'device_id': id,
        'name': dev['name'] as String? ?? '–',
        'session_count': usageMap[id] ?? 0,
      };
    }).toList();
    if (mounted) setState(() {});
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (_rangeStart != null && _rangeEnd != null)
          ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
          : null,
    );
    if (picked != null && mounted) {
      _rangeStart = picked.start;
      _rangeEnd = picked.end;
      _selectedDateRange =
          "${DateFormat('yyyy-MM-dd').format(picked.start)} bis ${DateFormat('yyyy-MM-dd').format(picked.end)}";
      await _fetchReportData();
    }
  }

  List<Map<String, dynamic>> get _sortedUsage {
    final list = _reportData.where((e) {
      return _selectedDevice.isEmpty || e['device_id'] == _selectedDevice;
    }).toList();
    list.sort((a, b) {
      final aC = a['session_count'] as int;
      final bC = b['session_count'] as int;
      return _sortDescending ? bC.compareTo(aC) : aC.compareTo(bC);
    });
    return list;
  }

  double get _maxCount {
    final mx = _sortedUsage
        .map((e) => e['session_count'] as int)
        .fold<int>(0, (p, e) => e > p ? e : p);
    return mx > 0 ? mx.toDouble() : 1.0;
  }

  void _handleFeedbackRequest(String id) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback-Anfrage für Gerät $id gesendet.')),
    );
  }

  void _showFeedbackOverview(String id) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: FeedbackOverview(deviceId: int.parse(id)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Reporting', style: theme.appBarTheme.titleTextStyle),
        backgroundColor: theme.appBarTheme.backgroundColor,
        actions: [
          PopupMenuButton<bool>(
            tooltip: 'Sortierreihenfolge',
            onSelected: (v) async {
              if (!mounted) return;
              setState(() => _sortDescending = v);
              await _fetchReportData();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: true, child: Text("Absteigend")),
              PopupMenuItem(value: false, child: Text("Aufsteigend")),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A), Color(0xFF333333)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Filter-Zeile
              Row(
                children: [
                  const Text("Gerät:"),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _selectedDevice.isEmpty ? null : _selectedDevice,
                    hint: const Text("Alle"),
                    items: [
                      const DropdownMenuItem(value: "", child: Text("Alle")),
                      ..._devices.map((d) {
                        final id = d['id'] as String;
                        final name = d['name'] as String? ?? '–';
                        return DropdownMenuItem(value: id, child: Text(name));
                      }),
                    ],
                    onChanged: (v) async {
                      if (!mounted) return;
                      setState(() => _selectedDevice = v ?? "");
                      await _fetchReportData();
                    },
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _selectDateRange,
                    child: Text(_selectedDateRange),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Column(
                  children: _sortedUsage.map((e) {
                    final cnt = e['session_count'] as int;
                    final pct = cnt / _maxCount;
                    final color = _deviceFeedbackColors[e['device_id']] ??
                        Colors.yellow;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              e['name'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(cnt.toString()),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              height: 16,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: FractionallySizedBox(
                                widthFactor: pct.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.error_outline, size: 16),
                            onPressed: () =>
                                _handleFeedbackRequest(e['device_id']),
                          ),
                          IconButton(
                            icon: Icon(Icons.star, color: color, size: 16),
                            onPressed: () =>
                                _showFeedbackOverview(e['device_id']),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
