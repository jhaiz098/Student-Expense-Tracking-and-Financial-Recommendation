import 'package:flutter/material.dart';

import 'home_page.dart';
import 'analytics_page.dart';
// import 'insights_page.dart';
import 'settings_page.dart';
import '../widgets/bottom_nav.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  int refreshKey = 0;

  void refreshPages() {
    setState(() {
      refreshKey++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(key: ValueKey(refreshKey)),
      AnalyticsPage(key: ValueKey(refreshKey)),
      SettingsPage(key: ValueKey(refreshKey)),
    ];

    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,

        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },

        onTransactionAdded: refreshPages,
      ),
    );
  }
}
