import 'package:flutter/material.dart';
import '../pages/add_transaction_modal.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onTransactionAdded;

  const BottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onTransactionAdded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          // Bottom navigation background
          NavigationBar(
            height: 70,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: "Home",
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: "Analytics",
              ),
              NavigationDestination(icon: SizedBox(), label: ""),
              NavigationDestination(
                icon: Icon(Icons.smart_toy_outlined),
                selectedIcon: Icon(Icons.smart_toy),
                label: "Insights",
              ),
              NavigationDestination(
                icon: Icon(Icons.settings),
                selectedIcon: Icon(Icons.settings),
                label: "Settings",
              ),
            ],
            selectedIndex: currentIndex < 2 ? currentIndex : currentIndex + 1,

            onDestinationSelected: (index) {
              if (index == 2) return;

              if (index > 2) {
                onTap(index - 1);
              } else {
                onTap(index);
              }
            },
          ),

          // Center + Button
          Positioned(
            bottom: 7,
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
        ],
      ),
    );
  }
}
