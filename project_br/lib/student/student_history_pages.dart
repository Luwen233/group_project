import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:project_br/student/booking_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentHistoryPages extends StatefulWidget {
  const StudentHistoryPages({super.key});

  @override
  State<StudentHistoryPages> createState() => _StudentHistoryPagesState();
}

class _StudentHistoryPagesState extends State<StudentHistoryPages> {
  int? savedUserID;
  //filter list status
  List<Map<String, dynamic>> _getFilteredBookings(String status) {
    if (status == 'All') {
      return BookingService.bookings
          .where((b) => b['status'] != 'Pending')
          .toList();
    }
    return BookingService.bookings.where((b) => b['status'] == status).toList();
  }

  // Function to show the btm sheet
  void _showMoreDetailsSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final String status = booking['status'] ?? 'Cancelled';
    Color statusColor;
    String statusActionText;

    switch (status) {
      case 'Approved':
        statusColor = Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'Rejected':
        statusColor = Color(0xffDB5151);
        statusActionText = 'Rejected On';
        break;
      case 'Cancelled':
      default:
        statusColor = Color(0xff4E534E);
        statusActionText = 'Cancelled On';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Request ID: ${booking['id']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                booking['roomName'] ?? 'Unknown Room',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${booking['date'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    'Time: ${booking['time'] ?? 'N/A'}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  booking['image'],
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        'Booked By',
                        booking['name'] ?? 'Mr. John',
                      ),
                      SizedBox(height: 12),
                      _buildDetailItem(
                        'Requested On',
                        booking['date'] ?? 'Sep 22, 2025',
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        'Approved By',
                        booking['approver'] ?? 'Mr. John',
                      ),
                      SizedBox(height: 12),
                      _buildDetailItem(
                        statusActionText,
                        booking['actionDate'] ?? 'Sep 22, 2025',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Don't show notes if Cancelled
              if (status != 'Cancelled')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Reason Requested
                    Text(
                      'Reason Requested', // Changed label
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking['reason'] ?? 'No reason provided.', // Show reason
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),

                    //lecuterer note only reject
                    if (status == 'Rejected')
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lecturer Note',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            booking['lecturerNote'] ?? 'No note provided.',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                  ],
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff3BCB53),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _init(); // เรียกตัวกลางแทน
  }

  Future<void> _init() async {
    await _loadUserData(); // รอให้ได้ savedUserID ก่อน
    await _loadLogs(); // แล้วค่อยโหลด logs ของ user
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      savedUserID = prefs.getInt('user_id'); // อาจเป็น null ได้ ถ้าไม่เคยเซฟ
    });
  }

  Future<void> _loadLogs() async {
    try {
      if (savedUserID == null) {
        // ป้องกัน null: จะเลือกโหลด all logs หรือ return เลยก็ได้
        // await BookingService.fetchAllLogs();
        return;
      }
      // ใช้ user id จริง แทน '1' ที่ฮาร์ดโค้ด
      await BookingService.fetchLogsByUser(savedUserID!.toString());
      setState(() {});
    } catch (e) {
      debugPrint('Load logs error: $e');
    }
  }

  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Color(0xFFF7F7F7),
          elevation: 3,
          shadowColor: Colors.black54,
          title: Text(
            'My History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          bottom: PreferredSize(
            preferredSize: Size.fromHeight(67),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(thickness: 1, height: 0),
                Padding(
                  padding: EdgeInsets.zero,
                  child: TabBar(
                    labelColor: Color(0xff3C9CBF),
                    unselectedLabelColor: Color(0xff4E534E),
                    indicatorColor: Color(0xff3C9CBF),
                    isScrollable: true,
                    tabs: [
                      Tab(text: 'All'),
                      Tab(text: 'Approved'),
                      Tab(text: 'Rejected'),
                      Tab(text: 'Cancelled'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryList('All'),
            _buildHistoryList('Approved'),
            _buildHistoryList('Rejected'),
            _buildHistoryList('Cancelled'),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryList(String status) {
    final List<Map<String, dynamic>> filteredList = _getFilteredBookings(
      status,
    );

    if (filteredList.isEmpty) {
      return _buildEmptyState(status);
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final booking = filteredList[index];
        return _buildHistoryCard(booking);
      },
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${status.toLowerCase()} bookings yet.',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final String status = booking['status'] ?? 'Cancelled';
    Color statusColor;
    String statusActionText;

    switch (status) {
      case 'Approved':
        statusColor = Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'Rejected':
        statusColor = Color(0xffDB5151);
        statusActionText = 'Rejected On';
        break;
      case 'Cancelled':
      default:
        statusColor = Color(0xff4E534E);
        statusActionText = 'Cancelled On';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              booking['roomName'],
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            child: Image.asset(
              booking['image'],
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      'Booked By',
                      booking['name'] ?? 'Mr. John',
                    ),
                    SizedBox(height: 12),
                    _buildDetailItem(
                      'Requested On',
                      booking['date'] ?? 'Sep 22, 2025',
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      'Approved By',
                      booking['approver'] ?? 'Mr. John',
                    ),
                    SizedBox(height: 12),
                    _buildDetailItem(
                      statusActionText,
                      booking['actionDate'] ?? 'Sep 22, 2025',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _showMoreDetailsSheet(context, booking);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'More',
                      style: TextStyle(
                        color: Colors.black54,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
