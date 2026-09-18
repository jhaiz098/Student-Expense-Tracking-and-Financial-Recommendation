import 'package:flutter/material.dart';
import '../pages/add_transaction_modal.dart';
import 'package:showcaseview/showcaseview.dart';

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

  // ------------------------------------------------------------
  // Tutorial styling
  // ------------------------------------------------------------

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

      tooltipBackgroundColor: Colors.deepPurple,

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

      // Makes the next highlight appear immediately.
      disableMovingAnimation: true,
      disableScaleAnimation: true,

      // Prevent tapping the dark overlay from advancing.
      disableBarrierInteraction: true,

      // Tapping the highlighted target closes this showcase.
      disposeOnTap: true,

      // This is what lets the user physically tap
      // Analytics / Advisor / Settings.
      onTargetClick: onTargetClick,

      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,

      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,

        children: [
          // ------------------------------------------------------
          // NAVIGATION BAR
          // ------------------------------------------------------
          NavigationBar(
            height: 70,

            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: "Home",
              ),

              // ANALYTICS
              NavigationDestination(
                icon: navShowcase(
                  key: analyticsNavKey,

                  title: "Analytics",

                  description:
                      "Tap Analytics to view your spending trends, categories, and monthly comparisons.",

                  onTargetClick: onAnalyticsTutorialTap,

                  child: const Icon(Icons.analytics_outlined),
                ),

                selectedIcon: const Icon(Icons.analytics),

                label: "Analytics",
              ),

              // CENTER EMPTY SPACE
              const NavigationDestination(icon: SizedBox(), label: ""),

              // ADVISOR
              NavigationDestination(
                icon: navShowcase(
                  key: advisorNavKey,

                  title: "AI Advisor",

                  description:
                      "Tap Advisor to get personalized financial recommendations based on your spending.",

                  onTargetClick: onAdvisorTutorialTap,

                  child: const Icon(Icons.smart_toy_outlined),
                ),

                selectedIcon: const Icon(Icons.smart_toy),

                label: "Advisor",
              ),

              // SETTINGS
              NavigationDestination(
                icon: navShowcase(
                  key: settingsNavKey,

                  title: "Settings",

                  description:
                      "Tap Settings to manage your profile, currency, theme, reminders, categories, and other preferences.",

                  onTargetClick: onSettingsTutorialTap,

                  child: const Icon(Icons.settings),
                ),

                selectedIcon: const Icon(Icons.settings),

                label: "Settings",
              ),
            ],

            selectedIndex: currentIndex < 2 ? currentIndex : currentIndex + 1,

            // ----------------------------------------------------
            // NORMAL NAVIGATION
            // ----------------------------------------------------
            onDestinationSelected: (index) {
              // Center "+" button
              if (index == 2) {
                return;
              }

              if (index > 2) {
                onTap(index - 1);
              } else {
                onTap(index);
              }
            },
          ),

          // ------------------------------------------------------
          // ADD TRANSACTION
          // ------------------------------------------------------
          Positioned(
            bottom: 7,

            child: Showcase(
              key: addTransactionKey,

              title: "Add Transaction",

              description:
                  "Use this button to record your monthly budget or an expense.",

              targetBorderRadius: BorderRadius.circular(50),

              overlayOpacity: 0.65,

              tooltipBackgroundColor: Colors.deepPurple,

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

              child: FloatingActionButton(
                onPressed: () async {
                  final result = await showAddModal(context);

                  if (result == true) {
                    onTransactionAdded();
                  }
                },

                elevation: 6,

                shape: const CircleBorder(),

                child: const Icon(Icons.add, size: 30),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
