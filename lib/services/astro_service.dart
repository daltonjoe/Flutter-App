// flutter_application/lib/services/astro_service.dart
//
// AKILLI URL DETEKSIYONU:
//   - Web modunda: mevcut tarayici origin'ini kullanir (localhost veya Render)
//   - Native modda: direkt Render Production URL'ini kullanir
//
// EKSTRA: CORS ve Web'de URI bazli origin tespiti

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/natal_chart_response.dart';

String? _authToken;

// ────────────────────────────────────────────────────────────────────
// AKILLI BASE URL: Hiç elle değiştirmen GEREK YOK!
// ────────────────────────────────────────────────────────────────────
String get _kBaseUrl {
  if (kIsWeb) {
    // Flutter WEB: Tarayıcının açık olduğu adresi kullan
    // (Örn: http://localhost:8000  VEYA  https://soulbound-m1td.onrender.com)
    final origin = Uri.base.origin;
    // Eğer Web Debug Proxy (flutter run -d chrome --web-port 5xxxx) kullanıyorsan
    // backend farklı portta olabilir, bu durumda sabit localhost:8000 kullan
        return 'https://soulbound-m1td.onrender.com';
  } else {
    // Native (Android / iOS / Desktop): Her zaman Render URL'i
    return 'https://soulbound-m1td.onrender.com';
  }
}

Future<String> _getToken() async {
  if (_authToken != null) return _authToken!;
  final uri = Uri.parse('$_kBaseUrl/app-token');
  final response = await http.get(uri).timeout(const Duration(seconds: 10));
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    _authToken = json['token'] as String;
    return _authToken!;
  }
  throw AstroServiceException(
    code: 'AUTH_ERROR',
    message: 'Token alınamadı (URL: $_kBaseUrl)',
    suggestion: 'URL doğru mu? Backend ayakta mı?',
  );
}

class AstroServiceException implements Exception {
  final String code;
  final String message;
  final String? suggestion;

  AstroServiceException({
    required this.code,
    required this.message,
    this.suggestion,
  });

  @override
  String toString() => '[$code] $message ${suggestion ?? ''}';
}

class AstroService {
  // ── getBaseUrl: Debug & bilgi için
  static String get baseUrl => _kBaseUrl;

  // ── generateNatalChart ──────────────────────────────────────────────
  static Future<NatalChartResponse> generateNatalChart({
    required String birthDate,
    required String birthTime,
    required String city,
    required double latitude,
    required double longitude,
    required String timezone,
    bool includeReport = false,
    String locale = 'tr',
  }) async {
    final uri = Uri.parse('$_kBaseUrl/generateNatalChart');
    final requestBody = {
      'birth_date': birthDate,
      'birth_time': birthTime,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'timezone': timezone,
      'include_report': includeReport,
      'locale': locale,
    };

    final token = await _getToken();
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));
    } on Exception catch (e) {
      throw AstroServiceException(
        code: 'NETWORK_ERROR',
        message: 'Sunucuya bağlanılamadı. (URL: $_kBaseUrl)',
        suggestion:
            'İnternet bağlantınızı ve sunucunun çalıştığını kontrol edin.',
      );
    }

    if (response.statusCode == 429) {
      throw AstroServiceException(
        code: 'RATE_LIMITED',
        message: 'Çok fazla istek gönderildi. Lütfen bekleyin.',
      );
    }
    if (response.statusCode >= 500) {
      throw AstroServiceException(
        code: 'SERVER_ERROR',
        message:
            'Sunucu hatası (${response.statusCode}). Lütfen tekrar deneyin.',
      );
    }
    if (response.statusCode >= 400) {
      throw AstroServiceException(
        code: 'CLIENT_ERROR_${response.statusCode}',
        message: 'Hatalı istek: ${utf8.decode(response.bodyBytes)}',
      );
    }

    final Map<String, dynamic> json = jsonDecode(
      utf8.decode(response.bodyBytes),
    );
    return NatalChartResponse.fromJson(json);
  }

  // ── generateAstroReport ──────────────────────────────────────────────
  static Future<String> generateAstroReport({
    required String birthDate,
    required String birthTime,
    required String city,
    required double latitude,
    required double longitude,
    required String timezone,
    String locale = 'tr',
  }) async {
    final uri = Uri.parse('$_kBaseUrl/generateAstroReport');

    final token = await _getToken();
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'birth_date': birthDate,
              'birth_time': birthTime,
              'city': city,
              'latitude': latitude,
              'longitude': longitude,
              'timezone': timezone,
              'locale': locale,
            }),
          )
          .timeout(const Duration(seconds: 120));
    } on Exception {
      throw AstroServiceException(
        code: 'NETWORK_ERROR',
        message: 'Sunucuya bağlanılamadı. (URL: $_kBaseUrl)',
      );
    }

    if (response.statusCode != 200) {
      throw AstroServiceException(
        code: 'SERVER_ERROR',
        message: 'Sunucu hatası: ${response.statusCode}',
      );
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json['status'] != 'success') {
      throw AstroServiceException(
        code: json['error_code'] ?? 'UNKNOWN',
        message: json['message'] ?? 'Bilinmeyen hata.',
      );
    }

    final report = json['ai_report'];
    if (report == null || report.toString().isEmpty) {
      throw AstroServiceException(
        code: 'EMPTY_REPORT',
        message: 'Analiz metni oluşturulamadı.',
      );
    }
    return report.toString();
  }

  // ── generateForecast ─────────────────────────────────────────────────
  static Future<Map<String, dynamic>> generateForecast({
    required String analysisType,
    required Map<String, dynamic> chartData,
    String locale = 'tr',
  }) async {
    final uri = Uri.parse('$_kBaseUrl/forecast-analysis');

    final token = await _getToken();
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'analysis_type': analysisType,
              'chart_data': chartData,
              'locale': locale,
            }),
          )
          .timeout(const Duration(seconds: 120));
    } on Exception {
      throw AstroServiceException(
        code: 'NETWORK_ERROR',
        message: 'Sunucuya bağlanılamadı. (URL: $_kBaseUrl)',
      );
    }

    if (response.statusCode != 200) {
      throw AstroServiceException(
        code: 'SERVER_ERROR',
        message: 'Sunucu hatası: ${response.statusCode}',
      );
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json['status'] != 'success') {
      throw AstroServiceException(
        code: json['error_code'] ?? 'UNKNOWN',
        message: json['message'] ?? 'Bilinmeyen hata.',
      );
    }
    return Map<String, dynamic>.from(json);
  }

  // ── generatePlanetReport ─────────────────────────────────────────────
  static Future<String> generatePlanetReport({
    required String planetName,
    required Map<String, dynamic> chartData,
    String locale = 'tr',
  }) async {
    final uri = Uri.parse('$_kBaseUrl/generatePlanetReport');

    final token = await _getToken();
    http.Response response;
    try {
      response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              'planet_name': planetName,
              'chart_data': chartData,
              'locale': locale,
            }),
          )
          .timeout(const Duration(seconds: 120));
    } on Exception {
      throw AstroServiceException(
        code: 'NETWORK_ERROR',
        message: 'Sunucuya bağlanılamadı. (URL: $_kBaseUrl)',
      );
    }

    if (response.statusCode != 200) {
      throw AstroServiceException(
        code: 'SERVER_ERROR',
        message: 'Sunucu hatası: ${response.statusCode}',
      );
    }

    final json = jsonDecode(utf8.decode(response.bodyBytes));
    if (json['status'] != 'success') {
      throw AstroServiceException(
        code: json['error_code'] ?? 'UNKNOWN',
        message: json['message'] ?? 'Bilinmeyen hata.',
      );
    }

    final report = json['report'];
    if (report == null || report.toString().isEmpty) {
      throw AstroServiceException(
        code: 'EMPTY_REPORT',
        message: 'Analiz metni oluşturulamadı.',
      );
    }
    return report.toString();
  }
}
