import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // ⭐️ 1. เพิ่ม Import นี้ (สำหรับตัด T)
import 'package:shared_preferences/shared_preferences.dart';

class StudentBookingPages extends StatefulWidget {
  const StudentBookingPages({super.key});

  @override
  State<StudentBookingPages> createState() => _StudentBookingPagesState();
}

class _StudentBookingPagesState extends State<StudentBookingPages> {
  // ⭐️ 2. แก้ไข Type ให้ถูกต้อง
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  final String baseUrl = "http://172.16.10.111:3000";

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  // ⭐️ 3. เพิ่มฟังก์ชันแปลง ID เป็นเวลา
  String _mapSlotIdToTime(int? slotId) {
    switch (slotId) {
      case 1:
        return '08.00 - 10.00 AM';
      case 2:
        return '10.00 - 12.00 AM';
      case 3:
        return '01.00 - 03.00 PM';
      case 4:
        return '03.00 - 05.00 PM';
      default:
        return 'Unknown Time';
    }
  }

  Future<void> _fetchBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) throw Exception("No user ID found");

      // ⭐️ 4. FIX: เรียก Endpoint "today" ที่ถูกต้อง (แก้ปัญหา Timezone)
      final response = await http.get(
        Uri.parse('$baseUrl/bookings/user/$userId/today'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _bookings = List<Map<String, dynamic>>.from(data);
        });
      } else {
        throw Exception('Failed to load booking (${response.statusCode})');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cancelBooking(int bookingId) async {
    try {
      // ⭐️ 5. FIX: API Path นี้ถูกต้องแล้ว (จากไฟล์ app.js)
      final response = await http.patch(
        Uri.parse('$baseUrl/bookings/$bookingId/cancel'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking cancelled successfully'),
            backgroundColor: Colors.grey,
          ),
        );
        _fetchBookings(); // รีเฟรช (รายการจะหายไป -> กลายเป็น Empty)
      } else {
        throw Exception("Failed to cancel (${response.statusCode})");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _confirmCancelDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_rounded, size: 100, color: Colors.amber),
        title: const Text('Confirm Cancellation'),
        content: const Text(
          'Are you sure you want to cancel this booking request?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelBooking(booking['id']);
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  // ⭐️ 6. เพิ่มฟังก์ชันจัดการรูปภาพ
  Widget _buildSafeImage(
    dynamic imageValue, {
    required double width,
    required double height,
  }) {
    final imageName = (imageValue as String?) ?? '';
    final localAsset = imageName.isNotEmpty
        ? 'assets/images/$imageName'
        : 'assets/images/placeholder.png';

    return Image.asset(
      localAsset,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          'assets/images/placeholder.png',
          width: width,
          height: height,
          fit: BoxFit.cover,
        );
      },
    );
  }

  // ================= UI ====================
  @override
  Widget build(BuildContext context) {
    // ⭐️ 7. FIX: ลบ TabController ทิ้ง
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: const Text(
          'My Books',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // ⭐️ 8. FIX: เอา TabBar (bottom) ออก, ใส่ "Upcoming" กลับมา
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(67),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: const [
              Divider(thickness: 1, height: 0),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "Today's booking",
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
              child: _bookings.isEmpty
                  ? _buildEmptyState()
                  : ListView(children: [_buildBookingCard(_bookings[0])]),
            ),
    );
  }

  Widget _buildErrorState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, color: Colors.red, size: 60),
        const SizedBox(height: 10),
        Text('Error: $_error', textAlign: TextAlign.center),
        const SizedBox(height: 10),
        ElevatedButton(onPressed: _fetchBookings, child: const Text('Retry')),
      ],
    ),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.calendar_month_outlined, size: 60, color: Colors.grey[400]),
        const SizedBox(height: 16),
        const Text(
          'No upcoming books yet.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black54,
          ),
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

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final String status = (booking['status'] ?? 'Unknown').toLowerCase();
    final String displayStatus = status.isNotEmpty
        ? status[0].toUpperCase() + status.substring(1)
        : 'Unknown';
    final bool isPending = (status == 'pending');

    Color statusColor;
    switch (status) {
      case 'approved':
        statusColor = const Color(0xff3BCB53); // Green
        break;
      case 'rejected':
        statusColor = const Color(0xffDB5151); // Red
        break;
      case 'pending':
        statusColor = const Color(0xffF4E75A); // Yellow
        break;
      default:
        statusColor = Colors.grey;
    }

    final String dateFromServer = (booking['booking_date'] ?? '').toString();
    final String displayDate = dateFromServer.split('T')[0];

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
                Text(
                  'Request ID: ${booking['id']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    displayStatus,
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
                  child: _buildSafeImage(
                    booking['image'],
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking['room_name'] ?? 'Unknown Room',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(label: 'Date', value: displayDate),
                      _buildDetailRow(
                        label: 'Time',
                        value: _mapSlotIdToTime(booking['slot_id'] as int?),
                      ),
                      _buildDetailRow(
                        label: 'Booking By',
                        value: booking['booked_by_name'] ?? '',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isPending) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _confirmCancelDialog(booking),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffDB5151),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String value}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}
