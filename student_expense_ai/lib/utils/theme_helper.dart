import 'package:flutter/material.dart';
import '../database/database_helper.dart';

class ThemeHelper extends ChangeNotifier {
  static final ThemeHelper instance = ThemeHelper._();

  ThemeHelper._();

  ThemeMode themeMode = ThemeMode.light;

  Future<void> loadTheme() async {
    final settings = await DatabaseHelper.instance.getSettings();

    String theme = settings["theme"] ?? "System";

    switch (theme) {
      case "Dark":
        themeMode = ThemeMode.dark;
        break;

      case "Light":
        themeMode = ThemeMode.light;
        break;

      case "System":
      default:
        themeMode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }

  Future<void> changeTheme(String theme) async {
    await DatabaseHelper.instance.updateTheme(theme);

    switch (theme) {
      case "Dark":
        themeMode = ThemeMode.dark;
        break;

      case "Light":
        themeMode = ThemeMode.light;
        break;

      case "System":
      default:
        themeMode = ThemeMode.system;
        break;
    }

    notifyListeners();
  }
}
