import 'package:flutter/material.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All History',
            style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.blue,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          HistoryList(type: 'all'),
          HistoryList(type: 'approved'),
          HistoryList(type: 'rejected'),
        ],
      ),
    );
  }
}

class HistoryList extends StatelessWidget {
  final String type;
  const HistoryList({super.key, required this.type});

  // Helper widget for building detail rows in the dialog
  Widget _buildDetailRow(String label, String value,
      {FontWeight weight = FontWeight.bold}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 2),
        Text(value,
            style: TextStyle(
                fontWeight: weight,
                fontSize: 14,
                color: Colors.black87)),
      ],
    );
  }

  // Show the detail dialog
  void _showDetailDialog(BuildContext context, Map<String, String> item) {
    bool isApproved = item['status'] == 'Approved';
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      item['image']!,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Request ID, Date, Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Request ID: ${item['id']!}",
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                      Text(item['date']!,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item['title']!,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(item['time']!,
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  const Divider(height: 24),

                  // Booked By / Approved By
                  Row(
                    children: [
                      Expanded(
                          child: _buildDetailRow(
                              "Booked By", item['booked_by']!)),
                      Expanded(
                        child: _buildDetailRow(
                          isApproved ? "Approved By" : "Rejected By",
                          item[isApproved ? 'approved_by' : 'rejected_by']!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Requested On / Approved On
                  Row(
                    children: [
                      Expanded(
                          child: _buildDetailRow(
                              "Requested On", item['requested_on']!)),
                      Expanded(
                        child: _buildDetailRow(
                          isApproved ? "Approved On" : "Rejected On",
                          item[isApproved ? 'approved_on' : 'rejected_on']!,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Note
                  _buildDetailRow("Note", item['note']!, weight: FontWeight.normal),
                  const SizedBox(height: 24),

                  // OK Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text("OK", style: TextStyle(color: Colors.white)),
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // UPDATED: Expanded mock data
    final histories = [
      {
        'id': '00001',
        'title': 'Study Room',
        'status': 'Approved',
        'booked_by': 'Mr. John',
        'approved_by': 'Mr. John',
        'rejected_by': '',
        'requested_on': 'Sep 22, 2025',
        'approved_on': 'Sep 22, 2025',
        'rejected_on': '',
        'date': 'Sun 22 Sep 2025',
        'time': '03:00 - 05:00 PM',
        'image': 'assets/images/room1.jpg',
        'note': 'Mai mi arai krub baebi.'
      },
      {
        'id': '00002',
        'title': 'Law Study Room',
        'status': 'Rejected',
        'booked_by': 'Mr. John',
        'approved_by': '',
        'rejected_by': 'Mr. Fred',
        'requested_on': 'Sep 22, 2025',
        'approved_on': '',
        'rejected_on': 'Sep 22, 2025',
        'date': 'Sun 22 Sep 2025',
        'time': '10:00 - 12:00 AM',
        'image': 'assets/images/room2.jpg',
        'note': 'Room is reserved for a faculty meeting.'
      },
      {
        'id': '00012',
        'title': 'Meeting Room',
        'status': 'Approved',
        'booked_by': 'Ms. Amy',
        'approved_by': 'Mr. John',
        'rejected_by': '',
        'requested_on': 'Sep 10, 2025',
        'approved_on': 'Sep 10, 2025',
        'rejected_on': '',
        'date': 'Wed 10 Sep 2025',
        'time': '01:00 - 03:00 PM',
        'image': 'assets/images/room3.jpg',
        'note': 'N/A'
      },
    ];

    // Filter by tab type
    final filtered = type == 'all'
        ? histories
        : histories.where((h) => h['status']!.toLowerCase() == type).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final status = item['status']!;
        final isApproved = status == 'Approved';
        final color = isApproved ? Colors.green : Colors.red;

        // NEW: Replaced ListTile with a custom Card
        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Request ID and Date/Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Request ID: ${item['id']!}",
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(item['date']!,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                        Text(item['time']!,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 16),
                
                // Middle Row: Image and Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        item['image']!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.broken_image, size: 80),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['title']!,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 8),
                          // Detail Columns
                          Row(
                            children: [
                              Expanded(
                                  child: _buildDetailRow(
                                      "Booked By", item['booked_by']!)),
                              Expanded(
                                child: _buildDetailRow(
                                  isApproved ? "Approved By" : "Rejected By",
                                  item[isApproved
                                      ? 'approved_by'
                                      : 'rejected_by']!,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                  child: _buildDetailRow("Requested On",
                                      item['requested_on']!)),
                              Expanded(
                                child: _buildDetailRow(
                                  isApproved ? "Approved On" : "Rejected On",
                                  item[isApproved
                                      ? 'approved_on'
                                      : 'rejected_on']!,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Bottom Row: Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Placeholder for approve/reject action
                        },
                        child: Text(status, style: const TextStyle(color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Show the detail dialog
                          _showDetailDialog(context, item);
                        },
                        child: const Text("More", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}