import 'package:flutter/material.dart';
import '../services/ai_service.dart';

class BackendTestPage extends StatefulWidget {
  const BackendTestPage({super.key});

  @override
  State<BackendTestPage> createState() => _BackendTestPageState();
}

class _BackendTestPageState extends State<BackendTestPage> {
  String result = "Press the button to test the backend.";

  Future<void> testBackend() async {
    setState(() {
      result = "Connecting...";
    });

    try {
      final response = await AIService.testConnection();

      setState(() {
        result = response;
      });
    } catch (e) {
      setState(() {
        result = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Backend Test")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(result, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: testBackend,
                child: const Text("Test Backend"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
