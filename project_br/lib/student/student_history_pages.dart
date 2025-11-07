import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_br/student/booking_service.dart';

class StudentHistoryPages extends StatefulWidget {
  const StudentHistoryPages({super.key});

  @override
  State<StudentHistoryPages> createState() => _StudentHistoryPagesState();
}

class _StudentHistoryPagesState extends State<StudentHistoryPages> {
  int? savedUserID;
  String? _token;
  List<Map<String, dynamic>> _allBookings = [];

  @override
  void initState() {
    super.initState();
    _loadHistoryData();
  }

  Future<void> _loadHistoryData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      savedUserID = prefs.getInt('user_id');
      _token = prefs.getString('token');

      if (savedUserID != null && _token != null) {
        // เรียก API เพื่อดึง history
        final bookings = await BookingService.fetchHistoryBookings(
          savedUserID!,
          _token!,
        );

        // 🔍 Debug: แสดงข้อมูลที่ได้จาก API
        debugPrint('📋 Total history bookings: ${bookings.length}');
        for (var b in bookings) {
          debugPrint(
            '  - ID: ${b['id']}, Status: ${b['status']}, Room: ${b['roomName']}',
          );
        }

        if (mounted) {
          setState(() {
            _allBookings = bookings;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) {
        setState(() {
          _allBookings = [];
        });
      }
    }
  }

  //filter list status
  List<Map<String, dynamic>> _getFilteredBookings(String status) {
    if (status == 'All') {
      final filtered = _allBookings
          .where((b) => b['status']?.toString().toLowerCase() != 'pending')
          .toList();
      debugPrint('🔍 Filter "$status": ${filtered.length} items');
      return filtered;
    }

    // เปรียบเทียบแบบไม่สนใจตัวพิมพ์เล็ก-ใหญ่
    final filtered = _allBookings.where((b) {
      final bookingStatus = b['status']?.toString().toLowerCase() ?? '';
      final targetStatus = status.toLowerCase();
      return bookingStatus == targetStatus;
    }).toList();

    debugPrint('🔍 Filter "$status": ${filtered.length} items');
    return filtered;
  }

  // Function to show the btm sheet
  void _showMoreDetailsSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final String status = booking['status'] ?? 'cancelled';
    String statusActionText;

    switch (status.toLowerCase()) {
      case 'approved':
        statusActionText = 'Approved On';
        break;
      case 'rejected':
        statusActionText = 'Rejected On';
        break;
      case 'cancelled':
      default:
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
              if (status.toLowerCase() != 'cancelled')
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
                    if (status.toLowerCase() == 'rejected')
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
    final String status = booking['status'] ?? 'cancelled';
    Color statusColor;
    String statusActionText;
    String displayStatus;

    switch (status.toLowerCase()) {
      case 'approved':
        statusColor = Colors.green;
        statusActionText = 'Approved On';
        displayStatus = 'Approved';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusActionText = 'Rejected On';
        displayStatus = 'Rejected';
        break;
      case 'cancelled':
      default:
        statusColor = Colors.grey;
        statusActionText = 'Cancelled On';
        displayStatus = 'Cancelled';
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
                Expanded(
                  child: Column(
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
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
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
                        displayStatus,
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
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
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
