import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:project_br/student/booking_service.dart';

class StudentBookingPages extends StatefulWidget {
  const StudentBookingPages({super.key});

  @override
  State<StudentBookingPages> createState() => _StudentBookingPagesState();
}

class _StudentBookingPagesState extends State<StudentBookingPages> {
  List<Map<String, dynamic>> _pendingBookings = [];

  @override
  void initState() {
    super.initState();
    _filterPendingBookings();
  }

  void _filterPendingBookings() {
    setState(() {
      _pendingBookings = BookingService.bookings
          .where((booking) => booking['status'] == 'Pending')
          .toList();
    });
  }

  // --- UPDATED LOGIC ---
  // This function now just updates the status and shows the snackbar
  void _cancelBooking(Map<String, dynamic> bookingToCancel) {
    setState(() {
      final originalBooking = BookingService.bookings.firstWhere(
        (b) => b['id'] == bookingToCancel['id'],
      );
      originalBooking['status'] = 'Cancelled';
      _filterPendingBookings();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your Booking request has been cancelled.'),
        backgroundColor: Colors.grey,
      ),
    );
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
          'My Books',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(67),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
      body: Padding(
        padding: EdgeInsets.all(20),
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
