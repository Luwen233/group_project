import 'package:flutter/material.dart';
import 'package:project_br/student/notifiers.dart';
import 'package:project_br/student/student_booking_pages.dart';
import 'package:project_br/student/student_history_pages.dart';
import 'package:project_br/student/student_home_pages.dart';
import 'student_navbar_widget.dart';

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
