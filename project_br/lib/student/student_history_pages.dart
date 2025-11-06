import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadUserData();
    await _loadLogs();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedUserID = prefs.getInt('user_id');
    });
  }

  Future<void> _loadLogs() async {
    if (savedUserID == null) return;

    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // 👇 เปลี่ยน IP ให้ตรงกับ server ของคุณ เช่น 192.168.1.10
      final uri = Uri.http('172.27.1.70:3000', '/logs/user/$savedUserID');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        setState(() {
          _bookings = data.map<Map<String, dynamic>>((b) {
            return {
              'id': b['booking_id'].toString(),
              'roomName': b['room_name'] ?? 'Unknown Room',
              'date': b['booking_date'] ?? 'N/A',
              'time': '${b['start_time'] ?? ''} - ${b['end_time'] ?? ''}',
              'status': b['booking_status'] ?? 'Cancelled',
              'reason': b['reason'] ?? '',
              'approver': b['approver'] ?? '-',
              'lecturerNote': b['approver_note'] ?? '',
              'actionDate': b['updated_at'] ?? '',
              'image': 'assets/images/room1.jpg',
              'name': b['user_name'] ?? 'Unknown',
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
    if (status == 'All') {
      return _bookings.where((b) => b['status'] != 'Pending').toList();
    }
    return _bookings.where((b) => b['status'] == status).toList();
  }

  void _showMoreDetailsSheet(BuildContext context, Map<String, dynamic> booking) {
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
                Text('Request ID: ${booking['id']}',
                    style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 10),
                Text(
                  booking['roomName'],
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Date: ${booking['date']}'),
                Text('Time: ${booking['time']}'),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    booking['image'],
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailItem('Booked By', booking['name']),
                _buildDetailItem('Approved By', booking['approver']),
                _buildDetailItem(statusActionText, booking['actionDate']),
                const SizedBox(height: 15),
                if (booking['reason'] != null && booking['reason'] != '')
                  _buildDetailItem('Reason', booking['reason']),
                if (status == 'Rejected' && booking['lecturerNote'] != null)
                  _buildDetailItem('Lecturer Note', booking['lecturerNote']),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3BCB53),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Center(
                    child: Text('OK', style: TextStyle(color: Colors.white)),
                  ),
                )
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
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
          title: const Text('My History',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          ListTile(
            title: Text(booking['roomName']),
            subtitle: Text('${booking['date']} | ${booking['time']}'),
          ),
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(10)),
              image: DecorationImage(
                image: AssetImage(booking['image']),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        status,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showMoreDetailsSheet(context, booking),
                    child: const Text('More',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
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
