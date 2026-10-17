import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:async';
import 'home_page.dart';
import 'analytics_page.dart';
import 'advisor_page.dart';
import 'settings_page.dart';
import '../widgets/bottom_nav.dart';

class MainPage extends StatefulWidget {
  final bool showTutorial;

  const MainPage({super.key, this.showTutorial = false});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  int refreshKey = 0;

  // ------------------------------------------------------------
  // HOME TUTORIAL KEYS
  // ------------------------------------------------------------

  final GlobalKey addTransactionKey = GlobalKey();
  final GlobalKey budgetKey = GlobalKey();
  final GlobalKey budgetUsageKey = GlobalKey();

  // ------------------------------------------------------------
  // PAGE TUTORIAL KEYS
  // ------------------------------------------------------------

  final GlobalKey analyticsKey = GlobalKey();
  final GlobalKey advisorKey = GlobalKey();
  final GlobalKey settingsKey = GlobalKey();

  // ------------------------------------------------------------
  // BOTTOM NAV TUTORIAL KEYS
  // ------------------------------------------------------------

  final GlobalKey analyticsNavKey = GlobalKey();
  final GlobalKey advisorNavKey = GlobalKey();
  final GlobalKey settingsNavKey = GlobalKey();

  // ------------------------------------------------------------
  // TUTORIAL STATE
  // ------------------------------------------------------------

  bool tutorialActive = false;

  bool homeTutorialFinished = false;

  bool analyticsTutorialFinished = false;

  bool advisorTutorialFinished = false;

  bool isHandlingTutorialTap = false;

  @override
  void initState() {
    super.initState();

    ShowcaseView.register(
      autoPlay: false,
      disableMovingAnimation: true,
      disableScaleAnimation: true,
      disableBarrierInteraction: true,

      onComplete: (index, key) {
        handleTutorialComplete(index, key);
      },

      onFinish: () {
        if (!mounted) return;

        // Only unlock navigation after reaching the final tutorial section.
        if (currentIndex == 3 &&
            homeTutorialFinished &&
            analyticsTutorialFinished &&
            advisorTutorialFinished) {
          setState(() {
            tutorialActive = false;
          });

          debugPrint("All tutorials finished. Navigation unlocked.");
        } else {
          debugPrint("Current showcase sequence finished.");
        }
      },

      onDismiss: (key) {
        debugPrint("Tutorial dismissed: $key");
      },
    );

    if (widget.showTutorial) {
      tutorialActive = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        startHomeTutorial();
      });
    }
  }

  void exitTutorial() {
    if (!mounted) return;

    ShowcaseView.get().dismiss();

    setState(() {
      tutorialActive = false;
    });
  }

  void recoverTutorial() {
    if (!mounted || !tutorialActive) return;

    setState(() {
      tutorialActive = false;
    });

    ShowcaseView.get().dismiss();
  }

  // ============================================================
  // HOME TUTORIAL
  // ============================================================

  void startHomeTutorial() {
    if (!mounted) return;

    currentIndex = 0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      ShowcaseView.get().startShowCase([
        budgetKey,
        budgetUsageKey,
        addTransactionKey,
      ]);
    });
  }

  // ============================================================
  // ANALYTICS NAVIGATION HIGHLIGHT
  // ============================================================

  void startAnalyticsNavigationTutorial() {
    if (!mounted || !tutorialActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      ShowcaseView.get().startShowCase([analyticsNavKey]);
    });
  }

  // ============================================================
  // ANALYTICS PAGE
  // ============================================================

  void startAnalyticsTutorial() {
    if (!mounted || !tutorialActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      ShowcaseView.get().startShowCase([analyticsKey]);
    });
  }

  // ============================================================
  // ADVISOR NAVIGATION HIGHLIGHT
  // ============================================================

  void startAdvisorNavigationTutorial() {
    if (!mounted || !tutorialActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      ShowcaseView.get().startShowCase([advisorNavKey]);
    });
  }

  // ============================================================
  // ADVISOR PAGE
  // ============================================================

  void startAdvisorTutorial() {
    if (!mounted || !tutorialActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      ShowcaseView.get().startShowCase([advisorKey]);
    });
  }

  // ============================================================
  // SETTINGS NAVIGATION HIGHLIGHT
  // ============================================================

  void startSettingsNavigationTutorial() {
    if (!mounted || !tutorialActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      ShowcaseView.get().startShowCase([settingsNavKey]);
    });
  }

  // ============================================================
  // SETTINGS PAGE
  // ============================================================

  void startSettingsTutorial() {
    if (!mounted || !tutorialActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      ShowcaseView.get().startShowCase([settingsKey]);
    });
  }

  // ============================================================
  // SHOWCASE COMPLETION
  // ============================================================

  void handleTutorialComplete(
    int? index,
    GlobalKey<State<StatefulWidget>> key,
  ) {
    if (!mounted || !tutorialActive) return;

    // ----------------------------------------------------------
    // HOME → ANALYTICS NAVIGATION
    // ----------------------------------------------------------

    if (key == addTransactionKey) {
      homeTutorialFinished = true;
      startAnalyticsNavigationTutorial();
      return;
    }

    // ----------------------------------------------------------
    // ANALYTICS PAGE → ADVISOR NAVIGATION
    // ----------------------------------------------------------

    if (key == analyticsKey) {
      analyticsTutorialFinished = true;

      startAdvisorNavigationTutorial();

      return;
    }

    // ----------------------------------------------------------
    // ADVISOR PAGE → SETTINGS NAVIGATION
    // ----------------------------------------------------------

    if (key == advisorKey) {
      advisorTutorialFinished = true;

      startSettingsNavigationTutorial();

      return;
    }

    // ----------------------------------------------------------
    // SETTINGS → FINISHED
    // ----------------------------------------------------------

    if (key == settingsKey) {
      setState(() {
        tutorialActive = false;
      });

      debugPrint("All tutorials completed");
      return;
    }
  }

  // ============================================================
  // ANALYTICS TUTORIAL TAP
  // ============================================================

  Future<void> handleAnalyticsTutorialTap() async {
    if (!mounted) return;

    // After the tutorial, allow normal navigation.
    if (!tutorialActive) {
      setState(() {
        currentIndex = 1;
      });
      return;
    }

    if (!homeTutorialFinished || isHandlingTutorialTap) return;

    isHandlingTutorialTap = true;

    try {
      ShowcaseView.get().dismiss();

      if (!mounted) return;

      setState(() {
        currentIndex = 1;
        refreshKey++;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || !tutorialActive) return;

      startAnalyticsTutorial();
    } finally {
      isHandlingTutorialTap = false;
    }
  }

  // ============================================================
  // ADVISOR TUTORIAL TAP
  // ============================================================

  Future<void> handleAdvisorTutorialTap() async {
    if (!mounted) return;

    if (!tutorialActive) {
      setState(() {
        currentIndex = 2;
      });
      return;
    }

    if (!analyticsTutorialFinished || isHandlingTutorialTap) return;

    isHandlingTutorialTap = true;

    try {
      ShowcaseView.get().dismiss();

      if (!mounted) return;

      setState(() {
        currentIndex = 2;
        refreshKey++;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || !tutorialActive) return;

      startAdvisorTutorial();
    } finally {
      isHandlingTutorialTap = false;
    }
  }

  // ============================================================
  // SETTINGS TUTORIAL TAP
  // ============================================================

  Future<void> handleSettingsTutorialTap() async {
    if (!mounted) return;

    if (!tutorialActive) {
      setState(() {
        currentIndex = 3;
      });
      return;
    }

    if (!advisorTutorialFinished || isHandlingTutorialTap) return;

    isHandlingTutorialTap = true;

    try {
      ShowcaseView.get().dismiss();

      if (!mounted) return;

      setState(() {
        currentIndex = 3;
        refreshKey++;
      });

      await Future.delayed(const Duration(milliseconds: 300));

      if (!mounted || !tutorialActive) return;

      startSettingsTutorial();
    } finally {
      isHandlingTutorialTap = false;
    }
  }

  // ============================================================
  // NORMAL NAVIGATION
  // ============================================================

  void handleNavigation(int index) {
    if (tutorialActive) {
      return;
    }

    setState(() {
      currentIndex = index;
    });
  }

  // ============================================================
  // REFRESH
  // ============================================================

  void refreshPages() {
    setState(() {
      refreshKey++;
    });
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    ShowcaseView.get().unregister();

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(
        key: ValueKey("home_$refreshKey"),
        budgetKey: budgetKey,
        budgetUsageKey: budgetUsageKey,
      ),

      AnalyticsPage(
        key: ValueKey("analytics_$refreshKey"),
        analyticsKey: analyticsKey,
      ),

      AdvisorPage(key: ValueKey("advisor_$refreshKey"), advisorKey: advisorKey),

      SettingsPage(
        key: ValueKey("settings_$refreshKey"),
        settingsKey: settingsKey,
      ),
    ];

    return Scaffold(
      body: pages[currentIndex],

      bottomNavigationBar: BottomNav(
        currentIndex: currentIndex,

        addTransactionKey: addTransactionKey,

        analyticsNavKey: analyticsNavKey,

        advisorNavKey: advisorNavKey,

        settingsNavKey: settingsNavKey,

        onAnalyticsTutorialTap: handleAnalyticsTutorialTap,

        onAdvisorTutorialTap: handleAdvisorTutorialTap,

        onSettingsTutorialTap: handleSettingsTutorialTap,

        onTap: handleNavigation,

        onTransactionAdded: refreshPages,
      ),
    );
  }
}
