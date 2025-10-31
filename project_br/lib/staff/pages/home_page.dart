import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/staff/pages/widgets/room_card.dart';
import 'package:project_br/staff/pages/edit_room_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchBox = TextEditingController();

  final List<Map<String, String>> _rooms = [
    {
      "name": "Study Room",
      "img": "assets/images/room1.jpg",
      "description": "A quiet place for study.",
      "roomStatus": "Free",
    },
    {
      "name": "Law Study Room",
      "img": "assets/images/room2.jpg",
      "description": "Exclusive room for law students.",
      "roomStatus": "Free",
    },
    {
      "name": "Meeting Room",
      "img": "assets/images/room3.jpg",
      "description": "Large space for group meetings.",
      "roomStatus": "Free",
    },
    {
      "name": "Math Study Room",
      "img": "assets/images/room4.jpg",
      "description": "For mathematics and engineering students.",
      "roomStatus": "Free",
    },
    {
      "name": "Music Study Room",
      "img": "assets/images/room4.jpg",
      "description": "For musical and engineering students.",
      "roomStatus": "Disable",
    },
  ];

  List<Map<String, String>> _filteredRooms() {
    final query = _searchBox.text.trim().toLowerCase();
    if (query.isEmpty) return _rooms;
    return _rooms.where((room) {
      return room["name"]!.toLowerCase().contains(query) ||
          room["description"]!.toLowerCase().contains(query);
    }).toList();
  }

  void navigateToEditRoom(BuildContext context, int index) async {
    final updatedRoom = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoomPage(roomData: _rooms[index]),
      ),
    );

    if (updatedRoom != null) {
      setState(() {
        _rooms[index] = updatedRoom;
      });
    }
  }

  @override
  void dispose() {
    _searchBox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String formattedDate = DateFormat('MMM d, y').format(DateTime.now());

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

      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            backgroundColor: const Color(0xFF3C9CBF),
            expandedHeight: 150,
            pinned: true,
            floating: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black, size: 30),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 25,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 40,
                        width: 160,
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(80, 33, 33, 40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          formattedDate,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: TextField(
                          controller: _searchBox,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            hintText: 'Search Room',
                            border: InputBorder.none,
                            suffixIcon: Icon(Icons.search),
                            contentPadding: EdgeInsets.all(14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Statistic Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _StatCard(
                    icon: Icons.check_circle,
                    color: Colors.green,
                    value: "14",
                    label: "Free Slots",
                  ),
                  _StatCard(
                    icon: Icons.calendar_month,
                    color: Colors.blue,
                    value: "10",
                    label: "Reserved Slots",
                  ),
                  _StatCard(
                    icon: Icons.hourglass_bottom,
                    color: Colors.orange,
                    value: "5",
                    label: "Pending Slots",
                  ),
                  _StatCard(
                    icon: Icons.lock,
                    color: Colors.red,
                    value: "1",
                    label: "Disable Slots",
                  ),
                ],
              ),
            ),
          ),

          // Room Grid
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid.builder(
              itemCount: _filteredRooms().length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 3.7,
              ),
              itemBuilder: (context, index) {
                final room = _filteredRooms()[index];
                final originalIndex = _rooms.indexOf(room);
                return RoomCard(
                  title: room['name']!,
                  imagePath: room['img']!,
                  roomData: room,
                  onEdit: () => navigateToEditRoom(context, originalIndex),
                );
              },
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
