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
  static const Color _darkPrimary = Color(0xFFB9A8FF);
  static const Color _green = Color(0xFF159A75);
  static const Color _red = Color(0xFFE05252);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _isDark ? const Color(0xFF15131E) : const Color(0xFFF7F7FB);

  Color get _card => _isDark ? const Color(0xFF211D2D) : Colors.white;

  Color get _border =>
      _isDark ? const Color(0xFF393246) : const Color(0xFFE7E4F0);

  Color get _text =>
      _isDark ? const Color(0xFFF5F2FF) : const Color(0xFF29263A);

  Color get _muted =>
      _isDark ? const Color(0xFFB7B2C8) : const Color(0xFF6F6B82);

  Color get _surface =>
      _isDark ? const Color(0xFF2A2538) : const Color(0xFFFAFAFD);

  Color get _softPurple =>
      _isDark ? const Color(0xFF302844) : const Color(0xFFF6F4FC);

  Color get _accent => _isDark ? _darkPrimary : _primary;

  List<Map<String, dynamic>> transactions = [];
  DateTime selectedMonth = DateTime.now();

  // Null means no filter is selected.
  String? selectedTransactionType;

  bool hasChanged = false;
  bool isLoading = true;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

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
      debugPrint('Unable to load transactions: $e');

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
              backgroundColor: _card,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: _border),
              ),
              title: Text(
                'Select Month',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: selectedYear,
                    dropdownColor: _card,
                    style: TextStyle(color: _text),
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
                    dropdownColor: _card,
                    style: TextStyle(color: _text),
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
                  child: Text('Cancel', style: TextStyle(color: _muted)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
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
      labelStyle: TextStyle(color: _muted),
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accent, width: 1.5),
      ),
    );
  }

  Widget _transactionFilterButton({
    required String label,
    required String type,
    required IconData icon,
  }) {
    final isSelected = selectedTransactionType == type;

    return OutlinedButton(
      onPressed: () {
        setState(() {
          // Tapping the selected filter again clears it.
          selectedTransactionType = isSelected ? null : type;
        });
      },
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? _primary : _card,
        foregroundColor: isSelected ? Colors.white : _text,
        side: BorderSide(color: isSelected ? _primary : _border),
        padding: const EdgeInsets.symmetric(vertical: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
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

  Map<String, List<Map<String, dynamic>>> groupTransactionsByDate(
    List<Map<String, dynamic>> monthTransactions,
  ) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final filteredTransactions = monthTransactions.where((transaction) {
      return selectedTransactionType == null ||
          transaction['type'] == selectedTransactionType;
    }).toList();

    filteredTransactions.sort((a, b) {
      final dateA = DateTime.tryParse(a['createdAt']?.toString() ?? '');
      final dateB = DateTime.tryParse(b['createdAt']?.toString() ?? '');

      if (dateA == null || dateB == null) return 0;
      return dateB.compareTo(dateA);
    });

    for (final transaction in filteredTransactions) {
      final date = DateTime.tryParse(
        transaction['createdAt']?.toString() ?? '',
      );

      if (date == null) continue;

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
    // All records for the selected month. The monthly summary always
    // represents the entire month, regardless of the history filter.
    final monthTransactions = transactions.where((transaction) {
      final date = DateTime.tryParse(
        transaction['createdAt']?.toString() ?? '',
      );

      return date != null &&
          date.year == selectedMonth.year &&
          date.month == selectedMonth.month;
    }).toList();

    // Apply the optional type filter to the history only.
    final filteredMonthTransactions = monthTransactions.where((transaction) {
      return selectedTransactionType == null ||
          transaction['type'] == selectedTransactionType;
    }).toList();

    final groupedTransactions = groupTransactionsByDate(monthTransactions);

    final totalExpenses = monthTransactions
        .where((transaction) => transaction['type'] == 'Expense')
        .fold<double>(
          0,
          (sum, transaction) =>
              sum + ((transaction['amount'] as num?)?.toDouble() ?? 0),
        );

    final totalBudgetRecords = monthTransactions
        .where((transaction) => transaction['type'] == 'Budget')
        .fold<double>(
          0,
          (sum, transaction) =>
              sum + ((transaction['amount'] as num?)?.toDouble() ?? 0),
        );

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: _accent,
          tooltip: 'Back',
          onPressed: () {
            Navigator.pop(context, hasChanged);
          },
        ),
        title: Text(
          'Transactions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        color: _accent,
        backgroundColor: _card,
        onRefresh: loadTransactions,
        child: isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 220),
                  Center(child: CircularProgressIndicator(color: _accent)),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  // Month selector
                  Material(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: selectMonthYear,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_month_rounded,
                              color: _accent,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              getCurrentMonthTitle(),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: _text,
                              ),
                            ),
                            const Spacer(),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: _muted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Monthly summary
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monthly Summary',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),

                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _SummaryItem(
                                icon: Icons.receipt_long_rounded,
                                label: 'Total Expenses',
                                amount: _currencyFormat.format(totalExpenses),
                                color: _red,
                                isDark: _isDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _SummaryItem(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'Total Budget',
                                amount: _currencyFormat.format(
                                  totalBudgetRecords,
                                ),
                                color: _green,
                                isDark: _isDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Transaction history heading
                  Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),

                  const SizedBox(height: 4),
                  Text(
                    'View your records by type and date.',
                    style: TextStyle(fontSize: 12, color: _muted),
                  ),

                  const SizedBox(height: 14),

                  // Optional type filters
                  Row(
                    children: [
                      Expanded(
                        child: _transactionFilterButton(
                          label: 'Expenses',
                          type: 'Expense',
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _transactionFilterButton(
                          label: 'Budgets',
                          type: 'Budget',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Tap to filter by type. Tap again to show all transactions.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: _muted,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedTransactionType == null
                              ? 'All Transactions'
                              : selectedTransactionType == 'Expense'
                              ? 'Expenses'
                              : 'Budgets',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: _text,
                          ),
                        ),
                      ),
                      Text(
                        '${filteredMonthTransactions.length} '
                        '${filteredMonthTransactions.length == 1 ? 'transaction' : 'transactions'}',
                        style: TextStyle(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (groupedTransactions.isEmpty)
                    _buildEmptyState()
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
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
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
                                amount: _currencyFormat.format(rawAmount),
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

  Widget _buildEmptyState() {
    final description = selectedTransactionType == null
        ? 'There are no transactions for ${getCurrentMonthTitle()}.'
        : 'There are no ${selectedTransactionType == 'Expense' ? 'expenses' : 'budget records'} '
              'for ${getCurrentMonthTitle()}.';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(Icons.receipt_long_rounded, size: 28, color: _accent),
          ),
          const SizedBox(height: 14),
          Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String amount;
  final Color color;
  final bool isDark;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final background = isDark
        ? const Color(0xFF2A2538)
        : color.withValues(alpha: 0.06);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(13),
        border: isDark ? Border.all(color: const Color(0xFF393246)) : null,
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
                    fontWeight: FontWeight.w600,
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
                fontWeight: FontWeight.w800,
                color: isDark ? const Color(0xFFF5F2FF) : color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
