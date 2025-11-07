import 'package:flutter/material.dart';
import 'package:project_br/student/booking_service.dart';
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
  int _userId = 0;
  String _token = '';

  @override
  void initState() {
    super.initState();
    _loadUserDataAndFetchBookings();
  }

  // ⭐️ ดึงข้อมูลจาก database
  Future<void> _loadUserDataAndFetchBookings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getInt('user_id') ?? 0;
      _token = prefs.getString('token') ?? '';

      if (_userId == 0 || _token.isEmpty) {
        setState(() {
          _error = 'User session expired. Please login again.';
          _isLoading = false;
        });
        return;
      }

      final bookings = await BookingService.fetchPendingBookings(
        _userId,
        _token,
      );

      if (mounted) {
        setState(() {
          _pendingBookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load bookings: $e';
          _isLoading = false;
        });
      }
    }
  }

  // ยกเลิก booking
  Future<void> _cancelBooking(Map<String, dynamic> bookingToCancel) async {
    try {
      // เรียก API เพื่อยกเลิก booking
      await BookingService.cancelBooking(bookingToCancel['id'], _token);

      // รีโหลดข้อมูลใหม่
      await _loadUserDataAndFetchBookings();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your booking request has been cancelled.'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showCancelConfirmationDialog(
    BuildContext context,
    Map<String, dynamic> bookingToCancel,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(Icons.warning_rounded, size: 100, color: Colors.amber),
          title: const Text('Confirm Cancellation'),
          content: const Text(
            'Are you sure you want to cancel this booking request?',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop();
              },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: Text(
          'My Bookings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        actions: [
          // ⭐️ ปุ่ม Refresh
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadUserDataAndFetchBookings,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(67),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Divider(thickness: 1, height: 0),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pending Requests',
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
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadUserDataAndFetchBookings,
                    child: Text('Retry'),
                  ),
                ],
              ),
            )
          : Padding(
              padding: EdgeInsets.all(20),
              child: _pendingBookings.isEmpty
                  ? _buildEmptyState()
                  : _buildBookingList(),
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
                    color: Color(0xffF4E75A),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking['status'],
                    style: TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildDetailRow(label: 'Date', value: booking['date']),
                      _buildDetailRow(label: 'Time', value: booking['time']),
                      _buildDetailRow(
                        label: 'Booking By',
                        value: booking['name'],
                      ),
                      _buildDetailRow(
                        label: 'Booking Date',
                        value: booking['bookingDate'],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _showCancelConfirmationDialog(context, booking);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xffDB5151),
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
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_month_outlined,
            size: 60,
            color: Colors.grey[400],
          ),
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
            style: TextStyle(
              color: Colors.black,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
