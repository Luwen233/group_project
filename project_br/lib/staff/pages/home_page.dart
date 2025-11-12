import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/staff/pages/widgets/room_card.dart';
import 'package:project_br/staff/pages/edit_room_page.dart';
import 'package:project_br/staff/pages/dashboard_summary.dart';
import 'package:project_br/staff/pages/staff_service.dart';

class HomePage extends StatefulWidget {
  final ValueNotifier<bool>? refreshNotifier;

  const HomePage({super.key, this.refreshNotifier});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchBox = TextEditingController();

  // Dashboard data
  int _totalRooms = 0; // เพิ่มตัวแปรนี้
  int _freeSlots = 0;
  int _reservedSlots = 0;
  int _disabledRooms = 0;
  bool _isLoadingDashboard = true;

  // Rooms data
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoadingRooms = true;

  List<Map<String, dynamic>> _filteredRooms() {
    final query = _searchBox.text.trim().toLowerCase();
    if (query.isEmpty) return _rooms;
    return _rooms.where((room) {
      final name = (room["room_name"] ?? '').toString().toLowerCase();
      final desc = (room["room_description"] ?? '').toString().toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _loadRooms();

    // Listen to refresh notifier
    widget.refreshNotifier?.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier?.removeListener(_onRefresh);
    _searchBox.dispose();
    super.dispose();
  }

  void _onRefresh() {
    _loadDashboardData();
    _loadRooms();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
    });

    try {
      final data = await fetchDashboardSummary();
      setState(() {
        _totalRooms = data['totalRooms'] ?? 0;
        _freeSlots = data['freeRooms'] ?? 0;
        _reservedSlots = data['reservedBookings'] ?? 0;
        _disabledRooms = data['disabledRooms'] ?? 0;
        _isLoadingDashboard = false;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      setState(() {
        _isLoadingDashboard = false;
      });
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoadingRooms = true;
    });

    try {
      final rooms = await fetchRooms();
      setState(() {
        _rooms = rooms;
        _isLoadingRooms = false;
      });
    } catch (e) {
      print('Error loading rooms: $e');
      setState(() {
        _isLoadingRooms = false;
      });
    }
  }

  void navigateToEditRoom(BuildContext context, int index) async {
    final room = _filteredRooms()[index];
    final roomId = room['room_id'];

    print('📝 Navigating to edit room:');
    print('   Room ID: $roomId');
    print('   Room data: $room');

    final updatedRoom = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditRoomPage(
          roomId: roomId,
          roomData: {
            'name': room['room_name']?.toString() ?? '',
            'description': room['room_description']?.toString() ?? '',
            'roomStatus': (room['room_status']?.toString() ?? 'free') == 'free'
                ? 'Free'
                : 'Disable',
            'capacity': room['capacity']?.toString() ?? '1',
            'img': room['image']?.toString() ?? 'assets/images/room1.jpg',
          },
        ),
      ),
    );

    if (updatedRoom != null) {
      // Reload rooms after edit
      await _loadRooms();
      await _loadDashboardData();
    }
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
              child: _isLoadingDashboard
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : DashboardSummary(
                      totalRooms: _totalRooms,
                      freeSlots: _freeSlots,
                      reservedSlots: _reservedSlots,
                      disabledRooms: _disabledRooms,
                    ),
            ),
          ),

          // Room Grid
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: _isLoadingRooms
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SliverGrid.builder(
                    itemCount: _filteredRooms().length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 3 / 3.7,
                        ),
                    itemBuilder: (context, index) {
                      final room = _filteredRooms()[index];
                      return RoomCard(
                        title: room['room_name']?.toString() ?? 'Unknown',
                        imagePath:
                            room['image']?.toString() ??
                            'assets/images/room1.jpg',
                        roomData: {
                          'roomStatus':
                              (room['room_status']?.toString() ?? 'free') ==
                                  'free'
                              ? 'Free'
                              : 'Disable',
                        },
                        onEdit: () => navigateToEditRoom(context, index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
