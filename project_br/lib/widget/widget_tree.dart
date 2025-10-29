import 'package:flutter/material.dart';
import 'package:project_br/student/notifiers.dart';
import 'package:project_br/student/student_booking_pages.dart';
import 'package:project_br/student/student_history_pages.dart';
import 'package:project_br/student/student_home_pages.dart';
<<<<<<<< HEAD:project_br/lib/student/widget_tree.dart
import 'student_navbar_widget.dart';
========
import '../student/student_navbar_widget.dart';
>>>>>>>> 6d7bcbed0d2345c1b42f0ee7840d51c966533257:project_br/lib/widget/widget_tree.dart

class WidgetTree extends StatelessWidget {
  const WidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [
      StudentHomePages(),
      StudentBookingPages(),
      StudentHistoryPages(),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifer,
      builder: (context, selectedPage, child) {
        return Scaffold(
          body: pages[selectedPage],
          bottomNavigationBar: const StudentNavbarWidget(),
        );
      },
    );
  }
}
