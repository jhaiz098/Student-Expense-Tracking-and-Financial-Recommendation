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
  String trendPeriod = "This Year";

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
    final expenses = await DatabaseHelper.instance.getExpenses();
    final budgets = await DatabaseHelper.instance.getBudget();

    Map<String, double> monthlyExpenses = {};
    Map<String, double> monthlyBudgets = {};

    DateTime now = DateTime.now();

    int startYear = now.year;

    if (trendPeriod == "Past 3 Years") {
      startYear = now.year - 2;
    } else if (trendPeriod == "Past 5 Years") {
      startYear = now.year - 4;
    }

    for (var expense in expenses) {
      DateTime date = DateTime.parse(expense["createdAt"]);

      if (trendPeriod != "All Time" && date.year < startYear) {
        continue;
      }

      String key;

      if (trendPeriod == "This Year") {
        if (date.year != now.year) continue;

        key = DateFormat("MMM").format(date);
      } else {
        key = date.year.toString();
      }

      monthlyExpenses[key] = (monthlyExpenses[key] ?? 0) + expense["amount"];
    }

    for (var budget in budgets) {
      DateTime date = DateTime.parse(budget["createdAt"]);

      if (trendPeriod != "All Time" && date.year < startYear) {
        continue;
      }

      String key;

      if (trendPeriod == "This Year") {
        if (date.year != now.year) continue;

        key = DateFormat("MMM").format(date);
      } else {
        key = date.year.toString();
      }

      monthlyBudgets[key] = (monthlyBudgets[key] ?? 0) + budget["amount"];
    }

    List<String> keys = [
      ...{...monthlyExpenses.keys, ...monthlyBudgets.keys},
    ];

    if (trendPeriod == "This Year") {
      List<String> months = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];

      keys.sort((a, b) => months.indexOf(a).compareTo(months.indexOf(b)));
    } else {
      keys.sort();
    }

    setState(() {
      trendData = keys.map((key) {
        return {
          "label": key,
          "budget": monthlyBudgets[key] ?? 0,
          "expense": monthlyExpenses[key] ?? 0,
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
                  "Budget vs Expenses Trend",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),

              DropdownButton<String>(
                value: trendPeriod,

                items: const [
                  DropdownMenuItem(
                    value: "This Year",
                    child: Text("This Year"),
                  ),

                  DropdownMenuItem(
                    value: "Past 3 Years",
                    child: Text("Past 3 Years"),
                  ),

                  DropdownMenuItem(
                    value: "Past 5 Years",
                    child: Text("Past 5 Years"),
                  ),

                  DropdownMenuItem(value: "All Time", child: Text("All Time")),
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
            height: 260,

            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),

                gridData: const FlGridData(show: true),

                barGroups: trendData.map((data) {
                  int index = trendData.indexOf(data);

                  return BarChartGroupData(
                    x: index,

                    barRods: [
                      BarChartRodData(
                        toY: data["budget"],
                        width: 10,
                        color: Colors.deepPurple,
                        borderRadius: BorderRadius.circular(4),
                      ),

                      BarChartRodData(
                        toY: data["expense"],
                        width: 10,
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),

                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,

                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();

                        if (index >= trendData.length) {
                          return const SizedBox();
                        }

                        return Text(
                          trendData[index]["label"],
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),

                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
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

          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),

              const SizedBox(width: 6),

              const Text("Budget"),

              const SizedBox(width: 20),

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
            ],
          ),
        ],
      ),
    );
  }
}
