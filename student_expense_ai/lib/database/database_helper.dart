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
      "budgetReminder": 1,
      "aiRecommendation": 1,
    });

    await insertDefaultCategories(db);
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
}
