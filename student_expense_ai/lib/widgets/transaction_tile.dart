import 'package:flutter/material.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final IconData icon;
  final String category;
  final String subtitle;
  final String amount;
  final bool isExpense;

  final Future<void> Function() onDelete;
  final Future<void> Function() onTap;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.icon,
    required this.category,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 16, right: 4),

        leading: CircleAvatar(child: Icon(icon)),

        title: Text(category),

        subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),

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
                  builder: (_) => AlertDialog(
                    title: const Text("Delete Transaction?"),
                    content: const Text(
                      "Are you sure you want to delete this transaction?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          "Delete",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  await onDelete();
                }
              },
            ),
          ],
        ),

        onTap: () async {
          await onTap();
        },
      ),
    );
  }
}
