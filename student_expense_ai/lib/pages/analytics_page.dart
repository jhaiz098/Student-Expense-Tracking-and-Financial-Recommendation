import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:showcaseview/showcaseview.dart';

import '../database/database_helper.dart';

class AnalyticsPage extends StatefulWidget {
  final GlobalKey analyticsKey;

  const AnalyticsPage({super.key, required this.analyticsKey});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const Color _primary = Color(0xFF5B45B5);
  static const Color _green = Color(0xFF159A75);
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFE05252);
  int budgetReminder = 80;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _isDark ? const Color(0xFF15131E) : const Color(0xFFF7F7FB);
  Color get _card => _isDark ? const Color(0xFF211D2D) : Colors.white;
  Color get _text =>
      _isDark ? const Color(0xFFF5F2FF) : const Color(0xFF29263A);
  Color get _muted =>
      _isDark ? const Color(0xFFB7B2C8) : const Color(0xFF6F6B82);
  Color get _border =>
      _isDark ? const Color(0xFF393246) : const Color(0xFFE7E4F0);
  Color get _softSurface =>
      _isDark ? const Color(0xFF2A2538) : const Color(0xFFFAFAFD);
  Color get _accent => _isDark ? const Color(0xFFB9A8FF) : _primary;
  Color get _gridColor =>
      _isDark ? const Color(0xFF393246) : const Color(0xFFECEAF3);

  final NumberFormat _money = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  final List<Color> _categoryColors = const [
    Color(0xFF5B45B5),
    Color(0xFFF59E0B),
    Color(0xFF159A75),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF64748B),
    Color(0xFF14B8A6),
    Color(0xFF8B5CF6),
  ];

  final List<String> _periodOptions = const [
    'This Month',
    'Past 3 Months',
    'Past 6 Months',
    'Past 12 Months',
    'All Time',
  ];

  String selectedPeriod = 'This Month';
  bool isLoading = true;

  final List<String> _trendOptions = const [
    'Daily',
    'Weekly',
    'Monthly',
    'Yearly',
  ];

  String selectedTrend = 'Monthly';

  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> budgets = [];

  @override
  void initState() {
    super.initState();
    loadAnalytics();
  }

  Future<void> refresh() => loadAnalytics();

  Future<void> loadAnalytics() async {
    if (mounted) setState(() => isLoading = true);

    try {
      final results = await Future.wait([
        DatabaseHelper.instance.getExpensesWithCategory(),
        DatabaseHelper.instance.getBudget(),
        DatabaseHelper.instance.getBudgetReminder(),
      ]);

      if (!mounted) return;

      setState(() {
        expenses = List<Map<String, dynamic>>.from(results[0] as List);
        budgets = List<Map<String, dynamic>>.from(results[1] as List);
        budgetReminder = results[2] as int;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load analytics. Please try again.'),
        ),
      );
    }
  }

  double _amount(Map<String, dynamic> item) =>
      (item['amount'] as num?)?.toDouble() ?? 0;

  DateTime? _date(Map<String, dynamic> item) =>
      DateTime.tryParse('${item['createdAt'] ?? ''}');

  String _expenseCategory(Map<String, dynamic> item) =>
      (item['category'] ?? item['categoryName'] ?? 'Others').toString();

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime get _nextMonthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  DateTime? get _periodStart {
    final now = DateTime.now();

    switch (selectedPeriod) {
      case 'This Month':
        return DateTime(now.year, now.month, 1);
      case 'Past 3 Months':
        return DateTime(now.year, now.month - 2, 1);
      case 'Past 6 Months':
        return DateTime(now.year, now.month - 5, 1);
      case 'Past 12 Months':
        return DateTime(now.year, now.month - 11, 1);
      default:
        return null;
    }
  }

  int? get _periodMonthCount {
    switch (selectedPeriod) {
      case 'This Month':
        return 1;
      case 'Past 3 Months':
        return 3;
      case 'Past 6 Months':
        return 6;
      case 'Past 12 Months':
        return 12;
      default:
        return null;
    }
  }

  DateTime get _periodEndExclusive => _nextMonthStart;

  Widget _comparisonRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: _muted, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          textAlign: TextAlign.end,
          style: TextStyle(
            color: valueColor ?? _text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Returns the start of the previous comparison period.
  DateTime? get _previousPeriodStart {
    final months = _periodMonthCount;
    final start = _periodStart;

    if (months == null || start == null) return null;

    return DateTime(start.year, start.month - months, 1);
  }

  // Formats a month range so users know exactly what is being compared.
  String _monthRangeLabel(DateTime start, DateTime endExclusive) {
    final lastDay = endExclusive.subtract(const Duration(days: 1));

    if (start.year == lastDay.year && start.month == lastDay.month) {
      return DateFormat('MMMM yyyy').format(start);
    }

    if (start.year == lastDay.year) {
      return '${DateFormat('MMM').format(start)}–'
          '${DateFormat('MMM yyyy').format(lastDay)}';
    }

    return '${DateFormat('MMM yyyy').format(start)}–'
        '${DateFormat('MMM yyyy').format(lastDay)}';
  }

  String get _currentPeriodLabel {
    final start = _periodStart;

    if (start == null) {
      if (expenses.isEmpty && budgets.isEmpty) return 'All recorded dates';

      final dates = [
        ...expenses.map(_date).whereType<DateTime>(),
        ...budgets.map(_date).whereType<DateTime>(),
      ]..sort();

      if (dates.isEmpty) return 'All recorded dates';

      return _monthRangeLabel(
        DateTime(dates.first.year, dates.first.month, 1),
        DateTime(dates.last.year, dates.last.month + 1, 1),
      );
    }

    return _monthRangeLabel(start, _periodEndExclusive);
  }

  String? get _previousPeriodLabel {
    final start = _previousPeriodStart;
    final currentStart = _periodStart;

    if (start == null || currentStart == null) return null;

    return _monthRangeLabel(start, currentStart);
  }

  List<Map<String, dynamic>> _recordsInPeriod(
    List<Map<String, dynamic>> records,
  ) {
    final start = _periodStart;

    return records.where((item) {
      final date = _date(item);
      if (date == null) return false;

      return (start == null || !date.isBefore(start)) &&
          date.isBefore(_periodEndExclusive);
    }).toList();
  }

  List<Map<String, dynamic>> get _periodExpenses => _recordsInPeriod(expenses);

  List<Map<String, dynamic>> get _periodBudgets => _recordsInPeriod(budgets);

  double get _totalSpent =>
      _periodExpenses.fold(0.0, (sum, item) => sum + _amount(item));

  double get _budgetTotal =>
      _periodBudgets.fold(0.0, (sum, item) => sum + _amount(item));

  double get _budgetRemaining => _budgetTotal - _totalSpent;

  int get _transactionCount => _periodExpenses.length;

  double get _averageTransaction =>
      _transactionCount == 0 ? 0 : _totalSpent / _transactionCount;

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};

    for (final item in _periodExpenses) {
      final name = _expenseCategory(item);
      totals[name] = (totals[name] ?? 0) + _amount(item);
    }

    return totals;
  }

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{};

    for (final item in _periodExpenses) {
      final name = _expenseCategory(item);
      counts[name] = (counts[name] ?? 0) + 1;
    }

    return counts;
  }

  Map<String, double> get _budgetCategoryTotals {
    final totals = <String, double>{};

    for (final item in _periodBudgets) {
      final name = _budgetCategory(item);
      totals[name] = (totals[name] ?? 0) + _amount(item);
    }

    return totals;
  }

  Map<String, double> get _dailyTotals {
    final totals = <String, double>{};

    for (final item in _periodExpenses) {
      final date = _date(item);
      if (date == null) continue;

      final key = DateFormat('yyyy-MM-dd').format(date);
      totals[key] = (totals[key] ?? 0) + _amount(item);
    }

    return totals;
  }

  int get _activeSpendingDays => _dailyTotals.length;

  double get _averagePerCalendarDay {
    final start = _periodStart ?? _oldestExpenseDate;
    if (start == null) return 0;

    final end = _today.isBefore(_periodEndExclusive)
        ? _today
        : _periodEndExclusive.subtract(const Duration(days: 1));

    if (end.isBefore(start)) return 0;

    final days = end.difference(start).inDays + 1;
    return days <= 0 ? 0 : _totalSpent / days;
  }

  DateTime? get _oldestExpenseDate {
    final dates = _periodExpenses.map(_date).whereType<DateTime>().toList()
      ..sort();

    if (dates.isEmpty) return null;

    final first = dates.first;
    return DateTime(first.year, first.month, first.day);
  }

  List<Map<String, dynamic>> get _largestTransactions {
    final rows = List<Map<String, dynamic>>.from(_periodExpenses)
      ..sort((a, b) => _amount(b).compareTo(_amount(a)));

    return rows.take(3).toList();
  }

  MapEntry<String, double>? get _topCategory {
    final entries = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.isEmpty ? null : entries.first;
  }

  MapEntry<String, double>? get _highestSpendingDay {
    final entries = _dailyTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries.isEmpty ? null : entries.first;
  }

  double? get _previousPeriodTotal {
    final start = _periodStart;
    final previousStart = _previousPeriodStart;

    if (previousStart == null || start == null) return null;

    return expenses.fold<double>(0, (sum, item) {
      final date = _date(item);

      if (date == null ||
          date.isBefore(previousStart) ||
          !date.isBefore(start)) {
        return sum;
      }

      return sum + _amount(item);
    });
  }

  int? get _previousPeriodCount {
    final start = _periodStart;
    final previousStart = _previousPeriodStart;

    if (previousStart == null || start == null) return null;

    return expenses.where((item) {
      final date = _date(item);

      return date != null &&
          !date.isBefore(previousStart) &&
          date.isBefore(start);
    }).length;
  }

  List<Map<String, dynamic>> get _spendingTrend {
    final now = DateTime.now();
    final rows = <Map<String, dynamic>>[];

    late DateTime start;
    late int count;

    switch (selectedTrend) {
      case 'Daily':
        // Today and the previous 6 days.
        start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(const Duration(days: 6));
        count = 7;

        for (int i = 0; i < count; i++) {
          final periodStart = start.add(Duration(days: i));
          final periodEnd = periodStart.add(const Duration(days: 1));

          rows.add({
            'label': DateFormat('E').format(periodStart),
            'start': periodStart,
            'end': periodEnd,
            'amount': _sumExpenses(periodStart, periodEnd),
          });
        }
        break;

      case 'Weekly':
        // Current week and the previous 5 weeks.
        final currentWeek = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1));

        start = currentWeek.subtract(const Duration(days: 35));
        count = 6;

        for (int i = 0; i < count; i++) {
          final periodStart = start.add(Duration(days: i * 7));
          final periodEnd = periodStart.add(const Duration(days: 7));

          rows.add({
            'label': DateFormat('MMM d').format(periodStart),
            'start': periodStart,
            'end': periodEnd,
            'amount': _sumExpenses(periodStart, periodEnd),
          });
        }
        break;

      case 'Yearly':
        // Current year and the previous 4 years.
        count = 5;
        start = DateTime(now.year - 4, 1, 1);

        for (int i = 0; i < count; i++) {
          final periodStart = DateTime(start.year + i, 1, 1);
          final periodEnd = DateTime(periodStart.year + 1, 1, 1);

          rows.add({
            'label': DateFormat('yyyy').format(periodStart),
            'start': periodStart,
            'end': periodEnd,
            'amount': _sumExpenses(periodStart, periodEnd),
          });
        }
        break;

      default:
        // Monthly: current month and the previous 11 months.
        count = 12;
        start = DateTime(now.year, now.month - 11, 1);

        for (int i = 0; i < count; i++) {
          final periodStart = DateTime(start.year, start.month + i, 1);
          final periodEnd = DateTime(
            periodStart.year,
            periodStart.month + 1,
            1,
          );

          rows.add({
            'label': DateFormat('MMM yy').format(periodStart),
            'start': periodStart,
            'end': periodEnd,
            'amount': _sumExpenses(periodStart, periodEnd),
          });
        }
    }

    return rows;
  }

  double _sumExpenses(DateTime start, DateTime end) {
    return expenses.fold<double>(0, (sum, item) {
      final date = _date(item);

      if (date == null || date.isBefore(start) || !date.isBefore(end)) {
        return sum;
      }

      return sum + _amount(item);
    });
  }

  Color _categoryColor(int index) =>
      _categoryColors[index % _categoryColors.length];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text('Analytics'),
        backgroundColor: _background,
        foregroundColor: _text,
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        child: isLoading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 220),
                  Center(child: CircularProgressIndicator()),
                ],
              )
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  Showcase(
                    key: widget.analyticsKey,
                    title: 'Analytics dashboard',
                    description:
                        'Review your budget, spending, categories, and monthly records.',
                    targetBorderRadius: BorderRadius.circular(14),
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
                    child: _periodSelector(),
                  ),
                  const SizedBox(height: 20),
                  _sectionIntro(
                    'Spending & Budget',
                    'See how much you spent and the budget amounts recorded for this period.',
                  ),
                  const SizedBox(height: 10),
                  _overviewCard(),
                  const SizedBox(height: 22),
                  _sectionIntro(
                    'Where Your Money Goes',
                    'See which categories account for most of your spending.',
                  ),
                  const SizedBox(height: 10),
                  _categoryChartCard(),
                  const SizedBox(height: 22),
                  _sectionIntro(
                    'Spending Trend',
                    'Compare your recorded expenses by day, week, month, or year.',
                  ),
                  const SizedBox(height: 10),
                  _monthlyTrendCard(),
                  const SizedBox(height: 12),
                  _historicalRecordsButton(),
                  const SizedBox(height: 16),
                  _dataNote(),
                ],
              ),
      ),
    );
  }

  Widget _periodSelector() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insights_rounded, color: _accent),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analysis period',
                  style: TextStyle(
                    color: _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Choose a date range',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              dropdownColor: _card,
              style: TextStyle(color: _text, fontSize: 12),
              items: _periodOptions
                  .map(
                    (period) =>
                        DropdownMenuItem(value: period, child: Text(period)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => selectedPeriod = value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionIntro(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: _muted, height: 1.4, fontSize: 12),
        ),
      ],
    );
  }

  Widget _overviewCard() {
    final hasBudget = _budgetTotal > 0;

    final budgetPercentage = hasBudget
        ? (_totalSpent / _budgetTotal) * 100
        : 0.0;

    final budgetColor = !hasBudget
        ? _muted
        : budgetPercentage.floor() >= budgetReminder
        ? _red
        : budgetPercentage.floor() >= budgetReminder - 20
        ? _orange
        : _green;

    final previous = _previousPeriodTotal;
    final difference = previous == null ? null : _totalSpent - previous;
    final percentage = previous == null || previous <= 0
        ? null
        : difference! / previous * 100;

    final topCategory = _topCategory;
    final highestDay = _highestSpendingDay;

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedPeriod,
            style: TextStyle(
              color: _muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _bigMetric(
                  'Total spent',
                  _money.format(_totalSpent),
                  Icons.shopping_bag_outlined,
                  _accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _bigMetric(
                  'Budget recorded',
                  _money.format(_budgetTotal),
                  Icons.account_balance_wallet_outlined,
                  _green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: _softSurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _budgetRemaining < 0
                          ? Icons.warning_amber_rounded
                          : Icons.savings_outlined,
                      color: _budgetRemaining < 0 ? _red : _green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _budgetRemaining < 0
                            ? 'Spending exceeds recorded budget'
                            : 'Budget remaining',
                        style: TextStyle(
                          color: _text,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      _money.format(_budgetRemaining),
                      style: TextStyle(
                        color: _budgetRemaining < 0 ? _red : _green,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: hasBudget
                        ? (_totalSpent / _budgetTotal).clamp(0.0, 1.0)
                        : 0,
                    minHeight: 7,
                    backgroundColor: _gridColor,
                    valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  !hasBudget
                      ? 'No budget amount is recorded for this period.'
                      : _totalSpent > _budgetTotal
                      ? 'You have exceeded your budget by ${_money.format(_totalSpent - _budgetTotal)}.'
                      : '${budgetPercentage.toStringAsFixed(0)}% of recorded budget spent',
                  style: TextStyle(
                    color: !hasBudget
                        ? _muted
                        : _totalSpent > _budgetTotal
                        ? _red
                        : budgetColor,
                    fontSize: 10,
                    fontWeight: hasBudget && _totalSpent > _budgetTotal
                        ? FontWeight.w700
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: _border),
          const SizedBox(height: 10),
          Text(
            'Spending statistics',
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _smallMetric(
                  'Expenses',
                  '$_transactionCount',
                  Icons.receipt_long_outlined,
                ),
              ),
              Expanded(
                child: _smallMetric(
                  'Average per expense',
                  _money.format(_averageTransaction),
                  Icons.calculate_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _smallMetric(
                  'Average per day',
                  _money.format(_averagePerCalendarDay),
                  Icons.calendar_month_outlined,
                ),
              ),
              Expanded(
                child: _smallMetric(
                  'Days with spending',
                  '$_activeSpendingDays',
                  Icons.event_available_outlined,
                ),
              ),
            ],
          ),

          if (previous != null) ...[
            const SizedBox(height: 16),
            Divider(color: _border),
            const SizedBox(height: 10),
            _subsectionTitle(
              'Expenses compared to the previous period',
              Icons.compare_arrows_rounded,
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                // LEFT: Previous period
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _border.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Previous Period',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _money.format(previous),
                          style: TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _previousPeriodLabel ?? 'Previous period',
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // RIGHT: Current period
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _accent.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current Period',
                          style: TextStyle(
                            color: _accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _money.format(_totalSpent),
                          style: TextStyle(
                            color: _text,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _currentPeriodLabel,
                          style: TextStyle(color: _muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Expense difference and direction
            Builder(
              builder: (context) {
                final change = _totalSpent - previous;
                final increased = change > 0;
                final decreased = change < 0;
                final percentChange = previous > 0
                    ? (change / previous) * 100
                    : null;

                final changeColor = increased
                    ? _red
                    : decreased
                    ? _green
                    : _muted;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: changeColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            increased
                                ? Icons.trending_up_rounded
                                : decreased
                                ? Icons.trending_down_rounded
                                : Icons.horizontal_rule_rounded,
                            color: changeColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              increased
                                  ? 'Expense increased by'
                                  : decreased
                                  ? 'Expense decreased by'
                                  : 'No change in expenses',
                              style: TextStyle(
                                color: _text,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _money.format(change.abs()),
                        style: TextStyle(
                          color: changeColor,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (percentChange != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          '${percentChange.abs().toStringAsFixed(1)}% '
                          '${increased
                              ? 'increase'
                              : decreased
                              ? 'decrease'
                              : 'change'} compared with the previous period',
                          style: TextStyle(
                            color: changeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else if (_totalSpent > 0) ...[
                        const SizedBox(height: 3),
                        Text(
                          'No spending was recorded in the previous period.',
                          style: TextStyle(color: _muted, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],

          if (topCategory != null || highestDay != null) ...[
            const SizedBox(height: 16),
            Divider(color: _border),
            const SizedBox(height: 10),
            _subsectionTitle('Quick insights', Icons.lightbulb_outline_rounded),
            const SizedBox(height: 10),
            if (topCategory != null)
              _insightLine(
                'Highest category',
                '${topCategory.key} · ${_money.format(topCategory.value)}',
              ),
            if (highestDay != null)
              _insightLine(
                'Highest-spending day',
                '${DateFormat('MMM d, yyyy').format(DateTime.parse(highestDay.key))} · ${_money.format(highestDay.value)}',
              ),
          ],
          const SizedBox(height: 16),
          Divider(color: _border),
          const SizedBox(height: 10),
          _subsectionTitle('Largest expenses', Icons.receipt_long_outlined),
          const SizedBox(height: 5),
          Text(
            'Your three most expensive transactions.',
            style: TextStyle(color: _muted, fontSize: 11),
          ),
          const SizedBox(height: 5),
          if (_largestTransactions.isEmpty)
            const _EmptyState(message: 'No expenses recorded for this period.')
          else
            ..._largestTransactions.asMap().entries.map((entry) {
              final item = entry.value;
              final date = _date(item);
              final category = _expenseCategory(item);
              final description =
                  (item['title'] ?? item['name'] ?? item['description'] ?? '')
                      .toString();

              return _transactionRow(
                item: item,
                rank: entry.key + 1,
                title: description.isNotEmpty ? description : 'Expense',
                subtitle: date == null
                    ? '$category · Date unavailable'
                    : '$category · ${DateFormat('MMM d, yyyy').format(date)}',
              );
            }),
        ],
      ),
    );
  }

  Widget _bigMetric(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 9),
          Text(label, style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: _text,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallMetric(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(width: 7),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: _muted, fontSize: 10)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _insightLine(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.circle, size: 7, color: _accent),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: TextStyle(color: _text, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subsectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _accent),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _transactionRow({
    required Map<String, dynamic> item,
    required int rank,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _categoryColor(rank - 1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                color: _categoryColor(rank - 1),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: TextStyle(color: _muted, fontSize: 10)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money.format(_amount(item)),
            style: TextStyle(
              color: _text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryChartCard() {
    final totals = _categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final counts = _categoryCounts;

    return _panel(
      child: totals.isEmpty
          ? const _EmptyState(message: 'No expenses recorded for this period.')
          : Column(
              children: [
                SizedBox(
                  height: 210,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 34,
                            sections: totals.asMap().entries.map((entry) {
                              final amount = entry.value.value;
                              final share = _totalSpent == 0
                                  ? 0.0
                                  : amount / _totalSpent;

                              return PieChartSectionData(
                                value: amount,
                                color: _categoryColor(entry.key),
                                radius: 46,
                                title: share >= 0.07
                                    ? '${(share * 100).toStringAsFixed(0)}%'
                                    : '',
                                titleStyle: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 4,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: totals.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 5,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: _categoryColor(entry.key),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        entry.value.key,
                                        style: TextStyle(
                                          color: _text,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(color: _border, height: 26),
                ...totals.asMap().entries.map((entry) {
                  final index = entry.key;
                  final name = entry.value.key;
                  final amount = entry.value.value;
                  final share = _totalSpent == 0 ? 0.0 : amount / _totalSpent;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: _text,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              _money.format(amount),
                              style: TextStyle(
                                color: _text,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 7),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: share.clamp(0.0, 1.0),
                            minHeight: 7,
                            backgroundColor: _gridColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _categoryColor(index),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(share * 100).toStringAsFixed(1)}% of spending',
                              style: TextStyle(color: _muted, fontSize: 10),
                            ),
                            Text(
                              '${counts[name] ?? 0} transaction${(counts[name] ?? 0) == 1 ? '' : 's'}',
                              style: TextStyle(color: _muted, fontSize: 10),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  Widget _monthlyTrendCard() {
    final data = _spendingTrend;
    final maxValue = data.fold<double>(
      0,
      (maximum, item) => math.max(maximum, item['amount'] as double).toDouble(),
    );

    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Spending by ${selectedTrend.toLowerCase()}',
                  style: TextStyle(
                    color: _text,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedTrend,
                  isDense: true,
                  dropdownColor: _card,
                  borderRadius: BorderRadius.circular(12),
                  style: TextStyle(color: _text, fontSize: 11),
                  items: _trendOptions.map((option) {
                    return DropdownMenuItem(value: option, child: Text(option));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedTrend = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            'Compare your recorded expenses across different time periods.',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 12),
          if (maxValue <= 0)
            const _EmptyState(
              message: 'There is not enough expense data to show a trend yet.',
            )
          else
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxValue / 4 > 0 ? maxValue / 4 : 1,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: _gridColor, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Text(
                            _compactMoney(value),
                            style: TextStyle(color: _muted, fontSize: 9),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index]['label'] as String,
                              style: TextStyle(color: _muted, fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final index = spot.x.toInt();

                        if (index < 0 || index >= data.length) {
                          return null;
                        }

                        final start = data[index]['start'] as DateTime;
                        final end = data[index]['end'] as DateTime;

                        String periodLabel;

                        if (selectedTrend == 'Weekly') {
                          periodLabel =
                              '${DateFormat('MMM d').format(start)} – '
                              '${DateFormat('MMM d, yyyy').format(end.subtract(const Duration(days: 1)))}';
                        } else if (selectedTrend == 'Monthly') {
                          periodLabel = DateFormat('MMMM yyyy').format(start);
                        } else if (selectedTrend == 'Yearly') {
                          periodLabel = DateFormat('yyyy').format(start);
                        } else if (selectedTrend == 'Daily') {
                          periodLabel = DateFormat(
                            'MMMM d, yyyy',
                          ).format(start);
                        } else {
                          periodLabel = DateFormat('MMMM yyyy').format(start);
                        }

                        return LineTooltipItem(
                          '$periodLabel\n${_money.format(spot.y)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((entry) {
                        return FlSpot(
                          entry.key.toDouble(),
                          entry.value['amount'] as double,
                        );
                      }).toList(),
                      isCurved: false,
                      color: _accent,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: _accent.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000000) {
      return '₱${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return '₱${(value / 1000).toStringAsFixed(1)}k';
    }
    return '₱${value.toStringAsFixed(0)}';
  }

  Widget _historicalRecordsButton() {
    return Material(
      color: _card,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: _showHistoricalRecords,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.calendar_month_rounded, color: _accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Browse Monthly Records',
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View monthly spending, budgets, and categories.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: _muted),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showHistoricalRecords() async {
    final now = DateTime.now();
    var selectedMonth = now.month;
    var selectedYear = now.year;

    final years = <int>{
      now.year,
      ...expenses.map(_date).whereType<DateTime>().map((d) => d.year),
      ...budgets.map(_date).whereType<DateTime>().map((d) => d.year),
    }.toList()..sort((a, b) => b.compareTo(a));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final start = DateTime(selectedYear, selectedMonth, 1);
            final end = DateTime(selectedYear, selectedMonth + 1, 1);

            final monthExpenses =
                expenses.where((item) {
                  final date = _date(item);
                  return date != null &&
                      !date.isBefore(start) &&
                      date.isBefore(end);
                }).toList()..sort((a, b) {
                  final dateA = _date(a);
                  final dateB = _date(b);
                  if (dateA == null) return 1;
                  if (dateB == null) return -1;
                  return dateB.compareTo(dateA);
                });

            final monthBudgets =
                budgets.where((item) {
                  final date = _date(item);
                  return date != null &&
                      !date.isBefore(start) &&
                      date.isBefore(end);
                }).toList()..sort((a, b) {
                  final dateA = _date(a);
                  final dateB = _date(b);
                  if (dateA == null) return 1;
                  if (dateB == null) return -1;
                  return dateB.compareTo(dateA);
                });

            final spent = monthExpenses.fold<double>(
              0,
              (sum, item) => sum + _amount(item),
            );

            final previousMonthDate = DateTime(
              selectedYear,
              selectedMonth - 1,
              1,
            );

            final previousMonthEnd = DateTime(
              previousMonthDate.year,
              previousMonthDate.month + 1,
              1,
            );

            final previousMonthExpenses = expenses.where((item) {
              final date = _date(item);

              if (date == null) return false;

              return !date.isBefore(previousMonthDate) &&
                  date.isBefore(previousMonthEnd);
            }).toList();

            final previousSpent = previousMonthExpenses.fold<double>(
              0,
              (sum, item) => sum + _amount(item),
            );

            final expenseDifference = spent - previousSpent;

            final expensePercentage = previousSpent == 0
                ? null
                : (expenseDifference / previousSpent) * 100;

            final budgetTotal = monthBudgets.fold<double>(
              0,
              (sum, item) => sum + _amount(item),
            );

            final spendingDays = monthExpenses
                .map(_date)
                .whereType<DateTime>()
                .map((date) => DateFormat('yyyy-MM-dd').format(date))
                .toSet()
                .length;

            return SafeArea(
              child: FractionallySizedBox(
                heightFactor: 0.90,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 4, 18, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Monthly Records',
                            style: TextStyle(
                              color: _text,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Choose a month to explore its saved records.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: DropdownButtonFormField<int>(
                                  value: selectedMonth,
                                  isExpanded: true,
                                  isDense: true,
                                  dropdownColor: _card,
                                  style: TextStyle(color: _text, fontSize: 12),
                                  decoration: _dropdownDecoration('Month'),
                                  items: List.generate(12, (index) {
                                    final month = index + 1;
                                    return DropdownMenuItem(
                                      value: month,
                                      child: Text(
                                        DateFormat(
                                          'MMMM',
                                        ).format(DateTime(2000, month)),
                                        style: TextStyle(
                                          color: _text,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setSheetState(
                                        () => selectedMonth = value,
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<int>(
                                  value: selectedYear,
                                  isExpanded: true,
                                  isDense: true,
                                  dropdownColor: _card,
                                  style: TextStyle(color: _text, fontSize: 12),
                                  decoration: _dropdownDecoration('Year'),
                                  items: years.map((year) {
                                    return DropdownMenuItem(
                                      value: year,
                                      child: Text(
                                        '$year',
                                        style: TextStyle(
                                          color: _text,
                                          fontSize: 12,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setSheetState(() => selectedYear = value);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(start),
                            style: TextStyle(
                              color: _text,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 1.65,
                            children: [
                              _historicalMetric(
                                'Total spent',
                                _money.format(spent),
                                Icons.payments_outlined,
                                _accent,
                              ),
                              _historicalMetric(
                                'Budget recorded',
                                _money.format(budgetTotal),
                                Icons.savings_outlined,
                                _green,
                              ),
                              _historicalMetric(
                                'Expenses',
                                '${monthExpenses.length}',
                                Icons.receipt_long_outlined,
                                const Color(0xFF3B82F6),
                              ),
                              _historicalMetric(
                                'Spending days',
                                '$spendingDays',
                                Icons.event_available_outlined,
                                _orange,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _card,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: _border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Text(
                                  'Expense Comparison',
                                  style: TextStyle(
                                    color: _text,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Current and previous month totals
                                Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _background,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(color: _border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Previous month',
                                              style: TextStyle(
                                                color: _muted,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _money.format(previousSpent),
                                              style: TextStyle(
                                                color: _text,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(width: 10),

                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _background,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(color: _border),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Selected month',
                                              style: TextStyle(
                                                color: _muted,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              _money.format(spent),
                                              style: TextStyle(
                                                color: _text,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 14),

                                // Clear spending change indicator
                                Builder(
                                  builder: (context) {
                                    final bool increased =
                                        expenseDifference > 0;
                                    final bool decreased =
                                        expenseDifference < 0;
                                    final bool unchanged =
                                        expenseDifference == 0;

                                    final Color changeColor = increased
                                        ? Colors.red
                                        : decreased
                                        ? Colors.green
                                        : _muted;

                                    final IconData changeIcon = increased
                                        ? Icons.trending_up
                                        : decreased
                                        ? Icons.trending_down
                                        : Icons.trending_flat;

                                    final String changeLabel = increased
                                        ? 'Spending increased'
                                        : decreased
                                        ? 'Spending decreased'
                                        : 'No change in spending';

                                    final String percentageText =
                                        previousSpent == 0
                                        ? (spent == 0 ? '0.0%' : 'N/A')
                                        : '${expensePercentage! > 0 ? '+' : ''}'
                                              '${expensePercentage.toStringAsFixed(1)}%';

                                    return Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(14),
                                      decoration: BoxDecoration(
                                        color: changeColor.withValues(
                                          alpha: 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: changeColor.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                changeIcon,
                                                color: changeColor,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  changeLabel,
                                                  style: TextStyle(
                                                    color: changeColor,
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Amount changed',
                                                      style: TextStyle(
                                                        color: _muted,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${increased
                                                          ? '+'
                                                          : decreased
                                                          ? '-'
                                                          : ''}'
                                                      '${_money.format(expenseDifference.abs())}',
                                                      style: TextStyle(
                                                        color: changeColor,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Container(
                                                width: 1,
                                                height: 38,
                                                color: _border,
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Percentage change',
                                                      style: TextStyle(
                                                        color: _muted,
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      percentageText,
                                                      style: TextStyle(
                                                        color: changeColor,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (previousSpent == 0 &&
                                              spent > 0) ...[
                                            const SizedBox(height: 10),
                                            Text(
                                              'No expenses were recorded in the previous month, '
                                              'so the percentage change cannot be calculated.',
                                              style: TextStyle(
                                                color: _muted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Expense transactions remain collapsible.
                          _expandableSection(
                            title: 'Expense Transactions',
                            subtitle:
                                '${monthExpenses.length} transactions · ${_money.format(spent)}',
                            icon: Icons.receipt_long_outlined,
                            initiallyExpanded: true,
                            child: monthExpenses.isEmpty
                                ? const _EmptyState(
                                    message:
                                        'No expenses were recorded this month.',
                                  )
                                : Column(
                                    children: monthExpenses.map((item) {
                                      final date = _date(item);
                                      final category = _expenseCategory(item);
                                      final description =
                                          (item['title'] ??
                                                  item['name'] ??
                                                  item['description'] ??
                                                  '')
                                              .toString();

                                      final categoryIcon = IconData(
                                        (item['categoryIcon'] as num?)
                                                ?.toInt() ??
                                            Icons.category.codePoint,
                                        fontFamily: 'MaterialIcons',
                                      );

                                      return _monthlyTransactionRow(
                                        title: description.isNotEmpty
                                            ? description
                                            : 'Expense',
                                        category: category,
                                        date: date,
                                        amount: _amount(item),
                                        icon: categoryIcon,
                                      );
                                    }).toList(),
                                  ),
                          ),

                          const SizedBox(height: 12),

                          // Budget records are displayed as a flat list,
                          // matching the expense transaction layout.
                          _expandableSection(
                            title: 'Budget Records',
                            subtitle:
                                '${monthBudgets.length} records · ${_money.format(budgetTotal)}',
                            icon: Icons.savings_outlined,
                            initiallyExpanded: true,
                            child: monthBudgets.isEmpty
                                ? const _EmptyState(
                                    message:
                                        'No budget records were created this month.',
                                  )
                                : Column(
                                    children: monthBudgets.map((item) {
                                      final date = _date(item);

                                      return _monthlyBudgetRow(
                                        category: 'Budget Record',
                                        date: date,
                                        amount: _amount(item),
                                        icon: Icons.savings_outlined,
                                      );
                                    }).toList(),
                                  ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Budget totals represent records created during the selected month. They may not represent the budget that was active throughout that month.',
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _dropdownDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _muted, fontSize: 11),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: _border),
      ),
    );
  }

  Widget _expandableSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
    bool initiallyExpanded = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 13),
          childrenPadding: const EdgeInsets.fromLTRB(13, 0, 13, 12),
          iconColor: _accent,
          collapsedIconColor: _muted,
          leading: Icon(icon, color: _accent, size: 21),
          title: Text(
            title,
            style: TextStyle(
              color: _text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(color: _muted, fontSize: 10),
          ),
          children: [child],
        ),
      ),
    );
  }

  Widget _monthlyTransactionRow({
    required String title,
    required String category,
    required DateTime? date,
    required double amount,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _red, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$category · ${date == null ? 'Date unavailable' : DateFormat('MMM d, yyyy').format(date)}',
                  style: TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money.format(amount),
            style: TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _monthlyBudgetRow({
    required String category,
    required DateTime? date,
    required double amount,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _green, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  date == null
                      ? 'Date unavailable'
                      : DateFormat('MMM d, yyyy').format(date),
                  style: TextStyle(color: _muted, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _money.format(amount),
            style: TextStyle(
              color: _text,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _historicalMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _softSurface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: _muted, fontSize: 10)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: _text,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _isDark ? const Color(0xFF302A20) : const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _isDark ? const Color(0xFF55472D) : const Color(0xFFF4E5BD),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFF946200),
            size: 19,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Analytics uses your saved records. Budget amounts are grouped by the records created within the selected period. The remaining amount is calculated from those recorded budgets and expenses, so it may not reflect the currently active budget.',
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: Color(0xFF946200),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: child,
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? const Color(0xFF2A2538)
        : const Color(0xFFFAFAFD);
    final muted = isDark ? const Color(0xFFB7B2C8) : const Color(0xFF6F6B82);
    final subtle = isDark ? const Color(0xFF928BA8) : const Color(0xFF8B8798);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.insert_chart_outlined_rounded, size: 30, color: subtle),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
