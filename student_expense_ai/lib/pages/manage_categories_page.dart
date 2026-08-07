import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  String selectedType = "Expense";

  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final data = await DatabaseHelper.instance.getCategories(selectedType);

    setState(() {
      categories = data;
    });
  }

  void showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name ?? "");

    IconData selectedIcon = category?.icon ?? Icons.category;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(category == null ? "Add Category" : "Edit Category"),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,

                    maxLength: 30,

                    decoration: const InputDecoration(
                      labelText: "Category Name",
                      counterText: "",
                    ),
                  ),

                  const SizedBox(height: 20),

                  Icon(selectedIcon, size: 40),

                  const SizedBox(height: 10),

                  ElevatedButton.icon(
                    icon: const Icon(Icons.category),

                    label: const Text("Select Icon"),

                    onPressed: () async {
                      final icon = await showIconPicker();

                      if (icon != null) {
                        setDialogState(() {
                          selectedIcon = icon;
                        });
                      }
                    },
                  ),
                ],
              ),

              actions: [
                TextButton(
                  child: const Text("Cancel"),

                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),

                ElevatedButton(
                  child: const Text("Save"),

                  onPressed: () async {
                    final name = nameController.text.trim();

                    if (name.isEmpty) {
                      return;
                    }

                    if (name.length > 30) {
                      return;
                    }

                    if (category == null) {
                      await DatabaseHelper.instance.insertCategory(
                        selectedType,
                        name,
                        selectedIcon.codePoint,
                      );
                    } else {
                      await DatabaseHelper.instance.updateCategory(
                        selectedType,
                        category.id,
                        name,
                        selectedIcon.codePoint,
                      );
                    }

                    Navigator.pop(context);

                    loadCategories();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<IconData?> showIconPicker() async {
    final icons = [
      // Food & Daily Needs
      Icons.restaurant,
      Icons.local_cafe,
      Icons.fastfood,
      Icons.local_dining,

      // Transportation
      Icons.directions_bus,
      Icons.directions_car,
      Icons.motorcycle,
      Icons.local_taxi,

      // School & Academics
      Icons.school,
      Icons.menu_book,
      Icons.book,
      Icons.edit,
      Icons.assignment,
      Icons.computer,

      // Work & Income
      Icons.work,
      Icons.work_outline,
      Icons.account_balance_wallet,
      Icons.payments,
      Icons.card_giftcard,

      // Finance
      Icons.savings,
      Icons.account_balance,
      Icons.wallet,
      Icons.money,
      Icons.attach_money,
      Icons.trending_up,

      // Internet & Technology
      Icons.wifi,
      Icons.phone_android,
      Icons.phone,
      Icons.devices,

      // Entertainment
      Icons.movie,
      Icons.games,
      Icons.music_note,
      Icons.sports_esports,

      // Personal
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.checkroom,
      Icons.face,
      Icons.fitness_center,

      // Health
      Icons.medical_services,
      Icons.health_and_safety,
      Icons.local_hospital,

      // Emergency / Others
      Icons.warning,
      Icons.category,
      Icons.more_horiz,
    ];

    return showDialog<IconData>(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text("Choose Icon")),

              IconButton(
                icon: const Icon(Icons.close),
                tooltip: "Close",
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),

          content: SizedBox(
            width: double.maxFinite,

            child: GridView.builder(
              shrinkWrap: true,

              itemCount: icons.length,

              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
              ),

              itemBuilder: (context, index) {
                return IconButton(
                  icon: Icon(icons[index], size: 26),

                  onPressed: () {
                    Navigator.pop(context, icons[index]);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteCategory(Category category) async {
    // Get all categories for the current type
    final allCategories = selectedType == "Expense"
        ? await DatabaseHelper.instance.getExpenseCategories()
        : await DatabaseHelper.instance.getBudgetCategories();

    // Prevent deleting the only remaining category
    if (allCategories.length <= 1) {
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Cannot Delete Category"),
            content: const Text(
              "This category cannot be deleted because it is "
              "the only category available. Add another category first.",
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );

      return;
    }

    // Count transactions using this category
    final transactionCount = await DatabaseHelper.instance
        .getCategoryTransactionCount(selectedType, category.id);

    // No transactions use this category
    if (transactionCount == 0) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Delete Category"),
            content: Text(
              'Delete "${category.name}"?\n\n'
              'This category is not being used by any transactions.',
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
                  "Delete",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
        await DatabaseHelper.instance.deleteCategory(selectedType, category.id);

        await loadCategories();
      }

      return;
    }

    // Remove the current category from the replacement choices
    final replacementCategories = allCategories
        .where((item) => item.id != category.id)
        .toList();

    if (!mounted) return;

    Category? selectedReplacement;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Delete "${category.name}"?'),

              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "This category is used by "
                    "$transactionCount transaction"
                    "${transactionCount == 1 ? "" : "s"}.",
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    "Move those transactions to:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  DropdownButtonFormField<Category>(
                    value: selectedReplacement,
                    isExpanded: true,

                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),

                    hint: const Text("Select category"),

                    items: replacementCategories.map((item) {
                      return DropdownMenuItem<Category>(
                        value: item,
                        child: Row(
                          children: [
                            Icon(item.icon, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),

                    onChanged: (value) {
                      setDialogState(() {
                        selectedReplacement = value;
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    "The transactions will not be deleted.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),

              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text("Cancel"),
                ),

                TextButton(
                  onPressed: selectedReplacement == null
                      ? null
                      : () {
                          Navigator.pop(context, true);
                        },
                  child: const Text(
                    "Delete Category",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedReplacement == null) {
      return;
    }

    await DatabaseHelper.instance.deleteCategoryAndMoveTransactions(
      type: selectedType,
      oldCategoryId: category.id,
      newCategoryId: selectedReplacement!.id,
    );

    await loadCategories();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '"${category.name}" deleted. '
          '$transactionCount transaction'
          '${transactionCount == 1 ? "" : "s"} moved to '
          '"${selectedReplacement!.name}".',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Categories")),

      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),

        onPressed: () {
          showCategoryDialog();
        },
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),

            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: "Expense",
                  label: Text("Expense"),
                  icon: Icon(Icons.money_off),
                ),

                ButtonSegment(
                  value: "Budget",
                  label: Text("Budget"),
                  icon: Icon(Icons.wallet),
                ),
              ],

              selected: {selectedType},

              onSelectionChanged: (value) {
                setState(() {
                  selectedType = value.first;
                });

                loadCategories();
              },
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(bottom: 100),

              itemCount: categories.length,

              itemBuilder: (context, index) {
                final category = categories[index];

                return ListTile(
                  leading: Icon(category.icon),
                  title: Text(category.name),

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () {
                          showCategoryDialog(category: category);
                        },
                      ),

                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          deleteCategory(category);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
