import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import 'package:student_expense_ai/models/category.dart';
import 'package:intl/intl.dart';

const Color _primaryPurple = Color(0xFF5B45B5);
const Color _pageBackground = Color(0xFFF7F7FB);
const Color _borderColor = Color(0xFFECEAF3);
const Color _mutedColor = Color(0xFF85839A);
const Color _expenseRed = Color(0xFFE05252);
const Color _incomeGreen = Color(0xFF159A75);

Future<bool?> showAddModal(
  BuildContext context, {
  Map<String, dynamic>? transaction,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => AddModalPage(transaction: transaction)),
  );
}

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text.replaceAll(',', '');

    // Allow empty input.
    if (rawText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Allow digits and up to two decimal places.
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(rawText)) {
      return oldValue;
    }

    final decimalIndex = rawText.indexOf('.');
    final integerPart = decimalIndex == -1
        ? rawText
        : rawText.substring(0, decimalIndex);

    final decimalPart = decimalIndex == -1
        ? ''
        : rawText.substring(decimalIndex);

    final formattedInteger = integerPart.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );

    final formattedText = '$formattedInteger$decimalPart';

    // Keep the cursor near its original position.
    final oldCursor = newValue.selection.baseOffset.clamp(
      0,
      newValue.text.length,
    );

    final charactersBeforeCursor = newValue.text
        .substring(0, oldCursor)
        .replaceAll(',', '')
        .length;

    int newCursor = 0;
    int countedCharacters = 0;

    while (newCursor < formattedText.length &&
        countedCharacters < charactersBeforeCursor) {
      if (formattedText[newCursor] != ',') {
        countedCharacters++;
      }
      newCursor++;
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }
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

  String selectedType = "Budget";
  Category? selectedCategory;
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    initializeTransaction();
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  Future<void> initializeTransaction() async {
    if (widget.transaction != null) {
      selectedType = widget.transaction!["type"];

      final amount = (widget.transaction!["amount"] as num).toDouble();

      amountController.text = NumberFormat('#,##0.00').format(amount);

      noteController.text = widget.transaction!["note"] ?? "";
    }

    final data = await loadCategories();

    if (widget.transaction != null) {
      final categoryId = widget.transaction!["categoryId"];

      selectedCategory = data.firstWhere(
        (category) => category.id == categoryId,
      );

      if (mounted) setState(() {});
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
    if (selectedType != "Expense") return false;

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

    if (widget.transaction != null &&
        widget.transaction!["type"] == "Expense") {
      final oldCreatedAt = DateTime.parse(widget.transaction!["createdAt"]);

      if (oldCreatedAt.month == now.month && oldCreatedAt.year == now.year) {
        currentMonthlyExpenses -= (widget.transaction!["amount"] as num)
            .toDouble();
      }
    }

    if (currentMonthlyExpenses < 0) {
      currentMonthlyExpenses = 0;
    }

    final projectedExpenses = currentMonthlyExpenses + newAmount;
    return projectedExpenses > monthlyBudget;
  }

  Future<void> saveTransaction() async {
    if (amountController.text.isEmpty || selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all fields"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.replaceAll(',', ''));

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a valid amount"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // CHECK FOR EXCESS SPENDING
    if (selectedType == "Expense") {
      final hasBudget = await DatabaseHelper.instance.hasCurrentMonthBudget();

      if (!hasBudget) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Please add a budget for this month before recording an expense.",
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

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

        if (widget.transaction != null &&
            widget.transaction!["type"] == "Expense") {
          final oldDate = DateTime.parse(widget.transaction!["createdAt"]);

          if (oldDate.month == now.month && oldDate.year == now.year) {
            monthlyExpenses -= (widget.transaction!["amount"] as num)
                .toDouble();
          }
        }

        if (monthlyExpenses < 0) {
          monthlyExpenses = 0;
        }

        final projectedExpenses = monthlyExpenses + amount;

        final remainingBudget = (monthlyBudget - monthlyExpenses).clamp(
          0.0,
          double.infinity,
        );

        final projectedExcess = (projectedExpenses - monthlyBudget).clamp(
          0.0,
          double.infinity,
        );

        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: _expenseRed),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Excess Spending Warning",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                "Your remaining budget is "
                "₱${remainingBudget.toStringAsFixed(2)}.\n\n"
                "This expense is ₱${amount.toStringAsFixed(2)}.\n\n"
                "Recording this expense will result in "
                "₱${projectedExcess.toStringAsFixed(2)} "
                "of excess spending.\n\n"
                "Do you want to continue?",
                style: const TextStyle(height: 1.45),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: _mutedColor),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    "Proceed",
                    style: TextStyle(
                      color: _expenseRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (shouldProceed != true) return;
      }
    }

    // PREPARE DATA
    final data = {
      "amount": amount,
      "categoryId": selectedCategory!.id,
      "note": noteController.text.trim(),
      "createdAt": widget.transaction != null
          ? widget.transaction!["createdAt"]
          : DateTime.now().toIso8601String(),
    };

    // EDIT MODE
    if (widget.transaction != null) {
      final oldType = widget.transaction!["type"];
      final id = widget.transaction!["id"];

      if (oldType == selectedType) {
        if (selectedType == "Expense") {
          await DatabaseHelper.instance.updateExpenses(id, data);
        } else {
          await DatabaseHelper.instance.updateBudget(id, data);
        }
      } else {
        if (oldType == "Expense" && selectedType == "Budget") {
          await DatabaseHelper.instance.deleteExpenses(id);
          await DatabaseHelper.instance.insertBudget(data);
        } else if (oldType == "Budget" && selectedType == "Expense") {
          await DatabaseHelper.instance.deleteBudget(id);
          await DatabaseHelper.instance.insertExpense(data);
        }
      }
    } else {
      // ADD MODE
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
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: _mutedColor,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? "Edit Transaction" : "Add Transaction",
          style: const TextStyle(
            color: Color(0xFF29263A),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: saveTransaction,
            child: const Text(
              "Save",
              style: TextStyle(
                color: _primaryPurple,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "What do you want to add?",
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: Color(0xFF29263A),
              ),
            ),
            const SizedBox(height: 14),

            // EXPENSE / BUDGET SELECTOR
            Row(
              children: [
                Expanded(
                  child: _typeButton(
                    title: "Expense",
                    icon: Icons.receipt_long_rounded,
                    type: "Expense",
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _typeButton(
                    title: "Budget",
                    icon: Icons.account_balance_wallet_rounded,
                    type: "Budget",
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // AMOUNT FIELD
            _fieldLabel("Amount"),
            const SizedBox(height: 7),
            Container(
              height: 58,
              decoration: _fieldDecoration(),
              child: TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF29263A),
                ),
                decoration: const InputDecoration(
                  prefixIcon: Icon(
                    Icons.payments_outlined,
                    color: _primaryPurple,
                    size: 21,
                  ),
                  prefixText: "₱ ",
                  prefixStyle: TextStyle(
                    color: _primaryPurple,
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                  hintText: "0.00",
                  hintStyle: TextStyle(color: Color(0xFFB9B5C9)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 17),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // DESCRIPTION FIELD
            _fieldLabel("Note / Description"),
            const SizedBox(height: 7),
            Container(
              decoration: _fieldDecoration(),
              child: TextField(
                controller: noteController,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Enter details (optional)",
                  hintStyle: TextStyle(color: _mutedColor, fontSize: 13),
                  prefixIcon: Icon(
                    Icons.notes_rounded,
                    color: _primaryPurple,
                    size: 21,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.fromLTRB(0, 14, 12, 12),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // CATEGORY
            Row(
              children: [
                _fieldLabel("Category"),
                const Spacer(),
                if (selectedCategory != null)
                  Text(
                    selectedCategory!.name,
                    style: const TextStyle(
                      color: _primaryPurple,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 9),

            if (categories.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: _fieldDecoration(),
                child: const Text(
                  "No categories available",
                  style: TextStyle(color: _mutedColor, fontSize: 13),
                ),
              )
            else
              Wrap(
                spacing: 7,
                runSpacing: 7,
                children: categories.map((category) {
                  final selected = selectedCategory?.id == category.id;

                  return ChoiceChip(
                    avatar: Icon(
                      category.icon,
                      size: 15,
                      color: selected ? Colors.white : _primaryPurple,
                    ),
                    label: Text(category.name),
                    selected: selected,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: selected ? Colors.white : const Color(0xFF514D66),
                    ),
                    selectedColor: _primaryPurple,
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: selected ? _primaryPurple : _borderColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    visualDensity: const VisualDensity(
                      horizontal: -2,
                      vertical: -2,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    onSelected: (value) {
                      setState(() {
                        selectedCategory = value ? category : null;
                      });
                    },
                  );
                }).toList(),
              ),
            const SizedBox(height: 22),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: saveTransaction,
                icon: const Icon(Icons.check_rounded, size: 19),
                label: Text(
                  isEditing ? "Save Changes" : "Save Transaction",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryPurple,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF302C43),
      ),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _borderColor),
    );
  }

  Widget _typeButton({
    required String title,
    required IconData icon,
    required String type,
  }) {
    final selected = selectedType == type;
    final accent = type == "Expense" ? _expenseRed : _incomeGreen;

    return Material(
      color: selected ? _primaryPurple.withValues(alpha: 0.08) : Colors.white,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () {
          setState(() {
            selectedType = type;
            selectedCategory = null;
          });
          loadCategories();
        },
        child: Container(
          height: 58,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: selected ? _primaryPurple : _borderColor),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: selected
                      ? _primaryPurple
                      : accent.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? _primaryPurple : const Color(0xFF514D66),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
