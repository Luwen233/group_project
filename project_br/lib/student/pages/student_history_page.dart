import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:project_br/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class StudentHistoryPages extends StatefulWidget {
  const StudentHistoryPages({super.key});

  @override
  State<StudentHistoryPages> createState() => _StudentHistoryPagesState();
}

class _StudentHistoryPagesState extends State<StudentHistoryPages> {
  int? savedUserID;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;
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

  String _formatIsoTo12HourTime(dynamic rawDate) {
    if (rawDate == null || rawDate.toString().isEmpty) {
      return '-';
    }

    try {
      final DateTime parsedDate = DateTime.parse(rawDate.toString());

      return DateFormat('hh:mm a').format(parsedDate);
    } catch (e) {
      print('Error parsing date: $e');
      return '-';
    }
  }

  bool _isHistoryItem(Map<String, dynamic> booking) {
    final String status = booking['status'] ?? '';
    final String bookingDateStr = booking['date'] ?? '';

    final String todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final bool isToday = (bookingDateStr == todayStr);
    if (status == 'Cancelled') {
      return true;
    }

    if ((status == 'Approved' || status == 'Rejected') && !isToday) {
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

     final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null) {
        throw Exception("User ID not found. Please log in again.");
      }

      final token = prefs.getString('token');
      final uri = Uri.parse('${ApiConfig.baseUrl}/bookings/user/$userId');
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _bookings = data.map<Map<String, dynamic>>((b) {
            final String dateFromServer = (b['booking_date'] ?? 'N/A')
                .toString();
            final String statusFromServer = (b['status'] ?? 'unknown')
                .toString();

            return {
              'id': b['id'].toString(),
              'roomName': b['room_name'] ?? 'Unknown Room',
              'date': dateFromServer.split('T')[0], // 👈 FIX 1
              'time': _mapSlotIdToTime(b['slot_id'] as int?),
              'status':
                  statusFromServer
                      .isNotEmpty // 👈 FIX 2
                  ? statusFromServer[0].toUpperCase() +
                        statusFromServer.substring(1)
                  : 'Unknown',
              'reason': b['reason'] ?? '',
              'approver': b['approver_name'] ?? '-',
              'lecturerNote': b['lecturer_note'] ?? '',
              'actionDate': b['action_date'] ?? '-',
              'actionTime': _formatIsoTo12HourTime(b['action_date']),
              'image': b['image'],
              'name': b['booked_by_name'] ?? 'Unknown',
            };
          }).toList();
        });
      } else {
        setState(() => _error = 'Server error ${res.statusCode}');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _getFilteredBookings(String status) {
    final List<Map<String, dynamic>> historyBookings = _bookings
        .where(_isHistoryItem)
        .toList();

    if (status == 'All') {
      return historyBookings;
    }

    return historyBookings.where((b) => b['status'] == status).toList();
  }

  void _showMoreDetailsSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final String status = booking['status'] ?? 'Cancelled';
    Color statusColor;
    String statusActionText;

    switch (status) {
      case 'Approved':
        statusColor = const Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'Rejected':
        statusColor = const Color(0xffDB5151);
        statusActionText = 'Rejected On';
        break;
      case 'Cancelled':
      default:
        statusColor = const Color(0xff4E534E);
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
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Request ID: ${booking['id']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            booking['roomName'],
                            style: const TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Date: ${booking['date']}',
                          style: const TextStyle(fontSize: 17),
                        ),
                        Text(
                          'Time: ${booking['time']}',
                          style: const TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // IMAGE
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: _buildSafeImage(booking['image']),
                  ),
                ),

                const SizedBox(height: 20),

                // DETAILS
                _buildDetailItem('Approved By', booking['approver']),
                if (booking['reason'] != null && booking['reason'] != '')
                  _buildDetailItem('Booking Reason', booking['reason']),

                if (status == 'Rejected' && booking['lecturerNote'] != null)
                  _buildDetailItem('Lecturer Note', booking['lecturerNote']),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'OK',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFFF7F7F7),
          elevation: 3,
          shadowColor: Colors.black54,
          title: const Text(
            'My History',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(67),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Divider(thickness: 1, height: 0),
                TabBar(
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
              ],
            ),
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(child: Text('Error: $_error'))
            : TabBarView(
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

  Widget _buildSafeImage(dynamic imageValue) {
    final imageName = (imageValue as String?) ?? '';
    final localAsset = imageName.isNotEmpty
        ? 'assets/images/$imageName'
        : 'assets/images/placeholder.png';

    return Image.asset(
      localAsset,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset('assets/images/placeholder.png', fit: BoxFit.cover);
      },
    );
  }

  Widget _buildHistoryList(String status) {
    final list = _getFilteredBookings(status);
    if (list.isEmpty) return _buildEmptyState(status);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) => _buildHistoryCard(list[index]),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final status = booking['status'] ?? 'Cancelled';
    Color statusColor;

    switch (status) {
      case 'Approved':
        statusColor = const Color(0xff3BCB53);
        break;
      case 'Rejected':
        statusColor = const Color(0xffDB5151);
        break;
      case 'Cancelled':
      default:
        statusColor = const Color(0xff4E534E);
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Stack(
        children: [
          Column(
            children: [
              ListTile(
                title: Text(booking['roomName']),
                subtitle: Text('${booking['date']} | ${booking['time']}'),
              ),
              SizedBox(
                height: 120,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(4),
                  ),
                  child: _buildSafeImage(booking['image']),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _showMoreDetailsSheet(context, booking),
                    child: const Text(
                      'More',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          //Status chips
          Positioned(
            top: 19,
            right: 15,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Text(
        'No ${status.toLowerCase()} bookings yet.',
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
}
