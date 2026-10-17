import 'package:flutter/material.dart';

const Color _aboutPurple = Color(0xFF5B45B5);
const Color _aboutBackground = Color(0xFFF7F7FB);
const Color _aboutBorder = Color(0xFFE7E4F0);
const Color _aboutText = Color(0xFF29263A);
const Color _aboutMuted = Color(0xFF6F6B82);
const Color _aboutGreen = Color(0xFF159A75);
const Color _aboutOrange = Color(0xFFE07816);
const Color _aboutBlue = Color(0xFF2374D8);

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 19,
            decoration: BoxDecoration(
              color: _aboutPurple,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Text(
            title,
            style: const TextStyle(
              color: _aboutText,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureTile({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _aboutText,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: _aboutMuted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : _aboutBackground,
      appBar: AppBar(
        title: const Text(
          "About",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : _aboutBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          // App identity
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white12 : _aboutBorder),
            ),
            child: Column(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: _aboutPurple,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _aboutPurple.withValues(alpha: 0.22),
                        blurRadius: 18,
                        offset: const Offset(0, 7),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 43,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Student Expense AI",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _aboutText,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Student Expense Recommendation System",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _aboutMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: _aboutPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "VERSION 1.0.0",
                    style: TextStyle(
                      color: _aboutPurple,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // About the app
          _sectionTitle("About the App"),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : _aboutBorder),
            ),
            child: const Text(
              "Student Expense AI is a personal finance application "
              "designed to help students track expenses, manage budgets, "
              "and understand their spending habits. It helps students "
              "make more informed decisions about how they use their money.",
              style: TextStyle(color: _aboutMuted, fontSize: 13, height: 1.65),
            ),
          ),

          const SizedBox(height: 26),

          // Features
          _sectionTitle("Key Features"),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : _aboutBorder),
            ),
            child: Column(
              children: [
                _featureTile(
                  icon: Icons.receipt_long_rounded,
                  title: "Expense Tracking",
                  description:
                      "Record and review your daily expenses in one place.",
                  color: _aboutPurple,
                ),
                _featureTile(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Budget Monitoring",
                  description:
                      "Set budgets and monitor spending against your limits.",
                  color: _aboutGreen,
                ),
                _featureTile(
                  icon: Icons.bar_chart_rounded,
                  title: "Spending Analytics",
                  description:
                      "Understand your spending patterns through summaries.",
                  color: _aboutBlue,
                ),
                _featureTile(
                  icon: Icons.psychology_rounded,
                  title: "AI Recommendations",
                  description:
                      "Get personalized suggestions based on your spending data.",
                  color: _aboutOrange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Footer
          Center(
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 3,
                  decoration: BoxDecoration(
                    color: _aboutBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Student Expense AI",
                  style: TextStyle(
                    color: _aboutText,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "© 2026 Student Expense AI",
                  style: TextStyle(color: _aboutMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
