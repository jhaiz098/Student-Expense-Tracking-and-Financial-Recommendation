import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'add_transaction_modal.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsPage({super.key, required this.transaction});

  static const Color _primary = Color(0xFF5B45B5);
  static const Color _expense = Color(0xFFE05252);
  static const Color _income = Color(0xFF159A75);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final background = isDark
        ? const Color(0xFF15131E)
        : const Color(0xFFF7F7FB);

    final cardColor = isDark ? const Color(0xFF211D2D) : Colors.white;

    final borderColor = isDark
        ? const Color(0xFF393246)
        : const Color(0xFFE7E4F0);

    final textColor = isDark
        ? const Color(0xFFF5F2FF)
        : const Color(0xFF29263A);

    final mutedColor = isDark
        ? const Color(0xFFB7B2C8)
        : const Color(0xFF85839A);

    final primaryColor = isDark ? const Color(0xFFB9A8FF) : _primary;

    final isExpense = transaction['type'] == 'Expense';

    final category = transaction['category']?.toString() ?? 'Unknown';

    final type = transaction['type']?.toString() ?? 'Unknown';

    final rawNote = transaction['note']?.toString().trim() ?? '';

    final note = rawNote.isNotEmpty ? rawNote : 'No description';

    final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;

    final date = DateTime.tryParse(transaction['createdAt']?.toString() ?? '');

    final formattedDate = date != null
        ? DateFormat('MMMM d, yyyy').format(date)
        : 'Date unavailable';

    final formattedTime = date != null ? DateFormat('h:mm a').format(date) : '';

    final amountColor = isExpense
        ? (isDark ? const Color(0xFFFF777E) : _expense)
        : (isDark ? const Color(0xFF54D6A4) : _income);

    final currencyFormat = NumberFormat.currency(
      locale: 'en_PH',
      symbol: '₱',
      decimalDigits: 2,
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        foregroundColor: textColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: primaryColor,
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Transaction Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.edit_outlined),
              color: primaryColor,
              tooltip: 'Edit transaction',
              style: IconButton.styleFrom(
                backgroundColor: primaryColor.withValues(
                  alpha: isDark ? 0.16 : 0.08,
                ),
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
            // Main transaction summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: borderColor),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: const Color(
                            0xFF29263A,
                          ).withValues(alpha: 0.03),
                          blurRadius: 16,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: amountColor.withValues(
                        alpha: isDark ? 0.16 : 0.09,
                      ),
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
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '${isExpense ? '-' : '+'}${currencyFormat.format(amount)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: amountColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: amountColor.withValues(
                        alpha: isDark ? 0.14 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: amountColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Text(
                      type,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: amountColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 15,
                        color: mutedColor,
                      ),
                      Text(
                        formattedDate,
                        style: TextStyle(fontSize: 13, color: mutedColor),
                      ),
                      if (formattedTime.isNotEmpty) ...[
                        Text('•', style: TextStyle(color: mutedColor)),
                        Icon(
                          Icons.access_time_rounded,
                          size: 15,
                          color: mutedColor,
                        ),
                        Text(
                          formattedTime,
                          style: TextStyle(fontSize: 13, color: mutedColor),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Description heading
            Text(
              'Description',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Additional details for this transaction',
              style: TextStyle(fontSize: 12, color: mutedColor),
            ),
            const SizedBox(height: 14),

            // Description card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.16 : 0.08,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.notes_rounded,
                      color: primaryColor,
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
                          color: rawNote.isNotEmpty ? textColor : mutedColor,
                          height: 1.6,
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
