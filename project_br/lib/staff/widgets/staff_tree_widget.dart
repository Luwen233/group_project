import 'package:flutter/material.dart';
import 'package:project_br/notifiers.dart';
import 'package:project_br/staff/pages/add_room_page.dart';
import 'package:project_br/staff/pages/history_page.dart';
import 'package:project_br/staff/pages/home_page.dart';
import 'package:project_br/staff/widgets/staff_navbar_widget.dart';

class StaffWidgetTree extends StatelessWidget {
  const StaffWidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [HomePage(), AddRoomPage(), HistoryPage()];

    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifer,
      builder: (context, selectedPage, child) {
        return Scaffold(
          body: pages[selectedPage],
          bottomNavigationBar: const StaffNavbarWidget(),
        );
      },
    );
  }
}
