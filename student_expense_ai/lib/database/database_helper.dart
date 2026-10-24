import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:student_expense_ai/models/category.dart';
import 'dart:convert';

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
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('DROP TABLE IF EXISTS budget_categories');
        }
      },
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
        note TEXT,
        createdAt TEXT NOT NULL
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
      CREATE TABLE settings(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        theme TEXT NOT NULL,
        budgetReminder INTEGER NOT NULL DEFAULT 80
      );
    ''');
    // aiRecommendation INTEGER NOT NULL

    await db.insert('settings', {"theme": "System", "budgetReminder": 80});
    // "aiRecommendation": 1,

    await db.execute('''
      CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        firstName TEXT NOT NULL,
        middleName TEXT,
        lastName TEXT NOT NULL,
        dateOfBirth TEXT NOT NULL,
        address TEXT NOT NULL,
        currentStatus TEXT NOT NULL,
        school TEXT,
        schoolAddress TEXT,
        workplace TEXT,
        workplaceAddress TEXT,
        position TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ai_recommendations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL DEFAULT 1,
        recommendation TEXT NOT NULL,
        generated_at TEXT NOT NULL,
        next_available_at TEXT NOT NULL
      )
    ''');

    await insertDefaultCategories(db);
  }

  Future<bool> hasCurrentMonthBudget() async {
    final db = await database;

    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();

    final startOfNextMonth = DateTime(
      now.year,
      now.month + 1,
      1,
    ).toIso8601String();

    final result = await db.query(
      "budgets",
      where: "createdAt >= ? AND createdAt < ?",
      whereArgs: [startOfMonth, startOfNextMonth],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final db = await database;

    final result = await db.query(
      'user_profile',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return result.first;
  }

  Future<void> saveUserProfile(Map<String, dynamic> data) async {
    final db = await database;

    await db.insert('user_profile', {
      'id': 1,
      ...data,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final db = await database;

    await db.update('user_profile', data, where: 'id = ?', whereArgs: [1]);
  }

  Future<int> getCategoryTransactionCount(String type, int categoryId) async {
    // Budget categories are no longer supported.
    if (type != "Expense") return 0;

    final db = await database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count
      FROM expenses
      WHERE categoryId = ?
      ''',
      [categoryId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<void> deleteCategoryAndMoveTransactions({
    required String type,
    required int oldCategoryId,
    required int newCategoryId,
  }) async {
    // This operation now applies only to expense categories.
    if (type != "Expense") return;

    final db = await database;

    await db.transaction((txn) async {
      await txn.update(
        "expenses",
        {"categoryId": newCategoryId},
        where: "categoryId = ?",
        whereArgs: [oldCategoryId],
      );

      await txn.delete(
        "expense_categories",
        where: "id = ?",
        whereArgs: [oldCategoryId],
      );
    });
  }

  Future<List<Category>> getCategories(String type) async {
    // Return no categories for the removed budget-category feature.
    if (type != "Expense") return [];

    final db = await database;
    final result = await db.query("expense_categories");

    return result.map((row) {
      return Category(
        id: row["id"] as int,
        name: row["name"] as String,
        icon: IconData(row["icon"] as int, fontFamily: "MaterialIcons"),
      );
    }).toList();
  }

  Future<void> insertCategory(String type, String name, int icon) async {
    if (type != "Expense") return;

    final db = await database;
    await db.insert("expense_categories", {"name": name, "icon": icon});
  }

  Future<void> updateCategory(
    String type,
    int id,
    String name,
    int icon,
  ) async {
    if (type != "Expense") return;

    final db = await database;
    await db.update(
      "expense_categories",
      {"name": name, "icon": icon},
      where: "id = ?",
      whereArgs: [id],
    );
  }

  Future<void> moveCategoryTransactions(
    String type,
    int oldCategoryId,
    int newCategoryId,
  ) async {
    if (type != "Expense") return;

    final db = await database;
    await db.update(
      "expenses",
      {"categoryId": newCategoryId},
      where: "categoryId = ?",
      whereArgs: [oldCategoryId],
    );
  }

  Future<void> deleteCategory(String type, int id) async {
    if (type != "Expense") return;

    final db = await database;
    await db.delete("expense_categories", where: "id = ?", whereArgs: [id]);
  }

  Future<void> clearAllData() async {
    final db = await database;

    await db.delete("expenses");

    await db.delete("budgets");
  }

  Future clearExpenses() async {
    final db = await database;

    await db.delete("expenses");
  }

  Future clearBudgets() async {
    final db = await database;

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
      return {"theme": "Light", "budgetReminder": 80};
    }

    String theme = result.first["theme"]?.toString() ?? "Light";

    if (theme != "System" && theme != "Light" && theme != "Dark") {
      theme = "System";
    }

    return {
      "theme": theme,
      "budgetReminder": result.first["budgetReminder"] ?? 80,
    };
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
      {"name": "Food & Drinks", "icon": Icons.restaurant.codePoint},
      {"name": "Transportation", "icon": Icons.directions_bus.codePoint},
      {"name": "School Expenses", "icon": Icons.school.codePoint},
      {"name": "Load & Internet", "icon": Icons.wifi.codePoint},
      {"name": "Housing & Utilities", "icon": Icons.home.codePoint},
      {
        "name": "Personal Care & Shopping",
        "icon": Icons.shopping_bag.codePoint,
      },
      {"name": "Health & Medicine", "icon": Icons.medical_services.codePoint},
      {"name": "Entertainment", "icon": Icons.movie.codePoint},
      {"name": "Work & Side Hustles", "icon": Icons.work.codePoint},
      {"name": "Others", "icon": Icons.more_horiz.codePoint},
    ];

    for (var category in expenseCategories) {
      await db.insert('expense_categories', category);
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

    return await db.query(
      'budgets',
      columns: ['id', 'amount', 'createdAt'],
      orderBy: 'createdAt DESC',
    );
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
      expense_categories.name AS category,
      expense_categories.icon AS categoryIcon
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
      id,
      amount,
      note,
      createdAt,
      NULL AS categoryId,
      'Budget' AS category,
      NULL AS icon,
      'Budget' AS type
    FROM budgets
  ''');

    final transactions = [...expenses, ...budgets];

    transactions.sort(
      (a, b) => b['createdAt'].toString().compareTo(a['createdAt'].toString()),
    );

    return transactions;
  }

  Future<List<Map<String, dynamic>>> getRecentTransactions({
    String? type,
  }) async {
    final db = await database;
    final now = DateTime.now();

    final startOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final endOfMonth = DateTime(now.year, now.month + 1, 1).toIso8601String();

    List<Map<String, dynamic>> transactions = [];

    if (type == null || type == 'Expense') {
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

      transactions.addAll(expenses);
    }

    if (type == null || type == 'Budget') {
      final budgets = await db.rawQuery(
        '''
      SELECT
        id,
        amount,
        note,
        createdAt,
        NULL AS categoryId,
        'Budget' AS category,
        NULL AS icon,
        'Budget' AS type
      FROM budgets
      WHERE createdAt >= ?
        AND createdAt < ?
    ''',
        [startOfMonth, endOfMonth],
      );

      transactions.addAll(budgets);
    }

    transactions.sort(
      (a, b) => b['createdAt'].toString().compareTo(a['createdAt'].toString()),
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

  int calculateAge(String dateOfBirth) {
    final birthDate = DateTime.parse(dateOfBirth);
    final today = DateTime.now();

    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  }

  Future<Map<String, dynamic>> getAdvisorData() async {
    final profile = await getUserProfile();

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

    final currentStatus = profile?["currentStatus"];

    final Map<String, dynamic> profileData = {
      "age": profile?["dateOfBirth"] != null
          ? calculateAge(profile!["dateOfBirth"])
          : null,
      "current_status": currentStatus,
      "address": profile?["address"],
      "school": profile?["school"],
      "school_address": profile?["schoolAddress"],
    };

    if (currentStatus == "Working Student") {
      profileData["workplace"] = profile?["workplace"];
      profileData["workplace_address"] = profile?["workplaceAddress"];
      profileData["position"] = profile?["position"];
    }

    final patterns = await getSpendingPatterns();

    return {
      "profile": profileData,

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

      "expense_summary": {"total_expense_transactions": transactions},

      "categories": {
        "current_month": currentCategories,

        "previous_month": previousCategories,
      },

      "patterns": patterns,
    };
  }

  Future<void> saveAIRecommendation({
    required int userId,
    required List<Map<String, dynamic>> recommendations,
  }) async {
    final db = await database; // Use your existing database getter.

    final now = DateTime.now();
    final nextAvailable = now.add(const Duration(days: 7));

    final values = {
      'recommendation': jsonEncode(recommendations),
      'generated_at': now.toIso8601String(),
      'next_available_at': nextAvailable.toIso8601String(),
    };

    await db.transaction((txn) async {
      final updated = await txn.update(
        'ai_recommendations',
        values,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (updated == 0) {
        await txn.insert('ai_recommendations', {'user_id': userId, ...values});
      }
    });
  }

  Future<Map<String, dynamic>?> getSavedAIRecommendation({
    required int userId,
  }) async {
    final db = await database;

    final result = await db.query(
      'ai_recommendations',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  List<Map<String, dynamic>> decodeAIRecommendations(String jsonString) {
    final decoded = jsonDecode(jsonString) as List;

    return decoded
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }
}
