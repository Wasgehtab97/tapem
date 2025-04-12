import 'package:flutter/material.dart';
import '../services/api_services.dart';
import '../widgets/add_client_dialog.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({Key? key}) : super(key: key);

  @override
  _CoachDashboardScreenState createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  bool isLoading = true;
  List<dynamic> clients = [];
  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchClients();
  }

  Future<void> _fetchClients() async {
    try {
      final data = await apiService.getClientsForCoach();
      if (!mounted) return;
      setState(() {
        clients = data;
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Fehler beim Abrufen der Klienten: $error');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _viewClientHistory(dynamic client) {
    Navigator.pushNamed(
      context,
      '/dashboard',
      arguments: {'clientId': client['id']},
    );
  }

  void _manageTrainingPlan(dynamic client) {
    Navigator.pushNamed(
      context,
      '/trainingsplan',
      arguments: {'clientId': client['id']},
    );
  }

  // Öffnet den Dialog, um eine Membership Number einzugeben
  void _showAddClientDialog() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const AddClientDialog(),
    );
    if (result != null && result.isNotEmpty) {
      await apiService.sendCoachingRequestByMembership(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Coaching-Anfrage wurde gesendet',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
      _fetchClients();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Coach Dashboard",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : clients.isEmpty
              ? Center(
                  child: Text(
                    "Keine Klienten gefunden.",
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 16),
                  ),
                )
              : ListView.builder(
                  itemCount: clients.length,
                  itemBuilder: (context, index) {
                    final client = clients[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      color: Theme.of(context).cardColor,
                      child: ListTile(
                        title: Text(
                          client['name'] ?? "Unbekannt",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        subtitle: Text(
                          "Mitglied seit: ${client['created_at'] ?? ''}",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'history') {
                              _viewClientHistory(client);
                            } else if (value == 'plan') {
                              _manageTrainingPlan(client);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'history',
                              child: Text(
                                "Trainingshistorie",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            PopupMenuItem(
                              value: 'plan',
                              child: Text(
                                "Trainingsplan bearbeiten",
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddClientDialog,
        label: Text(
          "Klient hinzufügen",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
