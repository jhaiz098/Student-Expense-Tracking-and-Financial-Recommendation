import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import 'package:student_expense_ai/models/category.dart';

Future<bool?> showAddModal(
  BuildContext context, {
  Map<String, dynamic>? transaction,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AddModalPage(transaction: transaction)),
  );
}

class AddModalPage extends StatefulWidget {
  final Map<String, dynamic>? transaction;

  const AddModalPage({super.key, this.transaction});

  @override
  State<AddModalPage> createState() => _AddModalPageState();
}

class _AddModalPageState extends State<AddModalPage> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String selectedType = "Expense";
  Category? selectedCategory;

  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    initializeTransaction();
  }

  Future<void> initializeTransaction() async {
    if (widget.transaction != null) {
      selectedType = widget.transaction!["type"];

      amountController.text = widget.transaction!["amount"].toString();

      noteController.text = widget.transaction!["note"] ?? "";
    }

    List<Category> data = await loadCategories();

    if (widget.transaction != null) {
      final categoryId = widget.transaction!["categoryId"];

      selectedCategory = data.firstWhere(
        (category) => category.id == categoryId,
      );

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<List<Category>> loadCategories() async {
    final data = selectedType == "Expense"
        ? await DatabaseHelper.instance.getExpenseCategories()
        : await DatabaseHelper.instance.getBudgetCategories();

    if (mounted) {
      setState(() {
        categories = data;
      });
    }

    return data;
  }

  Future<bool> checkExcessSpending(double newAmount) async {
    // Only expenses affect the budget.
    if (selectedType != "Expense") {
      return false;
    }

    final monthlyBudget = await DatabaseHelper.instance.getCurrentMonthBudget();

    final expenses = await DatabaseHelper.instance.getExpenses();

    final now = DateTime.now();

    double currentMonthlyExpenses = 0;

    for (final expense in expenses) {
      final createdAt = DateTime.parse(expense["createdAt"]);

      if (createdAt.month == now.month && createdAt.year == now.year) {
        currentMonthlyExpenses += (expense["amount"] as num).toDouble();
      }
    }

    // If editing an existing Expense,
    // remove its old amount first.
    if (widget.transaction != null &&
        widget.transaction!["type"] == "Expense") {
      final oldCreatedAt = DateTime.parse(widget.transaction!["createdAt"]);

      if (oldCreatedAt.month == now.month && oldCreatedAt.year == now.year) {
        currentMonthlyExpenses -= (widget.transaction!["amount"] as num)
            .toDouble();
      }
    }

    // Prevent tiny floating-point issues.
    if (currentMonthlyExpenses < 0) {
      currentMonthlyExpenses = 0;
    }

    // Calculate what spending will be after this expense.
    final projectedExpenses = currentMonthlyExpenses + newAmount;

    // If projected spending is greater than the budget,
    // the expense should trigger the warning.
    return projectedExpenses > monthlyBudget;
  }

  Future<void> saveTransaction() async {
    if (amountController.text.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final amount = double.tryParse(amountController.text);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount")),
      );
      return;
    }

    // --------------------------------------------------
    // CHECK FOR EXCESS SPENDING
    // --------------------------------------------------

    if (selectedType == "Expense") {
      final willExceedBudget = await checkExcessSpending(amount);

      if (willExceedBudget) {
        final monthlyBudget = await DatabaseHelper.instance
            .getCurrentMonthBudget();

        final expenses = await DatabaseHelper.instance.getExpenses();

        final now = DateTime.now();

        double monthlyExpenses = 0;

        for (final expense in expenses) {
          final date = DateTime.parse(expense["createdAt"]);

          if (date.month == now.month && date.year == now.year) {
            monthlyExpenses += (expense["amount"] as num).toDouble();
          }
        }

        // If editing an existing current-month expense,
        // remove its old amount from the calculation.
        if (widget.transaction != null &&
            widget.transaction!["type"] == "Expense") {
          final oldDate = DateTime.parse(widget.transaction!["createdAt"]);

          if (oldDate.month == now.month && oldDate.year == now.year) {
            monthlyExpenses -= (widget.transaction!["amount"] as num)
                .toDouble();
          }
        }

        // Prevent negative values caused by floating-point issues.
        if (monthlyExpenses < 0) {
          monthlyExpenses = 0;
        }

        // Spending after adding the new expense.
        final projectedExpenses = monthlyExpenses + amount;

        // Remaining budget should NEVER be negative.
        final remainingBudget = (monthlyBudget - monthlyExpenses).clamp(
          0.0,
          double.infinity,
        );

        // Excess spending after adding the new expense.
        final projectedExcess = (projectedExpenses - monthlyBudget).clamp(
          0.0,
          double.infinity,
        );

        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text("Excess Spending Warning"),

              content: Text(
                "Your remaining budget is "
                "₱${remainingBudget.toStringAsFixed(2)}.\n\n"
                "This expense is "
                "₱${amount.toStringAsFixed(2)}.\n\n"
                "Recording this expense will result in "
                "₱${projectedExcess.toStringAsFixed(2)} "
                "of excess spending.\n\n"
                "Do you want to continue?",
              ),

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
                  child: const Text(
                    "Proceed",
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        // User chose not to continue.
        if (shouldProceed != true) {
          return;
        }
      }
    }

    // --------------------------------------------------
    // PREPARE DATA
    // --------------------------------------------------

    final data = {
      "amount": amount,
      "categoryId": selectedCategory!.id,
      "note": noteController.text.trim(),

      // Preserve original date when editing.
      "createdAt": widget.transaction != null
          ? widget.transaction!["createdAt"]
          : DateTime.now().toIso8601String(),
    };

    // --------------------------------------------------
    // EDIT MODE
    // --------------------------------------------------

    if (widget.transaction != null) {
      final oldType = widget.transaction!["type"];
      final id = widget.transaction!["id"];

      // Same type: update existing record.
      if (oldType == selectedType) {
        if (selectedType == "Expense") {
          await DatabaseHelper.instance.updateExpenses(id, data);
        } else {
          await DatabaseHelper.instance.updateBudget(id, data);
        }
      }
      // Type changed: move record.
      else {
        if (oldType == "Expense" && selectedType == "Budget") {
          await DatabaseHelper.instance.deleteExpenses(id);
          await DatabaseHelper.instance.insertBudget(data);
        } else if (oldType == "Budget" && selectedType == "Expense") {
          await DatabaseHelper.instance.deleteBudget(id);
          await DatabaseHelper.instance.insertExpense(data);
        }
      }
    }
    // --------------------------------------------------
    // ADD MODE
    // --------------------------------------------------
    else {
      if (selectedType == "Expense") {
        await DatabaseHelper.instance.insertExpense(data);
      } else {
        await DatabaseHelper.instance.insertBudget(data);
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.transaction == null
              ? "Added successfully"
              : "Updated successfully",
        ),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        title: Text(
          widget.transaction == null ? "Add Transaction" : "Edit Transaction",
        ),

        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10),

            child: TextButton(
              onPressed: saveTransaction,

              child: const Text(
                "Save",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "What do you want to add?",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 15),

            // Expense / Budget buttons
            Row(
              children: [
                Expanded(
                  child: _typeButton(
                    title: "Expense",
                    icon: Icons.receipt_long,
                    type: "Expense",
                  ),
                ),

                const SizedBox(width: 15),

                Expanded(
                  child: _typeButton(
                    title: "Budget",
                    icon: Icons.account_balance_wallet,
                    type: "Budget",
                  ),
                ),
              ],
            ),

            const SizedBox(height: 25),

            TextField(
              controller: amountController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],

              decoration: InputDecoration(
                labelText: "Amount",
                prefixIcon: const Icon(Icons.attach_money),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            TextField(
              controller: noteController,

              maxLines: 2,

              decoration: InputDecoration(
                labelText: "Note / Description",
                hintText: "Enter details (optional)",
                prefixIcon: const Icon(Icons.notes),

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              "Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 4,

              children: categories.map((category) {
                return ChoiceChip(
                  avatar: Icon(category.icon, size: 15),

                  label: Text(
                    category.name,
                    style: const TextStyle(fontSize: 12),
                  ),

                  selected: selectedCategory?.id == category.id,

                  checkmarkColor: const Color.fromARGB(255, 255, 0, 200),

                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = selected ? category : null;
                    });
                  },

                  visualDensity: const VisualDensity(
                    horizontal: -2,
                    vertical: -2,
                  ),

                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,

                  labelPadding: const EdgeInsets.symmetric(horizontal: 4),

                  padding: EdgeInsets.zero,

                  avatarBorder: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton({
    required String title,
    required IconData icon,
    required String type,
  }) {
    bool selected = selectedType == type;

    return SizedBox(
      height: 50,

      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            selectedType = type;
            selectedCategory = null;
          });

          loadCategories();
        },

        icon: Icon(icon),

        label: Text(title),

        style: ElevatedButton.styleFrom(
          backgroundColor: selected
              ? Theme.of(context).colorScheme.primary
              : Colors.grey.shade300,

          foregroundColor: selected ? Colors.white : Colors.black,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
