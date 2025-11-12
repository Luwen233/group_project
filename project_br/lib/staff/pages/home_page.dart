import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ⭐️ import ไฟล์ตามโครงสร้าง "master branch" ที่ถูกต้อง
import 'package:project_br/staff/pages/room_card.dart';
import 'package:project_br/staff/pages/edit_room_page.dart';
import 'package:project_br/staff/pages/dashboard_summary.dart';
import 'package:project_br/staff/pages/staff_service.dart';
import 'package:project_br/login/login_page.dart'; // ⭐️ import สำหรับ Logout

class HomePage extends StatefulWidget {
  final ValueNotifier<bool>? refreshNotifier;

  const HomePage({super.key, this.refreshNotifier});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchBox = TextEditingController();

  // Dashboard data
  int _totalRooms = 0;
  int _freeSlots = 0;
  int _reservedSlots = 0;
  int _disabledRooms = 0;
  bool _isLoadingDashboard = true;
  String? _dashboardError; // 💡 เพิ่มตัวแปรสำหรับจัดการ Error

  // Rooms data
  List<Map<String, dynamic>> _rooms = [];
  bool _isLoadingRooms = true;
  String? _roomsError; // 💡 เพิ่มตัวแปรสำหรับจัดการ Error

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
    _loadAllData(); // 💡 เรียกฟังก์ชันเดียวเพื่อโหลดข้อมูล 2 ส่วน

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
    _loadAllData();
  }

  // 💡 ฟังก์ชันสำหรับโหลดข้อมูล 2 ส่วนพร้อมกัน
  Future<void> _loadAllData() async {
    // ใช้ Future.wait เพื่อให้โหลด Dashboard และ Rooms พร้อมกัน
    await Future.wait([_loadDashboardData(), _loadRooms()]);
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoadingDashboard = true;
      _dashboardError = null;
    });

    try {
      final data = await fetchDashboardSummary();
      if (!mounted) return;
      setState(() {
        // ⭐️⭐️⭐️ [โค้ดสำหรับ Total Rooms] ⭐️⭐️⭐️
        _totalRooms = data['totalRooms'] ?? 0; // 1. ดึงข้อมูล
        // ⭐️⭐️⭐️ [จบส่วน Total Rooms] ⭐️⭐️⭐️
        _freeSlots = data['freeRooms'] ?? 0;
        _reservedSlots = data['reservedBookings'] ?? 0;
        _disabledRooms = data['disabledRooms'] ?? 0;
      });
    } catch (e) {
      print('Error loading dashboard: $e');
      if (mounted) setState(() => _dashboardError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingDashboard = false);
    }
  }

  Future<void> _loadRooms() async {
    setState(() {
      _isLoadingRooms = true;
      _roomsError = null;
    });

    try {
      final rooms = await fetchRooms();
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
      });
    } catch (e) {
      print('Error loading rooms: $e');
      if (mounted) setState(() => _roomsError = e.toString());
    } finally {
      if (mounted) setState(() => _isLoadingRooms = false);
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

    // ⭐️ ใช้ == true เพื่อความชัดเจนว่า pop กลับมาด้วยผลลัพธ์ "สำเร็จ"
    if (updatedRoom == true) {
      // Reload rooms and dashboard after edit
      _loadAllData();
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
                'Staff01',
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
                  : _dashboardError != null
                  ? Center(
                      child: Text(
                        'Failed to load summary: $_dashboardError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    )
                  : DashboardSummary(
                      // ⭐️ 2. ส่ง _totalRooms ไปที่ DashboardSummary
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
                : _roomsError != null
                ? SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Failed to load rooms: $_roomsError',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
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

                    // ⭐️⭐️⭐️ [โค้ดแก้ไขปัญหาเรื่องรูปภาพ] ⭐️⭐️⭐️
                    itemBuilder: (context, index) {
                      final room = _filteredRooms()[index];

                      // 1. ดึงชื่อไฟล์ดิบจาก API (เช่น "room1.jpg" หรือ "assets/images/room1.jpg")
                      final String rawImage =
                          room['image']?.toString() ?? 'room1.jpg';

                      // 2. ตรวจสอบว่ามี path "assets/" หรือยัง ถ้ายังไม่มี ให้เติม "assets/images/" ข้างหน้า
                      final String fullImagePath =
                          rawImage.startsWith('assets/')
                          ? rawImage // ถ้ามี "assets/" แล้ว (เช่น "assets/images/room1.jpg") ก็ใช้เลย
                          : 'assets/images/${rawImage.isEmpty ? 'room1.jpg' : rawImage}'; // ถ้าไม่มี (เช่น "room1.jpg") ให้เติม

                      // 3. ส่ง path ที่แก้ไขแล้ว (fullImagePath) ไปให้ RoomCard
                      return RoomCard(
                        title: room['room_name']?.toString() ?? 'Unknown',
                        imagePath: fullImagePath, // ⭐️ ใช้ตัวแปรที่แก้ไขแล้ว
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
                    // ⭐️⭐️⭐️ [จบส่วนแก้ไข] ⭐️⭐️⭐️
                  ),
          ),
        ],
      ),
    );
  }
}
