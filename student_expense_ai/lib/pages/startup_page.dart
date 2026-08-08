import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import 'profile_page.dart';
import 'main_page.dart';

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> {
  @override
  void initState() {
    super.initState();

    checkProfile();
  }

  Future<void> checkProfile() async {
    final profile = await DatabaseHelper.instance.getUserProfile();

    if (!mounted) return;

    if (profile == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const ProfilePage(isFirstSetup: true),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
