import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl =
      'https://student-expense-ai-backend.onrender.com';

  static Future<List<Map<String, dynamic>>> getRecommendation({
    required Map<String, dynamic> spendingData,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/recommendation'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'spendingData': spendingData}),
          )
          .timeout(const Duration(seconds: 90));

      debugPrint('AI backend status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response from AI server.');
      }

      if (response.statusCode != 200 || data['success'] != true) {
        throw Exception(
          data['message']?.toString() ??
              'The AI server failed to generate recommendations.',
        );
      }

      final recommendations = data['recommendations'];

      if (recommendations is! List ||
          recommendations.length < 3 ||
          recommendations.length > 5) {
        throw Exception(
          'The AI server returned an invalid recommendations list.',
        );
      }

      final result = <Map<String, dynamic>>[];

      for (final item in recommendations) {
        if (item is! Map) {
          throw Exception('Invalid recommendation format.');
        }

        final recommendation = Map<String, dynamic>.from(item);

        if (recommendation['type'] is! String ||
            recommendation['title'] is! String ||
            recommendation['message'] is! String) {
          throw Exception('A recommendation is missing required information.');
        }

        result.add(recommendation);
      }

      return result;
    } on TimeoutException {
      throw Exception(
        'The AI server took too long to respond. Please try again.',
      );
    } on http.ClientException catch (e) {
      debugPrint('AI network error: $e');
      throw Exception(
        'Cannot connect to the AI server. Check your internet connection.',
      );
    } on FormatException catch (e) {
      debugPrint('AI response parsing error: $e');
      throw Exception('The AI server returned an invalid response.');
    }
  }

  static Future<String> testConnection() async {
    try {
      final response = await http
          .get(Uri.parse(baseUrl))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        return response.body;
      }

      throw Exception('Backend connection failed: ${response.statusCode}');
    } on TimeoutException {
      throw Exception('The backend took too long to respond.');
    } on http.ClientException {
      throw Exception(
        'Cannot reach the backend. Check your internet connection.',
      );
    }
  }
}
