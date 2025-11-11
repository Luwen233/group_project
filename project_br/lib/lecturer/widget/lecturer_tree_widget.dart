import 'package:flutter/material.dart';
import 'package:project_br/lecturer/pages/lecturer_history_pages.dart';
import 'package:project_br/lecturer/pages/lecturer_home_pages.dart';
import 'package:project_br/lecturer/pages/lecturer_request_pages.dart';
import 'package:project_br/lecturer/widget/lecturer_navbar_widget.dart';
import 'package:project_br/notifiers.dart';

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
      valueListenable: selectedPageNotifer,
      builder: (context, selectedPage, child) {
        return Scaffold(
          body: pages[selectedPage],
          bottomNavigationBar: const LecturerNavbarWidget(),
        );
      },
    );
  }
}
