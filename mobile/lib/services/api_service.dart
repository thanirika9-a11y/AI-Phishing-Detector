import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/scan_model.dart';
import '../models/report_model.dart';
import '../models/quiz_model.dart';

class ApiService {
  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Auth: Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.loginUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Login failed';
      throw Exception(detail);
    }
  }

  // Auth: Signup
  Future<Map<String, dynamic>> signup(String username, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.signupUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final detail = jsonDecode(response.body)['detail'] ?? 'Signup failed';
      throw Exception(detail);
    }
  }

  // Scanner: Run scan (URL or Text)
  Future<ScanHistoryItem> scan({
    required String inputType,
    required String inputContent,
    int? userId,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.scanUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'input_type': inputType,
        'input_content': inputContent,
        'user_id': userId,
      }),
    );
    if (response.statusCode == 200) {
      return ScanHistoryItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Scan execution failed');
    }
  }

  // Scanner: Upload screenshot for scan
  Future<ScanHistoryItem> scanScreenshot({
    required List<int> imageBytes,
    required String fileName,
    int? userId,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(ApiConfig.screenshotScanUrl));
    
    // Add file
    final multipartFile = http.MultipartFile.fromBytes(
      'file',
      imageBytes,
      filename: fileName,
    );
    request.files.add(multipartFile);

    // Add user_id if present
    if (userId != null) {
      request.fields['user_id'] = userId.toString();
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return ScanHistoryItem.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Screenshot analysis failed');
    }
  }

  // Report: Submit new crowdsourced scam
  Future<ScamReport> submitReport({
    required String scamType,
    required String indicator,
    required String description,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.reportsUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'scam_type': scamType,
        'indicator': indicator,
        'description': description,
      }),
    );
    if (response.statusCode == 200) {
      return ScamReport.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to submit report');
    }
  }

  // Report: Fetch recent scam reports
  Future<List<ScamReport>> fetchReports() async {
    final response = await http.get(Uri.parse(ApiConfig.reportsUrl));
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => ScamReport.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch reports');
    }
  }

  // Analytics: Get telemetry dashboard data
  Future<Map<String, dynamic>> fetchAnalytics({int? userId}) async {
    final url = userId != null ? '${ApiConfig.analyticsUrl}?user_id=$userId' : ApiConfig.analyticsUrl;
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to retrieve analytics');
    }
  }

  // Quiz: Get quiz questions
  Future<List<QuizQuestion>> fetchQuizzes() async {
    final response = await http.get(Uri.parse(ApiConfig.quizzesUrl));
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => QuizQuestion.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch quizzes');
    }
  }

  // Quiz: Submit score
  Future<LeaderboardScore> submitQuizScore({
    required String username,
    required int score,
    required int total,
  }) async {
    final response = await http.post(
      Uri.parse(ApiConfig.quizSubmitUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'score': score,
        'total': total,
      }),
    );
    if (response.statusCode == 200) {
      return LeaderboardScore.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to submit score');
    }
  }

  // Quiz: Get leaderboard entries
  Future<List<LeaderboardScore>> fetchLeaderboard() async {
    final response = await http.get(Uri.parse(ApiConfig.leaderboardUrl));
    if (response.statusCode == 200) {
      final List list = jsonDecode(response.body);
      return list.map((e) => LeaderboardScore.fromJson(e)).toList();
    } else {
      throw Exception('Failed to fetch leaderboard');
    }
  }
}
