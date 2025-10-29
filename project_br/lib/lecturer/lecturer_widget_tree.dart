import 'package:flutter/material.dart';
import 'package:project_br/lecturer/lecturer_history_pages.dart';
import 'package:project_br/lecturer/lecturer_home_pages.dart';
import 'package:project_br/lecturer/lecturer_request_pages.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'package:project_br/lecturer/lecturer_navbar_widget.dart';

class LecturerWidgetTree extends StatelessWidget {
  const LecturerWidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    // ⭐️ เพิ่ม <Widget> ตรงนี้ เพื่อระบุประเภทของ List ให้ชัดเจน
    final pages = const <Widget>[
      LecturerHomePages(),
      LecturerRequestPages(),
      LecturerHistoryPages(),
    ];

    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return Scaffold(
          body: pages[selectedPage],
          bottomNavigationBar: const LecturerNavbarWidget(),
        );
      },
    );
  }
}
