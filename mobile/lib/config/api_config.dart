import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Configurable deployed backend URL
  static String? customBackendUrl;

  static String get baseUrl {
    // 1. Check dart-define environment variable passed at build time
    const envUrl = String.fromEnvironment('BACKEND_URL');
    if (envUrl.isNotEmpty) {
      return envUrl;
    }

    // 2. Runtime override if set
    if (customBackendUrl != null && customBackendUrl!.isNotEmpty) {
      return customBackendUrl!;
    }

    // 3. Web check
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        return 'http://localhost:8000';
      }
      // Production Web (Vercel): Exact live Render deployed backend URL
      return 'https://ai-phishing-detector-backend.onrender.com';
    }

    try {
      if (Platform.isAndroid) {
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
