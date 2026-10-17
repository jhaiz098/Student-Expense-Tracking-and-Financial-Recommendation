import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database_helper.dart';
import '../services/ai_service.dart';
import 'package:showcaseview/showcaseview.dart';
import 'dart:convert';

const Color _advisorPurple = Color.fromARGB(255, 134, 118, 199);
const Color _advisorBackground = Color(0xFFF7F7FB);
const Color _advisorBorder = Color(0xFFECEAF3);
const Color _advisorMuted = Color(0xFF6F6B82);
const Color _advisorText = Color(0xFF29263A);
const Color _advisorGreen = Color(0xFF159A75);
const Color _advisorRed = Color(0xFFE05252);

class AdvisorPage extends StatefulWidget {
  final GlobalKey advisorKey;

  const AdvisorPage({super.key, required this.advisorKey});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  String advice =
      "Generate AI advice to receive personalized recommendations "
      "based on your spending habits.";

  bool hasInternet = false;
  bool isGenerating = false;

  List<Map<String, dynamic>> recommendations = [];

  DateTime? recommendationGeneratedAt;
  DateTime? nextAvailableAt;

  Timer? countdownTimer;
  Duration cooldownRemaining = Duration.zero;

  StreamSubscription? connectivitySubscription;

  @override
  void initState() {
    super.initState();

    checkInternet();
    loadSavedRecommendation();

    connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      result,
    ) {
      //TESTTTT OUTPUT
      // testRemainingBudget();
      // testRemainingDays();
      // testPreviousMonthExpense();
      // testTransactionCount();
      // testCategorySpending();
      // testPatterns();
      // test();

      // testAdvisorData();
      //TESTT OUTPUT

      checkInternet();
    });
  }

  Future<void> loadSavedRecommendation() async {
    try {
      final saved = await DatabaseHelper.instance.getSavedAIRecommendation(
        userId: 1,
      );

      if (!mounted || saved == null) return;

      final decoded = jsonDecode(saved['recommendation'] as String) as List;

      final loadedRecommendations = decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      final generatedAt = DateTime.tryParse(
        saved['generated_at']?.toString() ?? '',
      );

      final availableAt = DateTime.tryParse(
        saved['next_available_at']?.toString() ?? '',
      );

      setState(() {
        recommendations = loadedRecommendations;
        recommendationGeneratedAt = generatedAt;
        nextAvailableAt = availableAt;
      });

      updateCooldown();
    } catch (e) {
      debugPrint('Failed to load saved AI recommendation: $e');
    }
  }

  void updateCooldown() {
    countdownTimer?.cancel();

    void updateRemainingTime() {
      if (!mounted) return;

      final next = nextAvailableAt;

      final remaining = next == null
          ? Duration.zero
          : next.difference(DateTime.now());

      setState(() {
        cooldownRemaining = remaining.isNegative ? Duration.zero : remaining;
      });

      if (remaining.inSeconds <= 0) {
        countdownTimer?.cancel();
      }
    }

    updateRemainingTime();

    if (cooldownRemaining > Duration.zero) {
      countdownTimer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => updateRemainingTime(),
      );
    }
  }

  bool get isCooldownActive {
    return nextAvailableAt != null && DateTime.now().isBefore(nextAvailableAt!);
  }

  String formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not available';

    final local = dateTime.toLocal();

    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final year = local.year;

    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';

    return '$month/$day/$year at $hour:$minute $period';
  }

  String formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${days}d ${hours}h ${minutes}m ${seconds}s';
  }

  //TESTTTTT FUNCTIONS
  void test() async {
    final previousBudget = await DatabaseHelper.instance
        .getPreviousMonthBudgetAmount();

    print("Previous Budget: $previousBudget");
  }

  Future<void> testAdvisorData() async {
    final data = await DatabaseHelper.instance.getAdvisorData();

    // print(data);
    debugPrint(data.toString());
  }

  void testPatterns() async {
    final patterns = await DatabaseHelper.instance.getSpendingPatterns();

    print(patterns);
  }

  void testCategorySpending() async {
    final current = await DatabaseHelper.instance.getCategorySpending();

    final previous = await DatabaseHelper.instance.getCategorySpending(
      previousMonth: true,
    );

    print("CURRENT CATEGORY:");
    print(current);

    print("PREVIOUS CATEGORY:");
    print(previous);
  }

  void testTransactionCount() async {
    final current = await DatabaseHelper.instance.getExpenseTransactionCount();

    final previous = await DatabaseHelper.instance.getExpenseTransactionCount(
      previousMonth: true,
    );

    print("CURRENT MONTH EXPENSE TRANSACTIONS COUNT: $current");
    print("PREVIOUS MONTH EXPENSE TRANSACTIONS COUNT: $previous");
  }

  void testPreviousMonthExpense() async {
    final previousExpense = await DatabaseHelper.instance
        .getPreviousMonthExpenseAmount();

    print("PREVIOUS MONTH EXPENSE: $previousExpense");
  }

  void testRemainingDays() {
    final days = getRemainingDays();

    print("REMAINING DAYS: $days");
  }

  int getRemainingDays() {
    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return lastDayOfMonth.difference(today).inDays;
  }

  void testRemainingBudget() async {
    final budget = await DatabaseHelper.instance.getCurrentBudgetAmount();

    final expenses = await DatabaseHelper.instance.getCurrentExpenseAmount();

    final remaining = budget - expenses;

    print("CURRENT BUDGET: $budget");
    print("CURRENT EXPENSE: $expenses");
    print("REMAINING BUDGET: $remaining");
  }
  //TESTTTT FUNCTIONS

  Future<void> checkInternet() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity.contains(ConnectivityResult.none)) {
        if (!mounted) return;
        setState(() => hasInternet = false);
        return;
      }

      final response = await http
          .get(Uri.parse("https://www.google.com"))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() {
        hasInternet = response.statusCode == 200;
      });
    } catch (e) {
      debugPrint("Internet check failed: $e");

      if (!mounted) return;

      setState(() {
        hasInternet = false;
      });
    }
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    connectivitySubscription?.cancel();

    super.dispose();
  }

  Future<void> refresh() async {
    await checkInternet();
    await testAdvisorData();
  }

  void showAIConfirmation() {
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Internet connection is required for AI advice."),
        ),
      );

      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Generate AI Advice?"),
          content: const Text(
            "Your expense, budget, spending pattern, and profile information "
            "will be analyzed to create personalized financial recommendations.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                await generateAIAdvice();
              },
              child: const Text("Generate"),
            ),
          ],
        );
      },
    );
  }

  Future<void> generateAIAdvice() async {
    if (isCooldownActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You can generate new advice once every 7 days.'),
        ),
      );
      return;
    }

    setState(() {
      isGenerating = true;
    });

    try {
      final spendingData = await DatabaseHelper.instance.getAdvisorData();

      final result = await AIService.getRecommendation(
        spendingData: spendingData,
      );

      // Save only a successful, non-empty result.
      if (result.isEmpty) {
        throw Exception('No recommendations were returned.');
      }

      await DatabaseHelper.instance.saveAIRecommendation(
        userId: 1,
        recommendations: result,
      );

      // Reload the saved record so the displayed timestamps
      // match the values stored in SQLite.
      final saved = await DatabaseHelper.instance.getSavedAIRecommendation(
        userId: 1,
      );

      if (!mounted) return;

      if (saved == null) {
        throw Exception('The generated recommendation could not be loaded.');
      }

      final decoded = jsonDecode(saved['recommendation'] as String) as List;

      final loadedRecommendations = decoded
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();

      setState(() {
        recommendations = loadedRecommendations;

        recommendationGeneratedAt = DateTime.tryParse(
          saved['generated_at']?.toString() ?? '',
        );

        nextAvailableAt = DateTime.tryParse(
          saved['next_available_at']?.toString() ?? '',
        );

        isGenerating = false;
      });

      updateCooldown();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isGenerating = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to generate AI advice: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Advisor",
          style: TextStyle(
            color: _advisorText,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: _advisorPurple,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Showcase(
                key: widget.advisorKey,
                title: "AI Financial Advisor",
                description:
                    "Get personalized financial recommendations based on "
                    "your recorded spending and budget information.",
                targetBorderRadius: BorderRadius.circular(16),
                overlayOpacity: 0.65,
                tooltipBackgroundColor: _advisorPurple,
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
                child: _buildAdvisorStatusCard(),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Container(
                    width: 4,
                    height: 23,
                    decoration: BoxDecoration(
                      color: _advisorPurple,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 9),
                  const Expanded(
                    child: Text(
                      "Your Recommendations",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: _advisorText,
                      ),
                    ),
                  ),
                  if (recommendations.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _advisorPurple.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${recommendations.length}",
                        style: const TextStyle(
                          color: _advisorPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              if (isGenerating)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _advisorBorder),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(
                        color: _advisorPurple,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 14),
                      Text(
                        "Analyzing your spending...",
                        style: TextStyle(
                          color: _advisorText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Preparing personalized recommendations",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _advisorMuted, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (recommendations.isEmpty)
                _buildEmptyRecommendations()
              else
                ...recommendations.map(_buildRecommendationCard),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvisorStatusCard() {
    final statusColor = hasInternet ? _advisorGreen : _advisorRed;

    final statusText = hasInternet
        ? "Internet Connected"
        : "No Internet Connection";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _advisorBorder),
        boxShadow: [
          BoxShadow(
            color: _advisorPurple.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  hasInternet
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: const TextStyle(
                        color: _advisorText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      hasInternet
                          ? "Ready to connect to the AI advisor"
                          : "Check your connection to use AI advice",
                      style: const TextStyle(
                        color: _advisorMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFFE2DFEC)),
          const SizedBox(height: 15),

          if (isCooldownActive) ...[
            const Text(
              "NEXT RECOMMENDATION AVAILABLE IN",
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: _advisorMuted,
              ),
            ),
            const SizedBox(height: 7),
            Row(
              children: [
                const Icon(
                  Icons.schedule_rounded,
                  color: _advisorPurple,
                  size: 21,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formatDuration(cooldownRemaining),
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: _advisorPurple,
                    ),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              recommendations.isEmpty
                  ? "Generate AI advice to receive personalized recommendations "
                        "based on your spending habits."
                  : "You can generate new advice now.",
              style: const TextStyle(
                fontSize: 13,
                height: 1.45,
                color: _advisorMuted,
              ),
            ),

          if (recommendationGeneratedAt != null) ...[
            const SizedBox(height: 14),
            _buildTimestampRow(
              Icons.history_rounded,
              "Last generated",
              formatDateTime(recommendationGeneratedAt),
            ),
          ],

          if (nextAvailableAt != null) ...[
            const SizedBox(height: 8),
            _buildTimestampRow(
              Icons.event_available_rounded,
              "Next available",
              formatDateTime(nextAvailableAt),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: hasInternet && !isGenerating && !isCooldownActive
                  ? showAIConfirmation
                  : null,
              icon: const Icon(Icons.psychology_rounded, size: 20),
              label: const Text(
                "Generate AI Advice",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _advisorPurple,
                foregroundColor: Colors.white,

                // Gray when a recommendation is on cooldown or internet is unavailable.
                disabledBackgroundColor: const Color(0xFFE5E3EB),
                disabledForegroundColor: const Color(0xFF777386),

                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimestampRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: _advisorMuted),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            "$label: $value",
            style: const TextStyle(
              color: _advisorMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final title = recommendation["title"]?.toString() ?? "Recommendation";
    final message = recommendation["message"]?.toString() ?? "";
    final type = recommendation["type"]?.toString() ?? "general";

    IconData icon = Icons.lightbulb_outline_rounded;
    Color accent = _advisorPurple;
    Color tint = const Color(0xFFF0ECFF);

    switch (type) {
      case "budget":
        icon = Icons.account_balance_wallet_outlined;
        accent = const Color(0xFF6545D6);
        tint = const Color(0xFFEAE3FF);
        break;

      case "food":
        icon = Icons.restaurant_outlined;
        accent = const Color(0xFFE07816);
        tint = const Color(0xFFFFE8CF);
        break;

      case "transportation":
        icon = Icons.directions_bus_outlined;
        accent = const Color(0xFF2374D8);
        tint = const Color(0xFFDCEBFF);
        break;

      case "saving":
        icon = Icons.savings_outlined;
        accent = const Color(0xFF079669);
        tint = const Color(0xFFD7F5E8);
        break;

      case "spending":
        icon = Icons.trending_up_rounded;
        accent = const Color(0xFFE04444);
        tint = const Color(0xFFFFDEDE);
        break;

      case "warning":
        icon = Icons.warning_amber_rounded;
        accent = const Color(0xFFB77900);
        tint = const Color(0xFFFFEDB5);
        break;

      default:
        icon = Icons.lightbulb_outline_rounded;
        accent = const Color(0xFF6545D6);
        tint = const Color(0xFFEAE3FF);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: accent,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Color(0xFF514D66),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendations() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _advisorBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _advisorPurple.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_alt_rounded,
              color: _advisorPurple,
              size: 30,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            "No recommendations yet",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _advisorText,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Generate AI advice to get insights and suggestions "
            "based on your spending habits.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.5, color: _advisorMuted),
          ),
        ],
      ),
    );
  }
}
