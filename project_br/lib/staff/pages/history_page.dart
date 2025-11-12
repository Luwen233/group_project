import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ⭐️ 1. แก้ไข Import ให้เรียก staff_service.dart
import 'package:project_br/staff/pages/staff_service.dart';

class StaffHistoryPage extends StatefulWidget {
  const StaffHistoryPage({super.key});

  @override
  State<StaffHistoryPage> createState() => _StaffHistoryPageState();
}

class _StaffHistoryPageState extends State<StaffHistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  // ⭐️ 2. เพิ่ม State จัดการข้อมูล (เหมือน home_page.dart)
  List<Map<String, dynamic>> _allHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadHistory(); // ⭐️ 3. เรียกฟังก์ชันโหลดข้อมูล
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ⭐️ 4. ฟังก์ชันดึงข้อมูลจาก staff_service
  Future<void> _loadHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final history = await fetchGlobalHistory(); // ⭐️ 5. เรียกใช้ฟังก์ชันใหม่
      if (mounted) {
        setState(() {
          _allHistory = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // ⭐️ 6. แก้ไขฟังก์ชันกรองข้อมูล (เดี๋ยวนี้ใช้ Map)
  List<Map<String, dynamic>> _getFilteredBookings(
    List<Map<String, dynamic>> allBookings,
    String status,
  ) {
    // ฟังก์ชันกรองเดิมถูกต้องแล้ว (กรองเฉพาะ approved/rejected)
    final processedBookings = allBookings
        .where(
          (b) =>
              (b['action']?.toString().toLowerCase() == 'approved' ||
              b['action']?.toString().toLowerCase() == 'rejected'),
        )
        .toList();
    if (status == 'All') return processedBookings;
    return processedBookings
        .where(
          (b) => b['action']?.toString().toLowerCase() == status.toLowerCase(),
        )
        .toList();
  }

  // ⭐️ 7. แก้ไขฟังก์ชัน ShowMoreDetails (เดี๋ยวนี้ใช้ Map)
  void _showMoreDetailsSheet(
    BuildContext context,
    Map<String, dynamic> booking,
  ) {
    final String status = (booking['action'] ?? '').toString().toLowerCase();
    String statusActionText;
    String actionDate = '';

    // ลองจัดรูปแบบวันที่
    try {
      actionDate = DateFormat(
        'd MMM yyyy',
      ).format(DateTime.parse(booking['timestamp']));
    } catch (_) {
      actionDate = (booking['timestamp'] ?? '').toString().split('T')[0];
    }

    // จัดรูปแบบวันที่จอง
    String formattedBookingDate = '';
    try {
      formattedBookingDate = DateFormat(
        'd MMM yyyy',
      ).format(DateTime.parse(booking['booking_date']));
    } catch (_) {
      formattedBookingDate = (booking['booking_date'] ?? '').toString().split(
        'T',
      )[0];
    }

    switch (status) {
      case 'approved':
        statusActionText = 'Approved On';
        break;
      case 'rejected':
        statusActionText = 'Rejected On';
        break;
      default:
        statusActionText = 'Cancelled On';
    }

    // ⭐️ [แก้ไข] สร้าง Path เต็มสำหรับรูปภาพใน Bottom Sheet
    final String rawImage =
        booking['room_image']?.toString() ?? 'placeholder.png';
    final String fullImagePath = rawImage.startsWith('assets/')
        ? rawImage
        : 'assets/images/${rawImage.isEmpty ? 'placeholder.png' : rawImage}';

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Request ID    ${(booking['booking_id'] ?? 0).toString().padLeft(5, '0')}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          (booking['room_name'] ?? 'Unknown Room'),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            formattedBookingDate, // ใช้วันที่จอง
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Time',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 6),
                          Text(
                            "${booking['start_time']} - ${booking['end_time']}", // ใช้เวลา
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  // ⭐️⭐️⭐️ [แก้ไขจุดที่ 1] ⭐️⭐️⭐️
                  // เปลี่ยนจาก (booking['room_image'] ?? ...) เป็น fullImagePath
                  fullImagePath,
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
                      _buildDetailItem(
                        'Booked By',
                        booking['booked_by'] ?? 'N/A',
                      ),
                      SizedBox(height: 12),
                      _buildDetailItem(
                        'Requested On', // Backend ไม่มี requested on, ใช้วันที่จองแทน
                        formattedBookingDate,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailItem(
                        'Approved By',
                        booking['approved_by'] ?? 'N/A',
                      ),
                      SizedBox(height: 12),
                      _buildDetailItem(statusActionText, actionDate),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (status == 'rejected')
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lecturer Note', // ⭐️ Staff เห็นเป็น "Lecturer Note" ถูกต้องแล้ว
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      (booking['reject_reason'] ?? 'No note provided.'),
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

  // ⭐️ 8. แก้ไขฟังก์ชัน BuildList (เดี๋ยวนี้ใช้ Map)
  Widget _buildHistoryList(
    List<Map<String, dynamic>> filteredList,
    String status,
  ) {
    if (filteredList.isEmpty) {
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
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final booking = filteredList[index];
        return _buildHistoryCard(booking);
      },
    );
  }

  // ⭐️ 9. แก้ไขฟังก์ชัน BuildCard (เดี๋ยวนี้ใช้ Map)
  Widget _buildHistoryCard(Map<String, dynamic> booking) {
    final String status = (booking['action'] ?? '').toString().toLowerCase();
    Color statusColor;
    String statusActionText;
    String actionDate = '';

    // จัดรูปแบบวันที่จอง
    String formattedBookingDate = '';
    try {
      formattedBookingDate =
          DateFormat('d MMM yyyy') // ⭐️ แก้ไข typo yyyY เป็น yyyy
              .format(DateTime.parse(booking['booking_date']));
    } catch (_) {
      formattedBookingDate = (booking['booking_date'] ?? '').toString().split(
        'T',
      )[0];
    }

    // จัดรูปแบบวันที่ Action
    try {
      actionDate = DateFormat(
        'EEE d MMM yyyy',
      ).format(DateTime.parse(booking['timestamp']));
    } catch (_) {
      actionDate = (booking['timestamp'] ?? '').toString().split('T')[0];
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

    // ⭐️ [แก้ไข] สร้าง Path เต็มสำหรับรูปภาพใน Card
    final String rawImage =
        booking['room_image']?.toString() ?? 'placeholder.png';
    final String fullImagePath = rawImage.startsWith('assets/')
        ? rawImage
        : 'assets/images/${rawImage.isEmpty ? 'placeholder.png' : rawImage}';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Request ID    ${(booking['booking_id'] ?? 0).toString().padLeft(5, '0')}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      SizedBox(height: 2),
                      Text(
                        (booking['room_name'] ?? 'Unknown Room'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          formattedBookingDate,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'Time',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          "${booking['start_time']} - ${booking['end_time']}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            child: Image.asset(
              // ⭐️⭐️⭐️ [แก้ไขจุดที่ 2] ⭐️⭐️⭐️
              // เปลี่ยนจาก (booking['room_image'] ?? ...) เป็น fullImagePath
              fullImagePath,
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
                    _buildDetailItem(
                      'Booked By',
                      booking['booked_by'] ?? 'N/A',
                    ),
                    SizedBox(height: 12),
                    _buildDetailItem(
                      'Requested On', // Backend ไม่มี requested on, ใช้วันที่จองแทน
                      formattedBookingDate,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      'Approved By',
                      booking['approved_by'] ?? 'N/A',
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
                      side: BorderSide(color: Colors.grey[400]!),
                      padding: EdgeInsets.symmetric(vertical: 10),
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

  // ⭐️ 10. แก้ไข Build หลัก (เดี๋ยวนี้ใช้ _isLoading)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: Text(
          'Booking History', // ⭐️ 11. เปลี่ยนชื่อ Title
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(67),
          child: Column(
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text("Error: $_error"))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildHistoryList(
                  _getFilteredBookings(_allHistory, 'All'),
                  'All',
                ),
                _buildHistoryList(
                  _getFilteredBookings(_allHistory, 'approved'),
                  'Approved',
                ),
                _buildHistoryList(
                  _getFilteredBookings(_allHistory, 'rejected'),
                  'Rejected',
                ),
              ],
            ),
    );
  }
}
