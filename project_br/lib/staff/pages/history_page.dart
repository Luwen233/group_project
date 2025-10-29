import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Mock data
  final List<Map<String, dynamic>> histories = [
    {
      'id': '00001',
      'roomName': 'Study Room',
      'status': 'Approved',
      'name': 'Mr. John',
      'approver': 'Mr. John',
      'date': 'Sep 22, 2025',
      'actionDate': 'Sep 22, 2025',
      'time': '03:00 - 05:00 PM',
      'image': 'assets/images/room1.jpg',
      'reason': 'Mai mi arai krub baebi.',
      'lecturerNote': '',
    },
    {
      'id': '00002',
      'roomName': 'Law Study Room',
      'status': 'Rejected',
      'name': 'Mr. John',
      'approver': 'Mr. Fred',
      'date': 'Sep 22, 2025',
      'actionDate': 'Sep 22, 2025',
      'time': '10:00 - 12:00 AM',
      'image': 'assets/images/room2.jpg',
      'reason': 'Room is reserved for a faculty meeting.',
      'lecturerNote': 'Please reschedule to next week.',
    },
    {
      'id': '00012',
      'roomName': 'Meeting Room',
      'status': 'Approved',
      'name': 'Ms. Amy',
      'approver': 'Mr. John',
      'date': 'Sep 10, 2025',
      'actionDate': 'Sep 10, 2025',
      'time': '01:00 - 03:00 PM',
      'image': 'assets/images/room3.jpg',
      'reason': 'N/A',
      'lecturerNote': '',
    },
  ];

  // Filter list by status
  List<Map<String, dynamic>> _getFilteredBookings(String status) {
    if (status == 'All') return histories;
    return histories.where((b) => b['status'] == status).toList();
  }

  // Show bottom sheet
  void _showMoreDetailsSheet(BuildContext context, Map<String, dynamic> booking) {
    final String status = booking['status'] ?? 'Rejected';
    Color statusColor;
    String statusActionText;

    switch (status) {
      case 'Approved':
        statusColor = const Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'Rejected':
      default:
        statusColor = const Color(0xffDB5151);
        statusActionText = 'Rejected On';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Request ID: ${booking['id']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14)),
              const SizedBox(height: 16),
              Text(
                booking['roomName'] ?? 'Unknown Room',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Date: ${booking['date']}'),
                  Text('Time: ${booking['time']}'),
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
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Booked By', booking['name']),
                      const SizedBox(height: 12),
                      _buildDetailItem('Requested On', booking['date']),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem('Approved By', booking['approver']),
                      const SizedBox(height: 12),
                      _buildDetailItem(statusActionText, booking['actionDate']),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailItem('Reason Requested', booking['reason']),
              if (status == 'Rejected') ...[
                const SizedBox(height: 16),
                _buildDetailItem('Lecturer Note', booking['lecturerNote']),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: statusColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'OK',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black)),
      ],
    );
  }

  // Build List for each tab
  Widget _buildHistoryList(String status) {
    final list = _getFilteredBookings(status);
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No ${status.toLowerCase()} history yet.',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black54)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => _buildHistoryCard(list[i]),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final String status = booking['status'];
    Color statusColor;
    String statusActionText;

    switch (status) {
      case 'Approved':
        statusColor = const Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'Rejected':
      default:
        statusColor = const Color(0xffDB5151);
        statusActionText = 'Rejected On';
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Request ID: ${booking['id']}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(booking['date'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
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
              children: [
                _buildDetailItem('Booked By', booking['name']),
                _buildDetailItem('Approved By', booking['approver']),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                        child: Text(status,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showMoreDetailsSheet(context, booking),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text(
                      'More',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.black54),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('All History',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          bottom: TabBar(
            labelColor: const Color(0xff3C9CBF),
            unselectedLabelColor: const Color(0xff4E534E),
            indicatorColor: const Color(0xff3C9CBF),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Approved'),
              Tab(text: 'Rejected'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildHistoryList('All'),
            _buildHistoryList('Approved'),
            _buildHistoryList('Rejected'),
          ],
        ),
      ),
    );
  }
}
