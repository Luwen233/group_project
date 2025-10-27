import 'package:flutter/material.dart';
import 'package:project_br/notifiers.dart';

class StudentNavbarWidget extends StatelessWidget {
  const StudentNavbarWidget({super.key});

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
              icon: Icon(Icons.event_note_outlined),
              label: 'Comming request',
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
