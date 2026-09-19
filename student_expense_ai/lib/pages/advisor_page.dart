import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../services/ai_service.dart';
import 'package:showcaseview/showcaseview.dart';

class AdvisorPage extends StatefulWidget {
  final GlobalKey advisorKey;

  const AdvisorPage({super.key, required this.advisorKey});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  String advice =
      "Generate AI advice to receive personalized recommendations "
      "based on your spending habits.";

  bool hasInternet = false;
  bool isGenerating = false;

  List<Map<String, dynamic>> recommendations = [];

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

      // testAdvisorData();
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

  Future<void> testAdvisorData() async {
    final data = await DatabaseHelper.instance.getAdvisorData();

    // print(data);
    debugPrint(data.toString());
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

  Future<void> refresh() async {
    await checkInternet();
    await testAdvisorData();
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
            "Your expense, budget, spending pattern, and profile information "
            "will be analyzed to create personalized financial recommendations.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await generateAIAdvice();
              },
              child: const Text("Generate"),
            ),
          ],
        );
      },
    );
  }

  Future<void> generateAIAdvice() async {
    setState(() {
      isGenerating = true;
    });

    try {
      final spendingData = await DatabaseHelper.instance.getAdvisorData();

      final result = await AIService.getRecommendation(
        spendingData: spendingData,
      );

      if (!mounted) return;

      setState(() {
        recommendations = result;
        isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to generate AI advice: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Advisor")),

      body: RefreshIndicator(
        onRefresh: refresh,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Showcase(
                key: widget.advisorKey,
                title: "AI Financial Advisor",
                description:
                    "Get personalized financial recommendations based on your recorded spending and budget information.",
                targetBorderRadius: BorderRadius.circular(12),
                overlayOpacity: 0.65,
                tooltipBackgroundColor: Colors.deepPurple,
                tooltipBorderRadius: BorderRadius.circular(16),
                tooltipPadding: const EdgeInsets.all(16),
                textColor: Colors.white,

                titleTextStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),

                descTextStyle: const TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.white,
                ),

                child: Card(
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

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
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
              ),

              const SizedBox(height: 20),

              if (isGenerating)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                ),

              if (!isGenerating && recommendations.isNotEmpty) ...[
                const Text(
                  "Your Recommendations",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 12),

                ...recommendations.asMap().entries.map((entry) {
                  final recommendation = entry.value;

                  final title = recommendation["title"] ?? "Recommendation";

                  final type = recommendation["type"] ?? "general";

                  IconData icon = Icons.lightbulb_outline;
                  Color backgroundColor = Colors.deepPurple.shade50;
                  Color iconColor = Colors.deepPurple;

                  if (type == "budget") {
                    icon = Icons.account_balance_wallet_outlined;
                    backgroundColor = Colors.deepPurple.shade50;
                    iconColor = Colors.deepPurple;
                  } else if (type == "food") {
                    icon = Icons.restaurant_outlined;
                    backgroundColor = Colors.orange.shade50;
                    iconColor = Colors.orange.shade800;
                  } else if (type == "transportation") {
                    icon = Icons.directions_bus_outlined;
                    backgroundColor = Colors.blue.shade50;
                    iconColor = Colors.blue.shade800;
                  } else if (type == "saving") {
                    icon = Icons.savings_outlined;
                    backgroundColor = Colors.green.shade50;
                    iconColor = Colors.green.shade800;
                  } else if (type == "spending") {
                    icon = Icons.trending_up;
                    backgroundColor = Colors.red.shade50;
                    iconColor = Colors.red.shade800;
                  } else if (type == "warning") {
                    icon = Icons.warning_amber_outlined;
                    backgroundColor = Colors.amber.shade50;
                    iconColor = Colors.amber.shade800;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: iconColor, size: 24),
                          ),

                          const SizedBox(width: 14),

                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: iconColor,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  recommendation["message"] ?? "",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}
