import 'package:flutter/material.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/staff/pages/widgets/room_card.dart';
import 'package:project_br/staff/pages/edit_room_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  // Navigation function for the edit button on RoomCard
  void navigateToEditRoom(BuildContext context, Map<String, String> roomData) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditRoomPage(roomData: roomData)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Mock data for the room grid
    final rooms = [
      {
        "name": "Study Room",
        "img": "assets/images/room1.jpg",
        "description": "A quiet place for study.",
        "quantity": "5",
      },
      {
        "name": "Law Study Room",
        "img": "assets/images/room2.jpg",
        "description": "Exclusive room for law students.",
        "quantity": "5",
      },
      {
        "name": "Meeting Room",
        "img": "assets/images/room3.jpg",
        "description": "Large space for group meetings.",
        "quantity": "5",
      },
      {
        "name": "Math Study Room",
        "img": "assets/images/room4.jpg",
        "description": "For mathematics and engineering students.",
        "quantity": "5",
      },
      {
        "name": "Music Study Room",
        "img": "assets/images/room4.jpg",
        "description": "For Musical and engineering students.",
        "quantity": "1",
      },
    ];

    return Scaffold(
      // The body is now a Column to stack the header, stats, and grid
      body: Column(
        children: [
          // 1. Custom Header
          _buildHeader(context),

          // 2. Statistics Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatCard(
                  icon: Icons.meeting_room, // Using a standard icon
                  color: Colors.black54,
                  value: "20",
                  label: "Total Rooms",
                ),
                _StatCard(
                  icon: Icons.check_circle,
                  color: Colors.green,
                  value: "10",
                  label: "Free Slots",
                ),
                _StatCard(
                  icon: Icons.calendar_month,
                  color: Colors.blue,
                  value: "5",
                  label: "Reserved Slots",
                ),
                _StatCard(
                  icon: Icons.hourglass_bottom,
                  color: Colors.orange.shade800,
                  value: "1",
                  label: "Pending Slots",
                ),
              ],
            ),
          ),

          // 3. Room Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return RoomCard(
                  title: room["name"]!,
                  imagePath: room["img"]!,
                  roomData: room,
                  onEdit: () => navigateToEditRoom(context, room),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the custom blue header widget
  Widget _buildHeader(BuildContext context) {
    // Get status bar height for safe area padding
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 16,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: Color(0xff3C9CBF), // Header background color
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          // Top Row: Date and Staff Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Sep 20, 2025",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Staff Logout Dropdown Button
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'logout') {
                    // --- Handle Logout ---
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text("Staff logged out")),
                    // );
                    // In a real app, navigate to login screen:
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                      arguments: Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      ),
                    );
                  }
                },
                // This is the menu that appears on tap
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    value: 'logout',
                    child: Text('Logout'),
                  ),
                ],
                offset: const Offset(0, 40),
                // This is the widget that is tapped
                child: Row(
                  children: const [
                    Icon(Icons.person, color: Colors.white, size: 24),
                    SizedBox(width: 4),
                    Text(
                      "Staff jeff",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.white,
                      size: 24,
                    ),
                  ],
                ), // Position the menu
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: "Study Room",
                border: InputBorder.none, // Removes underline
                suffixIcon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper Widget for the four white statistic boxes
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded to make all cards share width equally
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                overflow: TextOverflow.ellipsis, // Prevents overflow
              ),
            ],
          ),
        ),
      ),
    );
  }
}
