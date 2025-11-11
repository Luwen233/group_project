import 'package:flutter/material.dart';
import 'package:project_br/api_config.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/student/pages/student_room_detail_page.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomePages extends StatefulWidget {
  const StudentHomePages({super.key});

  @override
  State<StudentHomePages> createState() => _StudentHomePagesState();
}

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

class _StudentHomePagesState extends State<StudentHomePages> {
  final _searchBox = TextEditingController();
  List<Map<String, dynamic>> _rooms = [];
  bool _isWaiting = true;
  String? _error;
  String _username = 'Student';
  int _userId = 0;
  bool _hasActiveBooking = false;
  int? _myBookingRoomId;
  String _myBookingStatus = '';

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
    _loadUserDataAndFetchData();
  }

  Future<void> _loadUserDataAndFetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('token');

      // Load user data from memo
      _userId = prefs.getInt('user_id') ?? 0;
      _username = prefs.getString('username') ?? 'Student';

      if (token == null || _userId == 0) {
        _logout();
        return;
      }

      await Future.wait([_checkMyBookingStatus(), _fetchRooms()]);
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

  Future<void> _checkMyBookingStatus() async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/bookings/user/$_userId/today',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            if (data.isNotEmpty) {
              final myBooking = data[0];
              _hasActiveBooking = true;
              _myBookingRoomId = myBooking['room_id'] as int?;

              _myBookingStatus = (myBooking['status']?.toString() ?? 'pending')
                  .toLowerCase();
            } else {
              _hasActiveBooking = false;
              _myBookingRoomId = null;
              _myBookingStatus = '';
            }
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/rooms'); //CHANGE IPs
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

  Future<void> _logout() async {
    final storage = await SharedPreferences.getInstance();
    await storage.clear(); // clear all

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  List<Map<String, dynamic>> _filteredRooms() {
    final q = _searchBox.text.trim().toLowerCase();
    if (q.isEmpty) return _rooms;
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
  Widget build(BuildContext buildContext) {
    final DateTime now = DateTime.now();
    final String formattedDate = DateFormat('MMM d, y').format(now);

    return Scaffold(
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              accountName: Text(
                _username,
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
              leading: Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: _logout,
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
                    onPressed: () {
                      setState(() {
                        _isWaiting = true;
                        _error = null;
                      });
                      _loadUserDataAndFetchData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  backgroundColor: const Color(0xFF3C9CBF),
                  expandedHeight: 150.0,
                  pinned: true,
                  floating: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
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
                                  hintText: 'Search Study Room or Status ',
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

                // Room Grid
                SliverPadding(
                  padding: const EdgeInsets.all(12),
                  sliver: SliverGrid.builder(
                    itemCount: _filteredRooms().length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 16,
                          childAspectRatio: 3 / 5.3,
                        ),
                    itemBuilder: (context, index) {
                      final room = _filteredRooms()[index];
                      final int currentRoomId = room['id'];
                      final String generalStatus = (room['status'] as String)
                          .toLowerCase();
                      final bool isMyActiveBooking =
                          (currentRoomId == _myBookingRoomId) &&
                          _hasActiveBooking;

                      String displayStatus;
                      Color displayColor;
                      bool canTap;

                      if (isMyActiveBooking) {
                        if (_myBookingStatus == 'pending') {
                          displayStatus = 'Pending';
                          displayColor = Colors.yellow[700]!;
                        } else {
                          // 'approved'
                          displayStatus = 'Reserved';
                          displayColor = const Color(0xff3BCB53);
                        }
                        canTap = false;
                      } else {
                        if (generalStatus == 'free') {
                          if (_hasActiveBooking) {
                            displayStatus = 'free';
                            displayColor = Colors.grey[400]!;
                            canTap = false;
                          } else {
                            displayStatus = 'free';
                            displayColor = const Color(0xff3BCB53);
                            canTap = true;
                          }
                        } else {
                          displayStatus = room['status'] as String;
                          displayColor = const Color(0xff4E534E);
                          canTap = false;
                        }
                      }
                      final capacityRoom = (room['capacity'] as String?) ?? '-';
                      final List<int> bookedSlots = room['booked_slots'] ?? [];
                      final imageValue = (room['image'] as String?) ?? '';
                      final isNetworkImage = imageValue.startsWith('http');
                      Widget roomImage;
                      if (isNetworkImage) {
                        roomImage = Image.network(
                          imageValue,
                          height: 165,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                                height: 165,
                                child: Center(child: Icon(Icons.broken_image)),
                              ),
                        );
                      } else {
                        final localAsset = imageValue.isNotEmpty
                            ? 'assets/images/$imageValue'
                            : 'assets/images/placeholder.png';
                        roomImage = Image.asset(
                          localAsset,
                          height: 165,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const SizedBox(
                                height: 165,
                                child: Center(child: Icon(Icons.broken_image)),
                              ),
                        );
                      }

                      return GestureDetector(
                        onTap:
                            canTap // 👈 Use new variable
                            ? () async {
                                final changed = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RoomDetailPage(
                                      rooms: room,
                                      bookedSlotIds: room['booked_slots'] ?? [],
                                    ),
                                  ),
                                );

                                if (!mounted) return;

                                if (changed == true) {
                                  await _fetchRooms();
                                  await _checkMyBookingStatus();
                                  if (mounted) setState(() {});
                                }
                              }
                            : null,
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
                                child: roomImage,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    //Room Name
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

                                    //Capacity
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 8),
                                        Icon(
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
                                        Icon(Icons.lock_clock, size: 15),
                                        SizedBox(width: 6),
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
                                    const SizedBox(height: 5),
                                    Row(
                                      children: List.generate(
                                        _timeSlots.length,
                                        (slotIndex) {
                                          final slot = _timeSlots[slotIndex];
                                          final double nowDouble = _t2d(
                                            TimeOfDay.now(),
                                          );
                                          final bool isBooked = bookedSlots
                                              .contains(slot.id);
                                          final bool isPast =
                                              nowDouble >= _t2d(slot.endTime);
                                          final Color barColor;
                                          final Color textColor;

                                          if (isBooked) {
                                            barColor = Color(
                                              0xffDB5151,
                                            ); // Booked
                                            textColor = Colors.white;
                                          } else if (isPast) {
                                            barColor =
                                                Colors.grey[350]!; // time past
                                            textColor = Colors.grey[700]!;
                                          } else {
                                            barColor = const Color(
                                              0xff3BCB53,
                                            ); // Available
                                            textColor = Colors.white;
                                          }
                                          //container ships time slots
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
                                                        BorderRadius.circular(
                                                          5,
                                                        ),
                                                  ),

                                                  //label
                                                  child: Center(
                                                    child: Text(
                                                      slot.display,
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: textColor,
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
                              ),
                              const Spacer(),
                              // Status Ships
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
