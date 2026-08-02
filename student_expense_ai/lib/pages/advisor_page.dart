import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';

class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  String advice =
      "Generate AI advice to receive personalized recommendations "
      "based on your spending habits.";

  bool hasInternet = false;

  StreamSubscription? connectivitySubscription;

  @override
  void initState() {
    super.initState();

    checkInternet();

    connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      //TESTTTT OUTPUT
      // testRemainingBudget();
      // testRemainingDays();
      // testPreviousMonthExpense();
      // testTransactionCount();
      // testCategorySpending();
      // testPatterns();
      // test();

      testAdvisorData();
      //TESTT OUTPUT

      checkInternet();
    });
  }

  //TESTTTTT FUNCTIONS
  void test() async {
    final previousBudget = await DatabaseHelper.instance
        .getPreviousMonthBudgetAmount();

    print("Previous Budget: $previousBudget");
  }

  void testAdvisorData() async {
    final data = await DatabaseHelper.instance.getAdvisorData();

    print(data);
  }

  void testPatterns() async {
    final patterns = await DatabaseHelper.instance.getSpendingPatterns();

    print(patterns);
  }

  void testCategorySpending() async {
    final current = await DatabaseHelper.instance.getCategorySpending();

    final previous = await DatabaseHelper.instance.getCategorySpending(
      previousMonth: true,
    );

    print("CURRENT CATEGORY:");
    print(current);

    print("PREVIOUS CATEGORY:");
    print(previous);
  }

  void testTransactionCount() async {
    final current = await DatabaseHelper.instance.getExpenseTransactionCount();

    final previous = await DatabaseHelper.instance.getExpenseTransactionCount(
      previousMonth: true,
    );

    print("CURRENT MONTH EXPENSE TRANSACTIONS COUNT: $current");
    print("PREVIOUS MONTH EXPENSE TRANSACTIONS COUNT: $previous");
  }

  void testPreviousMonthExpense() async {
    final previousExpense = await DatabaseHelper.instance
        .getPreviousMonthExpenseAmount();

    print("PREVIOUS MONTH EXPENSE: $previousExpense");
  }

  void testRemainingDays() {
    final days = getRemainingDays();

    print("REMAINING DAYS: $days");
  }

  int getRemainingDays() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return lastDayOfMonth.difference(today).inDays;
  }

  void testRemainingBudget() async {
    final budget = await DatabaseHelper.instance.getCurrentBudgetAmount();

    final expenses = await DatabaseHelper.instance.getCurrentExpenseAmount();

    final remaining = budget - expenses;

    print("CURRENT BUDGET: $budget");
    print("CURRENT EXPENSE: $expenses");
    print("REMAINING BUDGET: $remaining");
  }
  //TESTTTT FUNCTIONS

  Future<void> checkInternet() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity.contains(ConnectivityResult.none)) {
        setState(() {
          hasInternet = false;
        });

        return;
      }

      final response = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          hasInternet = true;
        });
      } else {
        setState(() {
          hasInternet = false;
        });
      }
    } catch (e) {
      print("Internet check failed: $e");

      setState(() {
        hasInternet = false;
      });
    }
  }

  @override
  void dispose() {
    connectivitySubscription?.cancel();

    super.dispose();
  }

  void showAIConfirmation() {
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Internet connection is required for AI advice."),
        ),
      );

      return;
    }

    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text("Generate AI Advice?"),

          content: const Text(
            "AI advice can only be generated once every 7 days.\n\n"
            "Your expense data will be analyzed to create "
            "personalized financial recommendations.",
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("AI Advisor is not available yet."),
                  ),
                );
              },

              child: const Text("Generate"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Advisor")),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.deepPurple,

                borderRadius: BorderRadius.circular(20),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.white),

                      SizedBox(width: 8),

                      Text(
                        "AI Financial Advisor",

                        style: TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),

                  const SizedBox(height: 15),

                  Text(
                    advice,

                    style: const TextStyle(
                      color: Colors.white,

                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "AI Recommendation",

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Icon(
                          hasInternet ? Icons.cloud_done : Icons.cloud_off,

                          color: hasInternet ? Colors.green : Colors.red,
                        ),

                        const SizedBox(width: 8),

                        Text(
                          hasInternet
                              ? "Internet Connected"
                              : "No Internet Connection",

                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      hasInternet
                          ? "AI advice can be generated once every 7 days."
                          : "Connect to the internet to use AI Advisor.",
                    ),

                    const SizedBox(height: 15),

                    SizedBox(
                      width: double.infinity,

                      child: ElevatedButton.icon(
                        onPressed: hasInternet ? showAIConfirmation : null,

                        icon: const Icon(Icons.psychology),

                        label: const Text("Generate AI Advice"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
