import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionTile extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final IconData icon;
  final String category;
  final String subtitle;
  final String amount;
  final bool isExpense;

  final Future<void> Function() onDelete;
  final Future<void> Function() onTap;
  final Future Function() onEdit;

  const TransactionTile({
    super.key,
    required this.transaction,
    required this.icon,
    required this.category,
    required this.subtitle,
    required this.amount,
    required this.isExpense,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  static const Color _primary = Color(0xFF5B45B5);
  static const Color _expense = Color(0xFFE05252);
  static const Color _income = Color(0xFF159A75);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = isDark ? const Color(0xFF211D2D) : Colors.white;

    final borderColor = isDark
        ? const Color(0xFF393246)
        : const Color(0xFFE7E4F0);

    final textColor = isDark
        ? const Color(0xFFF5F2FF)
        : const Color(0xFF29263A);

    final mutedColor = isDark
        ? const Color(0xFFB7B2C8)
        : const Color(0xFF85839A);

    final primaryColor = isDark ? const Color(0xFFB9A8FF) : _primary;

    final expenseColor = isDark ? const Color(0xFFFF777E) : _expense;

    final incomeColor = isDark ? const Color(0xFF54D6A4) : _income;

    final createdAt = DateTime.tryParse(
      transaction['createdAt']?.toString() ?? '',
    );

    final formattedDate = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt)
        : 'Date unavailable';

    final amountColor = isExpense ? expenseColor : incomeColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () async {
            await onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: isDark ? 0.17 : 0.09),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: primaryColor, size: 22),
                ),

                const SizedBox(width: 12),

                // Transaction details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: mutedColor),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 11,
                            color: mutedColor,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              formattedDate,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: mutedColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Amount and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${isExpense ? '-' : '+'}$amount',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: amountColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ActionButton(
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          color: primaryColor,
                          isDark: isDark,
                          onPressed: () async {
                            await onEdit();
                          },
                        ),
                        const SizedBox(width: 4),
                        _ActionButton(
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          color: expenseColor,
                          isDark: isDark,
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                backgroundColor: isDark
                                    ? const Color(0xFF211D2D)
                                    : Colors.white,
                                surfaceTintColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: BorderSide(color: borderColor),
                                ),
                                title: Text(
                                  'Delete Transaction?',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: textColor,
                                  ),
                                ),
                                content: Text(
                                  'Are you sure you want to delete this transaction?',
                                  style: TextStyle(
                                    color: mutedColor,
                                    height: 1.4,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, false),
                                    child: Text(
                                      'Cancel',
                                      style: TextStyle(color: mutedColor),
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext, true),
                                    child: Text(
                                      'Delete',
                                      style: TextStyle(
                                        color: expenseColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              await onDelete();
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final bool isDark;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.isDark,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      padding: EdgeInsets.zero,
      iconSize: 18,
      style: IconButton.styleFrom(
        backgroundColor: color.withValues(alpha: isDark ? 0.14 : 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      icon: Icon(icon, color: color),
    );
  }
}
