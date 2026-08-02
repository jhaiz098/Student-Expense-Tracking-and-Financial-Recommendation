import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'add_transaction_modal.dart';
import 'package:intl/intl.dart';
import '../utils/currency_helper.dart';
import 'package:student_expense_ai/pages/transactions_page.dart';
import '../widgets/transaction_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  int budgetReminder = 80;
  List<Map<String, dynamic>> recentTransactions = [];
  double monthlyBudget = 0;
  double monthlyExpenses = 0;
  String currentMonth = DateFormat('MMMM').format(DateTime.now());
  @override
  void initState() {
    super.initState();
    loadBudget();
    loadExpenses();
    loadTransactions();
  }

  // @override
  // void didUpdateWidget(covariant HomePage oldWidget) {
  //   super.didUpdateWidget(oldWidget);
  //   refresh();
  // }

  Future<void> refresh() async {
    await loadBudget();
    await loadExpenses();
    await loadTransactions();
  }

  Future<void> loadExpenses() async {
    final expenses = await DatabaseHelper.instance.getExpenses();

    final now = DateTime.now();

    double total = 0;

    for (var expense in expenses) {
      DateTime date = DateTime.parse(expense["createdAt"]);

      if (date.month == now.month && date.year == now.year) {
        total += expense["amount"];
      }
    }

    setState(() {
      monthlyExpenses = total;
    });
  }

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getRecentTransactions();

    setState(() {
      recentTransactions = data;
    });
  }

  Future<void> loadBudget() async {
    final budget = await DatabaseHelper.instance.getCurrentMonthBudget();

    final reminder = await DatabaseHelper.instance.getBudgetReminder();

    setState(() {
      monthlyBudget = budget;
      budgetReminder = reminder;
    });
  }

  double getBudgetPercentage() {
    if (monthlyBudget == 0) return 0;

    return (monthlyExpenses / monthlyBudget) * 100;
  }

  Widget build(BuildContext context) {
    double budgetUsage = monthlyBudget == 0
        ? 0
        : monthlyExpenses / monthlyBudget;

    final int budgetPercentage = (budgetUsage * 100).floor();

    Color getBudgetColor() {
      if (budgetPercentage >= 85) {
        return Colors.red;
      } else if (budgetPercentage >= 60) {
        return Colors.orange;
      } else {
        return Colors.green;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Home"), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: refresh,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Budget Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Remaining Budget",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      CurrencyHelper.format(monthlyBudget - monthlyExpenses),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$currentMonth Budget\n${CurrencyHelper.format(monthlyBudget)}",
                          style: const TextStyle(color: Colors.white),
                        ),

                        Text(
                          "Spent\n${CurrencyHelper.format(monthlyExpenses)}",
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.pie_chart,
                          color: Colors.deepPurple,
                          size: 20,
                        ),

                        const SizedBox(width: 8),

                        const Text(
                          "Budget Usage",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "$budgetPercentage%",
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        Text(
                          "${CurrencyHelper.format(monthlyExpenses)} / ${CurrencyHelper.format(monthlyBudget)}",
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: budgetUsage.clamp(0, 1),
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        color: budgetPercentage >= budgetReminder
                            ? Colors.red
                            : budgetPercentage >= (budgetReminder - 20)
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (getBudgetPercentage() >= budgetReminder)
                      Container(
                        width: double.infinity,

                        padding: const EdgeInsets.all(12),

                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.red.shade700,
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                "Budget Warning\n"
                                "You have used ${getBudgetPercentage().toStringAsFixed(0)}% "
                                "of your monthly budget.",
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Recent Transactions",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              ...recentTransactions.map((transaction) {
                bool isExpense = transaction["type"] == "Expense";

                return TransactionTile(
                  transaction: transaction,

                  icon: isExpense
                      ? Icons.receipt_long
                      : Icons.account_balance_wallet,

                  category: transaction["category"] ?? "Unknown",

                  subtitle: transaction["note"] ?? "No description",

                  amount:
                      "${CurrencyHelper.getSymbol()}${transaction["amount"].toStringAsFixed(2)}",

                  isExpense: isExpense,

                  onDelete: () async {
                    await _deleteTransaction(transaction);
                    refresh();
                  },

                  onTap: () async {
                    final result = await showAddModal(
                      context,
                      transaction: transaction,
                    );

                    if (result == true) {
                      refresh();
                    }
                  },
                );
              }).toList(),
              TextButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TransactionsPage(),
                    ),
                  );

                  refresh();
                },

                child: const Text("See All Transactions →"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String amount, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.grey.shade200,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),

          const SizedBox(height: 10),

          Text(title),

          Text(
            amount,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final id = transaction["id"];
    final type = transaction["type"];

    if (type == "Expense") {
      await DatabaseHelper.instance.deleteExpenses(id);
    } else {
      await DatabaseHelper.instance.deleteBudget(id);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Transaction deleted")));
  }
}
