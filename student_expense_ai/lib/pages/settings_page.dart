import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../database/database_helper.dart';
import '../utils/theme_helper.dart';
import 'about_page.dart';
import 'manage_categories_page.dart';
import 'profile_page.dart';

const Color _settingsPurple = Color(0xFF5B45B5);
const Color _settingsBackground = Color(0xFFF7F7FB);
const Color _settingsBorder = Color(0xFFE7E4F0);
const Color _settingsText = Color(0xFF29263A);
const Color _settingsMuted = Color(0xFF6F6B82);
const Color _settingsRed = Color(0xFFE04444);

class SettingsPage extends StatefulWidget {
  final GlobalKey settingsKey;

  const SettingsPage({super.key, required this.settingsKey});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
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

  Future<void> loadSettings() async {
    final data = await DatabaseHelper.instance.getSettings();

    if (!mounted) return;

    setState(() {
      theme = data["theme"]?.toString() ?? "System";
      budgetReminder = data["budgetReminder"] as int? ?? 80;
    });
  }

  Future<void> changeTheme(String value) async {
    await ThemeHelper.instance.changeTheme(value);

    if (!mounted) return;

    setState(() {
      theme = value;
    });
  }

  Future<void> changeBudgetReminder(int value) async {
    await DatabaseHelper.instance.updateBudgetReminder(value);

    if (!mounted) return;

    setState(() {
      budgetReminder = value;
    });
  }

  Future<void> clearData() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).cardColor,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Clear Data",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _settingsText,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Choose which records you want to delete.",
                    style: TextStyle(fontSize: 13, color: _settingsMuted),
                  ),
                ),
                const SizedBox(height: 14),
                _deleteOption(
                  icon: Icons.delete_forever_rounded,
                  title: "Delete All Data",
                  subtitle: "Delete all expenses and budgets",
                  onTap: () => Navigator.pop(sheetContext, "all"),
                ),
                _deleteOption(
                  icon: Icons.receipt_long_rounded,
                  title: "Delete Expenses",
                  subtitle: "Delete all expense records",
                  onTap: () => Navigator.pop(sheetContext, "expenses"),
                ),
                _deleteOption(
                  icon: Icons.account_balance_wallet_outlined,
                  title: "Delete Budgets",
                  subtitle: "Delete all budget records",
                  onTap: () => Navigator.pop(sheetContext, "budgets"),
                ),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(
                      color: _settingsMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: _settingsRed),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
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

      final messageText = switch (choice) {
        "all" => "All expense and budget data deleted",
        "expenses" => "All expense data deleted",
        "budgets" => "All budget data deleted",
        _ => "Data deleted",
      };

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(messageText)));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Unable to delete data. Please try again."),
        ),
      );
    }
  }

  Widget _deleteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _settingsRed.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: _settingsRed),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: _settingsMuted),
      onTap: onTap,
    );
  }

  Widget _sectionTitle(String title, {Widget? trailing}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 22),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 19,
            decoration: BoxDecoration(
              color: _settingsPurple,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: _settingsText,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _settingsCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white12
              : _settingsBorder,
        ),
      ),
      child: child,
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    Color accent = _settingsPurple,
    bool showArrow = true,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      minLeadingWidth: 42,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: accent, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _settingsText,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            height: 1.35,
            color: _settingsMuted,
          ),
        ),
      ),
      trailing:
          trailing ??
          (showArrow
              ? const Icon(
                  Icons.chevron_right_rounded,
                  color: _settingsMuted,
                  size: 22,
                )
              : null),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : _settingsBackground,
      appBar: AppBar(
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : _settingsBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: _settingsPurple,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Showcase(
              key: widget.settingsKey,
              title: "Settings",
              description:
                  "Manage your profile, theme, budget reminders, categories, and other app settings here.",
              targetBorderRadius: BorderRadius.circular(8),
              overlayOpacity: 0.65,
              tooltipBackgroundColor: _settingsPurple,
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
              child: const Text(
                "General",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _settingsText,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // General
            _settingsCard(
              child: _settingsTile(
                icon: Icons.person_outline_rounded,
                title: "Profile",
                subtitle: "Manage your personal information",
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
            ),

            _sectionTitle("Preferences"),

            // Theme
            _settingsCard(
              child: _settingsTile(
                icon: Icons.palette_outlined,
                title: "Theme",
                subtitle: "Choose your preferred appearance",
                showArrow: false,
                onTap: () {},
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: theme,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _settingsPurple,
                    ),
                    style: const TextStyle(
                      color: _settingsPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: "System", child: Text("System")),
                      DropdownMenuItem(value: "Light", child: Text("Light")),
                      DropdownMenuItem(value: "Dark", child: Text("Dark")),
                    ],
                    onChanged: (value) {
                      if (value != null) changeTheme(value);
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Budget reminder
            _settingsCard(
              child: _settingsTile(
                icon: Icons.notifications_active_outlined,
                title: "Budget Reminder",
                subtitle:
                    "Notify me when spending reaches $budgetReminder% of budget",
                showArrow: false,
                onTap: () {},
                accent: const Color(0xFFE07816),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: budgetReminder,
                    borderRadius: BorderRadius.circular(12),
                    icon: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _settingsPurple,
                    ),
                    style: const TextStyle(
                      color: _settingsPurple,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                    items: const [
                      DropdownMenuItem(value: 50, child: Text("50%")),
                      DropdownMenuItem(value: 60, child: Text("60%")),
                      DropdownMenuItem(value: 70, child: Text("70%")),
                      DropdownMenuItem(value: 80, child: Text("80%")),
                      DropdownMenuItem(value: 90, child: Text("90%")),
                      DropdownMenuItem(value: 100, child: Text("100%")),
                    ],
                    onChanged: (value) {
                      if (value != null) changeBudgetReminder(value);
                    },
                  ),
                ),
              ),
            ),

            _sectionTitle("Categories & Data"),

            _settingsCard(
              child: _settingsTile(
                icon: Icons.category_outlined,
                title: "Manage Categories",
                subtitle: "Add, edit, and remove categories",
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

            const SizedBox(height: 10),

            _settingsCard(
              child: _settingsTile(
                icon: Icons.delete_outline_rounded,
                title: "Clear Data",
                subtitle: "Delete expense or budget records",
                accent: _settingsRed,
                onTap: clearData,
              ),
            ),

            _sectionTitle("Information"),

            _settingsCard(
              child: _settingsTile(
                icon: Icons.info_outline_rounded,
                title: "About",
                subtitle: "Application information and details",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AboutPage()),
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
