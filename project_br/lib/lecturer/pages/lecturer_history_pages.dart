import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:project_br/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LecturerHistoryPages extends StatefulWidget {
  const LecturerHistoryPages({super.key});

  @override
  State<LecturerHistoryPages> createState() => _LecturerHistoryPagesState();
}

class _LecturerHistoryPagesState extends State<LecturerHistoryPages>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        setState(() {}); // 🔁 refresh หน้าทุกครั้งที่เปลี่ยนแท็บ
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');
      if (userId == null)
        throw Exception("User ID not found. Please log in again.");

      final token = prefs.getString('token');
      final uri = Uri.parse('${ApiConfig.baseUrl}/bookings/user');
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
            final status = (b['status'] ?? 'unknown').toString().toLowerCase();
            return {
              'id': b['id'].toString(),
              'roomName': b['room_name'] ?? 'Unknown Room',
              'date': (b['booking_date'] ?? '').toString().split('T')[0],
              'time': _mapSlotIdToTime(b['slot_id']),
              'status': status[0].toUpperCase() + status.substring(1),
              'reason': b['reason'] ?? '',
              'approver': b['approver_name'] ?? '-',
              'lecturerNote': b['reject_reason'] ?? '',
              'actionDate': b['action_date'] ?? '',
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

  List<Map<String, dynamic>> _getFilteredBookings(String status) {
    final historyBookings = _bookings
        .where((b) => b['status'] != 'Pending')
        .toList();

    if (status == 'All') return historyBookings;
    return historyBookings.where((b) => b['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: const Text(
          'My History',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(67),
          child: Column(
            children: [
              const Divider(thickness: 1, height: 0),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xff3C9CBF),
                unselectedLabelColor: const Color(0xff4E534E),
                indicatorColor: const Color(0xff3C9CBF),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Rejected'),
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
              controller: _tabController,
              children: [
                _buildHistoryList('All'),
                _buildHistoryList('Approved'),
                _buildHistoryList('Rejected'),
              ],
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
    final statusColor = switch (status) {
      'Approved' => const Color(0xff3BCB53),
      'Rejected' => const Color(0xffDB5151),
      _ => const Color(0xff4E534E),
    };

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
          SizedBox(
            height: 120,
            width: double.infinity,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
              child: _buildSafeImage(booking['image']),
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
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showMoreDetailsSheet(context, booking),
                    child: const Text(
                      'More',
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  void _showMoreDetailsSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final String status = booking['status'] ?? 'Cancelled';
    String statusActionText = switch (status) {
      'Approved' => 'Approved On',
      'Rejected' => 'Rejected On',
      _ => 'Cancelled On',
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ID: ${booking['id']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 10),
                Text(
                  booking['roomName'],
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Date: ${booking['date']}'),
                Text('Time: ${booking['time']}'),
                const SizedBox(height: 15),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    height: 160,
                    width: double.infinity,
                    child: _buildSafeImage(booking['image']),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailItem('Booked By', booking['name']),
                _buildDetailItem('Approved By', booking['approver']),
                _buildDetailItem(statusActionText, booking['actionDate']),
                const SizedBox(height: 15),
                if (booking['reason'] != '')
                  _buildDetailItem('Reason', booking['reason']),
                if (status == 'Rejected' && booking['lecturerNote'] != '')
                  _buildDetailItem('Lecturer Note', booking['lecturerNote']),
                const SizedBox(height: 15),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff3BCB53),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Center(
                    child: Text('OK', style: TextStyle(color: Colors.white)),
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
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black,
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
