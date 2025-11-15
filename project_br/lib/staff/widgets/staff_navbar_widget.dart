import 'package:flutter/material.dart';
import 'package:project_br/notifiers.dart';

class StaffNavbarWidget extends StatelessWidget {
  const StaffNavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifer,
      builder: (context, selectedPage, child) {
        return NavigationBar(
          selectedIndex: selectedPage,
          onDestinationSelected: (value) => selectedPageNotifer.value = value,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.add_home),
              label: 'Add rooms',
            ),
            NavigationDestination(
              icon: Icon(Icons.work_history_rounded),
              label: 'History',
            ),
          ],
        );
      },
    );
  }
}
