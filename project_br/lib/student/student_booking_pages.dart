import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StudentBookingPages extends StatefulWidget {
  const StudentBookingPages({super.key});

  @override
  State<StudentBookingPages> createState() => _StudentBookingPagesState();
}

class _StudentBookingPagesState extends State<StudentBookingPages> {
  List<Map<String, dynamic>> _pendingBookings = [];
  bool _isLoading = true;
  String? _error;
  int? _userId;

  final String serverIP = "172.27.1.70:3000"; // 🧩 เปลี่ยน IP ตรงนี้ให้ตรงกับ server ของคุณ

  @override
  void initState() {
    super.initState();
    _loadUserAndBookings();
  }

  Future<void> _loadUserAndBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('user_id');
      if (_userId == null) {
        setState(() => _error = "User not found. Please login again.");
        return;
      }
      await _loadBookings();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final uri = Uri.http(serverIP, '/bookings/user/$_userId');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _pendingBookings = data
              .map<Map<String, dynamic>>((b) => {
                    'id': b['booking_id'].toString(),
                    'roomName': b['room_name'] ?? 'Unknown Room',
                    'image': 'assets/images/room1.jpg',
                    'date': b['booking_date'] ?? '',
                    'time': '${b['start_time'] ?? ''} - ${b['end_time'] ?? ''}',
                    'name': b['user_name'] ?? '',
                    'bookingDate': b['created_at'] ?? '',
                    'status': b['booking_status'] ?? '',
                  })
              .where((b) => b['status'] == 'Pending')
              .toList();
        });
      } else {
        setState(() => _error = 'Server error: ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    try {
      final uri = Uri.http(serverIP, '/bookings/cancel/${booking['id']}');
      final res = await http.put(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully.'),
            backgroundColor: Colors.grey,
          ),
        );
        _loadBookings(); // refresh list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking (${res.statusCode})'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelConfirmationDialog(
      BuildContext context, Map<String, dynamic> bookingToCancel) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: const Icon(Icons.warning_rounded, size: 100, color: Colors.amber),
          title: const Text('Confirm Cancellation'),
          content: const Text(
            'Are you sure you want to cancel this booking request?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop();
                _cancelBooking(bookingToCancel);
              },
            ),
          ],
        );
      },
    );
  }

  // -------------------- UI Section --------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: const Text(
          'My Books',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(67),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Divider(thickness: 1, height: 0),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff3C9CBF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Padding(
                  padding: const EdgeInsets.all(20),
                  child: _pendingBookings.isEmpty
                      ? _buildEmptyState()
                      : _buildBookingList(),
                ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 10),
          Text('Error: $_error', textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadBookings,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList() {
    return ListView.builder(
      itemCount: _pendingBookings.length,
      itemBuilder: (context, index) {
        final booking = _pendingBookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Request ID: ${booking['id']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xffF4E75A), // pending = yellow
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['status'],
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    booking['image'],
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['roomName'],
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(label: 'Date', value: booking['date']),
                      _buildDetailRow(label: 'Time', value: booking['time']),
                      _buildDetailRow(label: 'Booking By', value: booking['name']),
                      _buildDetailRow(
                          label: 'Booking Date', value: booking['bookingDate']),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showCancelConfirmationDialog(context, booking),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffDB5151),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_month_outlined,
              size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No upcoming books yet.',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Text(
            'Browse Rooms On The Home Page To Reserve One.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(
            value,
            style: const TextStyle(
                color: Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
