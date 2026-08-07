import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_helper.dart';
import '../utils/theme_helper.dart';
import 'about_page.dart';
import 'manage_categories_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String currency = "PHP";
  String theme = "System";
  int budgetReminder = 80;

  @override
  void initState() {
    super.initState();

    loadSettings();
  }

  Future<void> refresh() async {
    await loadSettings();
  }

  Future clearData() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Clear Data",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Delete All Data"),
                subtitle: const Text("Delete all expenses and budgets"),
                onTap: () {
                  Navigator.pop(context, "all");
                },
              ),

              ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.red),
                title: const Text("Delete Expenses"),
                subtitle: const Text("Delete all expense records"),
                onTap: () {
                  Navigator.pop(context, "expenses");
                },
              ),

              ListTile(
                leading: const Icon(
                  Icons.account_balance_wallet,
                  color: Colors.red,
                ),
                title: const Text("Delete Budgets"),
                subtitle: const Text("Delete all budget records"),
                onTap: () {
                  Navigator.pop(context, "budgets");
                },
              ),

              const SizedBox(height: 8),

              ListTile(
                leading: const Icon(Icons.close),
                title: const Text("Cancel"),
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );

    if (choice == null || !mounted) return;

    String title;
    String message;

    switch (choice) {
      case "all":
        title = "Delete All Data?";
        message =
            "This will permanently delete all expenses and budgets. "
            "Your categories and settings will remain unchanged.";
        break;

      case "expenses":
        title = "Delete All Expenses?";
        message =
            "This will permanently delete all expense records. "
            "Your budgets and settings will remain unchanged.";
        break;

      case "budgets":
        title = "Delete All Budgets?";
        message =
            "This will permanently delete all budget records. "
            "Your expenses and settings will remain unchanged.";
        break;

      default:
        return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),

          content: Text(message),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text("Cancel"),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    switch (choice) {
      case "all":
        await DatabaseHelper.instance.clearAllData();
        break;

      case "expenses":
        await DatabaseHelper.instance.clearExpenses();
        break;

      case "budgets":
        await DatabaseHelper.instance.clearBudgets();
        break;
    }

    if (!mounted) return;

    String messageText;

    switch (choice) {
      case "all":
        messageText = "All expense and budget data deleted";
        break;

      case "expenses":
        messageText = "All expense data deleted";
        break;

      case "budgets":
        messageText = "All budget data deleted";
        break;

      default:
        messageText = "Data deleted";
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(messageText)));
  }

  Future<void> loadSettings() async {
    final data = await DatabaseHelper.instance.getSettings();

    setState(() {
      currency = data["currency"];
      theme = data["theme"];
      budgetReminder = data["budgetReminder"];
    });
  }

  Future<void> changeCurrency(String value) async {
    await DatabaseHelper.instance.updateCurrency(value);

    await CurrencyHelper.loadCurrency();

    setState(() {
      currency = value;
    });
  }

  Future<void> changeTheme(String value) async {
    await ThemeHelper.instance.changeTheme(value);

    setState(() {
      theme = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),

      body: RefreshIndicator(
        onRefresh: refresh,

        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),

          children: [
            const Text(
              "General",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Card(
              child: ListTile(
                leading: const Icon(Icons.currency_exchange),

                title: const Text("Currency"),

                subtitle: Text(currency),

                trailing: DropdownButton<String>(
                  value: currency,

                  items: const [
                    DropdownMenuItem(value: "PHP", child: Text("₱ PHP")),

                    DropdownMenuItem(value: "USD", child: Text("\$ USD")),

                    DropdownMenuItem(value: "EUR", child: Text("€ EUR")),
                  ],

                  onChanged: (value) {
                    if (value != null) {
                      changeCurrency(value);
                    }
                  },
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.palette),

                title: const Text("Theme"),

                subtitle: Text(theme),

                trailing: DropdownButton<String>(
                  value: theme,

                  items: const [
                    DropdownMenuItem(value: "System", child: Text("System")),

                    DropdownMenuItem(value: "Light", child: Text("Light")),

                    DropdownMenuItem(value: "Dark", child: Text("Dark")),
                  ],

                  onChanged: (value) {
                    if (value != null) {
                      changeTheme(value);
                    }
                  },
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active),

                title: const Text("Budget Reminder"),

                subtitle: Text(
                  "Notify me when spending reaches $budgetReminder% of budget",
                ),

                trailing: DropdownButton<int>(
                  value: budgetReminder,

                  items: const [
                    DropdownMenuItem(value: 50, child: Text("50%")),
                    DropdownMenuItem(value: 60, child: Text("60%")),
                    DropdownMenuItem(value: 70, child: Text("70%")),
                    DropdownMenuItem(value: 80, child: Text("80%")),
                    DropdownMenuItem(value: 90, child: Text("90%")),
                    DropdownMenuItem(value: 100, child: Text("100%")),
                  ],

                  onChanged: (value) async {
                    if (value != null) {
                      await DatabaseHelper.instance.updateBudgetReminder(value);

                      setState(() {
                        budgetReminder = value;
                      });
                    }
                  },
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.category),

                title: const Text("Manage Categories"),

                subtitle: const Text("Add, edit, and remove categories"),

                trailing: const Icon(Icons.arrow_forward_ios, size: 18),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ManageCategoriesPage(),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),

                title: const Text(
                  "Clear Data",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                subtitle: const Text("Delete expense or budget records"),

                trailing: const Icon(Icons.arrow_forward_ios, size: 18),

                onTap: clearData,
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info),

                title: const Text("About"),

                subtitle: const Text("Application information"),

                trailing: const Icon(Icons.arrow_forward_ios, size: 18),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
