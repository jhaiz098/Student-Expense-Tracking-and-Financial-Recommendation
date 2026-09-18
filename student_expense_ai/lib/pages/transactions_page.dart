import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_expense_ai/database/database_helper.dart';
import 'package:student_expense_ai/widgets/transaction_tile.dart';
import 'package:student_expense_ai/utils/currency_helper.dart';
import 'package:student_expense_ai/pages/add_transaction_modal.dart';
import 'package:student_expense_ai/pages/transaction_details_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  List<Map<String, dynamic>> transactions = [];
  DateTime selectedMonth = DateTime.now();
  bool hasChanged = false;

  @override
  void initState() {
    super.initState();

    loadTransactions();
  }

  Future<void> selectMonthYear() async {
    int selectedYear = selectedMonth.year;
    int selectedMonthNumber = selectedMonth.month;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Select Month"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: const InputDecoration(labelText: "Year"),
                    items: List.generate(DateTime.now().year - 1999, (index) {
                      final year = DateTime.now().year - index;

                      return DropdownMenuItem(
                        value: year,
                        child: Text(year.toString()),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedYear = value;
                        });
                      }
                    },
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<int>(
                    value: selectedMonthNumber,
                    decoration: const InputDecoration(labelText: "Month"),
                    items: List.generate(12, (index) {
                      final month = index + 1;

                      return DropdownMenuItem(
                        value: month,
                        child: Text(
                          DateFormat("MMMM").format(DateTime(2000, month)),
                        ),
                      );
                    }),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedMonthNumber = value;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      DateTime(selectedYear, selectedMonthNumber),
                    );
                  },
                  child: const Text("Select"),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        selectedMonth = result;
      });
    }
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

      if (date.year != selectedMonth.year ||
          date.month != selectedMonth.month) {
        continue;
      }

      String title;

      final now = DateTime.now();

      if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day) {
        title = "Today — ${DateFormat("MMMM d, yyyy").format(date)}";
      } else if (date.year == now.year &&
          date.month == now.month &&
          date.day == now.day - 1) {
        title = "Yesterday";
      } else {
        title = DateFormat("MMMM d, yyyy").format(date);
      }

      grouped.putIfAbsent(title, () => []);
      grouped[title]!.add(transaction);
    }

    return grouped;
  }

  String getCurrentMonthTitle() {
    return DateFormat("MMMM yyyy").format(selectedMonth);
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
            GestureDetector(
              onTap: selectMonthYear,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    getCurrentMonthTitle(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 24),
                ],
              ),
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
                          "₱${(transaction["amount"] as num).toDouble().toStringAsFixed(2)}",

                      isExpense: isExpense,

                      onDelete: () async {
                        await deleteTransaction(transaction);

                        hasChanged = true;

                        refresh();
                      },

                      onEdit: () async {
                        final result = await showAddModal(
                          context,
                          transaction: transaction,
                        );

                        if (result == true) {
                          hasChanged = true;
                          refresh();
                        }
                      },

                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TransactionDetailsPage(
                              transaction: transaction,
                            ),
                          ),
                        );

                        refresh();
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
