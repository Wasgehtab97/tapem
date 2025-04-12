import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class ApiService {
  final String baseUrl = API_URL;

  /// Hilfsmethode, die einen Request ausführt und bei einem 401-Error automatisch versucht,
  /// den Token über [refreshToken] zu erneuern und den Request zu wiederholen.
  Future<http.Response> _withTokenRefresh(
      Future<http.Response> Function() requestFunction) async {
    http.Response response = await requestFunction();
    if (response.statusCode == 401) {
      // Versuche, den Token zu erneuern
      try {
        await refreshToken();
        response = await requestFunction();
      } catch (e) {
        throw Exception('Token refresh failed: $e');
      }
    }
    return response;
  }

  /// Führt den Refresh-Token-Request aus und speichert den neuen Access-Token.
  Future<void> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final storedRefreshToken = prefs.getString('refreshToken') ?? '';
    final response = await http.post(
      Uri.parse('$baseUrl/api/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': storedRefreshToken}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final newToken = data['token'];
      await prefs.setString('token', newToken);
    } else {
      throw Exception('Failed to refresh token: ${response.statusCode}');
    }
  }

  // Öffentliche Methoden

  // Geräte abrufen
  Future<List<dynamic>> getDevices() async {
    final response = await http.get(Uri.parse('$baseUrl/api/devices'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to load devices: ${response.statusCode}');
    }
  }

  // Neues Gerät anlegen (secret_code wird im Backend automatisch generiert)
  Future<Map<String, dynamic>> createDevice(String name, String exerciseMode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.post(
          Uri.parse('$baseUrl/api/devices'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'exercise_mode': exerciseMode,
          }),
        ));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create device: ${response.statusCode}');
    }
  }

  // Gerät anhand von device_id und secret_code abrufen
  Future<Map<String, dynamic>> getDeviceBySecret(int deviceId, String secretCode) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/api/device_by_secret?device_id=$deviceId&secret_code=$secretCode'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get device by secret code: ${response.statusCode}');
    }
  }

  // Trainingshistorie für einen Nutzer abrufen
  Future<List<dynamic>> getHistory(int userId, {int? deviceId, String? exercise}) async {
    String url = '$baseUrl/api/history/$userId';
    List<String> queryParams = [];
    if (exercise != null && exercise.isNotEmpty) {
      queryParams.add("exercise=${Uri.encodeComponent(exercise)}");
    } else if (deviceId != null) {
      queryParams.add("deviceId=$deviceId");
    }
    if (queryParams.isNotEmpty) {
      url += '?' + queryParams.join('&');
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to load history: ${response.statusCode}');
    }
  }

  // Gerätedaten aktualisieren (Name, exercise_mode und secret_code)
  Future<Map<String, dynamic>> updateDevice(
      int deviceId, String name, String exerciseMode, String secretCode) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.put(
          Uri.parse('$baseUrl/api/devices/$deviceId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'name': name,
            'exercise_mode': exerciseMode,
            'secret_code': secretCode,
          }),
        ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to update device: ${response.statusCode}');
    }
  }

  // Benutzerregistrierung
  Future<Map<String, dynamic>> registerUser(
      String name, String email, String password, String membershipNumber) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'membershipNumber': membershipNumber
      }),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Registration failed: ${response.statusCode}');
    }
  }

  // Benutzer-Login inkl. EXP-Daten und Refresh-Token
  Future<Map<String, dynamic>> loginUser(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    if (response.statusCode == 200) {
      final result = jsonDecode(response.body) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();
      if (result.containsKey('exp_progress')) {
        await prefs.setInt('exp_progress', result['exp_progress']);
      }
      if (result.containsKey('division_index')) {
        await prefs.setInt('division_index', result['division_index']);
      }
      // Speichere sowohl den Access-Token als auch den Refresh-Token
      if (result.containsKey('token')) {
        await prefs.setString('token', result['token']);
      }
      if (result.containsKey('refreshToken')) {
        await prefs.setString('refreshToken', result['refreshToken']);
      }
      return result;
    } else {
      throw Exception('Login failed: ${response.statusCode}');
    }
  }

  // Trainingsdaten posten
  Future<void> postTrainingData(Map<String, dynamic> trainingData) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.post(
          Uri.parse('$baseUrl/api/training'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(trainingData),
        ));
    if (response.statusCode != 200) {
      throw Exception(response.body);
    }
  }

  // Reporting-Daten abrufen
  Future<List<dynamic>> getReportingData(
      {String? startDate, String? endDate, String? deviceId}) async {
    List<String> queryParams = [];
    if (startDate != null && endDate != null) {
      queryParams.add("startDate=${Uri.encodeComponent(startDate)}");
      queryParams.add("endDate=${Uri.encodeComponent(endDate)}");
    }
    if (deviceId != null && deviceId.isNotEmpty) {
      queryParams.add("deviceId=${Uri.encodeComponent(deviceId)}");
    }
    String queryString = queryParams.isNotEmpty ? "?${queryParams.join("&")}" : "";
    final response = await http.get(Uri.parse('$baseUrl/api/reporting/usage$queryString'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to load reporting data: ${response.statusCode}');
    }
  }

  // Allgemeine Daten abrufen (z.B. Streak)
  Future<Map<String, dynamic>> getDataFromUrl(String endpoint) async {
    final response = await http.get(Uri.parse('$baseUrl$endpoint'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get data from $endpoint: ${response.statusCode}');
    }
  }

  // User-Daten abrufen
  Future<Map<String, dynamic>> getUserData(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/user/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to get user data: ${response.statusCode}');
    }
  }

  // Trainingspläne erstellen
  Future<Map<String, dynamic>> createTrainingPlan(int userId, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/training-plans'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'name': name}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create training plan: ${response.statusCode}');
    }
  }

  // Trainingspläne abrufen
  Future<List<dynamic>> getTrainingPlans(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/training-plans/$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to get training plans: ${response.statusCode}');
    }
  }

  // Trainingsplan aktualisieren
  Future<Map<String, dynamic>> updateTrainingPlan(int planId, List<Map<String, dynamic>> exercises) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/training-plans/$planId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'exercises': exercises}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update training plan: ${response.statusCode}');
    }
  }

  // Trainingsplan löschen
  Future<void> deleteTrainingPlan(int planId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/training-plans/$planId'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete training plan: ${response.statusCode}');
    }
  }

  // Trainingsplan starten
  Future<Map<String, dynamic>> startTrainingPlan(int planId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/training-plans/$planId/start'),
      headers: {'Content-Type': 'application/json'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to start training plan: ${response.statusCode}');
    }
  }

  // ---------------------------
  // Neue Methoden für das Coach-Feature
  // ---------------------------

  Future<List<dynamic>> getClientsForCoach() async {
    final prefs = await SharedPreferences.getInstance();
    final coachId = prefs.getInt('userId');
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.get(
          Uri.parse('$baseUrl/api/coach/clients?coachId=$coachId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to load clients: ${response.statusCode}');
    }
  }

  Future<void> sendCoachingRequest(int clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final coachId = prefs.getInt('userId');
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.post(
          Uri.parse('$baseUrl/api/coaching/request'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'coachId': coachId,
            'clientId': clientId,
          }),
        ));
    if (response.statusCode != 200) {
      throw Exception('Coaching request failed: ${response.statusCode}');
    }
  }

  Future<void> sendCoachingRequestByMembership(String membershipNumber) async {
    final prefs = await SharedPreferences.getInstance();
    final coachId = prefs.getInt('userId');
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.post(
          Uri.parse('$baseUrl/api/coaching/request/by-membership'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'coachId': coachId,
            'membershipNumber': membershipNumber,
          }),
        ));
    if (response.statusCode != 200) {
      throw Exception('Coaching request failed: ${response.statusCode}');
    }
  }

  Future<void> respondCoachingRequest(int requestId, bool accept) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.put(
          Uri.parse('$baseUrl/api/coaching/request/$requestId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'status': accept ? 'accepted' : 'rejected',
          }),
        ));
    if (response.statusCode != 200) {
      throw Exception('Responding to coaching request failed: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> fetchClientHistory(int clientId, {int? deviceId, String? exercise}) async {
    String url = '$baseUrl/api/history/$clientId';
    List<String> queryParams = [];
    if (exercise != null && exercise.isNotEmpty) {
      queryParams.add("exercise=${Uri.encodeComponent(exercise)}");
    } else if (deviceId != null) {
      queryParams.add("deviceId=$deviceId");
    }
    if (queryParams.isNotEmpty) {
      url += '?' + queryParams.join('&');
    }
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to load client history: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> createTrainingPlanForClient(int clientId, String name) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/coach/training-plans'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'clientId': clientId, 'name': name}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create training plan for client: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> updateTrainingPlanForClient(int planId, List<Map<String, dynamic>> exercises) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/coach/training-plans/$planId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'exercises': exercises}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('Failed to update training plan for client: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(Uri.parse('$baseUrl/api/users'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to load users: ${response.statusCode}');
    }
  }

  // ---------------------------
  // Neue Methoden für Affiliate-Funktionalität
  // ---------------------------

  Future<List<dynamic>> getAffiliateOffers() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      {
        "id": 1,
        "title": "Supplements Special",
        "description": "Erhalte 20% Rabatt auf Supplements",
        "affiliate_url": "https://www.example.com/offer1",
        "image_url": "assets/images/creatine.png",
        "start_date": "2025-03-01",
        "end_date": "2025-12-31",
        "revenue_share": 50,
      },
      {
        "id": 2,
        "title": "Sportbekleidung Deal",
        "description": "Kaufe Sportbekleidung mit 15% Rabatt",
        "affiliate_url": "https://www.example.com/offer2",
        "image_url": "assets/images/clothing.png",
        "start_date": "2025-03-01",
        "end_date": "2025-12-31",
        "revenue_share": 50,
      },
    ];
  }

  Future<void> trackAffiliateClick(int offerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/affiliate_click'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'offer_id': offerId}),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to track click: ${response.statusCode}');
    }
  }

  // ---------------------------
  // Neue Methode: Eigene Übung anlegen
  // ---------------------------
  Future<Map<String, dynamic>> createCustomExercise(int userId, int deviceId, String exerciseName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.post(
          Uri.parse('$baseUrl/api/custom_exercise'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'userId': userId,
            'deviceId': deviceId,
            'name': exerciseName,
          }),
        ));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to create custom exercise: ${response.statusCode}');
    }
  }

  Future<List<dynamic>> getCustomExercises(int userId, int deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.get(
          Uri.parse('$baseUrl/api/custom_exercises?userId=$userId&deviceId=$deviceId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data['data'];
    } else {
      throw Exception('Failed to load custom exercises: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> deleteCustomExercise(int userId, int deviceId, String exerciseName) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final response = await _withTokenRefresh(() => http.delete(
          Uri.parse('$baseUrl/api/custom_exercise?userId=$userId&deviceId=$deviceId&name=${Uri.encodeComponent(exerciseName)}'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['data'] as Map<String, dynamic>;
    } else {
      throw Exception('Failed to delete custom exercise: ${response.statusCode}');
    }
  }
}
