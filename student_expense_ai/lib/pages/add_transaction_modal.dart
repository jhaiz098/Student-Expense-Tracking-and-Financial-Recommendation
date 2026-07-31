import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import 'package:student_expense_ai/models/category.dart';

Future<bool?> showAddModal(
  BuildContext context, {
  Map<String, dynamic>? transaction,
}) {
  return Navigator.push<bool>(
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

      setState(() {});
    }
  }

  Future<List<Category>> loadCategories() async {
    final data = selectedType == "Expense"
        ? await DatabaseHelper.instance.getExpenseCategories()
        : await DatabaseHelper.instance.getBudgetCategories();

    setState(() {
      categories = data;
    });

    return data;
  }

  Future<void> saveTransaction() async {
    if (amountController.text.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields")),
      );
      return;
    }

    final data = {
      "amount": double.parse(amountController.text),
      "categoryId": selectedCategory!.id,
      "note": noteController.text.trim(),
      "createdAt": DateTime.now().toIso8601String(),
    };

    // EDIT MODE
    if (widget.transaction != null) {
      final oldType = widget.transaction!["type"];
      final id = widget.transaction!["id"];

      // Same type, just update
      if (oldType == selectedType) {
        if (selectedType == "Expense") {
          await DatabaseHelper.instance.updateExpenses(id, data);
        } else {
          await DatabaseHelper.instance.updateBudget(id, data);
        }
      }
      // Type changed: move record
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
    // ADD MODE
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

      body: Padding(
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

            Text(
              "Category",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: categories.map((category) {
                return ChoiceChip(
                  avatar: Icon(category.icon, size: 18),
                  label: Text(category.name),
                  selected: selectedCategory?.id == category.id,
                  onSelected: (selected) {
                    setState(() {
                      selectedCategory = selected ? category : null;
                    });
                  },
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
