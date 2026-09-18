import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

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

  @override
  void initState() {
    super.initState();

    ShowcaseView.register(
      autoPlay: false,

      disableMovingAnimation: true,

      disableScaleAnimation: true,

      onComplete: (index, key) {
        handleTutorialComplete(index, key);
      },

      onFinish: () {
        debugPrint("Tutorial finished");
      },

      onDismiss: (key) {
        debugPrint("Tutorial dismissed");
      },
    );

    if (widget.showTutorial) {
      tutorialActive = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        startHomeTutorial();
      });
    }
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
      tutorialActive = false;

      debugPrint("All tutorials completed");

      return;
    }
  }

  // ============================================================
  // ANALYTICS TUTORIAL TAP
  // ============================================================

  void handleAnalyticsTutorialTap() {
    if (!tutorialActive || !homeTutorialFinished) {
      return;
    }

    setState(() {
      currentIndex = 1;
      refreshKey++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      startAnalyticsTutorial();
    });
  }

  // ============================================================
  // ADVISOR TUTORIAL TAP
  // ============================================================

  void handleAdvisorTutorialTap() {
    if (!tutorialActive || !analyticsTutorialFinished) {
      return;
    }

    setState(() {
      currentIndex = 2;
      refreshKey++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      startAdvisorTutorial();
    });
  }

  // ============================================================
  // SETTINGS TUTORIAL TAP
  // ============================================================

  void handleSettingsTutorialTap() {
    if (!tutorialActive || !advisorTutorialFinished) {
      return;
    }

    setState(() {
      currentIndex = 3;
      refreshKey++;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !tutorialActive) return;

      startSettingsTutorial();
    });
  }

  // ============================================================
  // NORMAL NAVIGATION
  // ============================================================

  void handleNavigation(int index) {
    // During tutorial, navigation is controlled by the
    // highlighted tutorial targets.
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
