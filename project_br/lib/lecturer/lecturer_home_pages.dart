import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_service.dart';
import 'package:project_br/lecturer/dashboard_summary.dart';
import 'package:project_br/login/login_page.dart';

class LecturerHomePages extends StatefulWidget {
  const LecturerHomePages({super.key});

  @override
  State<LecturerHomePages> createState() => _LecturerHomePagesState();
}

class _LecturerHomePagesState extends State<LecturerHomePages> {
  final List<Map<String, dynamic>> _rooms = [
    {'name': 'Study Room A', 'status': 'Free', 'image': 'assets/images/room1.jpg'},
    {'name': 'Law Study Room', 'status': 'Disable', 'image': 'assets/images/room2.jpg'},
    {'name': 'Room B101', 'status': 'Free', 'image': 'assets/images/room3.jpg'},
    {'name': 'Room B102', 'status': 'Disable', 'image': 'assets/images/room4.jpg'},
  ];

  final _searchBox = TextEditingController();

  List<Map<String, dynamic>> _filteredRooms() {
    final q = _searchBox.text.trim().toLowerCase();
    if (q.isEmpty) return _rooms;
    return _rooms.where((room) {
      final name = (room['name'] as String).toLowerCase();
      final status = (room['status'] as String).toLowerCase();
      return name.contains(q) || status.contains(q);
    }).toList();
  }

  @override
  void dispose() {
    _searchBox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('MMM d, y').format(now);

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text(
                'Mr. John',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              accountEmail: null,
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Colors.black, size: 40),
              ),
              decoration: const BoxDecoration(color: Color(0xFF3C9CBF)),
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
        slivers: <Widget>[
          SliverAppBar(
            backgroundColor: const Color(0xFF3C9CBF),
            expandedHeight: 220.0,
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
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
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
                          style: const TextStyle(color: Colors.white, fontSize: 20),
                        ),
                      ),
                      const SizedBox(height: 80),
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

          // Dashboard summary
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
              child: ValueListenableBuilder<List<BookingRequest>>(
                valueListenable: pendingRequestsNotifier,
                builder: (context, pendingList, _) {
                  return ValueListenableBuilder<List<BookingRequest>>(
                    valueListenable: historyRequestsNotifier,
                    builder: (context, historyList, _) {
                      final reservedCount =
                          historyList.where((req) => req.status == 'approved').length;

                      return DashboardSummary(
                        freeSlots: _rooms.where((r) => r['status'] == 'Free').length,
                        reservedSlots: reservedCount,
                        pendingSlots: pendingList.length,
                        disabledRooms: _rooms.where((r) => r['status'] == 'Disable').length,
                      );
                    },
                  );
                },
              ),
            ),
          ),

          // Simulate button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: ElevatedButton(
                onPressed: simulateNewBooking,
                child: const Text('Simulate New Booking'),
              ),
            ),
          ),

          // Grid of rooms
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
                final isFree = (room['status'] as String) == 'Free';

                return Container(
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
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.asset(
                          room['image'] as String,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15),
                        child: Align(
                          alignment: Alignment.bottomRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isFree ? const Color(0xff3BCB53) : const Color(0xff4E534E),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
