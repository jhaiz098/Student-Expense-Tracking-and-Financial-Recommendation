import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';

import '../database/database_helper.dart';
import 'add_transaction_modal.dart';
import 'package:student_expense_ai/pages/transactions_page.dart';
import '../widgets/transaction_tile.dart';
import 'transaction_details_page.dart';

class HomePage extends StatefulWidget {
  final GlobalKey budgetKey;
  final GlobalKey budgetUsageKey;

  const HomePage({
    super.key,
    required this.budgetKey,
    required this.budgetUsageKey,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color _primary = Color(0xFF5B45B5);
  static const Color _background = Color(0xFFF7F7FB);
  static const Color _green = Color(0xFF159A75);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFE05252);
  static const Color _border = Color(0xFFECEAF3);

  final NumberFormat _money = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  int budgetReminder = 80;
  List<Map<String, dynamic>> recentTransactions = [];
  double monthlyBudget = 0;
  double monthlyExpenses = 0;
  String currentMonth = DateFormat('MMMM').format(DateTime.now());
  String fullName = '';

  @override
  void initState() {
    super.initState();
    loadProfile();
    loadBudget();
    loadExpenses();
    loadTransactions();
  }

  Future<void> refresh() async {
    await Future.wait([loadBudget(), loadExpenses(), loadTransactions()]);
  }

  Future<void> loadProfile() async {
    final profile = await DatabaseHelper.instance.getUserProfile();

    if (!mounted) return;

    setState(() {
      fullName = profile?['fullName'] ?? '';
    });
  }

  Future<void> loadExpenses() async {
    final expenses = await DatabaseHelper.instance.getExpenses();
    final now = DateTime.now();

    double total = 0;

    for (final expense in expenses) {
      final rawDate = expense['createdAt'];
      if (rawDate == null) continue;

      final date = DateTime.tryParse(rawDate.toString());
      if (date == null) continue;

      if (date.month == now.month && date.year == now.year) {
        total += (expense['amount'] as num?)?.toDouble() ?? 0;
      }
    }

    if (!mounted) return;

    setState(() {
      monthlyExpenses = total;
      currentMonth = DateFormat('MMMM').format(now);
    });
  }

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getRecentTransactions();

    if (!mounted) return;

    setState(() {
      recentTransactions = data;
    });
  }

  Future<void> loadBudget() async {
    final results = await Future.wait([
      DatabaseHelper.instance.getCurrentMonthBudget(),
      DatabaseHelper.instance.getBudgetReminder(),
    ]);

    if (!mounted) return;

    setState(() {
      monthlyBudget = (results[0] as num).toDouble();
      budgetReminder = results[1] as int;
    });
  }

  double getBudgetPercentage() {
    if (monthlyBudget <= 0) return 0;
    return monthlyExpenses / monthlyBudget * 100;
  }

  double getRemainingBudget() {
    return (monthlyBudget - monthlyExpenses)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  double getExcessSpending() {
    if (monthlyBudget <= 0) return 0;

    return (monthlyExpenses - monthlyBudget)
        .clamp(0.0, double.infinity)
        .toDouble();
  }

  Color getBudgetColor(int percentage) {
    if (percentage >= budgetReminder) return _red;
    if (percentage >= budgetReminder - 20) return _orange;
    return _green;
  }

  @override
  Widget build(BuildContext context) {
    final budgetUsage = monthlyBudget <= 0
        ? 0.0
        : monthlyExpenses / monthlyBudget;

    final budgetPercentage = (budgetUsage * 100).floor().clamp(0, 100);

    final isOverBudget = getExcessSpending() > 0;
    final hasBudget = monthlyBudget > 0;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Home',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: _primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Text(
              'Hello, ${fullName.isNotEmpty ? fullName : 'there'}!',
              style: const TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
                color: Color(0xFF252238),
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Here's your financial overview for this month.",
              style: TextStyle(
                fontSize: 13,
                color: Colors.black54,
                height: 1.4,
              ),
            ),

            const SizedBox(height: 20),

            // Monthly Budget
            Showcase(
              key: widget.budgetKey,
              title: 'Monthly Budget',
              description:
                  'This shows your monthly budget, total spending, and remaining amount.',
              targetBorderRadius: BorderRadius.circular(18),
              overlayColor: Colors.black,
              overlayOpacity: 0.65,
              tooltipBackgroundColor: _primary,
              tooltipBorderRadius: BorderRadius.circular(16),
              tooltipPadding: const EdgeInsets.all(16),
              textColor: Colors.white,
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              descTextStyle: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.white,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOverBudget ? _red : _primary,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (isOverBudget ? _red : _primary).withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Remaining Budget',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOverBudget
                                    ? Icons.warning_amber_rounded
                                    : Icons.account_balance_wallet_outlined,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isOverBudget
                                    ? 'Over budget'
                                    : hasBudget
                                    ? 'Monthly budget'
                                    : 'No budget set',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _money.format(getRemainingBudget()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                        ),
                      ),
                    ),
                    if (isOverBudget) ...[
                      const SizedBox(height: 5),
                      Text(
                        '${_money.format(getExcessSpending())} over your budget',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    Container(height: 1, color: Colors.white.withOpacity(0.2)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _budgetValue(
                            '$currentMonth budget',
                            _money.format(monthlyBudget),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _budgetValue(
                            'Spent so far',
                            _money.format(monthlyExpenses),
                            alignRight: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Budget Usage
            Showcase(
              key: widget.budgetUsageKey,
              title: 'Budget Usage',
              description:
                  'Monitor how much of your monthly budget you have already used.',
              targetBorderRadius: BorderRadius.circular(18),
              overlayOpacity: 0.65,
              tooltipBackgroundColor: _primary,
              tooltipBorderRadius: BorderRadius.circular(16),
              tooltipPadding: const EdgeInsets.all(16),
              textColor: Colors.white,
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              descTextStyle: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.white,
              ),
              child: _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _iconBox(Icons.pie_chart_outline_rounded, _primary),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Budget Usage',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (hasBudget)
                          Text(
                            '$budgetPercentage%',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              color: getBudgetColor(budgetPercentage),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Spent',
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                        Flexible(
                          child: Text(
                            '${_money.format(monthlyExpenses)} / ${_money.format(monthlyBudget)}',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: budgetUsage.clamp(0.0, 1.0),
                        minHeight: 9,
                        backgroundColor: const Color(0xFFECEAF3),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          hasBudget
                              ? getBudgetColor(budgetPercentage)
                              : _primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      !hasBudget
                          ? 'Set a monthly budget to start tracking your usage.'
                          : isOverBudget
                          ? 'You have exceeded your budget by ${_money.format(getExcessSpending())}.'
                          : '${_money.format(getRemainingBudget())} remaining in your monthly budget.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: isOverBudget ? _red : Colors.black54,
                        fontWeight: isOverBudget
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                    if (hasBudget &&
                        !isOverBudget &&
                        getBudgetPercentage() >= budgetReminder) ...[
                      const SizedBox(height: 12),
                      _notice(
                        icon: Icons.warning_amber_rounded,
                        title: 'Budget Warning',
                        message:
                            'You have used ${getBudgetPercentage().toStringAsFixed(0)}% of your monthly budget.',
                        color: _orange,
                      ),
                    ],
                    if (isOverBudget) ...[
                      const SizedBox(height: 12),
                      _notice(
                        icon: Icons.error_outline_rounded,
                        title: 'Excess Spending',
                        message: 'Your expenses are above your monthly budget.',
                        color: _red,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Transactions heading
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Recent Transactions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openAllTransactions,
                  style: TextButton.styleFrom(
                    foregroundColor: _primary,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            const Text(
              'Your latest recorded expenses and budget transactions.',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            if (recentTransactions.isEmpty)
              _panel(
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 34,
                        color: Color(0xFF9A94B0),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your recent transactions will appear here once you add them.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: recentTransactions.asMap().entries.map((entry) {
                    final index = entry.key;
                    final transaction = entry.value;
                    final isExpense = transaction['type'] == 'Expense';
                    final amount =
                        (transaction['amount'] as num?)?.toDouble() ?? 0;

                    return Column(
                      children: [
                        TransactionTile(
                          transaction: transaction,
                          icon: isExpense
                              ? Icons.receipt_long_outlined
                              : Icons.account_balance_wallet_outlined,
                          category: transaction['category'] ?? 'Unknown',
                          subtitle: transaction['note'] ?? 'No description',
                          amount: _money.format(amount),
                          isExpense: isExpense,
                          onDelete: () async {
                            await _deleteTransaction(transaction);
                            await refresh();
                          },
                          onEdit: () async {
                            final result = await showAddModal(
                              context,
                              transaction: transaction,
                            );

                            if (result == true) {
                              await refresh();
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

                            await refresh();
                          },
                        ),
                        if (index != recentTransactions.length - 1)
                          const Divider(
                            height: 1,
                            color: _border,
                            indent: 8,
                            endIndent: 8,
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 14),
            _dataNote(),
          ],
        ),
      ),
    );
  }

  Widget _budgetValue(String label, String value, {bool alignRight = false}) {
    return Column(
      crossAxisAlignment: alignRight
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          textAlign: alignRight ? TextAlign.right : TextAlign.left,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }

  Widget _iconBox(IconData icon, Color color) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _notice({
    required IconData icon,
    required String title,
    required String message,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(color: color, fontSize: 11, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F4FC),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFE9E4FA)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _primary, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Your overview is based on the expenses and budget records saved in the app.',
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAllTransactions() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const TransactionsPage()),
    );

    await refresh();
  }

  Future<void> _deleteTransaction(Map<String, dynamic> transaction) async {
    final id = transaction['id'];
    final type = transaction['type'];

    if (type == 'Expense') {
      await DatabaseHelper.instance.deleteExpenses(id);
    } else {
      await DatabaseHelper.instance.deleteBudget(id);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Transaction deleted')));
  }
}
