import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/currency_helper.dart';
import 'package:showcaseview/showcaseview.dart';

class AnalyticsPage extends StatefulWidget {
  final GlobalKey analyticsKey;

  const AnalyticsPage({super.key, required this.analyticsKey});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  String selectedPeriod = "This Month";
  String trendPeriod = "This Month";

  List<Map<String, dynamic>> trendData = [];
  List<Map<String, dynamic>> expenses = [];

  Map<String, double> categoryTotals = {};

  double totalExpenses = 0;

  String highestCategory = "None";
  double highestAmount = 0;

  String highestSpendingDay = "None";
  double highestSpendingDayAmount = 0;

  String currentMonthLabel = "";
  String previousMonthLabel = "";

  double currentMonthExpenses = 0;
  double previousMonthExpenses = 0;

  double monthlyDifference = 0;
  double monthlyPercentageChange = 0;

  @override
  void initState() {
    super.initState();
    loadAnalytics();
    loadTrendData();
  }

  Future<void> refresh() async {
    await loadAnalytics();
    await loadTrendData();
  }

  Future<void> loadAnalytics() async {
    final data = await DatabaseHelper.instance.getExpensesWithCategory();

    expenses = data;

    calculateAnalytics();
    calculateMonthlyComparison();
  }

  void calculateMonthlyComparison() {
    final now = DateTime.now();

    final currentMonthStart = DateTime(now.year, now.month, 1);

    final nextMonthStart = DateTime(now.year, now.month + 1, 1);

    final previousMonthStart = DateTime(now.year, now.month - 1, 1);

    double currentTotal = 0;
    double previousTotal = 0;

    for (var expense in expenses) {
      final date = DateTime.parse(expense["createdAt"]);

      final amount = (expense["amount"] as num).toDouble();

      // Current month
      if (!date.isBefore(currentMonthStart) && date.isBefore(nextMonthStart)) {
        currentTotal += amount;
      }

      // Previous month
      if (!date.isBefore(previousMonthStart) &&
          date.isBefore(currentMonthStart)) {
        previousTotal += amount;
      }
    }

    final difference = currentTotal - previousTotal;

    double percentageChange = 0;

    if (previousTotal > 0) {
      percentageChange = (difference / previousTotal) * 100;
    }

    setState(() {
      currentMonthLabel = DateFormat("MMMM yyyy").format(currentMonthStart);

      previousMonthLabel = DateFormat("MMMM yyyy").format(previousMonthStart);

      currentMonthExpenses = currentTotal;
      previousMonthExpenses = previousTotal;

      monthlyDifference = difference;
      monthlyPercentageChange = percentageChange;
    });
  }

  Future<void> loadTrendData() async {
    final expensesData = await DatabaseHelper.instance.getExpenses();
    final budgetsData = await DatabaseHelper.instance.getBudget();

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    Map<String, double> chartExpenses = {};
    Map<String, double> chartRemaining = {};
    Map<String, double> chartExcess = {};

    List<String> labels = [];

    // ============================================================
    // THIS WEEK
    // ============================================================

    if (trendPeriod == "This Week") {
      final startOfWeek = DateTime(
        today.year,
        today.month,
        today.day - (today.weekday - 1),
      );

      // Create labels for the week.
      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));

        final key = DateFormat("MMM d").format(date);

        labels.add(key);

        chartExpenses[key] = 0;
        chartRemaining[key] = 0;
        chartExcess[key] = 0;
      }

      // ----------------------------------------------------------
      // BUDGETS
      // These are NOT displayed directly.
      // They are used to calculate the running balance.
      // ----------------------------------------------------------

      Map<String, double> dailyBudgetAdded = {};

      for (var budget in budgetsData) {
        final date = DateTime.parse(budget["createdAt"]);

        final budgetDate = DateTime(date.year, date.month, date.day);

        final difference = budgetDate.difference(startOfWeek).inDays;

        if (difference >= 0 && difference < 7) {
          final key = DateFormat("MMM d").format(date);

          dailyBudgetAdded[key] =
              (dailyBudgetAdded[key] ?? 0) +
              (budget["amount"] as num).toDouble();
        }
      }

      // ----------------------------------------------------------
      // RUNNING BALANCE
      // ----------------------------------------------------------

      double runningBudget = 0;

      for (int i = 0; i < 7; i++) {
        final date = startOfWeek.add(Duration(days: i));

        // Don't calculate future dates.
        if (date.isAfter(today)) {
          break;
        }

        final key = DateFormat("MMM d").format(date);

        // Add budget entered on this date.
        runningBudget += dailyBudgetAdded[key] ?? 0;

        // Calculate today's expenses.
        double dailyExpenses = 0;

        for (var expense in expensesData) {
          final expenseDate = DateTime.parse(expense["createdAt"]);

          final normalizedExpenseDate = DateTime(
            expenseDate.year,
            expenseDate.month,
            expenseDate.day,
          );

          if (normalizedExpenseDate == date) {
            dailyExpenses += (expense["amount"] as num).toDouble();
          }
        }

        chartExpenses[key] = dailyExpenses;

        // Subtract expenses.
        runningBudget -= dailyExpenses;

        // Remaining or excess.
        if (runningBudget >= 0) {
          chartRemaining[key] = runningBudget;
          chartExcess[key] = 0;
        } else {
          chartRemaining[key] = 0;
          chartExcess[key] = runningBudget.abs();
        }
      }
    }
    // ============================================================
    // THIS MONTH
    // ============================================================
    else if (trendPeriod == "This Month") {
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

      // Create labels for every day.
      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(now.year, now.month, day);

        final key = DateFormat("MMM d").format(date);

        labels.add(key);

        chartExpenses[key] = 0;
        chartRemaining[key] = 0;
        chartExcess[key] = 0;
      }

      // ----------------------------------------------------------
      // BUDGETS
      // Used internally to calculate remaining budget.
      // ----------------------------------------------------------

      Map<String, double> dailyBudgetAdded = {};

      for (var budget in budgetsData) {
        final date = DateTime.parse(budget["createdAt"]);

        if (date.year == now.year && date.month == now.month) {
          final key = DateFormat("MMM d").format(date);

          dailyBudgetAdded[key] =
              (dailyBudgetAdded[key] ?? 0) +
              (budget["amount"] as num).toDouble();
        }
      }

      // ----------------------------------------------------------
      // RUNNING BALANCE
      // ----------------------------------------------------------

      double runningBudget = 0;

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(now.year, now.month, day);

        // Do not calculate future dates.
        if (date.isAfter(today)) {
          break;
        }

        final key = DateFormat("MMM d").format(date);

        // Add budget entered on this date.
        runningBudget += dailyBudgetAdded[key] ?? 0;

        // Calculate expenses for this date.
        double dailyExpenses = 0;

        for (var expense in expensesData) {
          final expenseDate = DateTime.parse(expense["createdAt"]);

          final normalizedExpenseDate = DateTime(
            expenseDate.year,
            expenseDate.month,
            expenseDate.day,
          );

          if (normalizedExpenseDate == date) {
            dailyExpenses += (expense["amount"] as num).toDouble();
          }
        }

        // Store actual expenses for this day.
        chartExpenses[key] = dailyExpenses;

        // Subtract expenses.
        runningBudget -= dailyExpenses;

        // Remaining or excess.
        if (runningBudget >= 0) {
          chartRemaining[key] = runningBudget;
          chartExcess[key] = 0;
        } else {
          chartRemaining[key] = 0;
          chartExcess[key] = runningBudget.abs();
        }
      }
    }
    // ============================================================
    // PAST 12 MONTHS
    // ============================================================
    else if (trendPeriod == "Past 12 Months") {
      // Create 12 month labels.
      for (int i = 11; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);

        final key = DateFormat("MMM yyyy").format(date);

        labels.add(key);

        chartExpenses[key] = 0;
        chartRemaining[key] = 0;
        chartExcess[key] = 0;
      }

      // ----------------------------------------------------------
      // EXPENSES BY MONTH
      // ----------------------------------------------------------

      Map<String, double> monthlyExpenses = {};

      for (var expense in expensesData) {
        final date = DateTime.parse(expense["createdAt"]);

        final monthsAgo = (now.year - date.year) * 12 + now.month - date.month;

        if (monthsAgo >= 0 && monthsAgo < 12) {
          final key = DateFormat("MMM yyyy").format(date);

          monthlyExpenses[key] =
              (monthlyExpenses[key] ?? 0) +
              (expense["amount"] as num).toDouble();
        }
      }

      // ----------------------------------------------------------
      // BUDGETS BY MONTH
      // ----------------------------------------------------------

      Map<String, double> monthlyBudgetAdded = {};

      for (var budget in budgetsData) {
        final date = DateTime.parse(budget["createdAt"]);

        final monthsAgo = (now.year - date.year) * 12 + now.month - date.month;

        if (monthsAgo >= 0 && monthsAgo < 12) {
          final key = DateFormat("MMM yyyy").format(date);

          monthlyBudgetAdded[key] =
              (monthlyBudgetAdded[key] ?? 0) +
              (budget["amount"] as num).toDouble();
        }
      }

      // ----------------------------------------------------------
      // RUNNING BALANCE BY MONTH
      // ----------------------------------------------------------

      double runningBudget = 0;

      for (String key in labels) {
        // Add budgets that were entered during this month.
        runningBudget += monthlyBudgetAdded[key] ?? 0;

        // Get expenses for this month.
        final monthlyExpense = monthlyExpenses[key] ?? 0;

        // Display monthly expenses.
        chartExpenses[key] = monthlyExpense;

        // Subtract expenses.
        runningBudget -= monthlyExpense;

        // Remaining or excess.
        if (runningBudget >= 0) {
          chartRemaining[key] = runningBudget;
          chartExcess[key] = 0;
        } else {
          chartRemaining[key] = 0;
          chartExcess[key] = runningBudget.abs();
        }
      }
    }

    if (!mounted) return;

    setState(() {
      trendData = labels.map((label) {
        return {
          "label": label,
          "expenses": chartExpenses[label] ?? 0,
          "remaining": chartRemaining[label] ?? 0,
          "excess": chartExcess[label] ?? 0,
        };
      }).toList();
    });
  }

  void calculateAnalytics() {
    Map<String, double> totals = {};
    Map<String, double> dailyTotals = {};

    double total = 0;

    DateTime now = DateTime.now();

    DateTime? periodStart;
    DateTime? periodEnd;

    if (selectedPeriod == "This Month") {
      periodStart = DateTime(now.year, now.month, 1);
      periodEnd = DateTime(now.year, now.month + 1, 1);
    } else if (selectedPeriod == "Past 3 Months") {
      periodStart = DateTime(now.year, now.month - 2, 1);
      periodEnd = DateTime(now.year, now.month + 1, 1);
    } else if (selectedPeriod == "Past 12 Months") {
      periodStart = DateTime(now.year, now.month - 11, 1);
      periodEnd = DateTime(now.year, now.month + 1, 1);
    } else if (selectedPeriod == "All Time") {
      periodStart = null;
      periodEnd = null;
    }

    for (var expense in expenses) {
      DateTime date = DateTime.parse(expense["createdAt"]);

      bool include = true;

      if (periodStart != null && periodEnd != null) {
        include = !date.isBefore(periodStart) && date.isBefore(periodEnd);
      }

      if (include) {
        String category = expense["category"] ?? "Others";

        double amount = (expense["amount"] as num).toDouble();

        // Category totals
        totals[category] = (totals[category] ?? 0) + amount;

        // Overall total
        total += amount;

        // Daily totals
        DateTime day = DateTime(date.year, date.month, date.day);

        String dayKey = DateFormat("yyyy-MM-dd").format(day);

        dailyTotals[dayKey] = (dailyTotals[dayKey] ?? 0) + amount;
      }
    }

    // ----------------------------------------------------------
    // TOP SPENDING CATEGORY
    // ----------------------------------------------------------

    String topCategory = "None";
    double topAmount = 0;

    totals.forEach((key, value) {
      if (value > topAmount) {
        topCategory = key;
        topAmount = value;
      }
    });

    // ----------------------------------------------------------
    // HIGHEST SPENDING DAY
    // ----------------------------------------------------------

    String highestDay = "None";
    double highestDayAmount = 0;

    dailyTotals.forEach((key, value) {
      if (value > highestDayAmount) {
        highestDay = key;
        highestDayAmount = value;
      }
    });

    setState(() {
      categoryTotals = totals;

      totalExpenses = total;

      highestCategory = topCategory;

      highestAmount = topAmount;

      highestSpendingDay = highestDay;

      highestSpendingDayAmount = highestDayAmount;
    });
  }

  Color getCategoryColor(double percentage) {
    if (percentage >= 50) {
      return Colors.red;
    }

    if (percentage >= 25) {
      return Colors.orange;
    }

    return Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Analytics"), centerTitle: false),

      body: RefreshIndicator(
        onRefresh: refresh,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Showcase(
                key: widget.analyticsKey,
                title: "Analytics",
                description:
                    "Analyze your spending by category, trends, highest spending day, and monthly comparisons.",
                targetBorderRadius: BorderRadius.circular(12),
                overlayOpacity: 0.65,
                tooltipBackgroundColor: Colors.deepPurple,
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

                child: Align(
                  alignment: Alignment.centerRight,

                  child: DropdownButton<String>(
                    value: selectedPeriod,

                    items: const [
                      DropdownMenuItem(
                        value: "This Month",
                        child: Text("This Month"),
                      ),

                      DropdownMenuItem(
                        value: "Past 3 Months",
                        child: Text("Past 3 Months"),
                      ),

                      DropdownMenuItem(
                        value: "Past 12 Months",
                        child: Text("Past 12 Months"),
                      ),

                      DropdownMenuItem(
                        value: "All Time",
                        child: Text("All Time"),
                      ),
                    ],

                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedPeriod = value;
                        });

                        calculateAnalytics();
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ----------------------------------------------------------
              // SPENDING SUMMARY
              // ----------------------------------------------------------
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.deepPurple,
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Spending Insights",

                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ----------------------------------------------------------
                    // TOP SPENDING CATEGORY
                    // ----------------------------------------------------------
                    const Text(
                      "Top Spending Category",

                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      highestCategory,

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "₱${highestAmount.toStringAsFixed(2)}",

                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Container(height: 1, color: Colors.white24),

                    const SizedBox(height: 20),

                    // ----------------------------------------------------------
                    // HIGHEST SPENDING DAY
                    // ----------------------------------------------------------
                    const Text(
                      "Highest Spending Day",

                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      highestSpendingDay == "None"
                          ? "None"
                          : DateFormat(
                              "MMMM d, yyyy",
                            ).format(DateTime.parse(highestSpendingDay)),

                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      "₱${highestSpendingDayAmount.toStringAsFixed(2)}",

                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ----------------------------------------------------------
              // MONTHLY COMPARISON
              // ----------------------------------------------------------
              Container(
                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [
                    const Text(
                      "Monthly Comparison",

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ----------------------------------------------------------
                    // CURRENT MONTH
                    // ----------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Text(
                          currentMonthLabel,

                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                          ),
                        ),

                        Text(
                          "₱${currentMonthExpenses.toStringAsFixed(2)}",

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ----------------------------------------------------------
                    // PREVIOUS MONTH
                    // ----------------------------------------------------------
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,

                      children: [
                        Text(
                          previousMonthLabel,

                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 15,
                          ),
                        ),

                        Text(
                          "₱${previousMonthExpenses.toStringAsFixed(2)}",

                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Divider(color: Colors.grey.shade200),

                    const SizedBox(height: 20),

                    const Text(
                      "Compared with last month",

                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 8),

                    if (previousMonthExpenses == 0 && currentMonthExpenses == 0)
                      Text(
                        "No spending recorded",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                        ),
                      )
                    else if (previousMonthExpenses == 0)
                      Text(
                        "No spending recorded last month",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 15,
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            monthlyDifference >= 0
                                ? "↑ ₱${monthlyDifference.toStringAsFixed(2)}"
                                : "↓ ₱${monthlyDifference.abs().toStringAsFixed(2)}",

                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            monthlyPercentageChange >= 0
                                ? "${monthlyPercentageChange.toStringAsFixed(1)}% higher"
                                : "${monthlyPercentageChange.abs().toStringAsFixed(1)}% lower",

                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Spending by Category",

                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              if (categoryTotals.isEmpty)
                const Text("No expenses found.")
              else
                ...categoryTotals.entries.map((entry) {
                  double percentage = totalExpenses == 0
                      ? 0
                      : entry.value / totalExpenses;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 15),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,

                          children: [
                            Text(
                              entry.key,

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            Text("${(percentage * 100).toStringAsFixed(0)}%"),
                          ],
                        ),

                        const SizedBox(height: 6),

                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),

                          child: LinearProgressIndicator(
                            value: percentage,

                            minHeight: 10,

                            backgroundColor: Colors.grey.shade200,

                            color: getCategoryColor(percentage * 100),
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          "₱${entry.value.toStringAsFixed(2)}",

                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  );
                }).toList(),

              const SizedBox(height: 30),

              budgetExpenseChart(),
            ],
          ),
        ),
      ),
    );
  }

  double _getChartMaxY() {
    double highest = 0;

    for (final data in trendData) {
      final expenses = (data["expenses"] as num?)?.toDouble() ?? 0;
      final remaining = (data["remaining"] as num?)?.toDouble() ?? 0;
      final excess = (data["excess"] as num?)?.toDouble() ?? 0;

      highest = [
        highest,
        expenses,
        remaining,
        excess,
      ].reduce((a, b) => a > b ? a : b);
    }

    if (highest <= 0) {
      return 100;
    }

    // Give the chart some space above the highest bar.
    if (highest <= 500) {
      return 600;
    } else if (highest <= 1000) {
      return 1200;
    } else if (highest <= 5000) {
      return 6000;
    } else if (highest <= 10000) {
      return 12000;
    } else if (highest <= 50000) {
      return 60000;
    } else if (highest <= 100000) {
      return 120000;
    } else if (highest <= 500000) {
      return 600000;
    } else if (highest <= 1000000) {
      return 1200000;
    } else {
      return (highest / 500000).ceil() * 500000 + 500000;
    }
  }

  double _getChartInterval() {
    double maxY = _getChartMaxY();

    if (maxY <= 600) {
      return 100;
    } else if (maxY <= 1200) {
      return 200;
    } else if (maxY <= 6000) {
      return 1000;
    } else if (maxY <= 12000) {
      return 2000;
    } else if (maxY <= 60000) {
      return 10000;
    } else if (maxY <= 120000) {
      return 20000;
    } else if (maxY <= 600000) {
      return 100000;
    } else if (maxY <= 1200000) {
      return 200000;
    } else {
      return 500000;
    }
  }

  Widget budgetExpenseChart() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  "Budget & Spending Trend",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              DropdownButton<String>(
                value: trendPeriod,

                items: const [
                  DropdownMenuItem(
                    value: "This Week",
                    child: Text("This Week"),
                  ),

                  DropdownMenuItem(
                    value: "This Month",
                    child: Text("This Month"),
                  ),

                  DropdownMenuItem(
                    value: "Past 12 Months",
                    child: Text("Past 12 Months"),
                  ),
                ],

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      trendPeriod = value;
                    });

                    loadTrendData();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 250,

            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,

              child: SizedBox(
                width: trendPeriod == "This Month"
                    ? trendData.length * 40.0
                    : trendPeriod == "This Week"
                    ? trendData.length * 50.0
                    : trendData.length * 75.0,

                child: BarChart(
                  BarChartData(
                    borderData: FlBorderData(show: false),

                    gridData: FlGridData(
                      show: true,

                      // Keep horizontal grid lines.
                      drawHorizontalLine: true,

                      // We will draw the vertical lines ourselves.
                      drawVerticalLine: false,
                    ),

                    maxY: _getChartMaxY(),

                    barGroups: trendData.asMap().entries.map((entry) {
                      final index = entry.key;
                      final data = entry.value;

                      return BarChartGroupData(
                        x: index,

                        barsSpace: 2,

                        barRods: [
                          // EXPENSES
                          BarChartRodData(
                            toY: (data["expenses"] as num?)?.toDouble() ?? 0,
                            width: 8,
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(3),
                          ),

                          // REMAINING
                          if (((data["remaining"] as num?)?.toDouble() ?? 0) >
                              0)
                            BarChartRodData(
                              toY: (data["remaining"] as num?)?.toDouble() ?? 0,
                              width: 8,
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(3),
                            ),

                          // EXCESS
                          if (((data["excess"] as num?)?.toDouble() ?? 0) > 0)
                            BarChartRodData(
                              toY: (data["excess"] as num?)?.toDouble() ?? 0,
                              width: 8,
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(3),
                            ),
                        ],
                      );
                    }).toList(),

                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,

                          reservedSize: 30,

                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();

                            if (index < 0 || index >= trendData.length) {
                              return const SizedBox();
                            }

                            return Padding(
                              padding: const EdgeInsets.only(top: 4),

                              child: Text(
                                trendData[index]["label"],
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          },
                        ),
                      ),

                      // LEFT AXIS
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,

                          reservedSize: 55,

                          interval: _getChartInterval(),

                          getTitlesWidget: (value, meta) {
                            // Hide the very top Y-axis label.
                            if (value >= _getChartMaxY()) {
                              return const SizedBox();
                            }

                            String label;

                            if (value >= 1000000) {
                              label =
                                  "₱${(value / 1000000).toStringAsFixed(1)}M";
                            } else if (value >= 1000) {
                              label = "₱${(value / 1000).toStringAsFixed(0)}K";
                            } else {
                              label = "₱${value.toStringAsFixed(0)}";
                            }

                            return Padding(
                              padding: const EdgeInsets.only(right: 5),

                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 9),
                              ),
                            );
                          },
                        ),
                      ),

                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),

                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // Expenses
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(width: 6),

              const Text("Expenses"),

              const SizedBox(width: 15),

              // Remaining
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(width: 6),

              const Text("Remaining"),

              const SizedBox(width: 15),

              // Excess
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(width: 6),

              const Text("Excess"),
            ],
          ),
        ],
      ),
    );
  }
}
