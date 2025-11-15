import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/lecturer/pages/dashboard_summary.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_br/api_config.dart';
import 'package:project_br/notifiers.dart';

class TimeSlot {
  final int id;
  final String display;
  final TimeOfDay endTime;
  const TimeSlot({
    required this.id,
    required this.display,
    required this.endTime,
  });
}

class LecturerHomePages extends StatefulWidget {
  const LecturerHomePages({super.key});

  @override
  State<LecturerHomePages> createState() => _LecturerHomePagesState();
}

class _LecturerHomePagesState extends State<LecturerHomePages> {
  final TextEditingController _searchBox = TextEditingController();

  // --- State variables ---
  List<Map<String, dynamic>> _rooms = [];
  bool _isWaiting = true;
  String? _error;

  int totalSlots = 0;
  int freeRooms = 0;
  int reservedRooms = 0;
  int pendingRequests = 0;
  int disabledRooms = 0;
  String? userName;
  String? userEmail;

  double _t2d(TimeOfDay t) => t.hour + t.minute / 60.0;

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
        userName = prefs.getString('username') ?? 'Lecturer';
      });
    }
  }

  Future<void> _loadSummary() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/dashboard/summary');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    try {
      final res = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(res.body);
      if (!mounted) return;
      setState(() {
        totalSlots = data['totalSlots'] ?? 0;
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
                    'status': room['room_status']?.toString() ?? 'Disable',
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
    final currentUserRole = UserRole.lecturer;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF3C9CBF)),
              accountName: Text(
                userName ?? 'Lecturer',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              accountEmail: null,
              currentAccountPicture: const CircleAvatar(
                child: Icon(Icons.person, color: Colors.black, size: 40),
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

      body: _isWaiting
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xffDB5151)),
                  ),
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
                SliverAppBar(
                  backgroundColor: const Color(0xFF3C9CBF),
                  expandedHeight: 150,
                  pinned: true,
                  floating: true, // Added this
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                  actions: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.black),
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
                          mainAxisSize: MainAxisSize.min,
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
                                  hintText: "Search Study Room or Status ",
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

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DashboardSummary(
                      freeSlots: freeRooms,
                      totalSlots: totalSlots,
                      reservedSlots: reservedRooms,
                      pendingSlots: pendingRequests,
                      disabledRooms: disabledRooms,
                      userRole: currentUserRole,
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  sliver: SliverGrid.builder(
                    itemCount: _search(_rooms).length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 18,
                          childAspectRatio: 3 / 5.0,
                        ),
                    itemBuilder: (_, i) {
                      final list = _search(_rooms);
                      final room = list[i];

                      final List<int> bookedSlots = room['booked_slots'] ?? [];
                      final capacityRoom = (room['capacity'] as String?) ?? '-';
                      final String displayStatus = room['status'] ?? 'Disable';
                      final Color displayColor;
                      if (displayStatus.toLowerCase() == 'free') {
                        displayColor = const Color(0xff3BCB53);
                      } else {
                        displayColor = const Color(0xff4E534E);
                      }
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
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(16),
                              ),
                              child: Image.asset(
                                room['image']?.isNotEmpty ?? false
                                    ? 'assets/images/${room['image']}' // Added asset path
                                    : 'assets/images/placeholder.png',
                                height: 165,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const SizedBox(
                                      height: 165,
                                      child: Center(
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                              ),
                            ),
                            //Room Name
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      room['name'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const SizedBox(width: 8),
                                      const Icon(
                                        Icons.group,
                                        size: 16,
                                        color: Color(0xFF3C9CBF),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        capacityRoom,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            //Available Time
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 1.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.lock_clock, size: 15),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Available Times',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                  //Time ships
                                  const SizedBox(height: 5),
                                  Row(
                                    children: List.generate(_timeSlots.length, (
                                      slotIndex,
                                    ) {
                                      final slot = _timeSlots[slotIndex];
                                      final double nowDouble = _t2d(
                                        TimeOfDay.now(),
                                      );
                                      final bool isBooked = bookedSlots
                                          .contains(slot.id);
                                      final bool isPast =
                                          nowDouble >= _t2d(slot.endTime);
                                      final bool isDisabled =
                                          displayStatus.toLowerCase() ==
                                          'disable';
                                      final Color barColor;
                                      final Color textColor;

                                      if (isDisabled) {
                                        barColor = Colors.grey[500]!;
                                        textColor = Colors.grey[700]!;
                                      } else if (isBooked) {
                                        barColor = const Color(
                                          0xffDB5151,
                                        ); // Booked
                                        textColor = Colors.white;
                                      } else if (isPast) {
                                        barColor =
                                            Colors.grey[350]!; // time past
                                        textColor = Colors.grey[700]!;
                                      } else {
                                        // Available
                                        barColor = const Color(0xff3BCB53);
                                        textColor = Colors.white;
                                      }

                                      return Expanded(
                                        child: Column(
                                          children: [
                                            Container(
                                              height: 25,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 2.0,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: barColor,
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  slot.display,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color: textColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(
                                left: 12,
                                right: 12,
                                bottom: 15,
                              ),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: displayColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(
                                    displayStatus,
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
