import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/currency_helper.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

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

    double total = 0;

    DateTime now = DateTime.now();

    for (var expense in expenses) {
      DateTime date = DateTime.parse(expense["createdAt"]);

      bool include = false;

      if (selectedPeriod == "This Month") {
        include = date.month == now.month && date.year == now.year;
      } else if (selectedPeriod == "Past 3 Months") {
        DateTime threeMonthsAgo = DateTime(now.year, now.month - 2, 1);

        include = date.isAfter(
          threeMonthsAgo.subtract(const Duration(days: 1)),
        );
      } else if (selectedPeriod == "Past 12 Months") {
        DateTime twelveMonthsAgo = DateTime(now.year, now.month - 11, 1);

        include = date.isAfter(
          twelveMonthsAgo.subtract(const Duration(days: 1)),
        );
      } else if (selectedPeriod == "All Time") {
        include = true;
      }

      if (include) {
        String category = expense["category"] ?? "Others";

        double amount = expense["amount"].toDouble();

        totals[category] = (totals[category] ?? 0) + amount;

        total += amount;
      }
    }

    String topCategory = "None";
    double topAmount = 0;

    totals.forEach((key, value) {
      if (value > topAmount) {
        topCategory = key;
        topAmount = value;
      }
    });

    setState(() {
      categoryTotals = totals;

      totalExpenses = total;

      highestCategory = topCategory;

      highestAmount = topAmount;
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
              // Filter
              Align(
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

              const SizedBox(height: 20),

              // Highest Spending
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
                      "Top Spending Category",

                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      highestCategory,

                      style: const TextStyle(
                        color: Colors.white,

                        fontSize: 28,

                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      CurrencyHelper.format(highestAmount),

                      style: const TextStyle(color: Colors.white, fontSize: 18),
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
                          CurrencyHelper.format(entry.value),

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

    // Give the highest bar some breathing room.
    if (highest <= 500) {
      return 500;
    } else if (highest <= 1000) {
      return 1000;
    } else if (highest <= 5000) {
      return 5000;
    } else if (highest <= 10000) {
      return 10000;
    } else if (highest <= 50000) {
      return 50000;
    } else if (highest <= 100000) {
      return 100000;
    } else if (highest <= 500000) {
      return 500000;
    } else if (highest <= 1000000) {
      return 1000000;
    } else {
      return (highest / 500000).ceil() * 500000;
    }
  }

  double _getChartInterval() {
    double maxY = _getChartMaxY();

    if (maxY <= 500) {
      return 100;
    } else if (maxY <= 1000) {
      return 200;
    } else if (maxY <= 5000) {
      return 1000;
    } else if (maxY <= 10000) {
      return 2000;
    } else if (maxY <= 50000) {
      return 10000;
    } else if (maxY <= 100000) {
      return 20000;
    } else if (maxY <= 500000) {
      return 100000;
    } else if (maxY <= 1000000) {
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
