import 'package:flutter/material.dart';
import '../widgets/bottom_nav.dart';
import '../database/database_helper.dart';
import 'add_transaction_modal.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  List<Map<String, dynamic>> recentTransactions = [];
  double monthlyBudget = 0;

  @override
  void initState() {
    super.initState();
    loadBudget();
    loadTransactions();
  }

  Future<void> refresh() async {
    // await loadExpenses();
    await loadBudget();
    await loadTransactions();
  }

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getRecentTransactions();

    setState(() {
      recentTransactions = data;
    });
  }

  Future<void> loadBudget() async {
    final budget = await DatabaseHelper.instance.getCurrentMonthBudget();

    setState(() {
      monthlyBudget = budget;
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text("Home")),
      body: SingleChildScrollView(
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
                  Text(
                    "Monthly Budget",
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),

                  SizedBox(height: 10),

                  Text(
                    "₱${monthlyBudget.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    "Remaining: ₱2,800",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Summary cards
            Row(
              children: [
                Expanded(
                  child: _summaryCard("Spent", "₱2,200", Icons.money_off),
                ),

                const SizedBox(width: 15),

                Expanded(child: _summaryCard("Savings", "₱600", Icons.savings)),
              ],
            ),

            const SizedBox(height: 30),

            const Text(
              "Recent Transactions",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            ...recentTransactions.map((transaction) {
              bool isExpense = transaction["type"] == "Expense";

              return _transactionTile(
                transaction,
                isExpense ? Icons.receipt_long : Icons.account_balance_wallet,
                transaction["category"] ?? "Unknown",
                transaction["note"] ?? "No description",
                "₱${transaction["amount"].toStringAsFixed(2)}",
                isExpense,
              );
            }).toList(),
          ],
        ),
      ),

      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        onTransactionAdded: refresh,
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

  Widget _transactionTile(
    Map<String, dynamic> transaction,
    IconData icon,
    String category,
    String subtitle,
    String amount,
    bool isExpense,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),

        leading: CircleAvatar(child: Icon(icon)),

        title: Text(category),

        subtitle: Text(subtitle),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "${isExpense ? '-' : '+'} $amount",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),

            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Delete Transaction?"),
                      content: const Text(
                        "Are you sure you want to delete this transaction?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: const Text("Cancel"),
                        ),

                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          child: const Text(
                            "Delete",
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    );
                  },
                );

                if (confirm == true) {
                  await _deleteTransaction(transaction);
                  refresh();
                }
              },
            ),
          ],
        ),

        onTap: () async {
          final result = await showAddModal(context, transaction: transaction);

          if (result == true) {
            refresh();
          }
        },
      ),
    );
  }
}
