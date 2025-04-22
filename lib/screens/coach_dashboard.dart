// lib/screens/coach_dashboard.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../widgets/add_client_dialog.dart';
import '../widgets/full_screen_calendar.dart';

class CoachDashboardScreen extends StatefulWidget {
  const CoachDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CoachDashboardScreen> createState() => _CoachDashboardScreenState();
}

class _CoachDashboardScreenState extends State<CoachDashboardScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _clients = [];

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  Future<void> _loadClients() async {
    setState(() => _isLoading = true);
    try {
      final coachId = FirebaseAuth.instance.currentUser!.uid;
      // angenommen: Unter users/{coachId}/clients liegen Dokumente mit clientId als ID
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(coachId)
          .collection('clients')
          .get();

      final clients = await Future.wait(snap.docs.map((doc) async {
        final clientId = doc.id;
        // optional: stored join date
        final joinedTs = (doc.data()['joined_at'] as Timestamp?);
        final joined = joinedTs != null
            ? DateFormat('dd.MM.yyyy')
                .format(joinedTs.toDate().toUtc().add(const Duration(hours: 1)))
            : '–';
        // Name des Users aus users collection
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(clientId)
            .get();
        final name = userDoc.data()?['name'] as String? ?? 'Unbekannt';
        return {
          'id': clientId,
          'name': name,
          'joined': joined,
        };
      }));

      if (!mounted) return;
      setState(() {
        _clients = clients;
      });
    } catch (e) {
      debugPrint('Fehler beim Laden der Klienten: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _viewHistory(String clientId) async {
    // holt alle Trainingstermine und zeigt den FullScreenCalendar
    final snap = await FirebaseFirestore.instance
        .collection('training_history')
        .where('user_id', isEqualTo: clientId)
        .get();
    final dates = snap.docs
        .map((d) => (d.data()['training_date'] as Timestamp).toDate()
            .toUtc()
            .add(const Duration(hours: 1)))
        .map((dt) => DateFormat('yyyy-MM-dd').format(dt))
        .toSet()
        .toList();
    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenCalendar(trainingDates: dates),
      ),
    );
  }

  void _managePlan(String clientId) {
    Navigator.pushNamed(
      context,
      '/trainingsplan',
      arguments: {'clientId': clientId},
    );
  }

  Future<void> _showAddClientDialog() async {
    final membership = await showDialog<String>(
      context: context,
      builder: (_) => const AddClientDialog(),
    );
    if (membership != null && membership.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('coaching_requests')
            .add({
          'membership_number': membership,
          'coach_id': FirebaseAuth.instance.currentUser!.uid,
          'status': 'pending',
          'created_at': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Coaching‑Anfrage gesendet')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Fehler: $e')));
      }
    }
  }

  void _openClientOptions(Map<String, dynamic> c) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Trainingshistorie'),
            onTap: () {
              Navigator.pop(context);
              _viewHistory(c['id']);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Trainingsplan bearbeiten'),
            onTap: () {
              Navigator.pop(context);
              _managePlan(c['id']);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title:
            Text('Coach Dashboard', style: theme.appBarTheme.titleTextStyle),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _clients.isEmpty
              ? Center(
                  child: Text(
                    'Keine Klienten gefunden.',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _clients.length,
                  itemBuilder: (_, i) {
                    final c = _clients[i];
                    return InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _openClientOptions(c),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Stack(
                          children: [
                            // Icon + Name
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person,
                                      size: 48, color: Colors.white70),
                                  const SizedBox(height: 8),
                                  Text(
                                    c['name'],
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            // ID in der Ecke
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.black45,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${c['id']}',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(color: Colors.white70),
                                ),
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
        icon: const Icon(Icons.person_add),
        label: const Text('Klient hinzufügen'),
      ),
    );
  }
}
