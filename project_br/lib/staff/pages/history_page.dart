import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // Import for date formatting
import 'package:project_br/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

// ✅ 1. Added TickerProviderStateMixin
class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  // --- STATE VARIABLES ---
  late TabController _tabController; // ✅ 2. Added TabController
  List<Map<String, dynamic>> _allBookings = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBookings(); // Renamed from _loadHistory

    // ✅ 3. Initialized TabController
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging == false) {
        setState(() {}); // Refresh page on tab change
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose(); // ✅ 4. Dispose TabController
    super.dispose();
  }

  // --- ✅ 5. Merged data loading AND mapping logic ---
  Future<void> _loadBookings() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final userId = prefs.getInt('user_id') ?? 0;

      final url = Uri.parse('${ApiConfig.baseUrl}/bookings/user/$userId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);

        setState(() {
          _allBookings = data
              .map<Map<String, dynamic>?>((b) {
                // Map the data from server keys (e.g., room_name)
                // to UI-friendly keys (e.g., roomName)
                final status = (b['status'] ?? 'unknown')
                    .toString()
                    .toLowerCase();

                // Filter out "cancelled" from the start
                if (status == 'cancelled') {
                  return null;
                }

                return {
                  'id': b['id'].toString(),
                  'roomName': b['room_name'] ?? 'Unknown Room',
                  'date': (b['booking_date'] ?? '').toString().split('T')[0],
                  'time': _mapSlotIdToTime(b['slot_id']), // Use new time mapper
                  'status': status[0].toUpperCase() + status.substring(1),
                  'reason': b['reason'] ?? 'No reason provided.',
                  'approver': b['approver_name'] ?? 'N/A',
                  'lecturerNote': b['reject_reason'] ?? 'No note.',
                  'actionDate': _formatActionDate(b['action_date']),
                  'image': b['image'] ?? 'placeholder.png',
                  'name': b['booked_by_name'] ?? 'Unknown',
                };
              })
              .whereType<
                Map<String, dynamic>
              >() // Removes all null (cancelled) items
              .toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  // --- ✅ 6. Copied helper functions from LecturerUI ---
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

  String _formatActionDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, y @ h:mm a').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  // Filters out "Pending" for the history view
  List<Map<String, dynamic>> _getFilteredBookings(String status) {
    final historyBookings = _allBookings
        .where((b) => b['status'] != 'Pending')
        .toList();

    if (status == 'All') return historyBookings;
    return historyBookings.where((b) => b['status'] == status).toList();
  }

  // --- ✅ 7. Replaced the entire build method with the LecturerUI one ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: const Text(
          'All History', // Title changed
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
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Error: $_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _loadBookings,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
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
    final status =
        booking['status'] ?? 'Rejected'; // 'Cancelled' is already filtered
    final statusColor = switch (status) {
      'Approved' => const Color(0xff3BCB53),
      'Rejected' => const Color(0xffDB5151),
      _ => const Color(0xff4E534E), // Fallback
    };

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias, // Helps ClipRRect work
      child: Column(
        children: [
          ListTile(
            title: Text(booking['roomName']),
            subtitle: Text('${booking['date']} | ${booking['time']}'),
          ),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _buildSafeImage(booking['image']),
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
                    style: OutlinedButton.styleFrom(
                      // Match style
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'More Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black54, // Match style
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
    final String status = booking['status'] ?? 'Rejected';
    String statusActionText = switch (status) {
      'Approved' => 'Approved On',
      'Rejected' => 'Rejected On',
      _ => 'Action On',
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
                if (booking['reason'] != 'No reason provided.')
                  _buildDetailItem('Requested Reason', booking['reason']),
                if (status == 'Rejected' &&
                    booking['lecturerNote'] != 'No note.')
                  _buildDetailItem('Lecturer Note', booking['lecturerNote']),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'OK',
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
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
    // This is the detail item from LecturerUI
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    return Center(
      child: Column(
        // Added icon for consistency
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No ${status.toLowerCase()} history yet.',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
