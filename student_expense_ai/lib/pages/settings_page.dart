import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../database/database_helper.dart';
import '../utils/theme_helper.dart';
import 'about_page.dart';
import 'manage_categories_page.dart';
import 'profile_page.dart';

const Color _settingsPurple = Color(0xFF5B45B5);
const Color _settingsDarkPurple = Color(0xFFB9A8FF);
const Color _settingsRed = Color(0xFFE05252);
const Color _settingsOrange = Color(0xFFE07816);

class SettingsPage extends StatefulWidget {
  final GlobalKey settingsKey;

  const SettingsPage({super.key, required this.settingsKey});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String theme = 'System';
  int budgetReminder = 80;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _isDark ? const Color(0xFF15131E) : const Color(0xFFF7F7FB);

  Color get _card => _isDark ? const Color(0xFF211D2D) : Colors.white;

  Color get _border =>
      _isDark ? const Color(0xFF393246) : const Color(0xFFE7E4F0);

  Color get _text =>
      _isDark ? const Color(0xFFF5F2FF) : const Color(0xFF29263A);

  Color get _muted =>
      _isDark ? const Color(0xFFB7B2C8) : const Color(0xFF6F6B82);

  Color get _subtle =>
      _isDark ? const Color(0xFF928BA8) : const Color(0xFF8B8798);

  Color get _surface =>
      _isDark ? const Color(0xFF2A2538) : const Color(0xFFFAFAFD);

  Color get _accent => _isDark ? _settingsDarkPurple : _settingsPurple;

  @override
  void initState() {
    super.initState();
    loadSettings();
  }

  Future<void> refresh() async {
    await loadSettings();
  }

  Future<void> loadSettings() async {
    try {
      final data = await DatabaseHelper.instance.getSettings();

      if (!mounted) return;

      setState(() {
        theme = data['theme']?.toString() ?? 'System';
        budgetReminder = data['budgetReminder'] as int? ?? 80;
      });
    } catch (e) {
      debugPrint('Unable to load settings: $e');
    }
  }

  Future<void> changeTheme(String value) async {
    try {
      await ThemeHelper.instance.changeTheme(value);

      if (!mounted) return;

      setState(() {
        theme = value;
      });
    } catch (e) {
      debugPrint('Unable to change theme: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to change theme. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> changeBudgetReminder(int value) async {
    try {
      await DatabaseHelper.instance.updateBudgetReminder(value);

      if (!mounted) return;

      setState(() {
        budgetReminder = value;
      });
    } catch (e) {
      debugPrint('Unable to update budget reminder: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to update budget reminder.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> clearData() async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: _card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Clear Data',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Choose which records you want to delete.',
                    style: TextStyle(fontSize: 13, color: _muted),
                  ),
                ),
                const SizedBox(height: 16),
                _deleteOption(
                  icon: Icons.delete_forever_rounded,
                  title: 'Delete All Data',
                  subtitle: 'Delete all expenses and budgets',
                  onTap: () => Navigator.pop(sheetContext, 'all'),
                ),
                _deleteOption(
                  icon: Icons.receipt_long_rounded,
                  title: 'Delete Expenses',
                  subtitle: 'Delete all expense records',
                  onTap: () => Navigator.pop(sheetContext, 'expenses'),
                ),
                _deleteOption(
                  icon: Icons.account_balance_wallet_outlined,
                  title: 'Delete Budgets',
                  subtitle: 'Delete all budget records',
                  onTap: () => Navigator.pop(sheetContext, 'budgets'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: TextButton.styleFrom(
                      foregroundColor: _muted,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontWeight: FontWeight.w700),
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
      case 'all':
        title = 'Delete All Data?';
        message =
            'This will permanently delete all expenses and budgets. '
            'Your categories and settings will remain unchanged.';
        break;
      case 'expenses':
        title = 'Delete All Expenses?';
        message =
            'This will permanently delete all expense records. '
            'Your budgets and settings will remain unchanged.';
        break;
      case 'budgets':
        title = 'Delete All Budgets?';
        message =
            'This will permanently delete all budget records. '
            'Your expenses and settings will remain unchanged.';
        break;
      default:
        return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _border),
          ),
          title: Text(
            title,
            style: TextStyle(
              color: _text,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: TextStyle(color: _muted, height: 1.5, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text('Cancel', style: TextStyle(color: _muted)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: _settingsRed),
              child: const Text(
                'Delete',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      switch (choice) {
        case 'all':
          await DatabaseHelper.instance.clearAllData();
          break;
        case 'expenses':
          await DatabaseHelper.instance.clearExpenses();
          break;
        case 'budgets':
          await DatabaseHelper.instance.clearBudgets();
          break;
      }

      if (!mounted) return;

      final messageText = switch (choice) {
        'all' => 'All expense and budget data deleted',
        'expenses' => 'All expense data deleted',
        'budgets' => 'All budget data deleted',
        _ => 'Data deleted',
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(messageText),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Unable to delete data: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete data. Please try again.'),
          behavior: SnackBarBehavior.floating,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _settingsRed.withValues(alpha: _isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _settingsRed, size: 21),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 14,
          color: _text,
        ),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: _muted)),
      trailing: Icon(Icons.chevron_right_rounded, color: _subtle),
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
              color: _accent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: _text,
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
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
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
    Color? accent,
    bool showArrow = true,
  }) {
    final tileAccent = accent ?? _accent;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      minLeadingWidth: 42,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: tileAccent.withValues(alpha: _isDark ? 0.16 : 0.10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: tileAccent, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: _text,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(fontSize: 12, height: 1.4, color: _muted),
        ),
      ),
      trailing:
          trailing ??
          (showArrow
              ? Icon(Icons.chevron_right_rounded, color: _subtle, size: 22)
              : null),
      onTap: onTap,
    );
  }

  Widget _settingsDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        borderRadius: BorderRadius.circular(12),
        dropdownColor: _card,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: _accent),
        style: TextStyle(
          color: _accent,
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
        items: items,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800, color: _text),
        ),
        centerTitle: true,
        foregroundColor: _text,
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: _accent,
        backgroundColor: _card,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            Showcase(
              key: widget.settingsKey,
              title: 'Settings',
              description:
                  'Manage your profile, theme, budget reminders, categories, and other app settings here.',
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
              child: Text(
                'General',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // General
            _settingsCard(
              child: _settingsTile(
                icon: Icons.person_outline_rounded,
                title: 'Profile',
                subtitle: 'Manage your personal information',
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  );
                },
              ),
            ),

            _sectionTitle('Preferences'),

            // Theme
            _settingsCard(
              child: _settingsTile(
                icon: Icons.palette_outlined,
                title: 'Theme',
                subtitle: 'Choose your preferred appearance',
                showArrow: false,
                onTap: () {},
                trailing: _settingsDropdown<String>(
                  value: theme,
                  items: const [
                    DropdownMenuItem(value: 'System', child: Text('System')),
                    DropdownMenuItem(value: 'Light', child: Text('Light')),
                    DropdownMenuItem(value: 'Dark', child: Text('Dark')),
                  ],
                  onChanged: (value) {
                    if (value != null) changeTheme(value);
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Budget reminder
            _settingsCard(
              child: _settingsTile(
                icon: Icons.notifications_active_outlined,
                title: 'Budget Reminder',
                subtitle:
                    'Notify me when spending reaches $budgetReminder% of budget',
                showArrow: false,
                onTap: () {},
                accent: _settingsOrange,
                trailing: _settingsDropdown<int>(
                  value: budgetReminder,
                  items: const [
                    DropdownMenuItem(value: 50, child: Text('50%')),
                    DropdownMenuItem(value: 60, child: Text('60%')),
                    DropdownMenuItem(value: 70, child: Text('70%')),
                    DropdownMenuItem(value: 80, child: Text('80%')),
                    DropdownMenuItem(value: 90, child: Text('90%')),
                    DropdownMenuItem(value: 100, child: Text('100%')),
                  ],
                  onChanged: (value) {
                    if (value != null) changeBudgetReminder(value);
                  },
                ),
              ),
            ),

            _sectionTitle('Categories & Data'),

            _settingsCard(
              child: _settingsTile(
                icon: Icons.category_outlined,
                title: 'Manage Categories',
                subtitle: 'Add, edit, and remove categories',
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
                title: 'Clear Data',
                subtitle: 'Delete expense or budget records',
                accent: _settingsRed,
                onTap: clearData,
              ),
            ),

            _sectionTitle('Information'),

            _settingsCard(
              child: _settingsTile(
                icon: Icons.info_outline_rounded,
                title: 'About',
                subtitle: 'Application information and details',
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
