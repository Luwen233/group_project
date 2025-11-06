import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'package:project_br/lecturer/booking_service.dart';

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
    // ⭐️ [แก้ไข] เปลี่ยน length เป็น 3 (All, Approved, Rejected)
    _tabController = TabController(length: 3, vsync: this);
    fetchHistoryRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ⭐️ [แก้ไข] ฟังก์ชันกรองข้อมูล
  // (จะกรองให้เหลือเฉพาะ 'approved' และ 'rejected' เท่านั้น)
  List<BookingRequest> _getFilteredBookings(
    List<BookingRequest> allBookings,
    String status,
  ) {
    // 1. กรองรายการทั้งหมด ให้เหลือแค่ 'approved' และ 'rejected'
    final processedBookings = allBookings
        .where(
          (b) =>
              b.status.toLowerCase() == 'approved' ||
              b.status.toLowerCase() == 'rejected',
        )
        .toList();

    // 2. ถ้าเป็น Tab 'All' ให้แสดงทั้งหมดที่กรองแล้ว
    if (status == 'All') {
      return processedBookings;
    }

    // 3. ถ้าเป็น Tab อื่น (Approved, Rejected) ให้กรองตามสถานะนั้นๆ
    return processedBookings
        .where((b) => b.status.toLowerCase() == status.toLowerCase())
        .toList();
  }

  // ⭐️ [คัดลอก]
  // Function to show the btm sheet (จาก StudentHistoryPages)
  void _showMoreDetailsSheet(BuildContext context, BookingRequest booking) {
    final String status = booking.status.toLowerCase();
    Color statusColor;
    String statusActionText;
    String actionDate = '';

    if (booking.decisionTimestamp != null) {
      actionDate = DateFormat(
        'EEE d MMM yyyy',
      ).format(booking.decisionTimestamp!);
    }

    switch (status) {
      case 'approved':
        statusColor = Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'rejected':
        statusColor = Color(0xffDB5151);
        statusActionText = 'Rejected On';
        break;
      case 'cancelled': // (เผื่อไว้ แต่จะไม่ถูกเรียกใช้)
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
                    'Request ID: ${booking.id}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                booking.roomName,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date: ${booking.formattedDate}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  Text(
                    'Time: ${booking.time}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
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
                  errorBuilder: (c, e, s) => Container(
                    height: 150,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image, color: Colors.grey[400]),
                  ),
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
                      _buildDetailItem('Booked By', booking.bookedBy),
                      SizedBox(height: 12),
                      _buildDetailItem(
                        'Requested On',
                        booking.formattedRequestedOn,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        'Approved By',
                        booking.approvedBy ?? 'N/A',
                      ),
                      SizedBox(height: 12),
                      _buildDetailItem(statusActionText, actionDate),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              //lecuterer note only reject
              if (status == 'rejected')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lecturer Note',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      booking.rejectReason ?? 'No note provided.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
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

  // ⭐️ [คัดลอก]
  // Main Build Function (จาก StudentHistoryPages)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: Text(
          'My History',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // ⭐️⭐️⭐️ [แก้ไข] เพิ่ม centerTitle: true ⭐️⭐️⭐️
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(67),
          child: Column(
            // ⭐️ [แก้ไข] เปลี่ยนเป็น center (แม้ว่าการลบ isScrollable จะสำคัญกว่า)
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Divider(thickness: 1, height: 0),
              Padding(
                padding: EdgeInsets.zero,
                child: TabBar(
                  controller: _tabController,
                  labelColor: Color(0xff3C9CBF),
                  unselectedLabelColor: Color(0xff4E534E),
                  indicatorColor: Color(0xff3C9CBF),
                  // ⭐️⭐️⭐️ [แก้ไข] ลบ isScrollable: true ⭐️⭐️⭐️
                  // isScrollable: true,
                  tabs: [
                    Tab(text: 'All'),
                    Tab(text: 'Approved'),
                    Tab(text: 'Rejected'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: ValueListenableBuilder<List<BookingRequest>>(
        valueListenable: historyRequestsNotifier,
        builder: (context, allHistory, _) {
          // ⭐️ [แก้ไข] กรอง List ตามตรรกะใหม่
          final allList = _getFilteredBookings(allHistory, 'All');
          final approvedList = _getFilteredBookings(allHistory, 'approved');
          final rejectedList = _getFilteredBookings(allHistory, 'rejected');

          return TabBarView(
            controller: _tabController,
            children: [
              _buildHistoryList(allList, 'All'),
              _buildHistoryList(approvedList, 'Approved'),
              _buildHistoryList(rejectedList, 'Rejected'),
            ],
          );
        },
      ),
    );
  }

  // ⭐️ [คัดลอก]
  // Widget _buildHistoryList (จาก StudentHistoryPages)
  Widget _buildHistoryList(List<BookingRequest> filteredList, String status) {
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

  // ⭐️ [คัดลอก]
  // Widget _buildEmptyState (จาก StudentHistoryPages)
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

  // ⭐️ [คัดลอก]
  // Widget _buildHistoryCard (จาก StudentHistoryPages)
  Widget _buildHistoryCard(BookingRequest booking) {
    final String status = booking.status.toLowerCase();
    Color statusColor;
    String statusActionText;
    String actionDate = '';

    if (booking.decisionTimestamp != null) {
      actionDate = DateFormat(
        'EEE d MMM yyyy',
      ).format(booking.decisionTimestamp!);
    }

    switch (status) {
      case 'approved':
        statusColor = Color(0xff3BCB53);
        statusActionText = 'Approved On';
        break;
      case 'rejected':
        statusColor = Color(0xffDB5151);
        statusActionText = 'Rejected On';
        break;
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
              booking.roomName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ClipRRect(
            child: Image.asset(
              booking.image,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (c, e, s) => Container(
                height: 120,
                color: Colors.grey[200],
                child: Icon(Icons.broken_image, color: Colors.grey[400]),
              ),
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
                    _buildDetailItem('Booked By', booking.bookedBy),
                    SizedBox(height: 12),
                    _buildDetailItem(
                      'Requested On',
                      booking.formattedRequestedOn,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      'Approved By',
                      booking.approvedBy ?? 'N/A',
                    ),
                    SizedBox(height: 12),
                    _buildDetailItem(statusActionText, actionDate),
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
                        status.substring(0, 1).toUpperCase() +
                            status.substring(1),
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

  // ⭐️ [คัดลอก]
  // Widget _buildDetailItem (จาก StudentHistoryPages)
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
