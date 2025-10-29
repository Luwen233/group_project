import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/staff/pages/widgets/room_card.dart';
import 'package:project_br/staff/pages/edit_room_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void navigateToEditRoom(BuildContext context, Map<String, String> roomData) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => EditRoomPage(roomData: roomData)),
    );
  }

  @override
  Widget build(BuildContext context) {
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

    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('MMM d, y').format(now);

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              accountName: Text(
                'Staff Jeff',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: null,
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black, size: 40),
              ),
              decoration: BoxDecoration(color: Color(0xFF3C9CBF)),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),

      // Body layout
      body: Column(
        children: [
          _buildHeader(context, formattedDate),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatCard(
                  icon: Icons.meeting_room,
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

  Widget _buildHeader(BuildContext context, String formattedDate) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.only(
        top: statusBarHeight + 16,
        left: 16,
        right: 16,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xff3C9CBF),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            formattedDate,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openEndDrawer(),
              child: const Icon(Icons.menu, color: Colors.white, size: 26),
            ),
          ),
        ],
      ),
    );
  }
}

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
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
