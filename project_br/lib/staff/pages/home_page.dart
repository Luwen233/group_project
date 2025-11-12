import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/staff/pages/edit_room_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_br/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_br/staff/pages/room_card.dart';
import 'package:project_br/lecturer/pages/dashboard_summary.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchBox = TextEditingController();

  List<Map<String, dynamic>> _rooms = [];
  bool _isWaiting = true;
  String? _error;
  String? _username;

  int freeRooms = 0;
  int reservedRooms = 0;
  int pendingRequests = 0;
  int disabledRooms = 0;

  final List<TimeSlot> _timeSlots = const [
    TimeSlot(id: 1, display: '08-10', endTime: TimeOfDay(hour: 10, minute: 0)),
    TimeSlot(id: 2, display: '10-12', endTime: TimeOfDay(hour: 12, minute: 0)),
    TimeSlot(id: 3, display: '13-15', endTime: TimeOfDay(hour: 15, minute: 0)),
    TimeSlot(id: 4, display: '15-17', endTime: TimeOfDay(hour: 17, minute: 0)),
  ];

  @override
  void initState() {
    super.initState();
    _loadPageData();
  }

  Future<void> _loadPageData() async {
    setState(() {
      _isWaiting = true;
      _error = null;
    });
    try {
      await Future.wait([_loadUserInfo(), _loadSummary(), _fetchRooms()]);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst("Exception: ", "");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isWaiting = false;
        });
      }
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _username = prefs.getString('username') ?? 'Staff';
      });
    }
  }

  Future<void> _loadSummary() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/dashboard/summary');
    try {
      final res = await http.get(url);
      final data = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        freeRooms = data['freeRooms'] ?? 0;
        reservedRooms = data['reservedBookings'] ?? 0;
        pendingRequests = data['pendingBookings'] ?? 0;
        disabledRooms = data['disabledRooms'] ?? 0;
      });
    } catch (e) {
      throw Exception('Failed to load summary');
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/rooms');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _rooms = data
                .map<Map<String, dynamic>?>((room) {
                  if (room == null) return null;
                  return {
                    'id': room['room_id'] ?? 0,
                    'name': room['room_name']?.toString() ?? 'Unknown Room',
                    'description': room['room_description']?.toString() ?? '',
                    'status':
                        room['room_status']?.toString() ??
                        'disabled', // Default to disabled
                    'capacity': room['capacity']?.toString() ?? 'N/A',
                    'image': room['image']?.toString() ?? '',
                    'booked_slots': (room['booked_slots'] is List)
                        ? List<int>.from(room['booked_slots'])
                        : <int>[],
                  };
                })
                .whereType<Map<String, dynamic>>()
                .toList();
          });
        }
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  List<Map<String, dynamic>> _filteredRooms() {
    final query = _searchBox.text.trim().toLowerCase();
    if (query.isEmpty) return _rooms;
    return _rooms.where((room) {
      return room["name"]!.toLowerCase().contains(query) ||
          room["description"]!.toLowerCase().contains(query);
    }).toList();
  }

  void navigateToEditRoom(
    BuildContext context,
    Map<String, dynamic> room,
  ) async {
    final bool? didUpdate = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => EditRoomPage(rooms: room)),
    );

    if (didUpdate == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(12),
          ),
        );
      }
      _loadPageData();
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
            UserAccountsDrawerHeader(
              accountName: Text(
                _username ?? 'Staff',
                style: const TextStyle(
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
      body: _isWaiting
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadPageData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: [
                // Header
                SliverAppBar(
                  backgroundColor: const Color(0xFF3C9CBF),
                  expandedHeight: 150,
                  pinned: true,
                  floating: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                  actions: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.black,
                          size: 30,
                        ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    child: DashboardSummary(
                      freeSlots: freeRooms,
                      reservedSlots: reservedRooms,
                      pendingSlots: pendingRequests,
                      disabledRooms: disabledRooms,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid.builder(
                    itemCount: _filteredRooms().length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 3 / 5.0,
                        ),
                    itemBuilder: (context, index) {
                      final room = _filteredRooms()[index];
                      final String displayStatus = room['status'] ?? 'disabled';
                      final String status = displayStatus.toLowerCase();
                      final bool canEdit =
                          (status == 'free' || status == 'disabled');
                      return RoomCard(
                        room: room,
                        timeSlots: _timeSlots,
                        onEdit: canEdit
                            ? () => navigateToEditRoom(context, room)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
