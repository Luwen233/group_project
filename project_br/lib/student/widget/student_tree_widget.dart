import 'package:flutter/material.dart';
import 'package:project_br/notifiers.dart';
import 'package:project_br/student/pages/student_booking_page.dart';
import 'package:project_br/student/pages/student_history_page.dart';
import 'package:project_br/student/pages/student_home_page.dart';
import 'package:project_br/student/widget/student_navbar_widget.dart';


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
