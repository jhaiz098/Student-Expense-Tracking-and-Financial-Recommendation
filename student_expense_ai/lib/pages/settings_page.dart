import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../utils/currency_helper.dart';
import '../utils/theme_helper.dart';

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

  Future<void> loadSettings() async {
    final data = await DatabaseHelper.instance.getSettings();

    setState(() {
      currency = data["currency"];
      theme = data["theme"];
      budgetReminder = data["budgetReminder"];
    });
  }

  Future<void> changeCurrency(String currency) async {
    await DatabaseHelper.instance.updateCurrency(currency);

    await CurrencyHelper.loadCurrency();

    setState(() {});
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

      body: ListView(
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
        ],
      ),
    );
  }
}
