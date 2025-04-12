import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config.dart';

class FeedbackOverview extends StatefulWidget {
  final int deviceId;
  const FeedbackOverview({Key? key, required this.deviceId}) : super(key: key);

  @override
  FeedbackOverviewState createState() => FeedbackOverviewState();
}

class FeedbackOverviewState extends State<FeedbackOverview> {
  List<dynamic> feedbacks = [];
  bool loading = false;
  String statusFilter = '';

  @override
  void initState() {
    super.initState();
    _fetchFeedbacks();
  }

  Future<void> _fetchFeedbacks() async {
    setState(() {
      loading = true;
    });
    try {
      List<String> queryParams = ['deviceId=${widget.deviceId}'];
      if (statusFilter.isNotEmpty) {
        queryParams.add('status=${Uri.encodeComponent(statusFilter)}');
      }
      String queryString = queryParams.isNotEmpty ? '?${queryParams.join('&')}' : '';
      final response = await http.get(Uri.parse('$API_URL/api/feedback$queryString'));
      final result = jsonDecode(response.body);
      if (response.statusCode == 200 && result['data'] != null) {
        setState(() {
          feedbacks = result['data'];
        });
      } else {
        debugPrint(result['error']?.toString());
      }
    } catch (error) {
      debugPrint('Fehler beim Abrufen des Feedbacks: $error');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> _updateFeedbackStatus(int feedbackId, String newStatus) async {
    try {
      final response = await http.put(
        Uri.parse('$API_URL/api/feedback/$feedbackId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': newStatus}),
      );
      final result = jsonDecode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          feedbacks = feedbacks.map((fb) {
            if (fb['id'] == feedbackId) {
              fb['status'] = newStatus;
            }
            return fb;
          }).toList();
        });
      } else {
        debugPrint(result['error']?.toString());
      }
    } catch (error) {
      debugPrint('Fehler beim Aktualisieren des Feedback-Status: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Feedback Übersicht',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "Status: ",
                style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
              ),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: statusFilter.isNotEmpty ? statusFilter : null,
                hint: Text(
                  "Alle",
                  style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(
                      "Alle",
                      style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'neu',
                    child: Text(
                      "Neu",
                      style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'in Bearbeitung',
                    child: Text(
                      "In Bearbeitung",
                      style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'erledigt',
                    child: Text(
                      "Erledigt",
                      style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    statusFilter = value ?? '';
                  });
                  _fetchFeedbacks();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          loading
              ? const Center(child: CircularProgressIndicator())
              : feedbacks.isEmpty
                  ? Center(
                      child: Text(
                        "Kein Feedback vorhanden.",
                        style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: feedbacks.length,
                      itemBuilder: (context, index) {
                        final fb = feedbacks[index];
                        final createdAt = DateTime.tryParse(fb['created_at']?.toString() ?? '')?.toLocal() ?? DateTime.now();
                        final formattedDate =
                            "${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}";
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(
                              fb['feedback_text'] ?? '',
                              style: textTheme.bodyMedium?.copyWith(color: theme.colorScheme.secondary),
                            ),
                            subtitle: Text(
                              'Status: ${fb['status']} • $formattedDate',
                              style: textTheme.bodySmall?.copyWith(color: theme.colorScheme.secondary),
                            ),
                            trailing: fb['status'] != 'erledigt'
                                ? IconButton(
                                    icon: Icon(Icons.check, color: theme.colorScheme.secondary),
                                    onPressed: () => _updateFeedbackStatus(fb['id'], 'erledigt'),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
        ],
      ),
    );
  }
}
