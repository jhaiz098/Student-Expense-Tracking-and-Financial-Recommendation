import 'package:flutter/material.dart';
import '../utils/currency_helper.dart';
import 'add_transaction_modal.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isExpense = transaction["type"] == "Expense";

    final String category = transaction["category"] ?? "Unknown";

    final String note =
        transaction["note"]?.toString().trim().isNotEmpty == true
        ? transaction["note"]
        : "No description";

    final double amount = (transaction["amount"] as num).toDouble();

    final DateTime date = DateTime.parse(transaction["createdAt"]);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Transaction Details"),

        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: "Edit",
            onPressed: () async {
              final result = await showAddModal(
                context,
                transaction: transaction,
              );

              if (result == true && context.mounted) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 10),

            Icon(
              isExpense ? Icons.receipt_long : Icons.account_balance_wallet,
              size: 60,
            ),

            const SizedBox(height: 15),

            Text(
              category,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              "${isExpense ? '-' : '+'}"
              "${CurrencyHelper.format(amount)}",
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: isExpense ? Colors.red : Colors.green,
              ),
            ),

            const SizedBox(height: 30),

            _detailCard(
              icon: Icons.swap_vert,
              title: "Type",
              value: transaction["type"],
            ),

            const SizedBox(height: 12),

            _detailCard(
              icon: Icons.calendar_today,
              title: "Date",
              value: "${date.day}/${date.month}/${date.year}",
            ),

            const SizedBox(height: 12),

            _detailCard(
              icon: Icons.notes,
              title: "Note / Description",
              value: note,
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(icon),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 4),

                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
