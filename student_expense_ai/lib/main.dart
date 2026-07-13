import 'package:flutter/material.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const StudentExpenseAI());
}

class StudentExpenseAI extends StatelessWidget {
  const StudentExpenseAI({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Expense AI',
      theme: ThemeData(
        colorScheme: .fromSeed(
          seedColor: const Color.fromARGB(255, 137, 183, 58),
        ),
      ),
      home: const LoginPage(),
    );
  }
}
