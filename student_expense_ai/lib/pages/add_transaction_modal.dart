import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void showAddModal(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AddModalPage()),
  );
}

class AddModalPage extends StatefulWidget {
  const AddModalPage({super.key});

  @override
  State<AddModalPage> createState() => _AddModalPageState();
}

class _AddModalPageState extends State<AddModalPage> {
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String selectedType = "Expense";
  String? selectedCategory;

  final expenseCategories = [
    Category(name: "Food", icon: Icons.restaurant),

    Category(name: "Transportation", icon: Icons.directions_car),

    Category(name: "School", icon: Icons.school),

    Category(name: "Bills", icon: Icons.receipt_long),

    Category(name: "Entertainment", icon: Icons.movie),

    Category(name: "Others", icon: Icons.more_horiz),
  ];

  final budgetCategories = [
    Category(name: "Monthly Budget", icon: Icons.calendar_month),

    Category(name: "Weekly Budget", icon: Icons.date_range),

    Category(name: "Savings", icon: Icons.savings),

    Category(name: "Emergency Fund", icon: Icons.health_and_safety),
  ];

  Future<void> saveTransaction() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        return;
      }

      if (amountController.text.isEmpty || selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please complete all fields")),
        );
        return;
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .collection("transactions")
          .add({
            "type": selectedType,
            "amount": double.parse(amountController.text),
            "category": selectedCategory,
            "note": noteController.text.trim(),
            "createdAt": Timestamp.now(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction saved successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = selectedType == "Expense"
        ? expenseCategories
        : budgetCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Transaction"),
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
                  selected: selectedCategory == category.name,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        selectedCategory = category.name;
                      } else {
                        selectedCategory = null;
                      }
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
          });
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

class Category {
  final String name;
  final IconData icon;

  Category({required this.name, required this.icon});
}
