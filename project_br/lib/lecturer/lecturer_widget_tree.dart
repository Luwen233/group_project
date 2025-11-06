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
    // ⭐️ [แก้ไข] ลบ 'const' ที่อยู่หน้า <Widget>[] ออก ⭐️
    final pages = <Widget>[
      const LecturerHomePages(), // ⭐️ เติม const หน้า Widget แทน
      const LecturerRequestPages(), // ⭐️ เติม const หน้า Widget แทน
      const LecturerHistoryPages(), // ⭐️ เติม const หน้า Widget แทน
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
