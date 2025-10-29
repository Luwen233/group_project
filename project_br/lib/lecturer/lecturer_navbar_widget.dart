import 'package:flutter/material.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';

class LecturerNavbarWidget extends StatelessWidget {
  const LecturerNavbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: selectedPageNotifier,
      builder: (context, selectedPage, child) {
        return NavigationBar(
          height: 70,
          selectedIndex: selectedPage,
          onDestinationSelected: (value) => selectedPageNotifier.value = value,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(
              icon: Icon(Icons.list_alt),
              label: 'Comming request',
            ),
            NavigationDestination(icon: Icon(Icons.history), label: 'History'),
          ],
        );
      },
    );
  }
}
