import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


class TrainingsplanScreen extends StatefulWidget {
  const TrainingsplanScreen({Key? key}) : super(key: key);

  @override
  _TrainingsplanScreenState createState() => _TrainingsplanScreenState();
}

class _TrainingsplanScreenState extends State<TrainingsplanScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> trainingPlans = [];
  int? userId;

  @override
  void initState() {
    super.initState();
    _checkLoginAndLoadPlans();
  }

  Future<void> _checkLoginAndLoadPlans() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
    if (userId == null) {
      Navigator.pushReplacementNamed(context, '/auth');
    } else {
      await _loadTrainingPlans();
      setState(() {
        isLoading = false;
      });
    }
  }

  /// Lädt alle Trainingspläne des aktuell eingeloggten Nutzers aus Firestore
  Future<void> _loadTrainingPlans() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('training_plans')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();
      List<Map<String, dynamic>> plans = snapshot.docs.map((doc) {
        // Füge die Dokument-ID als "id" hinzu.
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
      setState(() {
        trainingPlans = plans;
      });
    } catch (e) {
      debugPrint('Error loading training plans: $e');
    }
  }

  /// Erstellt einen neuen Trainingsplan in Firestore.
  Future<void> _createNewPlan(String name) async {
    try {
      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('training_plans')
          .add({
        'userId': userId,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'exercises': [],
      });
      DocumentSnapshot newDoc = await docRef.get();
      Map<String, dynamic> newPlan = newDoc.data() as Map<String, dynamic>;
      newPlan['id'] = newDoc.id;
      setState(() {
        trainingPlans.add(newPlan);
      });
    } catch (e) {
      debugPrint('Error creating training plan: $e');
    }
  }

  /// Löscht einen Trainingsplan in Firestore.
  Future<void> _deletePlan(String planId) async {
    try {
      await FirebaseFirestore.instance
          .collection('training_plans')
          .doc(planId)
          .delete();
      setState(() {
        trainingPlans.removeWhere((plan) => plan['id'] == planId);
      });
    } catch (e) {
      debugPrint('Error deleting training plan: $e');
    }
  }

  /// Startet den Trainingsplan, indem er den Status aktualisiert und den Nutzer zum Dashboard navigiert.
  Future<void> _startPlan(String planId) async {
    try {
      await FirebaseFirestore.instance
          .collection('training_plans')
          .doc(planId)
          .update({'status': 'active'});
      // Angenommen, dass im Trainingsplan ein Feld "exerciseOrder" enthalten ist
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('training_plans')
          .doc(planId)
          .get();
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> exerciseOrder = data['exerciseOrder'] ?? [];
      if (exerciseOrder.isNotEmpty) {
        Navigator.pushNamed(context, '/dashboard', arguments: {
          'activeTrainingPlan': exerciseOrder,
          'currentIndex': 0,
        });
      } else {
        debugPrint("exerciseOrder is empty!");
      }
    } catch (e) {
      debugPrint('Error starting training plan: $e');
    }
  }

  Future<void> _showCreatePlanDialog() async {
    String planName = "";
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(
            "Neuen Trainingsplan erstellen",
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: TextField(
            style: Theme.of(context).textTheme.bodyMedium,
            decoration: InputDecoration(
              labelText: "Name des Plans",
              labelStyle: Theme.of(context).inputDecorationTheme.labelStyle,
              enabledBorder: Theme.of(context).inputDecorationTheme.enabledBorder,
            ),
            onChanged: (value) {
              planName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "Abbrechen",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              onPressed: () {
                if (planName.trim().isNotEmpty) {
                  _createNewPlan(planName.trim());
                  Navigator.of(context).pop();
                }
              },
              child: Text(
                "Erstellen",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        );
      },
    );
  }

  void _editPlan(Map<String, dynamic> plan) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTrainingPlanScreen(
          plan: plan,
          onPlanUpdated: (updatedPlan) {
            setState(() {
              int index =
                  trainingPlans.indexWhere((p) => p['id'] == updatedPlan['id']);
              if (index != -1) {
                trainingPlans[index] = updatedPlan;
              }
            });
          },
        ),
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final String planId = plan['id'];
    return Card(
      color: Theme.of(context).cardColor,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        title: Text(
          plan['name'] ?? "Unbenannter Plan",
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "Übungen: " +
              ((plan['exercises'] != null && (plan['exercises'] as List).isNotEmpty)
                  ? (plan['exercises'] as List)
                      .map((e) => e['device_name'])
                      .join(", ")
                  : "Keine Übungen"),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        trailing: PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
          onSelected: (value) {
            if (value == 'edit') {
              _editPlan(plan);
            } else if (value == 'delete') {
              _deletePlan(planId);
            } else if (value == 'start') {
              _startPlan(planId);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Text("Bearbeiten", style: Theme.of(context).textTheme.bodyMedium),
            ),
            PopupMenuItem(
              value: 'start',
              child: Text("Plan starten", style: Theme.of(context).textTheme.bodyMedium),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Text("Löschen", style: Theme.of(context).textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanList() {
    if (trainingPlans.isEmpty) {
      return Center(
        child: Text(
          "Keine Trainingspläne vorhanden.",
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return ListView.builder(
      itemCount: trainingPlans.length,
      itemBuilder: (context, index) {
        final plan = trainingPlans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trainingsplan', style: Theme.of(context).appBarTheme.titleTextStyle),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildPlanList(),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: _showCreatePlanDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class EditTrainingPlanScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Function(Map<String, dynamic>)? onPlanUpdated;

  const EditTrainingPlanScreen({Key? key, required this.plan, this.onPlanUpdated}) : super(key: key);

  @override
  _EditTrainingPlanScreenState createState() => _EditTrainingPlanScreenState();
}

class _EditTrainingPlanScreenState extends State<EditTrainingPlanScreen> {
  List<Map<String, dynamic>> exercises = [];
  List<dynamic> availableDevices = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.plan['exercises'] != null) {
      exercises = List<Map<String, dynamic>>.from(widget.plan['exercises']);
    }
    _loadDevices();
  }

  /// Lädt alle verfügbaren Geräte aus der Firestore-Collection 'devices'
  Future<void> _loadDevices() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('devices').get();
      availableDevices = snapshot.docs
          .map((doc) {
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return data;
          })
          .toList();
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading devices: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _addExercise(dynamic device) {
    setState(() {
      exercises.add({
        'device_id': device['id'],
        'device_name': device['name'],
        'exercise_order': exercises.length + 1,
      });
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, item);
      for (int i = 0; i < exercises.length; i++) {
        exercises[i]['exercise_order'] = i + 1;
      }
    });
  }

  Future<void> _savePlanChanges() async {
    try {
      await FirebaseFirestore.instance.collection('training_plans')
          .doc(widget.plan['id'])
          .update({'exercises': exercises});
      DocumentSnapshot updatedDoc = await FirebaseFirestore.instance
          .collection('training_plans')
          .doc(widget.plan['id'])
          .get();
      if (widget.onPlanUpdated != null) {
        widget.onPlanUpdated!(updatedDoc.data() as Map<String, dynamic>);
      }
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error updating training plan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Trainingsplan bearbeiten",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D0D0D), Color(0xFF1A1A1A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          "Übung hinzufügen: ",
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButton<dynamic>(
                            isExpanded: true,
                            hint: Text(
                              "Wähle ein Gerät",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            items: availableDevices.map((device) {
                              return DropdownMenuItem<dynamic>(
                                value: device,
                                child: Text(
                                  device['name'],
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              );
                            }).toList(),
                            onChanged: (device) {
                              if (device != null) _addExercise(device);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ReorderableListView(
                      onReorder: _onReorder,
                      children: exercises.asMap().entries.map((entry) {
                        final index = entry.key;
                        final exercise = entry.value;
                        return ListTile(
                          key: ValueKey('${exercise['device_id']}_$index'),
                          title: Text(
                            exercise['device_name'],
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          trailing: Icon(Icons.drag_handle, color: Theme.of(context).iconTheme.color),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ElevatedButton(
                      onPressed: _savePlanChanges,
                      style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
                      child: Text("Änderungen speichern", style: Theme.of(context).textTheme.bodyMedium),
                    ),
                  )
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close, color: Colors.white),
      ),
    );
  }
}
