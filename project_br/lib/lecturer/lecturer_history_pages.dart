import 'package:flutter/material.dart';
import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';

class LecturerHistoryPages extends StatefulWidget {
  const LecturerHistoryPages({super.key});

  @override
  State<LecturerHistoryPages> createState() => _LecturerHistoryPagesState();
}

class _LecturerHistoryPagesState extends State<LecturerHistoryPages>
    with TickerProviderStateMixin {
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

  // --- ฟังก์ชันกรองสถานะ ---
  List<BookingRequest> _getFilteredList(List<BookingRequest> all, String status) {
    if (status == 'All') return all;
    return all.where((b) => b.status.toLowerCase() == status.toLowerCase()).toList();
  }

  // --- ฟังก์ชันแสดง BottomSheet ---
  void _showMoreDetailsSheet(BuildContext context, BookingRequest booking) {
    final String status = booking.status.toLowerCase();
    Color statusColor;
    String statusActionText;

    switch (status) {
      case 'approved':
        statusColor = const Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'rejected':
        statusColor = const Color(0xffDB5151);
        statusActionText = 'Rejected On';
        break;
      default:
        statusColor = const Color(0xff4E534E);
        statusActionText = 'Action Date';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        final String decisionOn = booking.approvedOn ?? booking.rejectedOn ?? 'N/A';
        final String processedBy = booking.processedBy ?? 'System';

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request ID: ${booking.id}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 16),
                Text(
                  booking.roomName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Date: ${booking.date}', style: TextStyle(color: Colors.grey[700])),
                    Text('Time: ${booking.time}', style: TextStyle(color: Colors.grey[700])),
                  ],
                ),
                const SizedBox(height: 20),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    booking.image,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      height: 150,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.broken_image, size: 40)),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem('Booked By', booking.bookedBy),
                          const SizedBox(height: 12),
                          _buildDetailItem('Requested On', booking.requestedOn),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailItem(
                            status == 'approved' ? 'Approved By' : 'Rejected By',
                            booking.approvedBy ?? processedBy,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailItem(statusActionText, decisionOn),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (status == 'rejected' && booking.rejectReason != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lecturer Note',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(booking.rejectReason!,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    ],
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3BCB53),
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
          ),
        );
      },
    );
  }

  // --- Widget หลัก ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 3,
        title: const Text(
          'Booking History',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xff3C9CBF),
                unselectedLabelColor: const Color(0xff4E534E),
                indicatorColor: const Color(0xff3C9CBF),
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
      body: ValueListenableBuilder<List<BookingRequest>>(
        valueListenable: historyRequestsNotifier,
        builder: (context, allBookings, _) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(_getFilteredList(allBookings, 'All')),
              _buildHistoryList(_getFilteredList(allBookings, 'approved')),
              _buildHistoryList(_getFilteredList(allBookings, 'rejected')),
            ],
          );
        },
      ),
    );
  }

  // --- สร้าง List ของประวัติการจอง ---
  Widget _buildHistoryList(List<BookingRequest> list) {
    if (list.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final booking = list[index];
        return _buildHistoryCard(booking);
      },
    );
  }

  // --- Empty State ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 60, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No booking history yet.',
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

  // --- Card ---
  Widget _buildHistoryCard(BookingRequest booking) {
    final bool isRejected = booking.status == 'rejected';
    final Color statusColor = isRejected ? const Color(0xffDB5151) : const Color(0xff3BCB53);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Text(
              booking.roomName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(0),
              topRight: Radius.circular(0),
            ),
            child: Image.asset(
              booking.image,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 120,
                color: Colors.grey[300],
                child: const Center(child: Icon(Icons.broken_image, size: 40)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDetailItem('Booked By', booking.bookedBy),
                _buildDetailItem(
                  isRejected ? 'Rejected On' : 'Approved On',
                  booking.approvedOn ?? booking.rejectedOn ?? 'N/A',
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        booking.status.toUpperCase(),
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
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
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

  // --- Item Detail Text ---
  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
