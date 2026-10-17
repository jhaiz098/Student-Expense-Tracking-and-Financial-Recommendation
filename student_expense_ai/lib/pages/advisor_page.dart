import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:showcaseview/showcaseview.dart';

import '../database/database_helper.dart';
import '../services/ai_service.dart';

const Color _advisorPrimary = Color(0xFF5B45B5);
const Color _advisorPurpleLight = Color(0xFFB9A8FF);
const Color _advisorGreen = Color(0xFF159A75);
const Color _advisorRed = Color(0xFFE05252);
const Color _advisorOrange = Color(0xFFF59E0B);

class AdvisorPage extends StatefulWidget {
  final GlobalKey advisorKey;

  const AdvisorPage({super.key, required this.advisorKey});

  @override
  State<AdvisorPage> createState() => _AdvisorPageState();
}

class _AdvisorPageState extends State<AdvisorPage> {
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _background =>
      _isDark ? const Color(0xFF15131E) : const Color(0xFFF7F7FB);

  Color get _card => _isDark ? const Color(0xFF211D2D) : Colors.white;

  Color get _border =>
      _isDark ? const Color(0xFF393246) : const Color(0xFFE7E4F0);

  Color get _text =>
      _isDark ? const Color(0xFFF5F2FF) : const Color(0xFF29263A);

  Color get _muted =>
      _isDark ? const Color(0xFFB7B2C8) : const Color(0xFF6F6B82);

  Color get _subtle =>
      _isDark ? const Color(0xFF928BA8) : const Color(0xFF8B8798);

  Color get _surface =>
      _isDark ? const Color(0xFF2A2538) : const Color(0xFFFAFAFD);

  Color get _softPurple =>
      _isDark ? const Color(0xFF302844) : const Color(0xFFF6F4FC);

  Color get _purple => _isDark ? _advisorPurpleLight : _advisorPrimary;

  String advice =
      'Generate AI advice to receive personalized recommendations '
      'based on your spending habits.';

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

      setState(() {
        recommendations = loadedRecommendations;

        recommendationGeneratedAt = DateTime.tryParse(
          saved['generated_at']?.toString() ?? '',
        );

        nextAvailableAt = DateTime.tryParse(
          saved['next_available_at']?.toString() ?? '',
        );
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

  bool get isCooldownActive =>
      nextAvailableAt != null && DateTime.now().isBefore(nextAvailableAt!);

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

  // Optional database testing helpers.

  Future<void> testAdvisorData() async {
    final data = await DatabaseHelper.instance.getAdvisorData();
    debugPrint(data.toString());
  }

  Future<void> testPatterns() async {
    final patterns = await DatabaseHelper.instance.getSpendingPatterns();
    debugPrint(patterns.toString());
  }

  Future<void> testCategorySpending() async {
    final current = await DatabaseHelper.instance.getCategorySpending();

    final previous = await DatabaseHelper.instance.getCategorySpending(
      previousMonth: true,
    );

    debugPrint('CURRENT CATEGORY: $current');
    debugPrint('PREVIOUS CATEGORY: $previous');
  }

  Future<void> testTransactionCount() async {
    final current = await DatabaseHelper.instance.getExpenseTransactionCount();

    final previous = await DatabaseHelper.instance.getExpenseTransactionCount(
      previousMonth: true,
    );

    debugPrint('CURRENT MONTH EXPENSE TRANSACTIONS COUNT: $current');
    debugPrint('PREVIOUS MONTH EXPENSE TRANSACTIONS COUNT: $previous');
  }

  Future<void> testPreviousMonthExpense() async {
    final previous = await DatabaseHelper.instance
        .getPreviousMonthExpenseAmount();

    debugPrint('PREVIOUS MONTH EXPENSE: $previous');
  }

  Future<void> testRemainingBudget() async {
    final budget = await DatabaseHelper.instance.getCurrentBudgetAmount();

    final expenses = await DatabaseHelper.instance.getCurrentExpenseAmount();

    debugPrint('CURRENT BUDGET: $budget');
    debugPrint('CURRENT EXPENSE: $expenses');
    debugPrint('REMAINING BUDGET: ${budget - expenses}');
  }

  Future<void> testPreviousBudget() async {
    final budget = await DatabaseHelper.instance.getPreviousMonthBudgetAmount();

    debugPrint('Previous Budget: $budget');
  }

  int getRemainingDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);

    return lastDayOfMonth.difference(today).inDays;
  }

  Future<void> checkInternet() async {
    try {
      final connectivity = await Connectivity().checkConnectivity();

      if (connectivity.contains(ConnectivityResult.none)) {
        if (!mounted) return;
        setState(() => hasInternet = false);
        return;
      }

      final response = await http
          .get(Uri.parse('https://www.google.com'))
          .timeout(const Duration(seconds: 5));

      if (!mounted) return;

      setState(() {
        hasInternet = response.statusCode == 200;
      });
    } catch (e) {
      debugPrint('Internet check failed: $e');

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
    await loadSavedRecommendation();
  }

  void showAIConfirmation() {
    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internet connection is required for AI advice.'),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: _card,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _border),
          ),
          title: Text(
            'Generate AI Advice?',
            style: TextStyle(color: _text, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Your expense, budget, spending pattern, and profile '
            'information will be analyzed to create personalized '
            'financial recommendations.',
            style: TextStyle(color: _muted, height: 1.5, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('Cancel', style: TextStyle(color: _muted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _advisorPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                Navigator.pop(dialogContext);
                await generateAIAdvice();
              },
              child: const Text('Generate'),
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

    if (!hasInternet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internet connection is required for AI advice.'),
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

      if (result.isEmpty) {
        throw Exception('No recommendations were returned.');
      }

      await DatabaseHelper.instance.saveAIRecommendation(
        userId: 1,
        recommendations: result,
      );

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
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Advisor',
          style: TextStyle(
            color: _text,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: refresh,
        color: _purple,
        backgroundColor: _card,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            Showcase(
              key: widget.advisorKey,
              title: 'AI Financial Advisor',
              description:
                  'Get personalized financial recommendations based '
                  'on your recorded spending and budget information.',
              targetBorderRadius: BorderRadius.circular(18),
              overlayOpacity: 0.65,
              tooltipBackgroundColor: _advisorPrimary,
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
            _sectionHeading(
              'Your Recommendations',
              'Personalized suggestions based on your recorded finances.',
              trailing: recommendations.isEmpty
                  ? null
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _softPurple,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _border),
                      ),
                      child: Text(
                        '${recommendations.length}',
                        style: TextStyle(
                          color: _purple,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 14),
            if (isGenerating)
              _buildLoadingCard()
            else if (recommendations.isEmpty)
              _buildEmptyRecommendations()
            else
              ...recommendations.map(_buildRecommendationCard),
            const SizedBox(height: 12),
            _buildInformationNote(),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading(String title, String subtitle, {Widget? trailing}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 43,
          decoration: BoxDecoration(
            color: _purple,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 8), trailing],
      ],
    );
  }

  Widget _buildAdvisorStatusCard() {
    final statusColor = hasInternet ? _advisorGreen : _advisorRed;

    final statusText = hasInternet
        ? 'Internet Connected'
        : 'No Internet Connection';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _purple.withValues(alpha: _isDark ? 0.06 : 0.035),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  hasInternet
                      ? Icons.cloud_done_rounded
                      : Icons.cloud_off_rounded,
                  color: statusColor,
                  size: 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        color: _text,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasInternet
                          ? 'Ready to connect to the AI advisor'
                          : 'Check your connection to use AI advice',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          Divider(height: 1, color: _border),
          const SizedBox(height: 16),
          if (isCooldownActive) ...[
            Text(
              'NEXT RECOMMENDATION AVAILABLE IN',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w800,
                color: _muted,
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                Icon(Icons.schedule_rounded, color: _purple, size: 22),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    formatDuration(cooldownRemaining),
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: _purple,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              recommendations.isEmpty
                  ? 'Generate AI advice to receive personalized '
                        'recommendations based on your spending habits.'
                  : 'You can generate new advice now.',
              style: TextStyle(fontSize: 13, height: 1.5, color: _muted),
            ),
          ],
          if (recommendationGeneratedAt != null) ...[
            const SizedBox(height: 15),
            _buildTimestampRow(
              Icons.history_rounded,
              'Last generated',
              formatDateTime(recommendationGeneratedAt),
            ),
          ],
          if (nextAvailableAt != null) ...[
            const SizedBox(height: 9),
            _buildTimestampRow(
              Icons.event_available_rounded,
              'Next available',
              formatDateTime(nextAvailableAt),
            ),
          ],
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 49,
            child: ElevatedButton.icon(
              onPressed: hasInternet && !isGenerating && !isCooldownActive
                  ? showAIConfirmation
                  : null,
              icon: const Icon(Icons.psychology_rounded, size: 21),
              label: const Text(
                'Generate AI Advice',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _advisorPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: _isDark
                    ? const Color(0xFF393246)
                    : const Color(0xFFE5E3EB),
                disabledForegroundColor: _isDark
                    ? const Color(0xFF928BA8)
                    : const Color(0xFF777386),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
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
        Icon(icon, size: 16, color: _subtle),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: TextStyle(color: _muted, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Center(
              child: SizedBox(
                width: 27,
                height: 27,
                child: CircularProgressIndicator(
                  color: _purple,
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Analyzing your spending...',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Preparing personalized recommendations',
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final title = recommendation['title']?.toString() ?? 'Recommendation';

    final message = recommendation['message']?.toString() ?? '';

    final type = recommendation['type']?.toString() ?? 'general';

    IconData icon = Icons.lightbulb_outline_rounded;
    Color accent = _advisorPrimary;
    Color lightTint = const Color(0xFFEAE3FF);

    switch (type) {
      case 'budget':
        icon = Icons.account_balance_wallet_outlined;
        accent = const Color(0xFF6545D6);
        lightTint = const Color(0xFFEAE3FF);
        break;

      case 'food':
        icon = Icons.restaurant_outlined;
        accent = const Color(0xFFE07816);
        lightTint = const Color(0xFFFFE8CF);
        break;

      case 'transportation':
        icon = Icons.directions_bus_outlined;
        accent = const Color(0xFF2374D8);
        lightTint = const Color(0xFFDCEBFF);
        break;

      case 'saving':
        icon = Icons.savings_outlined;
        accent = _advisorGreen;
        lightTint = const Color(0xFFD7F5E8);
        break;

      case 'spending':
        icon = Icons.trending_up_rounded;
        accent = _advisorRed;
        lightTint = const Color(0xFFFFDEDE);
        break;

      case 'warning':
        icon = Icons.warning_amber_rounded;
        accent = const Color(0xFFB77900);
        lightTint = const Color(0xFFFFEDB5);
        break;

      default:
        icon = Icons.lightbulb_outline_rounded;
        accent = const Color(0xFF6545D6);
        lightTint = const Color(0xFFEAE3FF);
        break;
    }

    final tint = _isDark ? _surface : lightTint;

    final iconSurface = _isDark ? const Color(0xFF393246) : Colors.white;

    final titleColor = _isDark ? _text : accent;

    final messageColor = _isDark
        ? _advisorDarkMessageColor
        : const Color(0xFF514D66);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: _isDark
              ? accent.withValues(alpha: 0.22)
              : accent.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: iconSurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _border.withValues(alpha: 0.65)),
            ),
            child: Icon(icon, color: _isDark ? _purple : accent, size: 22),
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
                    color: titleColor,
                  ),
                ),
                if (message.isNotEmpty) ...[
                  const SizedBox(height: 7),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: messageColor,
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
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: _softPurple,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(Icons.psychology_alt_rounded, color: _purple, size: 33),
          ),
          const SizedBox(height: 16),
          Text(
            'No recommendations yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Generate AI advice to get insights and suggestions '
            'based on your spending habits.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, height: 1.55, color: _muted),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationNote() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _softPurple,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: _purple, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              'Recommendations are based on your saved financial '
              'records. Review each suggestion and decide whether '
              'it fits your needs and budget.',
              style: TextStyle(fontSize: 11, height: 1.5, color: _muted),
            ),
          ),
        ],
      ),
    );
  }
}

const Color _advisorDarkMessageColor = Color(0xFFB7B2C8);
