import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl =
      "https://student-expense-ai-backend.onrender.com";

  static Future<List<Map<String, dynamic>>> getRecommendation({
    required Map<String, dynamic> spendingData,
  }) async {
    final response = await http.post(
      Uri.parse("$baseUrl/recommendation"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"spendingData": spendingData}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final recommendations = data["recommendations"];

      if (recommendations is List) {
        return recommendations
            .map((item) => Map<String, dynamic>.from(item))
            .toList();
      }

      return [];
    }

    throw Exception("Failed to get recommendations: ${response.statusCode}");
  }

  static Future<String> testConnection() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      return response.body;
    }

    throw Exception("Backend connection failed: ${response.statusCode}");
  }
}
