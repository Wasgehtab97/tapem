// lib/screens/profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/registration_form.dart';
import '../widgets/login_form.dart';
import '../widgets/streak_badge.dart';
import '../widgets/exp_badge.dart';
import '../widgets/calendar.dart';
import '../widgets/full_screen_calendar.dart';
import 'gym.dart';
import 'rank.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String storedUsername = "BeispielNutzer";
  String? uid;
  int expProgress = 0;
  int divisionNumber = 0;
  int streak = 0;
  List<String> trainingDates = [];
  bool loadingDates = true;
  bool loadingCoachingRequest = true;
  Map<String, dynamic>? coachingRequest;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => uid = null);
      return;
    }
    uid = user.uid;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', uid!);

    // Profil-Daten laden
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      setState(() {
        storedUsername = data['name'] ?? storedUsername;
        expProgress = data['exp_progress'] ?? 0;
        divisionNumber = data['division_number'] ?? 0;
        streak = data['current_streak'] ?? 0;
      });
    }

    // Trainingsdaten & Coaching-Request parallel laden
    await Future.wait([
      _fetchTrainingDates(),
      _fetchCoachingRequest(),
    ]);
  }

  Future<void> _fetchTrainingDates() async {
    if (uid == null) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('training_history')
          .where('user_id', isEqualTo: uid)
          .get();
      final dates = snap.docs
          .map((d) => _formatGermanDate(d.data()['training_date']))
          .toSet()
          .toList();
      setState(() => trainingDates = dates);
    } catch (e) {
      debugPrint("Fehler beim Abrufen der Trainingsdaten: $e");
    } finally {
      setState(() => loadingDates = false);
    }
  }

  Future<void> _fetchCoachingRequest() async {
    if (uid == null) return;
    setState(() => loadingCoachingRequest = true);
    try {
      // NUR pending‑Requests abfragen
      final snap = await FirebaseFirestore.instance
          .collection('coaching_requests')
          .where('client_id', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        final doc = snap.docs.first;
        final data = doc.data()..['id'] = doc.id;
        setState(() => coachingRequest = data);
      } else {
        setState(() => coachingRequest = null);
      }
    } catch (e) {
      debugPrint("Fehler beim Abrufen der Coaching-Anfrage: $e");
      setState(() => coachingRequest = null);
    } finally {
      setState(() => loadingCoachingRequest = false);
    }
  }

  Future<void> _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
    }
  }

  Future<void> _respondToRequest(bool accept) async {
    if (coachingRequest == null) return;
    try {
      final reqId = coachingRequest!['id'] as String;
      // Status updaten
      await FirebaseFirestore.instance
          .collection('coaching_requests')
          .doc(reqId)
          .update({'status': accept ? 'accepted' : 'rejected'});

      // Wenn angenommen, füge client zur Coach‑Liste hinzu:
      if (accept) {
        final coachId = coachingRequest!['coach_id'] as String;
        final clientId = coachingRequest!['client_id'] as String;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(coachId)
            .collection('clients')
            .doc(clientId)
            .set({'joined_at': Timestamp.now()});
      }

      // Lokalen State zurücksetzen und neu laden
      setState(() => coachingRequest = null);
    } catch (e) {
      debugPrint("Fehler beim Beantworten der Anfrage: $e");
    }
  }

  String _formatGermanDate(dynamic dateInput) {
    DateTime d;
    if (dateInput is Timestamp) {
      d = dateInput.toDate();
    } else if (dateInput is String) {
      d = DateTime.parse(dateInput);
    } else if (dateInput is DateTime) {
      d = dateInput;
    } else {
      d = DateTime.now();
    }
    d = d.toUtc().add(const Duration(hours: 1));
    final y = d.year.toString();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return "$y-$m-$day";
  }

  @override
  Widget build(BuildContext context) {
    if (uid == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Anmeldung / Registrierung",
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: const [
              LoginForm(),
              SizedBox(height: 20),
              RegistrationForm(),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Profil", style: Theme.of(context).appBarTheme.titleTextStyle),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
            onSelected: (v) {
              if (v == 'logout') _handleLogout();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'logout', child: Text('Abmelden')),
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
        child: Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Coaching‑Anfrage nur anzeigen, solange status == pending
                    if (loadingCoachingRequest)
                      const CircularProgressIndicator()
                    else if (coachingRequest != null) ...[
                      Card(
                        color: Colors.blueGrey.shade800,
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              Text(
                                "Coaching-Anfrage von ${coachingRequest!['coachName'] ?? 'Coach'}",
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton(
                                    onPressed: () => _respondToRequest(true),
                                    child: const Text("Annehmen"),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _respondToRequest(false),
                                    child: const Text("Ablehnen"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    // Kalender etc...
                    GestureDetector(
                      onTap: () => showDialog(
                        context: context,
                        builder: (_) => Dialog(
                          insetPadding: const EdgeInsets.all(16),
                          child: FullScreenCalendar(trainingDates: trainingDates),
                        ),
                      ),
                      child: Calendar(
                        trainingDates: trainingDates,
                        cellSize: 12.0,
                        rows: 7,
                        cellSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const GymScreen()),
                      ),
                      child: Text("Gym",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => Navigator.pushNamed(context, '/trainingsplan'),
                      child: Text("Plans",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
                    ),
                  ],
                ),
              ),
            ),
            // Badges und Name oben
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                storedUsername,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                children: [
                  StreakBadge(streak: streak, size: 60),
                  const SizedBox(width: 8),
                  ExpBadge(
                    expProgress: expProgress,
                    divisionIndex: divisionNumber,
                    size: 60,
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RankScreen())),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(height: 50, color: Theme.of(context).primaryColor),
    );
  }
}
