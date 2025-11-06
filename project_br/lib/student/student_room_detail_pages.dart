import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Timeslot
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

// Room Detail Page
class RoomDetailPage extends StatefulWidget {
  final Map<String, dynamic> rooms;
  final List<int> bookedSlotIds;

  const RoomDetailPage({
    super.key,
    required this.rooms,
    required this.bookedSlotIds,
  });

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  TimeSlot? _selectedSlot;
  final _reasonController = TextEditingController();
  bool _submitting = false;

  late final List<int> _bookedSlotIds;

  int _userId = 0;
  String _token = ''; //store auth token

  final List<TimeSlot> _timeSlots = const [
    TimeSlot(
      id: 1,
      display: '08.00 - 10.00 AM',
      endTime: TimeOfDay(hour: 10, minute: 0),
    ),
    TimeSlot(
      id: 2,
      display: '10.00 - 12.00 AM',
      endTime: TimeOfDay(hour: 12, minute: 0),
    ),
    TimeSlot(
      id: 3,
      display: '01.00 - 03.00 PM',
      endTime: TimeOfDay(hour: 15, minute: 0),
    ),
    TimeSlot(
      id: 4,
      display: '03.00 - 05.00 PM',
      endTime: TimeOfDay(hour: 17, minute: 0),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _bookedSlotIds = List<int>.from(widget.bookedSlotIds);
    _loadUserData(); // Load user ID & token
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userId = prefs.getInt('user_id') ?? 0;
      _token = prefs.getString('token') ?? '';
    });
  }

  double _t2d(TimeOfDay t) => t.hour + t.minute / 60.0;
  void _snack(String message, {Color color = const Color(0xffDB5151)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _bookNow() async {
    if (_selectedSlot == null || _reasonController.text.trim().isEmpty) {
      _snack('Please select a time and enter a reason.');
      return;
    }

    if (_userId == 0 || _token.isEmpty) {
      _snack('Error: User session expired. Please log in again.');
      return;
    }

    final int roomId = (widget.rooms['id'] ?? widget.rooms['room_id']) as int;
    final int slotId = _selectedSlot!.id;
    final String bookingDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final String reason = _reasonController.text.trim();

    setState(() => _submitting = true);

    try {
      final url = Uri.http(
        '172.27.1.70:3000',
        '/bookings',
      ); // CHANGE if not emulator
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'room_id': roomId,
          'user_id': _userId,
          'slot_id': slotId,
          'booking_date': bookingDate,
          'booking_reason': reason,
        }),
      );

      if (!mounted) return;

      final Map<String, dynamic> data = jsonDecode(res.body);

      if (res.statusCode == 200) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(
              Icons.check_circle_outline_rounded,
              color: Color(0xff3BCB53),
              size: 100,
            ),
            title: const Text('Booking Request Sent!'),
            content: Text(
              'Booking ID: ${data['booking_id']}\nCheck it in My Bookings.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, true); // changed = true back to home
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _snack('Error: ${data['error'] ?? res.body}');
      }
    } catch (e) {
      _snack('Network error: $e');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String name = (widget.rooms['name'] ?? 'Unknown Room').toString();
    final String status = (widget.rooms['status'] ?? 'Disable').toString();
    final bool isFree = status.toLowerCase() == 'free';
    final String description =
        (widget.rooms['description'] ?? 'No description provided.').toString();

    final String capacityText = (() {
      final c = widget.rooms['capacity'];
      final n = int.tryParse(c?.toString() ?? '');
      return (n == null || n == 0) ? 'N/A' : '$n People';
    })();

    final String img = (widget.rooms['image'] ?? '').toString().trim();
    final bool isNetwork = img.startsWith('http');
    final String assetPath = img.isEmpty
        ? 'assets/images/placeholder.png'
        : 'assets/images/$img';

    final headerImage = isNetwork
        ? Image.network(
            img,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 250,
              width: double.infinity,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported, size: 48),
            ),
          )
        : Image.asset(
            assetPath,
            height: 250,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 250,
              width: double.infinity,
              color: Colors.white,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported, size: 48),
            ),
          );

    const primaryBlue = Color(0xFF3C9CBF);
    const lightGrey = Color.fromARGB(115, 236, 236, 236);
    final nowDouble = _t2d(TimeOfDay.now());

    return Scaffold(
      backgroundColor: const Color(0xffffffff),

      bottomNavigationBar: BottomAppBar(
        color: const Color(0xffF7F7F7),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(0),
          child: ElevatedButton(
            onPressed: isFree && !_submitting ? _bookNow : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFree ? primaryBlue : Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    isFree ? 'Book Now' : status,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),

      body: Column(
        children: [
          Stack(
            children: [
              headerImage,
              Positioned(
                top: 50,
                left: 15,
                child: CircleAvatar(
                  backgroundColor: Colors.black26,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- top info ----------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: isFree
                                    ? const Color(0xff3BCB53)
                                    : const Color(0xff4E534E),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                status,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Icon(
                              Icons.people_outline_rounded,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Room Capacity',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              capacityText,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const Divider(color: lightGrey, thickness: 10),

                  // ---------- time slots ----------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Time Available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: _timeSlots.map((slot) {
                              final bool isFuture =
                                  nowDouble < _t2d(slot.endTime);
                              final bool isAlreadyBooked = _bookedSlotIds
                                  .contains(slot.id);
                              final bool enabled =
                                  isFree && isFuture && !isAlreadyBooked;
                              final bool selected =
                                  _selectedSlot?.id == slot.id;

                              Color chipColor;
                              Color textColor;
                              if (enabled) {
                                chipColor = selected ? primaryBlue : lightGrey;
                                textColor = selected
                                    ? Colors.white
                                    : Colors.black87;
                              } else {
                                chipColor = Colors.grey[200]!;
                                textColor = Colors.grey[500]!;
                              }

                              return GestureDetector(
                                onTap: () {
                                  if (enabled) {
                                    setState(() => _selectedSlot = slot);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: chipColor,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    slot.display,
                                    style: TextStyle(
                                      color: textColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                  const Divider(color: lightGrey, thickness: 10),

                  // ---------- reason ----------
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Reason Booking',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _reasonController,
                          maxLines: 3,
                          maxLength: 100,
                          enabled: isFree,
                          decoration: InputDecoration(
                            hintText: isFree
                                ? 'Type reason for booking'
                                : 'This room is not available for booking',
                            fillColor: lightGrey,
                            filled: true,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
