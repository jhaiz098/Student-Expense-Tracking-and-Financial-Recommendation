import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_expense_ai/database/database_helper.dart';
import 'package:student_expense_ai/widgets/transaction_tile.dart';
import 'package:student_expense_ai/utils/currency_helper.dart';
import 'package:student_expense_ai/pages/add_transaction_modal.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Map<String, dynamic>> transactions = [];

  bool hasChanged = false;

  @override
  void initState() {
    super.initState();

    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getAllTransactions();

    if (!mounted) return;

    setState(() {
      transactions = data;
    });
  }

  void refresh() {
    loadTransactions();
  }

  Future<void> deleteTransaction(Map<String, dynamic> transaction) async {
    if (transaction["type"] == "Expense") {
      await DatabaseHelper.instance.deleteExpenses(transaction["id"]);
    } else {
      await DatabaseHelper.instance.deleteBudget(transaction["id"]);
    }
  }

  Map<String, List<Map<String, dynamic>>> groupTransactionsByDate() {
    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var transaction in transactions) {
      DateTime date = DateTime.parse(transaction["createdAt"]);

      String title;

      final now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        title = "Today";
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1) {
        title = "Yesterday";
      } else {
        title = DateFormat("MMMM d, yyyy").format(date);
      }

      if (!grouped.containsKey(title)) {
        grouped[title] = [];
      }

      grouped[title]!.add(transaction);
    }

    return grouped;
  }

  String getCurrentMonthTitle() {
    return DateFormat("MMMM yyyy").format(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = groupTransactionsByDate();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transactions"),

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),

          onPressed: () {
            Navigator.pop(context, hasChanged);
          },
        ),
      ),

      body: RefreshIndicator(
        onRefresh: loadTransactions,

        child: ListView(
          padding: const EdgeInsets.all(20),

          children: [
            Text(
              getCurrentMonthTitle(),

              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            ...groupedTransactions.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  Text(
                    entry.key,

                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 10),

                  ...entry.value.map((transaction) {
                    final bool isExpense = transaction["type"] == "Expense";

                    return TransactionTile(
                      transaction: transaction,

                      icon: isExpense
                          ? Icons.receipt_long
                          : Icons.account_balance_wallet,

                      category: transaction["category"] ?? "Unknown",

                      subtitle: transaction["note"] ?? "No description",

                      amount:
                          "${CurrencyHelper.getSymbol()}${(transaction["amount"] as num).toDouble().toStringAsFixed(2)}",

                      isExpense: isExpense,

                      onDelete: () async {
                        await deleteTransaction(transaction);

                        hasChanged = true;

                        refresh();
                      },

                      onTap: () async {
                        final result = await showAddModal(
                          context,
                          transaction: transaction,
                        );

                        if (result == true) {
                          hasChanged = true;

                          refresh();
                        }
                      },
                    );
                  }).toList(),

                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
