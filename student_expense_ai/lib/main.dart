import 'package:flutter/material.dart';
import 'utils/theme_helper.dart';
import 'pages/main_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ThemeHelper.instance.loadTheme();

  runApp(const StudentExpenseAI());
}

class StudentExpenseAI extends StatelessWidget {
  const StudentExpenseAI({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ThemeHelper.instance,

      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: "Student Expense AI",

          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 137, 183, 58),
            ),
          ),

          darkTheme: ThemeData.dark(),

          themeMode: ThemeHelper.instance.themeMode,

          home: const MainPage(),
        );
      },
    );
  }
}
