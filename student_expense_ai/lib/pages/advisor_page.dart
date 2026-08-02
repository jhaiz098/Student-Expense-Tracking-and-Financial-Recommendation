import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_helper.dart';

class AdvisorPage extends StatefulWidget {
  const AdvisorPage({super.key});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  double monthlyBudget = 0;
  double monthlyExpenses = 0;

  String highestCategory = "None";
  double highestAmount = 0;

  String advice = "";

  @override
  void initState() {
    super.initState();
    loadAdvisorData();
  }

  Future<void> loadAdvisorData() async {
    final budget = await DatabaseHelper.instance.getCurrentMonthBudget();

    final expenses = await DatabaseHelper.instance.getExpensesWithCategory();

    double totalExpense = 0;

    Map<String, double> categories = {};

    DateTime now = DateTime.now();

    for (var expense in expenses) {
      DateTime date = DateTime.parse(expense["createdAt"]);

      if (date.month == now.month && date.year == now.year) {
        double amount = expense["amount"].toDouble();

        totalExpense += amount;

        String category = expense["category"] ?? "Others";

        categories[category] = (categories[category] ?? 0) + amount;
      }
    }

    String topCategory = "None";
    double topAmount = 0;

    categories.forEach((key, value) {
      if (value > topAmount) {
        topCategory = key;
        topAmount = value;
      }
    });

    double usage = budget == 0 ? 0 : totalExpense / budget;

    String generatedAdvice;

    if (budget == 0) {
      generatedAdvice =
          "Set a monthly budget first so I can help you manage your spending.";
    } else if (usage >= 1) {
      generatedAdvice =
          "You have exceeded your monthly budget. "
          "Try reducing unnecessary expenses.";
    } else if (usage >= 0.85) {
      generatedAdvice =
          "You have used most of your budget. "
          "Be careful with additional spending.";
    } else if (usage >= 0.60) {
      generatedAdvice =
          "Your spending is increasing. "
          "Monitor your expenses carefully.";
    } else {
      generatedAdvice = "Good job! Your spending is within a healthy range.";
    }

    setState(() {
      monthlyBudget = budget;

      monthlyExpenses = totalExpense;

      highestCategory = topCategory;

      highestAmount = topAmount;

      advice = generatedAdvice;
    });
  }

  @override
  Widget build(BuildContext context) {
    double usage = monthlyBudget == 0 ? 0 : monthlyExpenses / monthlyBudget;

    int percentage = (usage * 100).floor();

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
                  const Text(
                    "Financial Advice",

                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  const SizedBox(height: 10),

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

            const SizedBox(height: 25),

            const Text(
              "Budget Health",

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.account_balance_wallet),

                title: Text("$percentage% Used"),

                subtitle: Text(
                  "${CurrencyHelper.format(monthlyExpenses)} / "
                  "${CurrencyHelper.format(monthlyBudget)}",
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Spending Pattern",

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.category),

                title: Text(highestCategory),

                subtitle: Text(
                  "Highest spending category: "
                  "${CurrencyHelper.format(highestAmount)}",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
