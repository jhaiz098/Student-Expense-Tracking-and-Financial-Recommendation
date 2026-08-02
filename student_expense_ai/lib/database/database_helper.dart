import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:student_expense_ai/models/category.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();

    return await openDatabase(
      join(dbPath, 'student_expense_ai.db'),
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE expenses(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(categoryId) REFERENCES expense_categories(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE budgets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        amount REAL NOT NULL,
        categoryId INTEGER NOT NULL,
        note TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY(categoryId) REFERENCES budget_categories(id)
      );
    ''');

    await db.execute('''
      CREATE TABLE expense_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE budget_categories(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency TEXT NOT NULL,
        theme TEXT NOT NULL,
        budgetReminder INTEGER NOT NULL DEFAULT 80,
        aiRecommendation INTEGER NOT NULL
      );
    ''');

    await db.insert('settings', {
      "currency": "PHP",
      "theme": "System",
      "budgetReminder": 80,
      "aiRecommendation": 1,
    });

    await insertDefaultCategories(db);
  }

  Future<void> clearAllData() async {
    final db = await database;

    await db.delete("expenses");

    await db.delete("budgets");
  }

  Future<int> getBudgetReminder() async {
    final db = await database;

    final result = await db.query("settings", where: "id = ?", whereArgs: [1]);

    if (result.isEmpty) return 80;

    return result.first["budgetReminder"] as int;
  }

  Future<void> updateBudgetReminder(int value) async {
    final db = await database;

    await db.update(
      "settings",
      {"budgetReminder": value},
      where: "id = ?",
      whereArgs: [1],
    );
  }

  Future<Map<String, dynamic>> getSettings() async {
    final db = await database;

    final result = await db.query("settings", where: "id = ?", whereArgs: [1]);

    if (result.isEmpty) {
      return {"currency": "PHP", "theme": "Light"};
    }

    String theme = result.first["theme"]?.toString() ?? "Light";

    if (theme != "System" && theme != "Light" && theme != "Dark") {
      theme = "System";
    }

    return {
      "currency": result.first["currency"]?.toString() ?? "PHP",
      "theme": theme,
      "budgetReminder": result.first["budgetReminder"] ?? 80,
    };
  }

  Future<void> updateCurrency(String currency) async {
    final db = await database;

    await db.update(
      "settings",
      {"currency": currency},
      where: "id = ?",
      whereArgs: [1],
    );
  }

  Future<void> updateTheme(String theme) async {
    final db = await database;

    // Get current theme first
    final oldData = await db.query("settings", where: "id = ?", whereArgs: [1]);

    print("Old theme: ${oldData.first["theme"]}");

    // Update theme
    await db.update(
      "settings",
      {"theme": theme},
      where: "id = ?",
      whereArgs: [1],
    );

    // Check new theme
    final newData = await db.query("settings", where: "id = ?", whereArgs: [1]);

    print("New theme: ${newData.first["theme"]}");
  }

  Future<String> getTheme() async {
    final db = await database;

    final result = await db.query("settings", where: "id = ?", whereArgs: [1]);

    return result.first["theme"]?.toString() ?? "Light";
  }

  Future<void> insertDefaultCategories(Database db) async {
    final expenseCategories = [
      {"name": "Food", "icon": Icons.restaurant.codePoint},
      {"name": "Transportation", "icon": Icons.directions_car.codePoint},
      {"name": "School", "icon": Icons.school.codePoint},
      {"name": "Bills", "icon": Icons.receipt_long.codePoint},
      {"name": "Entertainment", "icon": Icons.movie.codePoint},
      {"name": "Others", "icon": Icons.more_horiz.codePoint},
    ];

    final budgetCategories = [
      {"name": "Monthly Budget", "icon": Icons.calendar_month.codePoint},
      {"name": "Weekly Budget", "icon": Icons.date_range.codePoint},
      {"name": "Savings", "icon": Icons.savings.codePoint},
      {"name": "Emergency Fund", "icon": Icons.health_and_safety.codePoint},
    ];

    for (var category in expenseCategories) {
      await db.insert('expense_categories', category);
    }

    for (var category in budgetCategories) {
      await db.insert('budget_categories', category);
    }
  }

  Future<List<Category>> getExpenseCategories() async {
    final db = await database;

    final result = await db.query('expense_categories');

    return result.map((row) {
      return Category(
        id: row['id'] as int,
        name: row['name'] as String,
        icon: IconData(row['icon'] as int, fontFamily: 'MaterialIcons'),
      );
    }).toList();
  }

  Future<List<Category>> getBudgetCategories() async {
    final db = await database;

    final result = await db.query('budget_categories');

    return result.map((row) {
      return Category(
        id: row['id'] as int,
        name: row['name'] as String,
        icon: IconData(row['icon'] as int, fontFamily: 'MaterialIcons'),
      );
    }).toList();
  }

  Future<int> insertExpense(Map<String, dynamic> expense) async {
    final db = await database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;

    return await db.query('expenses', orderBy: 'createdAt DESC');
  }

  Future<int> deleteExpenses(int id) async {
    final db = await database;

    return await db.delete("expenses", where: "id=?", whereArgs: [id]);
  }

  Future<int> updateExpenses(int id, Map<String, dynamic> data) async {
    final db = await database;

    return await db.update("expenses", data, where: "id=?", whereArgs: [id]);
  }

  Future<int> insertBudget(Map<String, dynamic> budget) async {
    final db = await database;
    return await db.insert('budgets', budget);
  }

  Future<List<Map<String, dynamic>>> getBudget() async {
    final db = await database;

    return await db.query('budgets', orderBy: 'createdAt DESC');
  }

  Future<int> deleteBudget(int id) async {
    final db = await database;

    return await db.delete("budgets", where: "id=?", whereArgs: [id]);
  }

  Future<int> updateBudget(int id, Map<String, dynamic> data) async {
    final db = await database;

    return await db.update("budgets", data, where: "id=?", whereArgs: [id]);
  }

  Future<double> getCurrentMonthBudget() async {
    final db = await database;

    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final endOfMonth = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      1,
    ).toIso8601String();

    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) as total
    FROM budgets
    WHERE createdAt >= ? 
    AND createdAt < ?
    ''',
      [startOfMonth, endOfMonth],
    );

    return result.first['total'] == null ? 0 : result.first['total'] as double;
  }

  Future<List<Map<String, dynamic>>> getExpensesWithCategory() async {
    final db = await database;

    return await db.rawQuery('''
    SELECT 
      expenses.id,
      expenses.amount,
      expenses.note,
      expenses.createdAt,
      expenses.categoryId,
      expense_categories.name AS category
    FROM expenses
    INNER JOIN expense_categories
    ON expenses.categoryId = expense_categories.id
    ORDER BY expenses.createdAt DESC
  ''');
  }

  Future<List<Map<String, dynamic>>> getAllTransactions() async {
    final db = await database;

    final expenses = await db.rawQuery('''
    SELECT 
      expenses.id,
      expenses.amount,
      expenses.note,
      expenses.createdAt,
      expenses.categoryId,
      expense_categories.name AS category,
      expense_categories.icon AS icon,
      'Expense' AS type
    FROM expenses

    INNER JOIN expense_categories
    ON expenses.categoryId = expense_categories.id
  ''');

    final budgets = await db.rawQuery('''
    SELECT 
      budgets.id,
      budgets.amount,
      budgets.note,
      budgets.createdAt,
      budgets.categoryId,
      budget_categories.name AS category,
      budget_categories.icon AS icon,
      'Budget' AS type
    FROM budgets

    INNER JOIN budget_categories
    ON budgets.categoryId = budget_categories.id
  ''');

    final transactions = [...expenses, ...budgets];

    transactions.sort(
      (a, b) => b["createdAt"].toString().compareTo(a["createdAt"].toString()),
    );

    return transactions;
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions() async {
    final db = await database;

    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

    final expenses = await db.rawQuery(
      '''
    SELECT 
      expenses.id,
      expenses.amount,
      expenses.note,
      expenses.createdAt,
      expenses.categoryId,
      expense_categories.name AS category,
      expense_categories.icon AS icon,
      'Expense' AS type
    FROM expenses
    INNER JOIN expense_categories
    ON expenses.categoryId = expense_categories.id
    WHERE expenses.createdAt >= ?
    AND expenses.createdAt < ?
    ''',
      [startOfMonth, endOfMonth],
    );

    final budgets = await db.rawQuery(
      '''
    SELECT 
      budgets.id,
      budgets.amount,
      budgets.note,
      budgets.createdAt,
      budgets.categoryId,
      budget_categories.name AS category,
      budget_categories.icon AS icon,
      'Budget' AS type
    FROM budgets
    INNER JOIN budget_categories
    ON budgets.categoryId = budget_categories.id
    WHERE budgets.createdAt >= ?
    AND budgets.createdAt < ?
    ''',
      [startOfMonth, endOfMonth],
    );

    final transactions = [...expenses, ...budgets];

    transactions.sort(
      (a, b) => b["createdAt"].toString().compareTo(a["createdAt"].toString()),
    );

    return transactions.take(5).toList();
  }

  Future<double> getCurrentBudgetAmount() async {
    final db = await database;

    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) as total
    FROM budgets
    WHERE createdAt >= ?
    AND createdAt < ?
    ''',
      [startOfMonth, endOfMonth],
    );

    if (result.first["total"] == null) {
      return 0;
    }

    return (result.first["total"] as num).toDouble();
  }

  Future<double> getPreviousMonthBudgetAmount() async {
    final db = await database;

    final now = DateTime.now();

    final startOfPreviousMonth = DateTime(
      now.year,
      now.month - 1,
      1,
    ).toIso8601String();

    final startOfCurrentMonth = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String();

    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) as total
    FROM budgets
    WHERE createdAt >= ?
    AND createdAt < ?
    ''',
      [startOfPreviousMonth, startOfCurrentMonth],
    );

    if (result.first["total"] == null) {
      return 0;
    }

    return (result.first["total"] as num).toDouble();
  }

  Future<double> getCurrentExpenseAmount() async {
    final db = await database;

    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) as total
    FROM expenses
    WHERE createdAt >= ?
    AND createdAt < ?
    ''',
      [startOfMonth, endOfMonth],
    );

    if (result.first["total"] == null) {
      return 0;
    }

    return (result.first["total"] as num).toDouble();
  }

  Future<double> getPreviousMonthExpenseAmount() async {
    final db = await database;

    final now = DateTime.now();

    final startOfPreviousMonth = DateTime(
      now.year,
      now.month - 1,
      1,
    ).toIso8601String();

    final startOfCurrentMonth = DateTime(
      now.year,
      now.month,
      1,
    ).toIso8601String();

    final result = await db.rawQuery(
      '''
    SELECT SUM(amount) as total
    FROM expenses
    WHERE createdAt >= ?
    AND createdAt < ?
    ''',
      [startOfPreviousMonth, startOfCurrentMonth],
    );

    if (result.first["total"] == null) {
      return 0;
    }

    return (result.first["total"] as num).toDouble();
  }

  Future<int> getExpenseTransactionCount({bool previousMonth = false}) async {
    final db = await database;

    final now = DateTime.now();

    late DateTime startDate;
    late DateTime endDate;

    if (previousMonth) {
      startDate = DateTime(now.year, now.month - 1, 1);

      endDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1);

      endDate = DateTime(now.year, now.month + 1, 1);
    }

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) as total
    FROM expenses
    WHERE createdAt >= ?
    AND createdAt < ?
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, double>> getCategorySpending({
    bool previousMonth = false,
  }) async {
    final db = await database;

    final now = DateTime.now();

    late DateTime startDate;
    late DateTime endDate;

    if (previousMonth) {
      startDate = DateTime(now.year, now.month - 1, 1);

      endDate = DateTime(now.year, now.month, 1);
    } else {
      startDate = DateTime(now.year, now.month, 1);

      endDate = DateTime(now.year, now.month + 1, 1);
    }

    final result = await db.rawQuery(
      '''
    SELECT 
      expense_categories.name AS category,
      SUM(expenses.amount) AS total
    FROM expenses

    INNER JOIN expense_categories
    ON expenses.categoryId = expense_categories.id

    WHERE expenses.createdAt >= ?
    AND expenses.createdAt < ?

    GROUP BY expense_categories.name
    ''',
      [startDate.toIso8601String(), endDate.toIso8601String()],
    );

    Map<String, double> categories = {};

    for (var row in result) {
      categories[row["category"].toString()] = (row["total"] as num).toDouble();
    }

    return categories;
  }

  Future<Map<String, dynamic>> getSpendingPatterns() async {
    final current = await getCategorySpending();

    final previous = await getCategorySpending(previousMonth: true);

    String? highestCategory;
    double highestAmount = 0;

    String? largestIncreaseCategory;
    double largestIncrease = 0;

    for (var category in current.keys) {
      final currentAmount = current[category] ?? 0;

      final previousAmount = previous[category] ?? 0;

      // Highest current spending
      if (currentAmount > highestAmount) {
        highestAmount = currentAmount;
        highestCategory = category;
      }

      // Biggest increase
      final increase = currentAmount - previousAmount;

      if (increase > largestIncrease) {
        largestIncrease = increase;
        largestIncreaseCategory = category;
      }
    }

    return {
      "highest_current_month_spending_category": highestCategory,
      "highest_current_month_spending_amount": highestAmount,

      "biggest_month_to_month_increase_category": largestIncreaseCategory,
      "biggest_month_to_month_increase_amount": largestIncrease,
    };
  }

  Future<Map<String, dynamic>> getAdvisorData() async {
    final budget = await getCurrentMonthBudget();
    final spent = await getCurrentExpenseAmount();

    final previousBudget = await getPreviousMonthBudgetAmount();
    final previousSpent = await getPreviousMonthExpenseAmount();

    final remaining = budget - spent;

    final daysRemaining = DateTime(
      DateTime.now().year,
      DateTime.now().month + 1,
      1,
    ).difference(DateTime.now()).inDays;

    final transactions = await getExpenseTransactionCount();

    final currentCategories = await getCategorySpending();

    final previousCategories = await getCategorySpending(previousMonth: true);

    final patterns = await getSpendingPatterns();

    return {
      "budget": {
        "current_month_budget": budget,

        "current_month_spent": spent,

        "remaining_budget": remaining,

        "days_remaining": daysRemaining,
      },

      "previous_budget_information": {
        "previous_month_budget_amount": previousBudget,

        "previous_month_expense_amount": previousSpent,

        "previous_month_remaining_budget_amount":
            previousBudget - previousSpent,
      },

      "expense_summary": {"total_transactions": transactions},

      "categories": {
        "current_month": currentCategories,

        "previous_month": previousCategories,
      },

      "patterns": patterns,
    };
  }
}
