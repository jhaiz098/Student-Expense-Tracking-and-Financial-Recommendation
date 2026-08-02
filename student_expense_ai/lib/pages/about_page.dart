import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("About")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Center(
              child: Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.deepPurple,
              ),
            ),

            const SizedBox(height: 20),

            const Center(
              child: Text(
                "Student Expense AI",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Colors.grey),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "About the App",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "Student Expense AI is a personal finance "
              "application designed to help students "
              "track expenses, manage budgets, and "
              "understand their spending habits.",

              style: TextStyle(fontSize: 15),
            ),

            const SizedBox(height: 25),

            const Text(
              "Features",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            const Text(
              "✓ Expense Tracking\n"
              "✓ Budget Monitoring\n"
              "✓ Spending Analytics\n"
              "✓ AI Recommendations (Coming Soon)",

              style: TextStyle(fontSize: 15),
            ),

            const Spacer(),

            const Center(
              child: Text(
                "© 2026 Student Expense AI",
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
