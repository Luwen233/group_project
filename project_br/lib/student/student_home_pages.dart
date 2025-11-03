import 'package:flutter/material.dart';
import 'package:project_br/login/login_page.dart';
import 'package:project_br/student/student_room_detail_pages.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentHomePages extends StatefulWidget {
  const StudentHomePages({super.key});

  @override
  State<StudentHomePages> createState() => _StudentHomePagesState();
}

class _StudentHomePagesState extends State<StudentHomePages> {
  final _searchBox = TextEditingController();
  List<Map<String, dynamic>> _rooms = [];
  bool _isWaiting = true;
  String? _error;
  String _username = 'Student';
  int _userId = 0;
  bool _hasActiveBooking = false;

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
      final uri = Uri.http(
        '127.0.0.1:3000',
        '/my-bookings-today/$_userId',
      ); //CHANGE IPs
      final res = await http.get(uri).timeout(const Duration(seconds: 5));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _hasActiveBooking = data.isNotEmpty;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isWaiting = false);
    }
  }

  Future<void> _fetchRooms() async {
    try {
      final uri = Uri.http('127.0.0.1:3000', '/rooms'); //CHANGE IPs
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
                          childAspectRatio: 3 / 3.7,
                        ),
                    itemBuilder: (context, index) {
                      final room = _filteredRooms()[index];
                      final isFree =
                          (room['status'] as String).toLowerCase() == 'free';

                      final bool canTap = isFree && !_hasActiveBooking;

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
                        onTap: canTap
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

                                // Refresh ONLY if detail page returned true (i.e., after booking)
                                if (changed == true) {
                                  // refresh quietly—no spinner/flicker
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
                                  vertical: 6,
                                ),
                                child: Text(
                                  room['name'] as String,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
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
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFree
                                          ? (canTap
                                                ? const Color(0xff3BCB53)
                                                : Colors.grey[400])
                                          : const Color(0xff4E534E),
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
