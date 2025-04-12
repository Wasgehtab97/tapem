import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_services.dart';
import '../widgets/registration_form.dart';
import '../widgets/login_form.dart';
import '../widgets/streak_badge.dart';
import '../widgets/exp_badge.dart';
import '../widgets/calendar.dart'; // Altes Kalender-Widget
import '../widgets/full_screen_calendar.dart'; // Vollbildkalender-Popup
import 'gym.dart';
import 'rank.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  String storedUsername = "BeispielNutzer";
  String? token;
  int? userId;
  int expProgress = 0;
  int divisionIndex = 0;
  List<String> trainingDates = [];
  bool loadingDates = true;
  int streak = 0;
  bool loadingCoachingRequest = true;
  Map<String, dynamic>? coachingRequest;

  final ApiService apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  /// Konvertiert ein Datum in die deutsche Zeitzone (GMT+1) und formatiert als "YYYY-MM-DD".
  String getGermanDateString(DateTime date) {
    final germanDate = date.toUtc().add(const Duration(hours: 1));
    final year = germanDate.year.toString();
    final month = germanDate.month.toString().padLeft(2, '0');
    final day = germanDate.day.toString().padLeft(2, '0');
    return "$year-$month-$day";
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      storedUsername = prefs.getString('username') ?? "BeispielNutzer";
      token = prefs.getString('token');
      userId = prefs.getInt('userId');
      expProgress = prefs.getInt('exp_progress') ?? 0;
      divisionIndex = prefs.getInt('division_index') ?? 0;
    });
    if (userId != null) {
      await Future.wait([
        _fetchStreak(),
        _fetchTrainingDates(),
        _fetchCoachingRequest(),
      ]);
      try {
        final userData = await apiService.getUserData(userId!);
        setState(() {
          expProgress = userData['data']['exp_progress'] ?? 0;
          divisionIndex = userData['data']['division_index'] ?? 0;
          storedUsername = userData['data']['name'] ?? storedUsername;
        });
        await prefs.setInt('exp_progress', expProgress);
        await prefs.setInt('division_index', divisionIndex);
        await prefs.setString('username', storedUsername);
      } catch (e) {
        debugPrint("Fehler beim Abrufen der Benutzerdaten: $e");
      }
    }
  }

  Future<void> _fetchStreak() async {
    try {
      final response = await apiService.getDataFromUrl('/api/streak/${userId!}');
      setState(() {
        streak = response['data']['current_streak'] ?? 0;
      });
    } catch (error) {
      debugPrint("Fehler beim Abrufen des Streaks: $error");
    }
  }

  Future<void> _fetchTrainingDates() async {
    try {
      final response = await apiService.getDataFromUrl('/api/history/${userId!}');
      if (response['data'] != null) {
        final dates = (response['data'] as List)
            .map<String>((entry) {
              DateTime d = DateTime.parse(entry['training_date']);
              return getGermanDateString(d);
            })
            .toSet()
            .toList();
        setState(() {
          trainingDates = dates;
        });
      }
    } catch (error) {
      debugPrint("Fehler beim Abrufen der Trainingsdaten: $error");
    } finally {
      setState(() {
        loadingDates = false;
      });
    }
  }

  Future<void> _fetchCoachingRequest() async {
    try {
      final response = await apiService.getDataFromUrl('/api/coaching/request?clientId=$userId');
      if (response['data'] != null && (response['data'] as List).isNotEmpty) {
        setState(() {
          coachingRequest = (response['data'] as List)[0];
        });
      }
    } catch (error) {
      debugPrint("Fehler beim Abrufen der Coaching-Anfrage: $error");
    } finally {
      setState(() {
        loadingCoachingRequest = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  Future<void> _acceptCoachingRequest() async {
    if (coachingRequest == null) return;
    try {
      await apiService.respondCoachingRequest(coachingRequest!['id'], true);
      setState(() {
        coachingRequest = null;
      });
    } catch (error) {
      debugPrint("Fehler beim Annehmen der Coaching-Anfrage: $error");
    }
  }

  Future<void> _declineCoachingRequest() async {
    if (coachingRequest == null) return;
    try {
      await apiService.respondCoachingRequest(coachingRequest!['id'], false);
      setState(() {
        coachingRequest = null;
      });
    } catch (error) {
      debugPrint("Fehler beim Ablehnen der Coaching-Anfrage: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (token == null || token!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            "Anmeldung / Registrierung",
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
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
        title: Text(
          "Profil",
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Theme.of(context).iconTheme.color),
            onSelected: (value) {
              if (value == 'logout') {
                _handleLogout();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'logout',
                child: Text(
                  'Abmelden',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
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
                    if (coachingRequest != null)
                      Card(
                        color: Colors.blueGrey.shade800,
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
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
                                    onPressed: _acceptCoachingRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                    ),
                                    child: Text(
                                      "Annehmen",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _declineCoachingRequest,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).primaryColor,
                                    ),
                                    child: Text(
                                      "Ablehnen",
                                      style: Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Kalender-Widget (klein) – beim Tippen öffnet sich ein Popup mit FullScreenCalendar
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return Dialog(
                              insetPadding: const EdgeInsets.all(16),
                              child: FullScreenCalendar(trainingDates: trainingDates),
                            );
                          },
                        );
                      },
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
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GymScreen()),
                        );
                      },
                      child: Center(
                        child: Text(
                          "Gym",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(context, '/trainingsplan');
                      },
                      child: Center(
                        child: Text(
                          "Plans",
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreakBadge(streak: streak, size: 60),
                  const SizedBox(width: 8),
                  ExpBadge(
                    expProgress: expProgress,
                    divisionIndex: divisionIndex,
                    size: 60,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RankScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Text(
                storedUsername,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        height: 50,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
