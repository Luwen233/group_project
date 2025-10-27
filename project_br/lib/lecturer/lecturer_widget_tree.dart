import 'package:flutter/material.dart';
import 'package:project_br/lecturer/lecturer_home_pages.dart';

class LecturerWidgetTree extends StatelessWidget {
  const LecturerWidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = const [LecturerHomePages()];

    // return ValueListenableBuilder<int>(
    //   valueListenable: selectedPageNotifer,
    //   builder: (context, selectedPage, child) {
    //     return Scaffold(
    //       body: pages[selectedPage],
    //       bottomNavigationBar: const StudentNavbarWidget(),
    //     );
    //   },
    // );
  }
}
