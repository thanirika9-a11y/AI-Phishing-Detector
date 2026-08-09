import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    try {
      if (Platform.isAndroid) {
        // Android emulator points to 10.0.2.2 for the host machine loopback
        return 'http://10.0.2.2:8000';
      }
    } catch (_) {}
    return 'http://localhost:8000';
  }

  // API Endpoint URIs
  static String get loginUrl => '$baseUrl/api/auth/login';
  static String get signupUrl => '$baseUrl/api/auth/signup';
  static String get scanUrl => '$baseUrl/api/scan';
  static String get screenshotScanUrl => '$baseUrl/api/scan/screenshot';
  static String get reportsUrl => '$baseUrl/api/reports';
  static String get analyticsUrl => '$baseUrl/api/analytics';
  static String get quizzesUrl => '$baseUrl/api/quizzes';
  static String get quizSubmitUrl => '$baseUrl/api/quizzes/submit';
  static String get leaderboardUrl => '$baseUrl/api/quizzes/leaderboard';
}
