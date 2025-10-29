import 'package:flutter/material.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/student/student_room_detail_pages.dart';
import 'package:intl/intl.dart';


class StudentHomePages extends StatefulWidget {
  const StudentHomePages({super.key});

  @override
  State<StudentHomePages> createState() => _StudentHomePagesState();
}

class _StudentHomePagesState extends State<StudentHomePages> {
  final List<Map<String, dynamic>> _rooms = [
    {
      'name': 'Study Room A',
      'status': 'Free',
      'image': 'assets/images/room1.jpg',
    },
    {
      'name': 'Law Study Room',
      'status': 'Disable',
      'image': 'assets/images/room2.jpg',
    },
    {'name': 'Room B101', 'status': 'Free', 'image': 'assets/images/room3.jpg'},
    {
      'name': 'Room B102',
      'status': 'Disable',
      'image': 'assets/images/room4.jpg',
    },
    {
      'name': 'Law Study Room',
      'status': 'Full',
      'image': 'assets/images/room2.jpg',
    },
    {
      'name': 'Law Study Room',
      'status': 'Full',
      'image': 'assets/images/room2.jpg',
    },
  ];

  final _searchBox = TextEditingController();

  // filter Room >> status & room's name
  List<Map<String, dynamic>> _filteredRooms() {
    final q = _searchBox.text.trim().toLowerCase();
    if (q.isEmpty) return _rooms; // shows all rooms

    return _rooms.where((room) {
      final nameMatch = (room['name'] as String).toLowerCase().contains(q);
      final statusMatch = (room['status'] as String).toLowerCase().contains(q);

      return nameMatch || statusMatch;
    }).toList();
  }

  @override
  void dispose() {
    _searchBox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //current date format
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('MMM d, y').format(now);

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                'Mr. John',
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

            // Logout button
            ListTile(
              leading: Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: Color(0xFF3C9CBF),
            expandedHeight: 284.0,
            pinned: true,
            floating: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
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
                          color: Color.fromARGB(80, 33, 33, 40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          formattedDate,
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),

                      const SizedBox(height: 150),

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
                            hintText: 'Study Room',
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

          // Grid of rooms
          SliverPadding(
            padding: EdgeInsets.all(12),
            sliver: SliverGrid.builder(
              itemCount: _filteredRooms().length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 3 / 3.7,
              ),
              itemBuilder: (context, index) {
                final room = _filteredRooms()[index];
                final isFree = (room['status'] as String) == 'Free';

                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RoomDetailPage(room: room),
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.asset(
                            room['image'] as String,
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            room['name'] as String,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 15,
                          ),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isFree
                                    ? Color(0xff3BCB53)
                                    : Color(0xff4E534E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                room['status'] as String,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
