import 'package:flutter/material.dart';
import 'package:project_br/staff/pages/add_room_page.dart';
import 'package:project_br/staff/pages/history_page.dart';
import 'package:project_br/staff/pages/home_page.dart';

// Wrapper for login navigation
class StaffWidgetTree extends StatelessWidget {
  const StaffWidgetTree({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainNavigation();
  }
}

void main() {
  runApp(const RoomApp());
}

class RoomApp extends StatelessWidget {
  const RoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Room Management',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final ValueNotifier<bool> _refreshNotifier = ValueNotifier(false);

  List<Widget> get _pages => [
    HomePage(refreshNotifier: _refreshNotifier),
    AddRoomPage(
      onRoomAdded: () {
        setState(() => _selectedIndex = 0);
        _refreshNotifier.value = !_refreshNotifier.value;
      },
    ),
    const StaffHistoryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            label: "Add rooms",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
        ],
      ),
    );
  }
}
