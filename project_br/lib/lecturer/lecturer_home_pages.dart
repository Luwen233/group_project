import 'package:flutter/material.dart';
// ⭐️ Imports ใหม่ สำหรับ State และ Model และ Service
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_service.dart'; // สำหรับเรียก simulateNewBooking
import 'package:project_br/lecturer/dashboard_summary.dart';

class LecturerHomePages extends StatefulWidget {
  const LecturerHomePages({super.key});

  @override
  State<LecturerHomePages> createState() => _LecturerHomePagesState();
}

class _LecturerHomePagesState extends State<LecturerHomePages> {
  // Mock data for rooms (can be kept or fetched from a source later)
  final List<Map<String, dynamic>> _rooms = [
    {
      'name': 'Study Room A',
      'status': 'Free',
      'image': 'assets/images/room1.jpg',
    },
    {
      'name': 'Law Study Room',
      'status': 'Disable',
      'image': 'assets/images/room2.jpg',
    },
    {'name': 'Room B101', 'status': 'Free', 'image': 'assets/images/room3.jpg'},
    {
      'name': 'Room B102',
      'status': 'Disable',
      'image': 'assets/images/room4.jpg',
    },
  ];

  bool _isLogoutVisible = false;

  void _logout() {
    setState(() {
      _isLogoutVisible = false;
    });
    // Ensure login route exists and is correct
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF3C9CBF),
        toolbarHeight: 180,
        centerTitle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),
        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          height: 40,
                          width: 160,
                          decoration: BoxDecoration(
                            color: Color.fromARGB(80, 33, 33, 40),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Oct 29, 2025', // Use current date or format dynamically
                            style: TextStyle(color: Colors.white, fontSize: 20),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isLogoutVisible = !_isLogoutVisible;
                            });
                          },
                          child: Row(
                            children: [
                              Icon(Icons.person, color: Colors.black, size: 40),
                              SizedBox(width: 6),
                              Text(
                                'Mr. John', // Replace with actual user name
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                ),
                              ),
                              Icon(
                                Icons.arrow_drop_down,
                                color: Colors.black,
                                size: 24,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(
                        bottom: 8.0,
                      ), // Add padding below search bar if needed
                      child: Container(
                        height: 40, // Adjusted height
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: const TextField(
                          decoration: InputDecoration(
                            hintText: 'Study Room',
                            hintStyle: TextStyle(
                              color: Colors.grey, // Standard hint color
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey,
                            ), // Add prefix icon
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20, // Adjusted padding
                              vertical:
                                  12, // Adjusted padding for vertical center
                            ),
                            suffixIcon:
                                null, // Remove suffixIcon if prefixIcon is used
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isLogoutVisible)
                  Positioned(
                    top: 40, // Adjust top position if needed
                    right: 10,
                    child: SizedBox(
                      width: 120,
                      height: 35,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.zero,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(26),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                            elevation:
                                0, // Remove default elevation, rely on Container shadow
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.zero,
                            ),
                          ),
                          onPressed: _logout,
                          child: Text('Logout'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // ⭐️ ใช้ ValueListenableBuilder เพื่อฟังการเปลี่ยนแปลง
          ValueListenableBuilder<List<BookingRequest>>(
            valueListenable: pendingRequestsNotifier,
            builder: (context, pendingList, _) {
              return ValueListenableBuilder<List<BookingRequest>>(
                valueListenable: historyRequestsNotifier,
                builder: (context, historyList, _) {
                  // นับจำนวน Reserved จาก History
                  final reservedCount = historyList
                      .where((req) => req.status == 'approved')
                      .length;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 14,
                    ),
                    child: DashboardSummary(
                      freeSlots: _rooms
                          .where((room) => room['status'] == 'Free')
                          .length,
                      // ⭐️ ใช้ค่าจริงจาก Notifier
                      reservedSlots: reservedCount,
                      pendingSlots: pendingList.length,
                      disabledRooms: _rooms
                          .where((room) => room['status'] == 'Disable')
                          .length,
                    ),
                  );
                },
              );
            },
          ),
          // ⭐️ เพิ่มปุ่ม Simulate New Booking (ตัวเลือก B)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ElevatedButton(
              onPressed: simulateNewBooking, // เรียกฟังก์ชันจาก service
              child: Text('Simulate New Booking'),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: _rooms.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 3 / 3.7,
                ),
                itemBuilder: (context, index) {
                  final room = _rooms[index];
                  final isFree = room['status'] == 'Free';

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.asset(
                            room['image'],
                            height: 120,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // แสดง Placeholder ถ้าโหลดรูปไม่ได้
                              return Container(
                                height: 120,
                                color: Colors.grey[300],
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Text(
                            room['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            bottom: 15,
                          ),
                          child: Align(
                            alignment: Alignment.bottomRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: isFree
                                    ? Color(0xff3BCB53)
                                    : Color(0xff4E534E),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                room['status'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
