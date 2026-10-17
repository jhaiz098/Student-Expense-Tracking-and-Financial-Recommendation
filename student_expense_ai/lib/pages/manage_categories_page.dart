import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/category.dart';

const Color _categoryPurple = Color(0xFF5B45B5);
const Color _categoryDarkPurple = Color(0xFFB9A8FF);
const Color _categoryBackground = Color(0xFFF7F7FB);
const Color _categoryDarkBackground = Color(0xFF15131E);
const Color _categoryDarkCard = Color(0xFF211D2D);
const Color _categoryBorder = Color(0xFFE7E4F0);
const Color _categoryDarkBorder = Color(0xFF393246);
const Color _categoryText = Color(0xFF29263A);
const Color _categoryDarkText = Color(0xFFF5F2FF);
const Color _categoryMuted = Color(0xFF6F6B82);
const Color _categoryDarkMuted = Color(0xFFB7B2C8);
const Color _categoryRed = Color(0xFFE05252);

const Color _categoryGreen = Color(0xFF159A75);
const Color _categoryDarkGreen = Color(0xFF54D6A4);

class ManageCategoriesPage extends StatefulWidget {
  const ManageCategoriesPage({super.key});

  @override
  State<ManageCategoriesPage> createState() => _ManageCategoriesPageState();
}

class _ManageCategoriesPageState extends State<ManageCategoriesPage> {
  String selectedType = "Expense";
  List<Category> categories = [];
  bool isLoading = true;

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _isDark ? _categoryDarkBackground : _categoryBackground;

  Color get _card => _isDark ? _categoryDarkCard : Colors.white;

  Color get _border => _isDark ? _categoryDarkBorder : _categoryBorder;

  Color get _text => _isDark ? _categoryDarkText : _categoryText;

  Color get _muted => _isDark ? _categoryDarkMuted : _categoryMuted;

  Color get _accent => _isDark ? _categoryDarkPurple : _categoryPurple;

  Color get _softSurface =>
      _isDark ? const Color(0xFF2A2538) : const Color(0xFFFAFAFD);

  Color get _softPurple =>
      _isDark ? const Color(0xFF302844) : const Color(0xFFF6F4FC);

  Color get _typeColor {
    if (selectedType == "Expense") {
      return _isDark ? const Color(0xFFFF777E) : _categoryRed;
    }

    return _isDark ? _categoryDarkGreen : _categoryGreen;
  }

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

    final isDark = Theme.of(context).brightness == Brightness.dark;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(
              color: isDark ? _categoryText : Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: isDark ? Colors.white : _categoryPurple,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
  }

  Future<void> showCategoryDialog({Category? category}) async {
    final result = await showDialog<_CategoryDialogResult>(
      context: context,
      builder: (_) => _CategoryEditorDialog(
        category: category,
        isDark: _isDark,
        type: selectedType,
        showIconPicker: showIconPicker,
      ),
    );

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
        final dark = Theme.of(pickerContext).brightness == Brightness.dark;
        final accent = selectedType == "Expense"
            ? (dark ? const Color(0xFFFF777E) : _categoryRed)
            : (dark ? _categoryDarkGreen : _categoryGreen);
        final textColor = dark ? _categoryDarkText : _categoryText;
        final cardColor = dark ? _categoryDarkCard : Colors.white;

        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  "Choose Icon",
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 19,
                  ),
                ),
              ),
              IconButton(
                tooltip: "Close",
                onPressed: () => Navigator.pop(pickerContext),
                icon: Icon(Icons.close_rounded, color: textColor),
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
                  color: accent.withValues(alpha: dark ? 0.16 : 0.08),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.pop(pickerContext, icons[index]);
                    },
                    child: Icon(icons[index], size: 25, color: accent),
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

      if (allCategories.length <= 1) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) {
            final dark = Theme.of(dialogContext).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: dark ? _categoryDarkCard : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Cannot Delete Category",
                style: TextStyle(
                  color: dark ? _categoryDarkText : _categoryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                "This is the only category available. "
                "Add another category before deleting it.",
                style: TextStyle(
                  color: dark ? _categoryDarkMuted : _categoryMuted,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(
                    "OK",
                    style: TextStyle(
                      color: dark ? _categoryDarkPurple : _categoryPurple,
                    ),
                  ),
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

      if (transactionCount == 0) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final dark = Theme.of(dialogContext).brightness == Brightness.dark;

            return AlertDialog(
              backgroundColor: dark ? _categoryDarkCard : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Text(
                "Delete Category?",
                style: TextStyle(
                  color: dark ? _categoryDarkText : _categoryText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Text(
                'Delete "${category.name}"?\n\n'
                'This category is not used by any transactions.',
                style: TextStyle(
                  color: dark ? _categoryDarkMuted : _categoryMuted,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: dark ? _categoryDarkMuted : _categoryMuted,
                    ),
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

      // Preserve existing transactions by choosing a replacement.
      final replacementCategories = allCategories
          .where((item) => item.id != category.id)
          .toList();

      Category? selectedReplacement;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final dark = Theme.of(dialogContext).brightness == Brightness.dark;
          final textColor = dark ? _categoryDarkText : _categoryText;
          final mutedColor = dark ? _categoryDarkMuted : _categoryMuted;
          final accent = dark ? _categoryDarkPurple : _categoryPurple;
          final cardColor = dark ? _categoryDarkCard : Colors.white;
          final borderColor = dark ? _categoryDarkBorder : _categoryBorder;
          final fieldColor = dark
              ? const Color(0xFF2A2538)
              : _categoryBackground;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                title: Text(
                  'Delete "${category.name}"?',
                  style: TextStyle(
                    color: textColor,
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
                          color: _categoryRed.withValues(
                            alpha: dark ? 0.14 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _categoryRed.withValues(alpha: 0.25),
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
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "Move transactions to",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 9),
                      DropdownButtonFormField<Category>(
                        value: selectedReplacement,
                        isExpanded: true,
                        dropdownColor: cardColor,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          hintText: "Select replacement category",
                          hintStyle: TextStyle(color: mutedColor),
                          filled: true,
                          fillColor: fieldColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: accent, width: 1.5),
                          ),
                        ),
                        items: replacementCategories.map((item) {
                          return DropdownMenuItem<Category>(
                            value: item,
                            child: Row(
                              children: [
                                Icon(item.icon, color: accent, size: 21),
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
                      Text(
                        "Your transactions will be preserved and "
                        "reassigned to the selected category.",
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext, false),
                    child: Text("Cancel", style: TextStyle(color: mutedColor)),
                  ),
                  ElevatedButton(
                    onPressed: selectedReplacement == null
                        ? null
                        : () => Navigator.pop(dialogContext, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _categoryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: dark
                          ? const Color(0xFF393246)
                          : const Color(0xFFE5E3EB),
                      disabledForegroundColor: mutedColor,
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
    final accent = isSelected ? _typeColor : _muted;

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
            color: isSelected ? accent : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : _muted),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  type,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : _muted,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: _border),
      ),
      child: Material(
        color: _card,
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
              color: _typeColor.withValues(alpha: _isDark ? 0.17 : 0.09),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(category.icon, color: _typeColor, size: 23),
          ),
          title: Text(
            category.name,
            style: TextStyle(
              color: _text,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              "$selectedType category",
              style: TextStyle(color: _muted, fontSize: 11),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                tooltip: "Edit category",
                visualDensity: VisualDensity.compact,
                onPressed: () => showCategoryDialog(category: category),
                icon: Icon(Icons.edit_outlined, color: _accent, size: 21),
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
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${categories.length} "
            "${categories.length == 1 ? 'category' : 'categories'}",
            style: TextStyle(fontSize: 12, color: _muted),
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
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.category_outlined, size: 38, color: _accent),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "No categories yet",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Add your first $selectedType category "
          "to keep your records organized.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: Text(
          "Manage Categories",
          style: TextStyle(color: _text, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showCategoryDialog(),
        backgroundColor: _typeColor,
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
                color: _card,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: _border),
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
              color: _accent,
              onRefresh: loadCategories,
              child: isLoading
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 180),
                        Center(
                          child: CircularProgressIndicator(color: _accent),
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

class _CategoryDialogResult {
  final String name;
  final IconData icon;

  const _CategoryDialogResult({required this.name, required this.icon});
}

class _CategoryEditorDialog extends StatefulWidget {
  final Category? category;
  final bool isDark;
  final Future<IconData?> Function() showIconPicker;
  final String type;

  const _CategoryEditorDialog({
    required this.category,
    required this.isDark,
    required this.showIconPicker,
    required this.type,
  });

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  final _formKey = GlobalKey<FormState>();

  late IconData _selectedIcon;

  bool get _isDark => widget.isDark;

  Color get _card => _isDark ? _categoryDarkCard : Colors.white;

  Color get _text => _isDark ? _categoryDarkText : _categoryText;

  Color get _muted => _isDark ? _categoryDarkMuted : _categoryMuted;

  Color get _accent {
    if (widget.type == "Expense") {
      return _isDark ? const Color(0xFFFF777E) : _categoryRed;
    }

    return _isDark ? _categoryDarkGreen : _categoryGreen;
  }

  Color get _field => _isDark ? const Color(0xFF2A2538) : _categoryBackground;

  Color get _border => _isDark ? _categoryDarkBorder : _categoryBorder;

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
      backgroundColor: _card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        widget.category == null ? "Add Category" : "Edit Category",
        style: TextStyle(
          color: _text,
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
              Text(
                "CATEGORY NAME",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 30,
                textCapitalization: TextCapitalization.words,
                style: TextStyle(color: _text),
                decoration: InputDecoration(
                  hintText: "Enter category name",
                  hintStyle: TextStyle(color: _muted),
                  counterText: "",
                  filled: true,
                  fillColor: _field,
                  prefixIcon: Icon(Icons.label_outline_rounded, color: _accent),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _accent, width: 1.5),
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
              Text(
                "CATEGORY ICON",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: _muted,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _softPurple,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _accent.withValues(alpha: 0.22)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(
                        _selectedIcon,
                        size: 30,
                        color: _isDark ? _categoryDarkBackground : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Selected icon",
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _chooseIcon,
                        icon: const Icon(Icons.grid_view_rounded, size: 18),
                        label: const Text("Choose Icon"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _accent,
                          side: BorderSide(color: _accent),
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
          child: Text("Cancel", style: TextStyle(color: _muted)),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: _isDark ? _categoryDarkBackground : Colors.white,
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

  Color get _softPurple =>
      _isDark ? const Color(0xFF302844) : const Color(0xFFF6F4FC);
}
