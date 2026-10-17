import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
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
  static const Color _orange = Color(0xFFF59E0B);
  static const Color _green = Color(0xFF159A75);
  static const Color _red = Color(0xFFE05252);

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _background =>
      _isDark ? const Color(0xFF15131E) : const Color(0xFFF7F7FB);
  Color get _card => _isDark ? const Color(0xFF211D2D) : Colors.white;
  Color get _text =>
      _isDark ? const Color(0xFFF5F2FF) : const Color(0xFF29263A);
  Color get _muted =>
      _isDark ? const Color(0xFFB7B2C8) : const Color(0xFF6F6B82);
  Color get _subtle =>
      _isDark ? const Color(0xFF928BA8) : const Color(0xFF8B8798);
  Color get _border =>
      _isDark ? const Color(0xFF393246) : const Color(0xFFE7E4F0);
  Color get _softSurface =>
      _isDark ? const Color(0xFF2A2538) : const Color(0xFFFAFAFD);
  Color get _softPurple =>
      _isDark ? const Color(0xFF302844) : const Color(0xFFF6F4FC);
  Color get _accent => _isDark ? const Color(0xFFB9A8FF) : _primary;
  Color get _gridColor =>
      _isDark ? const Color(0xFF393246) : const Color(0xFFECEAF3);

  final NumberFormat _money = NumberFormat.currency(
    locale: 'en_PH',
    symbol: '₱',
    decimalDigits: 2,
  );

  String selectedPeriod = 'This Month';
  bool isLoading = true;
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> budgets = [];

  final List<String> _periodOptions = const [
    'This Month',
    'Past 3 Months',
    'Past 6 Months',
    'Past 12 Months',
    'All Time',
  ];

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
      ]);

      if (!mounted) return;

      setState(() {
        expenses = List<Map<String, dynamic>>.from(results[0] as List);
        budgets = List<Map<String, dynamic>>.from(results[1] as List);
        isLoading = false;
      });
    } catch (error) {
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

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
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

  DateTime get _periodEndExclusive {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
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

  List<Map<String, dynamic>> get _periodExpenses {
    final start = _periodStart;
    return expenses.where((item) {
      final date = _date(item);
      if (date == null) return false;
      return (start == null || !date.isBefore(start)) &&
          date.isBefore(_periodEndExclusive);
    }).toList();
  }

  List<Map<String, dynamic>> get _periodBudgets {
    final start = _periodStart;
    return budgets.where((item) {
      final date = _date(item);
      if (date == null) return false;
      return (start == null || !date.isBefore(start)) &&
          date.isBefore(_periodEndExclusive);
    }).toList();
  }

  double get _totalSpent =>
      _periodExpenses.fold(0.0, (sum, item) => sum + _amount(item));

  int get _transactionCount => _periodExpenses.length;

  Map<String, double> get _categoryTotals {
    final totals = <String, double>{};
    for (final item in _periodExpenses) {
      final category = (item['category'] ?? 'Others').toString();
      totals[category] = (totals[category] ?? 0) + _amount(item);
    }
    return totals;
  }

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{};
    for (final item in _periodExpenses) {
      final category = (item['category'] ?? 'Others').toString();
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
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

  Map<int, double> get _weekdayTotals {
    final totals = <int, double>{for (int day = 1; day <= 7; day++) day: 0};
    for (final item in _periodExpenses) {
      final date = _date(item);
      if (date == null) continue;
      totals[date.weekday] = (totals[date.weekday] ?? 0) + _amount(item);
    }
    return totals;
  }

  List<Map<String, dynamic>> get _sortedCategories {
    final totals = _categoryTotals;
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .map(
          (entry) => {
            'category': entry.key,
            'amount': entry.value,
            'count': _categoryCounts[entry.key] ?? 0,
          },
        )
        .toList();
  }

  List<Map<String, dynamic>> get _largestTransactions {
    final rows = List<Map<String, dynamic>>.from(_periodExpenses)
      ..sort((a, b) => _amount(b).compareTo(_amount(a)));
    return rows.take(5).toList();
  }

  double get _averageTransaction =>
      _transactionCount == 0 ? 0 : _totalSpent / _transactionCount;

  int get _activeSpendingDays => _dailyTotals.length;

  double get _averageActiveDay =>
      _activeSpendingDays == 0 ? 0 : _totalSpent / _activeSpendingDays;

  double get _averageCalendarDay {
    if (_periodExpenses.isEmpty) return 0;
    final start =
        _periodStart ??
        _date(
          _periodExpenses.reduce(
            (a, b) => _date(a)!.isBefore(_date(b)!) ? a : b,
          ),
        )!;
    final end = _today.isBefore(_periodEndExclusive)
        ? _today
        : _periodEndExclusive.subtract(const Duration(days: 1));
    final days =
        end.difference(DateTime(start.year, start.month, start.day)).inDays + 1;
    return days <= 0 ? 0 : _totalSpent / days;
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

  MapEntry<int, double>? get _highestSpendingWeekday {
    final entries = _weekdayTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.isEmpty || entries.first.value <= 0 ? null : entries.first;
  }

  double get _highestTransaction =>
      _largestTransactions.isEmpty ? 0 : _amount(_largestTransactions.first);

  double get _lowestTransaction {
    if (_periodExpenses.isEmpty) return 0;
    return _periodExpenses
        .map(_amount)
        .reduce((a, b) => math.min(a, b).toDouble());
  }

  double get _recordedBudgetTotal =>
      _periodBudgets.fold(0.0, (sum, item) => sum + _amount(item));

  double? get _previousPeriodTotal {
    final months = _periodMonthCount;
    final start = _periodStart;
    if (months == null || start == null) return null;

    final previousStart = DateTime(start.year, start.month - months, 1);
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

  List<Map<String, dynamic>> get _monthlyTrend {
    final now = DateTime.now();
    final rows = <Map<String, dynamic>>[];
    for (int offset = 5; offset >= 0; offset--) {
      final month = DateTime(now.year, now.month - offset, 1);
      final nextMonth = DateTime(month.year, month.month + 1, 1);
      var total = 0.0;
      for (final item in expenses) {
        final date = _date(item);
        if (date != null && !date.isBefore(month) && date.isBefore(nextMonth)) {
          total += _amount(item);
        }
      }
      rows.add({
        'label': DateFormat('MMM').format(month),
        'month': month,
        'amount': total,
      });
    }
    return rows;
  }

  DateTime get _currentMonthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get _nextMonthStart {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1);
  }

  List<Map<String, dynamic>> get _currentMonthExpenses =>
      expenses.where((item) {
        final date = _date(item);
        return date != null &&
            !date.isBefore(_currentMonthStart) &&
            date.isBefore(_nextMonthStart);
      }).toList();

  double get _currentMonthSpent =>
      _currentMonthExpenses.fold<double>(0, (sum, item) => sum + _amount(item));

  int get _daysInCurrentMonth =>
      DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

  double get _currentMonthDailyPace {
    final elapsedDays = DateTime.now().day;
    return elapsedDays <= 0 ? 0 : _currentMonthSpent / elapsedDays;
  }

  double get _monthEndPaceEstimate =>
      _currentMonthDailyPace * _daysInCurrentMonth;

  List<double> get _currentMonthActiveDayTotals {
    final totals = <String, double>{};
    for (final item in _currentMonthExpenses) {
      final date = _date(item);
      if (date == null) continue;
      final key = DateFormat('yyyy-MM-dd').format(date);
      totals[key] = (totals[key] ?? 0) + _amount(item);
    }
    return totals.values.toList();
  }

  double get _activeDaySpendingStdDev {
    final values = _currentMonthActiveDayTotals;
    if (values.length < 2) return 0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values
            .map((value) => math.pow(value - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        values.length;
    return math.sqrt(variance);
  }

  String get _variabilityDescription {
    final values = _currentMonthActiveDayTotals;
    if (values.length < 2)
      return 'Add expenses on more days to compare day-to-day variation.';
    final mean = values.reduce((a, b) => a + b) / values.length;
    if (mean <= 0)
      return 'There is not enough recorded spending to compare daily variation.';
    final coefficient = _activeDaySpendingStdDev / mean * 100;
    if (coefficient < 25) {
      return 'Recorded spending on active days has been relatively consistent this month.';
    }
    if (coefficient < 60) {
      return 'Recorded spending varies moderately from one active day to another this month.';
    }
    return 'Recorded spending varies considerably across active days this month.';
  }

  String _weekdayName(int weekday) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[weekday - 1];
  }

  Color _categoryColor(int index) {
    const colors = [
      Color(0xFF5B45B5),
      Color(0xFFF59E0B),
      Color(0xFF159A75),
      Color(0xFF3B82F6),
      Color(0xFFEC4899),
      Color(0xFF64748B),
      Color(0xFF14B8A6),
      Color(0xFF8B5CF6),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final categories = _sortedCategories;
    final topCategory = _topCategory;
    final highestDay = _highestSpendingDay;
    final previousTotal = _previousPeriodTotal;
    final monthlyTrend = _monthlyTrend;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text('Analytics'),
        centerTitle: false,
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
                        'Explore spending totals, category patterns, daily activity, monthly trends, and recorded budget information.',
                    targetBorderRadius: BorderRadius.circular(14),
                    overlayOpacity: 0.65,
                    tooltipBackgroundColor: _primary,
                    tooltipBorderRadius: BorderRadius.circular(16),
                    tooltipPadding: const EdgeInsets.all(16),
                    textColor: Colors.white,
                    titleTextStyle: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    descTextStyle: TextStyle(
                      fontSize: 14,
                      height: 1.4,
                      color: Colors.white,
                    ),
                    child: _periodSelector(),
                  ),
                  const SizedBox(height: 18),
                  _sectionIntro(
                    'Your spending summary',
                    'Here is a summary of the expenses you recorded for ${selectedPeriod.toLowerCase()}.',
                  ),
                  const SizedBox(height: 12),
                  _summaryGrid(),
                  const SizedBox(height: 22),
                  _insightsCard(topCategory, highestDay, previousTotal),
                  const SizedBox(height: 22),
                  _sectionIntro(
                    'How your spending changes over time',
                    'Compare each month to see when you spent more or less.',
                  ),
                  const SizedBox(height: 10),
                  _monthlyTrendCard(monthlyTrend),
                  const SizedBox(height: 14),
                  _paceAndConsistencyCard(),
                  const SizedBox(height: 22),
                  _sectionIntro(
                    'What you spend money on',
                    'See which categories take up the biggest part of your spending.',
                  ),
                  const SizedBox(height: 10),
                  _categoryChartCard(categories),
                  const SizedBox(height: 22),
                  _sectionIntro(
                    'Spending by day of week',
                    'Identify the days when your recorded expenses tend to be higher.',
                  ),
                  const SizedBox(height: 10),
                  _weekdayCard(),
                  const SizedBox(height: 22),
                  _sectionIntro(
                    'Transaction details',
                    'Review your largest recorded expenses in this period.',
                  ),
                  const SizedBox(height: 10),
                  _largestTransactionsCard(),
                  const SizedBox(height: 22),
                  _sectionIntro(
                    'Budget records',
                    'A summary of budget entries created during the selected period.',
                  ),
                  const SizedBox(height: 10),
                  _budgetRecordsCard(),
                  const SizedBox(height: 16),
                  _dataNote(),
                ],
              ),
      ),
    );
  }

  Widget _periodSelector() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.insights_rounded, color: _accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analysis period',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 3),
                Text(
                  'Change the data range',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedPeriod,
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              items: _periodOptions
                  .map(
                    (period) => DropdownMenuItem(
                      value: period,
                      child: Text(period, style: TextStyle(fontSize: 12)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedPeriod = value);
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: TextStyle(color: _muted, height: 1.35, fontSize: 12),
        ),
      ],
    );
  }

  Widget _summaryGrid() {
    final tiles = [
      _MetricData(
        label: 'Total spent',
        value: _money.format(_totalSpent),
        helper: 'All expenses entered in this period',
        icon: Icons.account_balance_wallet_outlined,
        color: _accent,
      ),
      _MetricData(
        label: 'Expenses recorded',
        value: '$_transactionCount',
        helper: 'Number of expenses you entered',
        icon: Icons.receipt_long_outlined,
        color: const Color(0xFF3B82F6),
      ),
      _MetricData(
        label: 'Average amount per expense',
        value: _money.format(_averageTransaction),
        helper: 'Total spent divided by number of expenses',
        icon: Icons.calculate_outlined,
        color: _green,
      ),
      _MetricData(
        label: 'Average spent per day',
        value: _money.format(_averageCalendarDay),
        helper: 'Total spent divided by days in this period',
        icon: Icons.calendar_month_outlined,
        color: _orange,
      ),
      _MetricData(
        label: 'Days you spent money',
        value: '$_activeSpendingDays',
        helper: 'Days with at least one recorded expense',
        icon: Icons.event_available_outlined,
        color: const Color(0xFF0F766E),
      ),
      _MetricData(
        label: 'Most expensive purchase',
        value: _money.format(_highestTransaction),
        helper: 'Your largest individual expense',
        icon: Icons.trending_up_rounded,
        color: _red,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 650 ? 3 : 2;
        final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: tiles
              .map((tile) => SizedBox(width: width, child: _metricCard(tile)))
              .toList(),
        );
      },
    );
  }

  Widget _metricCard(_MetricData data) {
    return Container(
      constraints: const BoxConstraints(minHeight: 132),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, color: data.color, size: 19),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(data.label, style: TextStyle(color: _muted, fontSize: 11)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              data.value,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 3),
          Text(data.helper, style: TextStyle(color: _subtle, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _insightsCard(
    MapEntry<String, double>? topCategory,
    MapEntry<String, double>? highestDay,
    double? previousTotal,
  ) {
    final insights = <_InsightData>[];

    if (topCategory != null && _totalSpent > 0) {
      final share = topCategory.value / _totalSpent * 100;
      insights.add(
        _InsightData(
          icon: Icons.pie_chart_outline_rounded,
          color: _accent,
          title: 'Category you spent the most on',
          text:
              '${topCategory.key} accounts for ${share.toStringAsFixed(1)}% of recorded spending (${_money.format(topCategory.value)}).',
        ),
      );
    }

    if (previousTotal != null) {
      if (previousTotal == 0 && _totalSpent > 0) {
        insights.add(
          _InsightData(
            icon: Icons.compare_arrows_rounded,
            color: _orange,
            title: 'Spending comparison',
            text:
                'There is no spending recorded in the previous comparison period, so a percentage change cannot be calculated.',
          ),
        );
      } else if (previousTotal > 0) {
        final difference = _totalSpent - previousTotal;
        final percentage = difference / previousTotal * 100;
        insights.add(
          _InsightData(
            icon: difference > 0
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: difference > 0 ? _red : _green,
            title: 'Compared with the previous period',
            text: difference == 0
                ? 'You spent the same amount as in the previous ${_periodMonthCount}-month period.'
                : 'You spent ${_money.format(difference.abs())} (${percentage.abs().toStringAsFixed(1)}%) ${difference > 0 ? 'more' : 'less'} than in the previous ${_periodMonthCount}-month period.',
          ),
        );
      } else {
        insights.add(
          _InsightData(
            icon: Icons.compare_arrows_rounded,
            color: _green,
            title: 'Spending comparison',
            text: 'No spending was recorded in either comparison period.',
          ),
        );
      }
    }

    if (highestDay != null) {
      insights.add(
        _InsightData(
          icon: Icons.calendar_today_outlined,
          color: _orange,
          title: 'Day you spent the most',
          text:
              '${DateFormat('MMM d, yyyy').format(DateTime.parse(highestDay.key))} has the highest recorded daily total at ${_money.format(highestDay.value)}.',
        ),
      );
    }

    final highestWeekday = _highestSpendingWeekday;
    if (highestWeekday != null) {
      insights.add(
        _InsightData(
          icon: Icons.date_range_rounded,
          color: _green,
          title: 'Weekday you spent the most',
          text:
              '${_weekdayName(highestWeekday.key)} has the highest combined spending across the selected period (${_money.format(highestWeekday.value)}).',
        ),
      );
    }

    return _panel(
      title: 'What your spending shows',
      subtitle: 'Simple observations based only on the expenses you entered.',
      child: insights.isEmpty
          ? const _EmptyState(
              message: 'Add expenses to generate spending insights.',
            )
          : Column(
              children: insights
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: item.color.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(item.icon, color: item.color, size: 19),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  item.text,
                                  style: TextStyle(
                                    color: _muted,
                                    height: 1.4,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _monthlyTrendCard(List<Map<String, dynamic>> data) {
    final maxValue = data.fold<double>(
      0,
      (max, item) => math.max(max, item['amount'] as double).toDouble(),
    );

    return _panel(
      title: 'Spending by month',
      subtitle:
          'Each dot shows the total you spent that month. An upward line means you spent more; a month at ₱0 means no expenses were recorded.',
      child: data.every((item) => (item['amount'] as double) == 0)
          ? const _EmptyState(
              message: 'There is not enough expense data to show a trend yet.',
            )
          : SizedBox(
              height: 230,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxValue <= 0 ? 100 : maxValue * 1.2,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) =>
                        FlLine(color: _gridColor, strokeWidth: 1),
                    horizontalInterval: maxValue <= 0 ? 20 : maxValue / 4,
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
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: Text(
                            _compactMoney(value),
                            style: TextStyle(fontSize: 9, color: _muted),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= data.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index]['label'] as String,
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((spot) {
                        final label = data[spot.x.toInt()]['label'] as String;
                        return LineTooltipItem(
                          '$label\n${_money.format(spot.y)}',
                          TextStyle(
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
                      spots: data
                          .asMap()
                          .entries
                          .map(
                            (entry) => FlSpot(
                              entry.key.toDouble(),
                              entry.value['amount'] as double,
                            ),
                          )
                          .toList(),
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
    );
  }

  String _compactMoney(double value) {
    if (value >= 1000000) return '₱${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '₱${(value / 1000).toStringAsFixed(1)}k';
    return '₱${value.toStringAsFixed(0)}';
  }

  Widget _paceAndConsistencyCard() {
    final month = DateFormat('MMMM yyyy').format(DateTime.now());
    final elapsedDays = DateTime.now().day;
    final activeDays = _currentMonthActiveDayTotals.length;
    final estimateAvailable =
        _currentMonthExpenses.isNotEmpty && elapsedDays > 0;

    return _panel(
      title: 'This month’s spending pace',
      subtitle:
          'Shows what you have spent so far and estimates the month-end total if you keep spending at the same daily rate.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _isDark
                    ? const Color(0xFF4A3D68)
                    : const Color(0xFFE9E4FA),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.speed_rounded, color: _accent, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$month pace estimate',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      '$elapsedDays/$_daysInCurrentMonth days',
                      style: TextStyle(fontSize: 10, color: _muted),
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: _paceMetric(
                        'Recorded so far',
                        _money.format(_currentMonthSpent),
                        Icons.receipt_long_outlined,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _paceMetric(
                        'Daily average',
                        _money.format(_currentMonthDailyPace),
                        Icons.today_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.timeline_rounded, color: _accent, size: 19),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Estimated total by the end of the month',
                              style: TextStyle(fontSize: 11, color: _muted),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              estimateAvailable
                                  ? _money.format(_monthEndPaceEstimate)
                                  : 'Not available yet',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: _accent,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'This is an estimate based on your spending so far, not a guaranteed result or your remaining budget.',
                              style: TextStyle(
                                fontSize: 10,
                                height: 1.35,
                                color: _muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _consistencyMetric(
                  label: 'Days you spent money',
                  value: '$activeDays',
                  helper: 'Days with at least one recorded expense this month',
                  icon: Icons.event_available_outlined,
                  color: _green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _consistencyMetric(
                  label: 'Changes between spending days',
                  value: activeDays < 2
                      ? '—'
                      : _money.format(_activeDaySpendingStdDev),
                  helper:
                      'A higher amount means the amounts you spend on different days vary more',
                  icon: Icons.show_chart_rounded,
                  color: _orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.insights_outlined, size: 18, color: _accent),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _variabilityDescription,
                  style: TextStyle(fontSize: 11, color: _text, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _paceMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: _primary),
          const SizedBox(height: 7),
          Text(label, style: TextStyle(fontSize: 10, color: _muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _consistencyMetric({
    required String label,
    required String value,
    required String helper,
    required IconData icon,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 19),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 10, color: _muted)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            helper,
            style: TextStyle(fontSize: 9, color: _subtle, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _categoryChartCard(List<Map<String, dynamic>> categories) {
    final total = _totalSpent;
    final pieCategories = categories.take(5).toList();
    final otherTotal = categories
        .skip(5)
        .fold<double>(0, (sum, item) => sum + (item['amount'] as double));

    if (otherTotal > 0) {
      pieCategories.add({
        'category': 'Other categories',
        'amount': otherTotal,
        'count': 0,
      });
    }

    return _panel(
      title: 'Spending by category',
      subtitle:
          'See how much you spent in each category, its share of your total, and how many expenses you recorded.',
      child: categories.isEmpty
          ? const _EmptyState(
              message: 'No categorized expenses are available for this period.',
            )
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
                            centerSpaceRadius: 38,
                            sections: pieCategories.asMap().entries.map((
                              entry,
                            ) {
                              final amount = entry.value['amount'] as double;
                              final share = total == 0
                                  ? 0.0
                                  : amount / total * 100;
                              return PieChartSectionData(
                                value: amount,
                                color: _categoryColor(entry.key),
                                radius: 48,
                                title: share >= 7
                                    ? '${share.toStringAsFixed(0)}%'
                                    : '',
                                titleStyle: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 4,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: pieCategories.asMap().entries.map((entry) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
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
                                      entry.value['category'] as String,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: _text,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 24, color: _border),
                ...categories.asMap().entries.map((entry) {
                  final item = entry.value;
                  final category = item['category'] as String;
                  final amount = item['amount'] as double;
                  final count = item['count'] as int;
                  final share = total == 0 ? 0.0 : amount / total;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                category,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              _money.format(amount),
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
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
                            valueColor: AlwaysStoppedAnimation(
                              _categoryColor(entry.key),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(share * 100).toStringAsFixed(1)}% of spending',
                              style: TextStyle(fontSize: 10, color: _muted),
                            ),
                            Text(
                              '$count transaction${count == 1 ? '' : 's'}',
                              style: TextStyle(fontSize: 10, color: _muted),
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

  Widget _weekdayCard() {
    final totals = _weekdayTotals;
    final maxValue = totals.values.fold<double>(
      0,
      (max, value) => math.max(max, value).toDouble(),
    );
    final dataExists = maxValue > 0;

    return _panel(
      title: 'Spending by day of the week',
      subtitle:
          'Adds up your expenses by weekday across this period. It does not mean you spent that amount every Monday.',
      child: !dataExists
          ? const _EmptyState(
              message: 'Add expense records to compare weekdays.',
            )
          : SizedBox(
              height: 230,
              child: BarChart(
                BarChartData(
                  maxY: maxValue * 1.25,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                          BarTooltipItem(
                            '${_weekdayName(group.x + 1)}\n${_money.format(rod.toY)}',
                            TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
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
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) => Text(
                          _compactMoney(value),
                          style: TextStyle(fontSize: 9, color: _muted),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 26,
                        getTitlesWidget: (value, meta) {
                          final day = value.toInt() + 1;
                          if (day < 1 || day > 7)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _weekdayName(day),
                              style: TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(7, (index) {
                    final value = totals[index + 1] ?? 0;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: value,
                          width: 20,
                          color: _categoryColor(index),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
    );
  }

  Widget _largestTransactionsCard() {
    final rows = _largestTransactions;
    return _panel(
      title: 'Your five biggest expenses',
      subtitle:
          'The five individual expenses with the highest amounts in this period.',
      child: rows.isEmpty
          ? const _EmptyState(
              message: 'No expense transactions found for this period.',
            )
          : Column(
              children: rows.asMap().entries.map((entry) {
                final item = entry.value;
                final date = _date(item);
                final category = (item['category'] ?? 'Others').toString();
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    border: entry.key == rows.length - 1
                        ? null
                        : const Border(
                            bottom: BorderSide(color: Color(0xFFEDEBF4)),
                          ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _categoryColor(
                            entry.key,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _categoryColor(entry.key),
                          ),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              date == null
                                  ? 'Date unavailable'
                                  : DateFormat('MMM d, yyyy').format(date),
                              style: TextStyle(color: _muted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _money.format(_amount(item)),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }

  Widget _budgetRecordsCard() {
    final budgetTotal = _recordedBudgetTotal;
    final difference = budgetTotal - _totalSpent;

    return _panel(
      title: 'Budget entries and expenses',
      subtitle:
          'Shows budget amounts entered and expenses recorded during this period. It does not calculate your actual remaining budget.',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _budgetMiniMetric(
                  label: 'Budget amounts entered',
                  value: _money.format(budgetTotal),
                  icon: Icons.savings_outlined,
                  color: _green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _budgetMiniMetric(
                  label: 'Total expenses recorded',
                  value: _money.format(_totalSpent),
                  icon: Icons.shopping_bag_outlined,
                  color: _orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, color: _accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Difference between recorded budget amounts and expenses: ${_money.format(difference)}. This is a comparison of records created during the selected period, not necessarily the live remaining budget.',
                    style: TextStyle(fontSize: 11, height: 1.4, color: _text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetMiniMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
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
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(label, style: TextStyle(fontSize: 10, color: _muted)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
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
        color: _isDark ? const Color(0xFF302A20) : const Color(0xFFFFF8E8),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: _isDark ? const Color(0xFF55472D) : const Color(0xFFF4E5BD),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.lightbulb_outline_rounded,
            color: Color(0xFF946200),
            size: 19,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Analytics are calculated from saved expense and budget records. Days without a recorded expense are treated as having no recorded spending, not proof that no money was spent. The month-end figure is a simple pace estimate, not a prediction. True allowance runway, savings rate, and category-level budget utilization require corresponding allowance/income and category-budget data.',
              style: TextStyle(
                fontSize: 11,
                height: 1.45,
                color: Color(0xFF6F571C),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: _muted, height: 1.4),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final String helper;
  final IconData icon;
  final Color color;

  const _MetricData({
    required this.label,
    required this.value,
    required this.helper,
    required this.icon,
    required this.color,
  });
}

class _InsightData {
  final IconData icon;
  final Color color;
  final String title;
  final String text;

  const _InsightData({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final softSurface = isDark
        ? const Color(0xFF2A2538)
        : const Color(0xFFFAFAFD);
    final subtle = isDark ? const Color(0xFF928BA8) : const Color(0xFF8B8798);
    final muted = isDark ? const Color(0xFFB7B2C8) : const Color(0xFF6F6B82);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: softSurface,
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
