import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_transaction_modal.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsPage({super.key, required this.transaction});

  static const Color _primary = Color(0xFF5B45B5);
  static const Color _background = Color(0xFFF7F7FB);
  static const Color _border = Color(0xFFECEAF3);
  static const Color _muted = Color(0xFF85839A);
  static const Color _expense = Color(0xFFE05252);
  static const Color _income = Color(0xFF159A75);

  @override
  Widget build(BuildContext context) {
    final bool isExpense = transaction['type'] == 'Expense';

    final String category = transaction['category']?.toString() ?? 'Unknown';

    final String type = transaction['type']?.toString() ?? 'Unknown';

    final String rawNote = transaction['note']?.toString().trim() ?? '';

    final String note = rawNote.isNotEmpty ? rawNote : 'No description';

    final double amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    final DateTime? date = DateTime.tryParse(
      transaction['createdAt']?.toString() ?? '',
    );

    final String formattedDate = date != null
        ? DateFormat('MMMM d, yyyy').format(date)
        : 'Date unavailable';

    final String formattedTime = date != null
        ? DateFormat('h:mm a').format(date)
        : '';

    final Color amountColor = isExpense ? _expense : _income;

    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: _primary,
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF29263D),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: _primary,
              tooltip: 'Edit transaction',
              style: IconButton.styleFrom(
                backgroundColor: _primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
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
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Main transaction summary — unchanged
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      isExpense
                          ? Icons.receipt_long_rounded
                          : Icons.account_balance_wallet_rounded,
                      size: 36,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    category,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF29263D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${isExpense ? '-' : '+'}${currencyFormat.format(amount)}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      color: amountColor,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: amountColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(color: _border, height: 1),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: _muted,
                      ),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          formattedDate,
                          style: const TextStyle(fontSize: 13, color: _muted),
                        ),
                      ),
                      if (formattedTime.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Text('•', style: TextStyle(color: _muted)),
                        const SizedBox(width: 8),
                        Text(
                          formattedTime,
                          style: const TextStyle(fontSize: 13, color: _muted),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Description section — redesigned
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF29263D),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Additional details for this transaction',
              style: TextStyle(fontSize: 12, color: _muted),
            ),
            const SizedBox(height: 14),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.notes_rounded,
                      color: _primary,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        note,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: rawNote.isNotEmpty
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: rawNote.isNotEmpty
                              ? const Color(0xFF29263D)
                              : _muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
