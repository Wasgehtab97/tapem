import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_services.dart';
import '../widgets/feedback_overview.dart';

class ReportDashboardScreen extends StatefulWidget {
  const ReportDashboardScreen({super.key});

  @override
  ReportDashboardScreenState createState() => ReportDashboardScreenState();
}

class ReportDashboardScreenState extends State<ReportDashboardScreen> {
  final ApiService apiService = ApiService();

  List<dynamic> reportData = [];
  List<dynamic> devices = [];
  // selectedDevice: leer bedeutet "Alle"
  String selectedDevice = "";
  bool isLoading = false;
  final int lowUsageThreshold = 3;

  // Steuerung der Sortierreihenfolge: true = absteigend, false = aufsteigend.
  bool sortDescending = true;

  // Speichert den aktuell ausgewählten Zeitraum als String (z. B. "2023-01-01 bis 2023-01-31")
  String selectedDateRange = "Zeitraum auswählen";

  // Map zum Speichern des Feedbackstatus (Farbe) für jedes Gerät (device_id als Key).
  Map<String, Color> deviceFeedbackColors = {};

  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    _fetchDevices().then((_) {
      for (var device in devices) {
        _fetchFeedbackStatus(device['id'].toString());
      }
    });
    _fetchReportData();
  }

  Future<void> _fetchDevices() async {
    try {
      final fetchedDevices = await apiService.getDevices();
      setState(() {
        devices = fetchedDevices;
      });
    } catch (error) {
      debugPrint('Fehler beim Abrufen der Geräte: $error');
    }
  }

  Future<void> _fetchReportData() async {
    setState(() {
      isLoading = true;
    });
    try {
      final data = await apiService.getReportingData(
        startDate: _rangeStart != null ? DateFormat('yyyy-MM-dd').format(_rangeStart!) : null,
        endDate: _rangeEnd != null ? DateFormat('yyyy-MM-dd').format(_rangeEnd!) : null,
        // Da selectedDevice nie null ist, prüfen wir nur auf isNotEmpty.
        deviceId: selectedDevice.isNotEmpty ? selectedDevice : null,
      );
      setState(() {
        reportData = data;
      });
    } catch (error) {
      debugPrint('Fehler beim Abrufen der Nutzungshäufigkeit: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Öffnet den DateRangePicker und speichert den ausgewählten Zeitraum.
  Future<void> _selectDateRange() async {
    final DateTime now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: (_rangeStart != null && _rangeEnd != null)
          ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
          : null,
      helpText: 'Zeitraum auswählen',
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.red,
              onPrimary: Colors.white,
              surface: Colors.black,
              onSurface: Colors.red,
            ),
            dialogTheme: DialogTheme(
              backgroundColor: Colors.grey,
            ),
          ),
          // Da wir sicher sind, dass child niemals null ist, casten wir ihn direkt.
          child: child as Widget,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
        selectedDateRange =
            "${DateFormat('yyyy-MM-dd').format(picked.start)} bis ${DateFormat('yyyy-MM-dd').format(picked.end)}";
      });
      _fetchReportData();
    }
  }

  /// Ruft den Feedbackstatus für ein bestimmtes Gerät ab.
  Future<void> _fetchFeedbackStatus(String deviceId) async {
    try {
      final response =
          await apiService.getDataFromUrl('/api/feedback?deviceId=$deviceId');
      if (response != null && response['data'] != null) {
        List feedbacks = response['data'];
        Color color;
        if (feedbacks.isEmpty) {
          color = Colors.yellow;
        } else if (feedbacks.any((fb) => fb['status'] == 'neu')) {
          color = Colors.red;
        } else {
          color = Colors.green;
        }
        setState(() {
          deviceFeedbackColors[deviceId] = color;
        });
      } else {
        setState(() {
          deviceFeedbackColors[deviceId] = Colors.yellow;
        });
      }
    } catch (e) {
      setState(() {
        deviceFeedbackColors[deviceId] = Colors.yellow;
      });
      debugPrint('Fehler beim Abrufen des Feedbackstatus für Gerät $deviceId: $e');
    }
  }

  /// Kombiniert die Reportdaten mit allen Geräten.
  /// Für Geräte ohne Reportdaten wird der session_count auf 0 gesetzt.
  List<Map<String, dynamic>> get combinedUsage {
    return devices.map((device) {
      final devId = device['id'].toString();
      final reportEntry = reportData.firstWhere(
        (entry) => entry['device_id'].toString() == devId,
        orElse: () => <String, dynamic>{},
      );
      double count = reportEntry.isNotEmpty
          ? double.tryParse(reportEntry['session_count'].toString()) ?? 0.0
          : 0.0;
      return {
        'device_id': devId,
        'name': device['name'],
        'session_count': count,
      };
    }).toList();
  }

  /// Liefert die kombinierte Nutzungs-Liste sortiert nach session_count.
  /// Wird ein Gerät ausgewählt (selectedDevice ist nicht leer), wird nur dieses angezeigt.
  List<Map<String, dynamic>> get sortedCombinedUsage {
    List<Map<String, dynamic>> usage = List.from(combinedUsage);
    if (selectedDevice.isNotEmpty) {
      usage = usage.where((item) => item['device_id'] == selectedDevice).toList();
    }
    usage.sort((a, b) {
      double countA = a['session_count'];
      double countB = b['session_count'];
      return sortDescending ? countB.compareTo(countA) : countA.compareTo(countB);
    });
    return usage;
  }

  /// Bestimmt den maximalen session_count aus der sortierten Nutzungs-Liste.
  double get _maxSessionCount {
    double maxCount = 0.0;
    for (var item in sortedCombinedUsage) {
      double count = item['session_count'];
      if (count > maxCount) maxCount = count;
    }
    return maxCount > 0 ? maxCount : 1;
  }

  void _handleFeedbackRequest(dynamic deviceId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Feedback-Anfrage für Gerät $deviceId gesendet.')),
    );
  }

  /// Öffnet die Feedbackübersicht für das jeweilige Gerät.
  void _showFeedbackOverview(String deviceId) {
    showDialog(
      context: context,
      builder: (context) {
        // Achte darauf, dass FeedbackOverview als öffentliche Klasse definiert ist.
        return Dialog(
          child: FeedbackOverview(deviceId: int.tryParse(deviceId) ?? 0),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Reporting',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          PopupMenuButton<bool>(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).iconTheme.color,
              size: 20,
            ),
            onSelected: (value) {
              setState(() {
                sortDescending = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: true,
                child: Text(
                  "Absteigend",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ),
              PopupMenuItem(
                value: false,
                child: Text(
                  "Aufsteigend",
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12),
                ),
              ),
            ],
          )
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          "Auswahl:",
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 12),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 100,
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedDevice.isNotEmpty ? selectedDevice : null,
                            hint: Text(
                              "Alle",
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontSize: 12),
                            ),
                            items: [
                              DropdownMenuItem(
                                value: "",
                                child: Text(
                                  "Alle",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 12),
                                ),
                              ),
                              ...devices.map((device) {
                                return DropdownMenuItem<String>(
                                  value: device['id'].toString(),
                                  child: Text(
                                    device['name'].toString(),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontSize: 12),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedDevice = value ?? "";
                                _fetchReportData();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _selectDateRange,
                    child: Text(
                      selectedDateRange,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 12),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 8),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sortedCombinedUsage.map((item) {
                        double sessionCount = item['session_count'];
                        String deviceName = item['name'];
                        double percentage = sessionCount / _maxSessionCount;
                        // Ersetze withOpacity durch withAlpha unter Verwendung der .a-Eigenschaft
                        Color backgroundColor = Theme.of(context)
                            .colorScheme
                            .secondary
                            .withAlpha((Theme.of(context).colorScheme.secondary.a * 0.3).toInt());
                        Color starColor = deviceFeedbackColors[item['device_id']] ?? Colors.yellow;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100,
                                child: Text(
                                  deviceName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  sessionCount.toStringAsFixed(0),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: backgroundColor,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: percentage > 1 ? 1 : percentage,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.secondary,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  Icons.error_outline,
                                  color: Theme.of(context).iconTheme.color,
                                  size: 16,
                                ),
                                onPressed: () => _handleFeedbackRequest(item['device_id']),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.star,
                                  color: starColor,
                                  size: 16,
                                ),
                                onPressed: () => _showFeedbackOverview(item['device_id']),
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
