import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

const Color _categoryPurple = Color(0xFF5B45B5);
const Color _categoryBackground = Color(0xFFF7F7FB);
const Color _categoryBorder = Color(0xFFE7E4F0);
const Color _categoryText = Color(0xFF29263A);
const Color _categoryMuted = Color(0xFF6F6B82);
const Color _categoryRed = Color(0xFFE04444);

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  String selectedType = "Expense";
  List<Category> categories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await DatabaseHelper.instance.getCategories(selectedType);

      if (!mounted) return;

      setState(() {
        categories = data;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => isLoading = false);
      _showMessage("Unable to load categories. Please try again.");
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> showCategoryDialog({Category? category}) async {
    final result = await showDialog<_CategoryDialogResult>(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        category: category,
        showIconPicker: showIconPicker,
      ),
    );

    // Cancel returns null and does not touch the database.
    if (result == null || !mounted) return;

    try {
      if (category == null) {
        await DatabaseHelper.instance.insertCategory(
          selectedType,
          result.name,
          result.icon.codePoint,
        );
      } else {
        await DatabaseHelper.instance.updateCategory(
          selectedType,
          category.id,
          result.name,
          result.icon.codePoint,
        );
      }

      if (!mounted) return;

      await loadCategories();

      _showMessage(
        category == null
            ? "Category added successfully"
            : "Category updated successfully",
      );
    } catch (e) {
      _showMessage("Unable to save category. Please try again.");
    }
  }

  Future<IconData?> showIconPicker() async {
    final icons = [
      // Food and daily needs
      Icons.restaurant,
      Icons.local_cafe,
      Icons.fastfood,
      Icons.local_dining,
      Icons.lunch_dining,
      Icons.local_grocery_store,

      // Transportation
      Icons.directions_bus,
      Icons.directions_car,
      Icons.motorcycle,
      Icons.local_taxi,
      Icons.train,
      Icons.flight,

      // School and academics
      Icons.school,
      Icons.menu_book,
      Icons.book,
      Icons.edit,
      Icons.assignment,
      Icons.computer,
      Icons.library_books,
      Icons.calculate,

      // Work and income
      Icons.work,
      Icons.work_outline,
      Icons.account_balance_wallet,
      Icons.payments,
      Icons.card_giftcard,
      Icons.attach_money,
      Icons.request_quote,

      // Finance
      Icons.savings,
      Icons.account_balance,
      Icons.wallet,
      Icons.money,
      Icons.trending_up,
      Icons.credit_card,
      Icons.receipt_long,

      // Technology
      Icons.wifi,
      Icons.phone_android,
      Icons.phone,
      Icons.devices,
      Icons.electrical_services,

      // Entertainment
      Icons.movie,
      Icons.games,
      Icons.music_note,
      Icons.sports_esports,
      Icons.camera_alt,
      Icons.theaters,

      // Personal
      Icons.shopping_bag,
      Icons.shopping_cart,
      Icons.checkroom,
      Icons.face,
      Icons.fitness_center,
      Icons.pets,
      Icons.home,

      // Health
      Icons.medical_services,
      Icons.health_and_safety,
      Icons.local_hospital,
      Icons.medication,
      Icons.favorite,

      // Other
      Icons.warning,
      Icons.category,
      Icons.more_horiz,
      Icons.lightbulb,
      Icons.star,
    ];

    return showDialog<IconData>(
      context: context,
      builder: (pickerContext) {
        return AlertDialog(
          backgroundColor: Theme.of(pickerContext).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              const Expanded(
                child: Text(
                  "Choose Icon",
                  style: TextStyle(
                    color: _categoryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Close",
                onPressed: () => Navigator.pop(pickerContext),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            height: MediaQuery.of(pickerContext).size.height * 0.48,
            child: GridView.builder(
              itemCount: icons.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                return Material(
                  color: _categoryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(pickerContext, icons[index]);
                    },
                    child: Icon(icons[index], size: 25, color: _categoryPurple),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Future<void> deleteCategory(Category category) async {
    try {
      final allCategories = selectedType == "Expense"
          ? await DatabaseHelper.instance.getExpenseCategories()
          : await DatabaseHelper.instance.getBudgetCategories();

      if (!mounted) return;

      // Preserve the last remaining category.
      if (allCategories.length <= 1) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Cannot Delete Category"),
              content: const Text(
                "This is the only category available. "
                "Add another category before deleting it.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("OK"),
                ),
              ],
            );
          },
        );
        return;
      }

      final transactionCount = await DatabaseHelper.instance
          .getCategoryTransactionCount(selectedType, category.id);

      if (!mounted) return;

      // If the category is unused, ask for confirmation.
      if (transactionCount == 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text("Delete Category?"),
              content: Text(
                'Delete "${category.name}"?\n\n'
                'This category is not used by any transactions.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: _categoryMuted),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text(
                    "Delete",
                    style: TextStyle(color: _categoryRed),
                  ),
                ),
              ],
            );
          },
        );

        if (confirm != true || !mounted) return;

        await DatabaseHelper.instance.deleteCategory(selectedType, category.id);

        if (!mounted) return;

        await loadCategories();
        _showMessage('"${category.name}" deleted.');
        return;
      }

      // Preserve transactions by requiring a replacement category.
      final replacementCategories = allCategories
          .where((item) => item.id != category.id)
          .toList();

      Category? selectedReplacement;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: Text(
                  'Delete "${category.name}"?',
                  style: const TextStyle(
                    color: _categoryText,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: _categoryRed.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _categoryRed.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: _categoryRed,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                "This category is used by "
                                "$transactionCount transaction"
                                "${transactionCount == 1 ? '' : 's'}.",
                                style: const TextStyle(
                                  color: _categoryText,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Move transactions to",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _categoryText,
                        ),
                      ),
                      const SizedBox(height: 9),
                      DropdownButtonFormField<Category>(
                        value: selectedReplacement,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: "Select replacement category",
                          filled: true,
                          fillColor: _categoryBackground,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _categoryBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: _categoryBorder,
                            ),
                          ),
                        ),
                        items: replacementCategories.map((item) {
                          return DropdownMenuItem<Category>(
                            value: item,
                            child: Row(
                              children: [
                                Icon(
                                  item.icon,
                                  color: _categoryPurple,
                                  size: 21,
                                ),
                                const SizedBox(width: 10),
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
                        "Your transactions will be preserved and "
                        "reassigned to the selected category.",
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: _categoryMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: _categoryMuted),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: selectedReplacement == null
                        ? null
                        : () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _categoryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE5E3EB),
                      disabledForegroundColor: _categoryMuted,
                      elevation: 0,
                    ),
                    child: const Text("Delete Category"),
                  ),
                ],
              );
            },
          );
        },
      );

      if (confirmed != true || selectedReplacement == null || !mounted) {
        return;
      }

      final replacement = selectedReplacement!;

      await DatabaseHelper.instance.deleteCategoryAndMoveTransactions(
        type: selectedType,
        oldCategoryId: category.id,
        newCategoryId: replacement.id,
      );

      if (!mounted) return;

      await loadCategories();

      _showMessage(
        '"${category.name}" deleted. '
        '$transactionCount transaction'
        '${transactionCount == 1 ? '' : 's'} moved to '
        '"${replacement.name}".',
      );
    } catch (e) {
      _showMessage("Unable to delete category. Please try again.");
    }
  }

  Widget _typeSelector({required String type, required IconData icon}) {
    final isSelected = selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (selectedType == type) return;

          setState(() {
            selectedType = type;
          });

          loadCategories();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: isSelected ? _categoryPurple : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : _categoryMuted,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  type,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _categoryMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryCard(Category category) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.white12 : _categoryBorder),
      ),
      // Material owns the card background and ListTile ink effects.
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 5,
          ),
          leading: Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: _categoryPurple.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(category.icon, color: _categoryPurple, size: 23),
          ),
          title: Text(
            category.name,
            style: const TextStyle(
              color: _categoryText,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "$selectedType category",
              style: const TextStyle(color: _categoryMuted, fontSize: 11),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: "Edit category",
                visualDensity: VisualDensity.compact,
                onPressed: () => showCategoryDialog(category: category),
                icon: const Icon(
                  Icons.edit_outlined,
                  color: _categoryPurple,
                  size: 21,
                ),
              ),
              IconButton(
                tooltip: "Delete category",
                visualDensity: VisualDensity.compact,
                onPressed: () => deleteCategory(category),
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  color: _categoryRed,
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$selectedType Categories",
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _categoryText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${categories.length} "
            "${categories.length == 1 ? 'category' : 'categories'}",
            style: const TextStyle(fontSize: 12, color: _categoryMuted),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 60, 28, 120),
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: _categoryPurple.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.category_outlined,
              size: 38,
              color: _categoryPurple,
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          "No categories yet",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _categoryText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add your first $selectedType category "
          "to keep your records organized.",
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: _categoryMuted,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? Theme.of(context).scaffoldBackgroundColor
          : _categoryBackground,
      appBar: AppBar(
        title: const Text(
          "Manage Categories",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: isDark
            ? Theme.of(context).scaffoldBackgroundColor
            : _categoryBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryDialog(),
        backgroundColor: _categoryPurple,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          "Add Category",
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: isDark ? Colors.white12 : _categoryBorder,
                ),
              ),
              child: Row(
                children: [
                  _typeSelector(type: "Expense", icon: Icons.money_off_rounded),
                  _typeSelector(
                    type: "Budget",
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              color: _categoryPurple,
              onRefresh: loadCategories,
              child: isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 180),
                        Center(
                          child: CircularProgressIndicator(
                            color: _categoryPurple,
                          ),
                        ),
                      ],
                    )
                  : categories.isEmpty
                  ? _emptyState()
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                      children: [
                        _sectionHeader(),
                        ...categories.map(_categoryCard),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// The editor owns its controller. It is disposed only when the editor
// itself is removed from the widget tree.
class _CategoryDialogResult {
  final String name;
  final IconData icon;

  const _CategoryDialogResult({required this.name, required this.icon});
}

class _CategoryEditorDialog extends StatefulWidget {
  final Category? category;
  final Future<IconData?> Function() showIconPicker;

  const _CategoryEditorDialog({
    required this.category,
    required this.showIconPicker,
  });

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  late IconData _selectedIcon;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.category?.name ?? "");

    _selectedIcon = widget.category?.icon ?? Icons.category_rounded;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _chooseIcon() async {
    final icon = await widget.showIconPicker();

    if (!mounted || icon == null) return;

    setState(() {
      _selectedIcon = icon;
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _CategoryDialogResult(
        name: _nameController.text.trim(),
        icon: _selectedIcon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        widget.category == null ? "Add Category" : "Edit Category",
        style: const TextStyle(
          color: _categoryText,
          fontSize: 19,
          fontWeight: FontWeight.w800,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "CATEGORY NAME",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _categoryMuted,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: "Enter category name",
                  counterText: "",
                  filled: true,
                  fillColor: _categoryBackground,
                  prefixIcon: const Icon(
                    Icons.label_outline_rounded,
                    color: _categoryPurple,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _categoryBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _categoryBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: _categoryPurple,
                      width: 1.5,
                    ),
                  ),
                ),
                validator: (value) {
                  final name = value?.trim() ?? "";

                  if (name.isEmpty) {
                    return "Please enter a category name";
                  }

                  if (name.length > 30) {
                    return "Name must be 30 characters or fewer";
                  }

                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                "CATEGORY ICON",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _categoryMuted,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _categoryPurple.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _categoryPurple.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _categoryPurple,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(_selectedIcon, size: 30, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Selected icon",
                      style: TextStyle(color: _categoryMuted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _chooseIcon,
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text("Choose Icon"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _categoryPurple,
                          side: const BorderSide(color: _categoryPurple),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Cancel", style: TextStyle(color: _categoryMuted)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _categoryPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(11),
            ),
          ),
          child: const Text(
            "Save",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
