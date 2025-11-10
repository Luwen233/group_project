import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/lecturer/booking_service.dart';
import 'package:project_br/lecturer/dashboard_summary.dart';
import 'package:project_br/lecturer/rooms_notifier.dart';

class LecturerHomePages extends StatefulWidget {
  const LecturerHomePages({super.key});

  @override
  State<LecturerHomePages> createState() => _LecturerHomePagesState();
}

class _LecturerHomePagesState extends State<LecturerHomePages> {
  final TextEditingController _searchBox = TextEditingController();
  int freeRooms = 0;
  int reservedRooms = 0;
  int pendingRequests = 0;
  int disabledRooms = 0;

  @override
  void initState() {
    super.initState();
    fetchRooms();
    fetchPendingRequests();
    fetchHistoryRequests();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final data = await fetchDashboardSummary();
    if (!mounted) return;
    setState(() {
      freeRooms = data['freeRooms'] ?? 0;
      reservedRooms = data['reservedBookings'] ?? 0;
      pendingRequests = data['pendingBookings'] ?? 0;
      disabledRooms = data['disabledRooms'] ?? 0;
    });
  }

  List<Map<String, dynamic>> _search(List rooms) {
    final q = _searchBox.text.trim().toLowerCase();
    if (q.isEmpty) return rooms.cast<Map<String, dynamic>>();
    return rooms
        .where(
          (r) =>
              r['name'].toString().toLowerCase().contains(q) ||
              r['status'].toString().toLowerCase().contains(q),
        )
        .cast<Map<String, dynamic>>()
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('MMM d, y').format(DateTime.now());

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF3C9CBF)),
              accountName: Text("Lecturer"),
              accountEmail: null,
              currentAccountPicture: CircleAvatar(
                child: Icon(Icons.person, color: Colors.black),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                  (_) => false,
                );
              },
            ),
          ],
        ),
      ),

      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: const Color(0xFF3C9CBF),
            expandedHeight: 150,
            pinned: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
            ),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ),
            ],
            flexibleSpace: SafeArea(
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
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(80, 33, 33, 40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        dateText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
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
                          hintText: "Search Room",
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

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: DashboardSummary(
                freeSlots: freeRooms,
                reservedSlots: reservedRooms,
                pendingSlots: pendingRequests,
                disabledRooms: disabledRooms,
              ),
            ),
          ),

          // ✅ Room Grid
          ValueListenableBuilder(
            valueListenable: roomsNotifier,
            builder: (_, rooms, __) {
              final list = _search(rooms);

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                sliver: SliverGrid.builder(
                  itemCount: list.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 18,
                    childAspectRatio: 3 / 3.9,
                  ),
                  itemBuilder: (_, i) {
                    final room = list[i];
                    final bool isFree = room['status'] == 'Free';

                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
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
                              room['image'],
                              height: 150,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            child: Text(
                              room['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // ✅ ปุ่มสถานะอยู่ชิดขวา + เว้นที่พอดี
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 12,
                              bottom: 12,
                            ),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isFree
                                      ? const Color(0xff3BCB53)
                                      : const Color(0xff4E534E),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  room['status'],
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
              );
            },
          ),
        ],
      ),
    );
  }
}
