import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:student_expense_ai/database/database_helper.dart';
import 'package:student_expense_ai/widgets/transaction_tile.dart';
import 'package:student_expense_ai/pages/add_transaction_modal.dart';
import 'package:student_expense_ai/pages/transaction_details_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  static const Color _primary = Color(0xFF5B45B5);
  static const Color _background = Color(0xFFF7F7FB);
  static const Color _border = Color(0xFFECEAF3);
  static const Color _muted = Color(0xFF85839A);

  List<Map<String, dynamic>> transactions = [];
  DateTime selectedMonth = DateTime.now();
  bool hasChanged = false;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final data = await DatabaseHelper.instance.getAllTransactions();

      if (!mounted) return;

      setState(() {
        transactions = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load transactions. Please try again.'),
        ),
      );
    }
  }

  Future<void> selectMonthYear() async {
    int selectedYear = selectedMonth.year;
    int selectedMonthNumber = selectedMonth.month;
    final currentYear = DateTime.now().year;

    final result = await showDialog<DateTime>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Select Month',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    decoration: _dropdownDecoration('Year'),
                    items: List.generate(currentYear - 1999, (index) {
                      final year = currentYear - index;

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
                    decoration: _dropdownDecoration('Month'),
                    items: List.generate(12, (index) {
                      final month = index + 1;

                      return DropdownMenuItem(
                        value: month,
                        child: Text(
                          DateFormat('MMMM').format(DateTime(2000, month)),
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
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: _muted)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                      DateTime(selectedYear, selectedMonthNumber),
                    );
                  },
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      setState(() {
        selectedMonth = result;
      });
    }
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  Future<void> deleteTransaction(Map<String, dynamic> transaction) async {
    if (transaction['type'] == 'Expense') {
      await DatabaseHelper.instance.deleteExpenses(transaction['id']);
    } else {
      await DatabaseHelper.instance.deleteBudget(transaction['id']);
    }
  }

  Map<String, List<Map<String, dynamic>>> groupTransactionsByDate() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final filteredTransactions = transactions.where((transaction) {
      final date = DateTime.tryParse(
        transaction['createdAt']?.toString() ?? '',
      );

      return date != null &&
          date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();

    // Sort newest transactions first.
    filteredTransactions.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');

      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    for (final transaction in filteredTransactions) {
      final date = DateTime.parse(transaction['createdAt'].toString());
      final transactionDay = DateTime(date.year, date.month, date.day);

      String title;

      if (transactionDay == today) {
        title = 'Today';
      } else if (transactionDay == yesterday) {
        title = 'Yesterday';
      } else {
        title = DateFormat('MMMM d, yyyy').format(date);
      }

      grouped.putIfAbsent(title, () => []);
      grouped[title]!.add(transaction);
    }

    return grouped;
  }

  String getCurrentMonthTitle() {
    return DateFormat('MMMM yyyy').format(selectedMonth);
  }

  @override
  Widget build(BuildContext context) {
    final groupedTransactions = groupTransactionsByDate();

    final monthTransactions = transactions.where((transaction) {
      final date = DateTime.tryParse(
        transaction['createdAt']?.toString() ?? '',
      );

      return date != null &&
          date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();

    final totalExpenses = monthTransactions
        .where((transaction) => transaction['type'] == 'Expense')
        .fold<double>(
          0,
          (sum, transaction) =>
              sum + ((transaction['amount'] as num?)?.toDouble() ?? 0),
        );

    final totalIncome = monthTransactions
        .where((transaction) => transaction['type'] != 'Expense')
        .fold<double>(
          0,
          (sum, transaction) =>
              sum + ((transaction['amount'] as num?)?.toDouble() ?? 0),
        );

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
          onPressed: () {
            Navigator.pop(context, hasChanged);
          },
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF29263D),
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: loadTransactions,
        child: isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator(color: _primary)),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  // Month selector
                  InkWell(
                    onTap: selectMonthYear,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.calendar_month_rounded,
                            color: _primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            getCurrentMonthTitle(),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF29263D),
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: _muted,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Monthly overview
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Monthly Overview',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF29263D),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryItem(
                                icon: Icons.arrow_downward_rounded,
                                label: 'Expenses',
                                amount: currencyFormat.format(totalExpenses),
                                color: const Color(0xFFE05252),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryItem(
                                icon: Icons.arrow_upward_rounded,
                                label: 'Income',
                                amount: currencyFormat.format(totalIncome),
                                color: const Color(0xFF159A75),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transaction list heading
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Transaction History',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF29263D),
                          ),
                        ),
                      ),
                      Text(
                        '${monthTransactions.length} ${monthTransactions.length == 1 ? 'transaction' : 'transactions'}',
                        style: const TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),
                  const Text(
                    'Your activity, organized by date',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),

                  const SizedBox(height: 14),

                  if (groupedTransactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 36,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: _primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.receipt_long_rounded,
                              size: 28,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No transactions found',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF29263D),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'There are no transactions for ${getCurrentMonthTitle()}.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: _muted),
                          ),
                        ],
                      ),
                    )
                  else
                    ...groupedTransactions.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 2,
                                bottom: 8,
                              ),
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _muted,
                                ),
                              ),
                            ),
                            ...entry.value.map((transaction) {
                              final isExpense =
                                  transaction['type'] == 'Expense';

                              final rawAmount =
                                  (transaction['amount'] as num?)?.toDouble() ??
                                  0.0;

                              return TransactionTile(
                                transaction: transaction,
                                icon: isExpense
                                    ? Icons.receipt_long_rounded
                                    : Icons.account_balance_wallet_rounded,
                                category: transaction['category'] ?? 'Unknown',
                                subtitle:
                                    transaction['note'] ?? 'No description',
                                amount: currencyFormat.format(rawAmount),
                                isExpense: isExpense,
                                onDelete: () async {
                                  await deleteTransaction(transaction);

                                  if (!mounted) return;

                                  setState(() {
                                    hasChanged = true;
                                  });

                                  await loadTransactions();
                                },
                                onEdit: () async {
                                  final result = await showAddModal(
                                    context,
                                    transaction: transaction,
                                  );

                                  if (result == true && mounted) {
                                    setState(() {
                                      hasChanged = true;
                                    });

                                    await loadTransactions();
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

                                  if (mounted) {
                                    await loadTransactions();
                                  }
                                },
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
