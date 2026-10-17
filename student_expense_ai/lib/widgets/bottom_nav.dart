import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../pages/add_transaction_modal.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onTransactionAdded;

  final GlobalKey addTransactionKey;

  // Tutorial keys
  final GlobalKey analyticsNavKey;
  final GlobalKey advisorNavKey;
  final GlobalKey settingsNavKey;

  // Tutorial navigation callbacks
  final VoidCallback onAnalyticsTutorialTap;
  final VoidCallback onAdvisorTutorialTap;
  final VoidCallback onSettingsTutorialTap;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onTransactionAdded,
    required this.addTransactionKey,
    required this.analyticsNavKey,
    required this.advisorNavKey,
    required this.settingsNavKey,
    required this.onAnalyticsTutorialTap,
    required this.onAdvisorTutorialTap,
    required this.onSettingsTutorialTap,
  });

  static const Color _purple = Color(0xFF5B45B5);
  static const Color _lightBackground = Color(0xFFF7F7FB);
  static const Color _lightBorder = Color(0xFFE7E4F0);

  Widget navShowcase({
    required GlobalKey key,
    required String title,
    required String description,
    required Widget child,
    required VoidCallback onTargetClick,
  }) {
    return Showcase(
      key: key,
      title: title,
      description: description,
      targetBorderRadius: BorderRadius.circular(12),
      overlayOpacity: 0.65,
      tooltipBackgroundColor: _purple,
      tooltipBorderRadius: BorderRadius.circular(16),
      tooltipPadding: const EdgeInsets.all(16),
      textColor: Colors.white,
      titleTextStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      descTextStyle: const TextStyle(
        fontSize: 14,
        height: 1.4,
        color: Colors.white,
      ),
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      disableBarrierInteraction: true,
      disposeOnTap: false,
      onTargetClick: onTargetClick,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final barColor = isDark ? const Color(0xFF211D2D) : Colors.white;

    final borderColor = isDark ? const Color(0xFF393246) : _lightBorder;

    final selectedColor = isDark ? const Color(0xFFB9A8FF) : _purple;

    final unselectedColor = isDark
        ? const Color(0xFFB7B2C8)
        : const Color(0xFF6F6B82);

    return SizedBox(
      height: 88,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Navigation bar
          Positioned(
            left: 12,
            right: 12,
            bottom: 8,
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: barColor,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: isDark ? 0.16 : 0.045,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: NavigationBar(
                  height: 68,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  indicatorShape: const CircleBorder(),
                  selectedIndex: currentIndex < 2
                      ? currentIndex
                      : currentIndex + 1,
                  indicatorColor: selectedColor.withValues(alpha: 0.10),
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((
                    states,
                  ) {
                    final selected = states.contains(WidgetState.selected);

                    return TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected ? selectedColor : unselectedColor,
                    );
                  }),
                  onDestinationSelected: (index) {
                    // Reserve the middle position for the add button.
                    if (index == 2) return;

                    final pageIndex = index > 2 ? index - 1 : index;

                    // Handle tutorial navigation explicitly.
                    if (pageIndex == 1) {
                      onAnalyticsTutorialTap();
                      return;
                    }

                    if (pageIndex == 2) {
                      onAdvisorTutorialTap();
                      return;
                    }

                    if (pageIndex == 3) {
                      onSettingsTutorialTap();
                      return;
                    }

                    onTap(pageIndex);
                  },
                  destinations: [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined, color: unselectedColor),
                      selectedIcon: Icon(
                        Icons.home_rounded,
                        color: selectedColor,
                      ),
                      label: 'Home',
                    ),

                    NavigationDestination(
                      icon: navShowcase(
                        key: analyticsNavKey,
                        title: 'Analytics',
                        description:
                            'Tap Analytics to view your spending trends, categories, and monthly comparisons.',
                        onTargetClick: onAnalyticsTutorialTap,
                        child: Icon(
                          Icons.analytics_outlined,
                          color: unselectedColor,
                        ),
                      ),
                      selectedIcon: Icon(
                        Icons.analytics_rounded,
                        color: selectedColor,
                      ),
                      label: 'Analytics',
                    ),

                    // Center space for the floating add button.
                    const NavigationDestination(
                      icon: SizedBox(width: 32, height: 24),
                      label: '',
                    ),

                    NavigationDestination(
                      icon: navShowcase(
                        key: advisorNavKey,
                        title: 'AI Advisor',
                        description:
                            'Tap Advisor to get personalized financial recommendations based on your spending.',
                        onTargetClick: onAdvisorTutorialTap,
                        child: Icon(
                          Icons.smart_toy_outlined,
                          color: unselectedColor,
                        ),
                      ),
                      selectedIcon: Icon(
                        Icons.smart_toy_rounded,
                        color: selectedColor,
                      ),
                      label: 'Advisor',
                    ),

                    NavigationDestination(
                      icon: navShowcase(
                        key: settingsNavKey,
                        title: 'Settings',
                        description:
                            'Tap Settings to manage your profile, currency, theme, reminders, categories, and other preferences.',
                        onTargetClick: onSettingsTutorialTap,
                        child: Icon(
                          Icons.settings_outlined,
                          color: unselectedColor,
                        ),
                      ),
                      selectedIcon: Icon(
                        Icons.settings_rounded,
                        color: selectedColor,
                      ),
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating add transaction button
          Positioned(
            bottom: 22,
            child: Showcase(
              key: addTransactionKey,
              title: 'Add Transaction',
              description:
                  'Use this button to record your income or an expense.',
              targetBorderRadius: BorderRadius.circular(50),
              overlayOpacity: 0.65,
              tooltipBackgroundColor: _purple,
              tooltipBorderRadius: BorderRadius.circular(16),
              tooltipPadding: const EdgeInsets.all(16),
              textColor: Colors.white,
              titleTextStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              descTextStyle: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.white,
              ),
              disableMovingAnimation: true,
              disableScaleAnimation: true,
              child: Material(
                color: _purple,
                shape: const CircleBorder(),
                elevation: 5,
                shadowColor: _purple.withValues(alpha: 0.35),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () async {
                    final result = await showAddModal(context);

                    if (result == true) {
                      onTransactionAdded();
                    }
                  },
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: barColor, width: 4),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      size: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
