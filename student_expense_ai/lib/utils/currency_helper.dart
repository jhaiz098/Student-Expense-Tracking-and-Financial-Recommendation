import '../database/database_helper.dart';

class CurrencyHelper {
  static String currentCurrency = "PHP";

  static Future<void> loadCurrency() async {
    final settings = await DatabaseHelper.instance.getSettings();

    currentCurrency = settings["currency"];

    print("Loaded currency: $currentCurrency");
  }

  static String getSymbol() {
    switch (currentCurrency) {
      case "USD":
        return "\$";

      case "EUR":
        return "€";

      case "PHP":
      default:
        return "₱";
    }
  }

  static String format(double amount) {
    return "${getSymbol()}${amount.toStringAsFixed(2)}";
  }
}
