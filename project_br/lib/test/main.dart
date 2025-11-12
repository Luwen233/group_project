import 'package:flutter/material.dart';
import 'package:project_br/lecturer/widget/lecturer_tree_widget.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/login/signup_page.dart';
import 'package:project_br/student/widget/student_tree_widget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xff3C9CBF)),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (_) => const LoginPage(),
        '/signup': (_) => const SignUpPage(),
        '/homeLecturer': (_) => const LecturerWidgetTree(),
        '/homeStudent': (_) => const StudentWidgetTree(),
      },
    );
  }
}
