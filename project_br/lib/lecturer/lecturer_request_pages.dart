import 'package:flutter/material.dart';
// ⭐️ Imports ใหม่ สำหรับ Model, State, Service
import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'package:project_br/lecturer/booking_service.dart';

class LecturerRequestPages extends StatefulWidget {
  const LecturerRequestPages({super.key});

  @override
  State<LecturerRequestPages> createState() => _LecturerRequestPagesState();
}

class _LecturerRequestPagesState extends State<LecturerRequestPages> {
  final TextEditingController _rejectReasonController = TextEditingController();

  void _showRejectDialog(BookingRequest requestToReject) {
    _rejectReasonController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          // ⭐️ Card โค้งมน
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reject Of Request :",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _rejectReasonController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Description...',
                    // ⭐️ TextField โค้งมน
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        // ⭐️ ปุ่มโค้งมน
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        // ⭐️ ปุ่มโค้งมน
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        rejectRequest(
                          requestToReject,
                          _rejectReasonController.text,
                        );
                        Navigator.of(context).pop();
                      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "Coming Request",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0, // ⭐️ ไม่มีเงาที่ AppBar
      ),
      body: Column(
        children: [
          // ⭐️ เส้นแบ่งใต้ AppBar (ถ้ายังไม่มี)
          Container(
            height: 1,
            color: Colors.grey[300], // สีเทาอ่อน
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Upcoming",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3C9CBF),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ValueListenableBuilder<List<BookingRequest>>(
                      valueListenable: pendingRequestsNotifier,
                      builder: (context, pendingList, _) {
                        if (pendingList.isEmpty) {
                          return _buildEmptyState();
                        } else {
                          return _buildRequestList(pendingList);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          // ⭐️ Card ไม่มีมุมโค้ง
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 * 255 = 13
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 50,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No upcoming requests yet.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Browse Rooms On The Home Page To Reserve One.", // ⭐️ เปลี่ยนข้อความ
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestList(List<BookingRequest> requests) {
    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _buildRequestCard(request);
      },
    );
  }

  Widget _buildRequestCard(BookingRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        // ⭐️ Card ไม่มีมุมโค้ง
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13), // 0.05 * 255 = 13
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- ส่วนบน: Request ID, Room Name, Date, Time ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Request ID : ${request.id}",
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4), // ⭐️ ปรับระยะห่าง
                    Text(
                      request.roomName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Date: ${request.date}",
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                  const SizedBox(height: 4), // ⭐️ ปรับระยะห่าง
                  Text(
                    "Time: ${request.time}",
                    style: TextStyle(fontSize: 12, color: Colors.black),
                  ),
                ],
              ),
            ],
          ),
          Divider(height: 4, color: Colors.grey[300]), // ⭐️ เส้นแบ่งที่ 1
          // --- ส่วนกลาง: รูปภาพ, Booked By, Requested On ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // รูปภาพ
              ClipRRect(
                // ⭐️ รูปภาพไม่มีมุมโค้ง
                borderRadius: BorderRadius.circular(0),
                child: Image.asset(
                  request.image,
                  width: 160,
                  height: 110,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
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
              const SizedBox(width: 16),
              // ข้อมูล Booked By, Requested On
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ⭐️ แสดง Booked By แยกบรรทัด ---
                    Text(
                      "Booked By:",
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    Text(
                      request.bookedBy,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4), // ระยะห่างระหว่างรายการ
                    // --- ⭐️ แสดง Requested On แยกบรรทัด ---
                    Text(
                      "Requested On:",
                      style: TextStyle(color: Colors.black, fontSize: 13),
                    ),
                    Text(
                      request.requestedOn,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 10, color: Colors.grey[300]), // ⭐️ เส้นแบ่งที่ 2
          // --- ส่วนล่าง: ปุ่ม Approve / Reject ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    // ⭐️ ปุ่มไม่มีมุมโค้ง
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // ⭐️ ปรับ Padding แนวตั้งเพื่อลดความสูง
                    padding: EdgeInsets.symmetric(vertical: 1),
                  ),
                  onPressed: () => _showRejectDialog(request),
                  child: Text("Reject", style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    // ⭐️ ปุ่มไม่มีมุมโค้ง
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    // ⭐️ ปรับ Padding แนวตั้งเพื่อลดความสูง
                    padding: EdgeInsets.symmetric(vertical: 1),
                  ),
                  onPressed: () => approveRequest(request),
                  child: Text("Approve", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }
}
