import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../database/database_helper.dart';
import 'package:student_expense_ai/models/category.dart';

const Color _primaryPurple = Color(0xFF5B45B5);
const Color _darkPurple = Color(0xFFB9A8FF);
const Color _expenseRed = Color(0xFFE05252);
const Color _incomeGreen = Color(0xFF159A75);

Future<bool?> showAddModal(
  BuildContext context, {
  Map<String, dynamic>? transaction,
}) {
  return Navigator.push<bool>(
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

    if (rawText.isEmpty) {
      return newValue.copyWith(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

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

  String selectedType = 'Budget';
  Category? selectedCategory;
  List<Category> categories = [];

  bool isSaving = false;
  bool isLoadingCategories = false;
  bool categoriesLoaded = false;
  Future<List<Category>>? _categoriesFuture;

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

  Color get _softPurple =>
      _isDark ? const Color(0xFF302844) : const Color(0xFFF6F4FC);

  Color get _accent => _isDark ? _darkPurple : _primaryPurple;

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
      selectedType = widget.transaction!['type']?.toString() ?? 'Budget';

      final rawAmount = widget.transaction!['amount'];
      final amount = rawAmount is num ? rawAmount.toDouble() : 0.0;

      amountController.text = NumberFormat('#,##0.00').format(amount);
      noteController.text = widget.transaction!['note']?.toString() ?? '';
    }

    // Start loading categories immediately, even if Budget is selected.
    final data = await loadCategories();

    if (!mounted) return;

    if (selectedType == 'Expense' && widget.transaction != null) {
      final categoryId = widget.transaction!['categoryId'];

      Category? match;

      for (final category in data) {
        if (category.id == categoryId) {
          match = category;
          break;
        }
      }

      setState(() {
        selectedCategory = match;
      });
    }
  }

  Future<List<Category>> loadCategories() async {
    // Return cached categories instead of querying the database again.
    if (categoriesLoaded) {
      return categories;
    }

    // Reuse the same pending request if categories are already loading.
    if (_categoriesFuture != null) {
      return _categoriesFuture!;
    }

    if (mounted) {
      setState(() {
        isLoadingCategories = true;
      });
    }

    _categoriesFuture = DatabaseHelper.instance.getExpenseCategories();

    try {
      final data = await _categoriesFuture!;

      if (mounted) {
        setState(() {
          categories = data;
          categoriesLoaded = true;
          isLoadingCategories = false;
        });
      }

      return data;
    } catch (e) {
      debugPrint('Failed to load expense categories: $e');

      _categoriesFuture = null;

      if (mounted) {
        setState(() {
          isLoadingCategories = false;
        });
      }

      return [];
    }
  }

  Future<void> changeType(String type) async {
    if (selectedType == type || isSaving) return;

    setState(() {
      selectedType = type;
      selectedCategory = null;
    });

    if (type == 'Expense' && !categoriesLoaded) {
      await loadCategories();
    }
  }

  Future<bool> checkExcessSpending(double newAmount) async {
    if (selectedType != 'Expense') return false;

    final monthlyBudget = await DatabaseHelper.instance.getCurrentMonthBudget();

    final expenses = await DatabaseHelper.instance.getExpenses();
    final now = DateTime.now();

    double currentMonthlyExpenses = 0;

    for (final expense in expenses) {
      final createdAt = DateTime.tryParse(
        expense['createdAt']?.toString() ?? '',
      );

      if (createdAt != null &&
          createdAt.month == now.month &&
          createdAt.year == now.year) {
        currentMonthlyExpenses += (expense['amount'] as num).toDouble();
      }
    }

    if (widget.transaction != null &&
        widget.transaction!['type'] == 'Expense') {
      final oldCreatedAt = DateTime.tryParse(
        widget.transaction!['createdAt']?.toString() ?? '',
      );

      if (oldCreatedAt != null &&
          oldCreatedAt.month == now.month &&
          oldCreatedAt.year == now.year) {
        currentMonthlyExpenses -= (widget.transaction!['amount'] as num)
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
    if (isSaving) return;

    // A category is required for an expense, but not for a budget.
    if (amountController.text.trim().isEmpty ||
        (selectedType == 'Expense' && selectedCategory == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all required fields'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.replaceAll(',', ''));

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      if (selectedType == 'Expense') {
        final hasBudget = await DatabaseHelper.instance.hasCurrentMonthBudget();

        if (!hasBudget) {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please add a budget for this month before recording an expense.',
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
            final date = DateTime.tryParse(
              expense['createdAt']?.toString() ?? '',
            );

            if (date != null &&
                date.month == now.month &&
                date.year == now.year) {
              monthlyExpenses += (expense['amount'] as num).toDouble();
            }
          }

          if (widget.transaction != null &&
              widget.transaction!['type'] == 'Expense') {
            final oldDate = DateTime.tryParse(
              widget.transaction!['createdAt']?.toString() ?? '',
            );

            if (oldDate != null &&
                oldDate.month == now.month &&
                oldDate.year == now.year) {
              monthlyExpenses -= (widget.transaction!['amount'] as num)
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

          if (!mounted) return;

          final shouldProceed = await showDialog<bool>(
            context: context,
            builder: (dialogContext) {
              return AlertDialog(
                backgroundColor: _card,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: _border),
                ),
                title: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: _expenseRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Excess Spending Warning',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: _text,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Text(
                  'Your remaining budget is '
                  '₱${remainingBudget.toStringAsFixed(2)}.\n\n'
                  'This expense is ₱${amount.toStringAsFixed(2)}.\n\n'
                  'Recording this expense will result in '
                  '₱${projectedExcess.toStringAsFixed(2)} '
                  'of excess spending.\n\n'
                  'Do you want to continue?',
                  style: TextStyle(height: 1.5, color: _muted),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text('Cancel', style: TextStyle(color: _muted)),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, true),
                    child: const Text(
                      'Proceed',
                      style: TextStyle(
                        color: _expenseRed,
                        fontWeight: FontWeight.w800,
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

      final createdAt = widget.transaction != null
          ? widget.transaction!['createdAt']
          : DateTime.now().toIso8601String();

      final Map<String, dynamic> data = {
        'amount': amount,
        'note': noteController.text.trim(),
        'createdAt': createdAt,
      };

      if (selectedType == 'Expense') {
        data['categoryId'] = selectedCategory!.id;
      }

      if (widget.transaction != null) {
        final oldType = widget.transaction!['type']?.toString() ?? 'Budget';
        final id = widget.transaction!['id'];

        if (oldType == selectedType) {
          if (selectedType == 'Expense') {
            await DatabaseHelper.instance.updateExpenses(id, data);
          } else {
            await DatabaseHelper.instance.updateBudget(id, data);
          }
        } else {
          if (oldType == 'Expense' && selectedType == 'Budget') {
            await DatabaseHelper.instance.deleteExpenses(id);
            await DatabaseHelper.instance.insertBudget(data);
          } else if (oldType == 'Budget' && selectedType == 'Expense') {
            await DatabaseHelper.instance.deleteBudget(id);
            await DatabaseHelper.instance.insertExpense(data);
          }
        }
      } else {
        if (selectedType == 'Expense') {
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
                ? 'Added successfully'
                : 'Updated successfully',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e, stackTrace) {
      debugPrint('Failed to save transaction: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save transaction. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;

    return Scaffold(
      backgroundColor: _background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          color: _muted,
          tooltip: 'Close',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Transaction' : 'Add Transaction',
          style: TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          TextButton(
            onPressed: isSaving ? null : saveTransaction,
            child: Text(
              'Save',
              style: TextStyle(
                color: isSaving ? _subtle : _accent,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What do you want to add?',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              const SizedBox(height: 14),

              // Keep both Expense and Budget flows.
              Row(
                children: [
                  Expanded(
                    child: _typeButton(
                      title: 'Expense',
                      icon: Icons.receipt_long_rounded,
                      type: 'Expense',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _typeButton(
                      title: 'Budget',
                      icon: Icons.account_balance_wallet_rounded,
                      type: 'Budget',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Amount field
              _fieldLabel('Amount'),
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
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.payments_outlined,
                      color: selectedType == 'Expense'
                          ? _expenseRed
                          : _incomeGreen,
                      size: 21,
                    ),
                    prefixText: '₱ ',
                    prefixStyle: TextStyle(
                      color: selectedType == 'Expense'
                          ? _expenseRed
                          : _incomeGreen,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                    hintText: '0.00',
                    hintStyle: TextStyle(color: _subtle),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                ),
              ),
              const SizedBox(height: 17),

              // Description field
              _fieldLabel('Note / Description'),
              const SizedBox(height: 7),
              Container(
                decoration: _fieldDecoration(),
                child: TextField(
                  controller: noteController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  style: TextStyle(fontSize: 14, color: _text),
                  decoration: InputDecoration(
                    hintText: 'Enter details (optional)',
                    hintStyle: TextStyle(color: _subtle, fontSize: 13),
                    prefixIcon: Icon(
                      Icons.notes_rounded,
                      color: selectedType == 'Expense'
                          ? _expenseRed
                          : _incomeGreen,
                      size: 21,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.fromLTRB(0, 14, 12, 12),
                  ),
                ),
              ),

              // Show categories only for Expense.
              if (selectedType == 'Expense') ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    _fieldLabel('Category'),
                    const Spacer(),
                    if (selectedCategory != null)
                      Flexible(
                        child: Text(
                          selectedCategory!.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),

                if (isLoadingCategories)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: _fieldDecoration(),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _accent,
                        ),
                      ),
                    ),
                  )
                else if (categories.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: _fieldDecoration(),
                    child: Text(
                      'No expense categories available',
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final selected = selectedCategory?.id == category.id;

                      return ChoiceChip(
                        avatar: Icon(
                          category.icon,
                          size: 16,
                          color: selected ? Colors.white : _expenseRed,
                        ),
                        label: Text(category.name),
                        selected: selected,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : _text,
                        ),
                        selectedColor: _primaryPurple,
                        backgroundColor: _card,
                        side: BorderSide(
                          color: selected ? _primaryPurple : _border,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11),
                        ),
                        visualDensity: const VisualDensity(
                          horizontal: -2,
                          vertical: -2,
                        ),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        onSelected: (value) {
                          setState(() {
                            selectedCategory = value ? category : null;
                          });
                        },
                      );
                    }).toList(),
                  ),
              ],

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 49,
                child: ElevatedButton.icon(
                  onPressed: isSaving ? null : saveTransaction,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 19),
                  label: Text(
                    isSaving
                        ? 'Saving...'
                        : isEditing
                        ? 'Save Changes'
                        : 'Save Transaction',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryPurple,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _isDark
                        ? const Color(0xFF393246)
                        : const Color(0xFFE5E3EB),
                    disabledForegroundColor: _isDark
                        ? const Color(0xFF928BA8)
                        : const Color(0xFF777386),
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
      ),
    );
  }

  Widget _fieldLabel(String label) {
    return Text(
      label,
      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _text),
    );
  }

  BoxDecoration _fieldDecoration() {
    return BoxDecoration(
      color: _card,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: _border),
    );
  }

  Widget _typeButton({
    required String title,
    required IconData icon,
    required String type,
  }) {
    final selected = selectedType == type;
    final typeColor = type == 'Expense' ? _expenseRed : _incomeGreen;

    return Material(
      color: selected ? _softPurple : _card,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: () => changeType(type),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: selected ? _accent : _border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: selected
                      ? _primaryPurple
                      : typeColor.withValues(alpha: _isDark ? 0.15 : 0.09),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: selected ? Colors.white : typeColor,
                  size: 19,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: selected ? _accent : _text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
              if (selected)
                Icon(Icons.check_circle_rounded, color: _accent, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
