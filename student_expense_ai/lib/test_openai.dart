import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> testOpenAI() async {
  const apiKey = "PASTE_YOUR_API_KEY_HERE";

  final response = await http.post(
    Uri.parse("https://api.openai.com/v1/chat/completions"),

    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $apiKey",
    },

    body: jsonEncode({
      "model": "gpt-4o-mini",

      "messages": [
        {
          "role": "system",
          "content": "You are a financial advisor for students.",
        },

        {
          "role": "user",
          "content": """
A student has:

Monthly budget: PHP 10000
Monthly spending: PHP 8500
Highest category: Food
Food spending: PHP 3000

Give short financial advice.
""",
        },
      ],

      "max_tokens": 200,
    }),
  );

  print("STATUS:");
  print(response.statusCode);

  print("RESPONSE:");
  print(response.body);
}
