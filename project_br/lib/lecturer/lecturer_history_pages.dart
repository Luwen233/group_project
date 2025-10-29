import 'package:flutter/material.dart';
// ⭐️ Imports ที่ถูกต้องสำหรับ Model และ State
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

  // --- ฟังก์ชันสำหรับแสดง Dialog More Details (ปรับขนาด UI ให้เล็กลง) ---
  void _showMoreDetailsDialog(BookingRequest request) {
    final String decisionOn = request.approvedOn ?? request.rejectedOn ?? 'N/A';
    final String processedBy = request.processedBy ?? 'System';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0), // โค้งมน
          ),
          child: SingleChildScrollView(
            child: Container(
              // ⭐️ ลด Padding รอบนอก (โดยเฉพาะด้านล่าง)
              padding: const EdgeInsets.fromLTRB(
                16,
                16,
                16,
                12,
              ), // <--- ปรับ Padding
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- รูปภาพห้อง ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.0), // โค้งมน
                    child: Image.asset(
                      request.image,
                      // ⭐️ ลดความสูงรูปภาพ
                      height: 100, // <--- จาก 120
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 100, // <--- จาก 120
                          color: Colors.grey[300],
                          child: Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey[600],
                              size: 30,
                            ),
                          ),
                        ); // ลดขนาด icon
                      },
                    ),
                  ),
                  // ⭐️ ลดช่องว่างใต้รูป
                  const SizedBox(height: 10), // <--- จาก 12
                  // ------------------------
                  Text(
                    "Booking Details",
                    // ⭐️ ลดขนาด Title
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ), // <--- จาก 18
                  ),
                  // ⭐️ ลดช่องว่างใต้ Title
                  const SizedBox(height: 8), // <--- จาก 12
                  _buildDetailRow("Request ID:", request.id),
                  _buildDetailRow("Room Name:", request.roomName),
                  _buildDetailRow("Date:", request.date),
                  _buildDetailRow("Time:", request.time),
                  _buildDetailRow("Booked By:", request.bookedBy),
                  _buildDetailRow("Requested On:", request.requestedOn),
                  Divider(
                    height: 16,
                    color: Colors.grey[300],
                  ), // ⭐️ ลด height Divider
                  _buildDetailRow(
                    "Status:",
                    request.status.toUpperCase(),
                    valueColor: request.status == 'approved'
                        ? Colors.green
                        : Colors.red,
                  ),
                  // แสดง Approved/Rejected By & On
                  if (request.status == 'approved') ...[
                    _buildDetailRow(
                      "Approved By:",
                      request.approvedBy ?? processedBy,
                    ),
                    _buildDetailRow("Approved On:", decisionOn),
                  ] else if (request.status == 'rejected') ...[
                    _buildDetailRow("Rejected By:", processedBy),
                    _buildDetailRow("Rejected On:", decisionOn),
                    if (request.rejectReason != null &&
                        request.rejectReason!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 4.0,
                        ), // ⭐️ ลด Padding บน Note
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Note:",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              request.rejectReason!,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

                  // ⭐️ ลดช่องว่างก่อนปุ่ม OK
                  const SizedBox(height: 16), // <--- จาก 20
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        // ⭐️ ลด Padding ปุ่ม OK
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ), // <--- ปรับ Padding
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      // ⭐️ ลดขนาด Font ปุ่ม
                      child: Text(
                        "OK",
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ), // <--- จาก 14
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Widget ช่วยสร้างแถว Detail ใน Dialog (ปรับ Font Size และ Padding) ---
  Widget _buildDetailRow(String title, String value, {Color? valueColor}) {
    return Padding(
      // ⭐️ ลด Padding แนวตั้งเล็กน้อย
      padding: const EdgeInsets.symmetric(vertical: 2.0), // <--- จาก 3.0
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ⭐️ ลดขนาด Font Title
          Text(
            "$title ",
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              // ⭐️ ลดขนาด Font Value
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: valueColor,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          "History",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey[400],
          indicatorColor: Colors.blue,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
          tabs: const [
            Tab(text: "All"),
            Tab(text: "Approved"),
            Tab(text: "Rejected"),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey[300]),
          Expanded(
            child: ValueListenableBuilder<List<BookingRequest>>(
              valueListenable: historyRequestsNotifier,
              builder: (context, historyList, _) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildHistoryList(historyList, context),
                    _buildHistoryList(
                      historyList
                          .where((req) => req.status == 'approved')
                          .toList(),
                      context,
                    ),
                    _buildHistoryList(
                      historyList
                          .where((req) => req.status == 'rejected')
                          .toList(),
                      context,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(List<BookingRequest> list, BuildContext context) {
    if (list.isEmpty) {
      return _buildEmptyHistoryState();
    } else {
      return ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final request = list[index];
          return _buildHistoryCard(request, context);
        },
      );
    }
  }

  Widget _buildEmptyHistoryState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
        ), // Add margin for empty state
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12), // Match card radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_toggle_off, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 24),
            Text(
              "No history yet",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Approved or rejected requests\nwill appear here",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget สร้าง Column แสดง Title และ Value ---
  Widget _buildDetailColumn(String title, String value) {
    // ใช้ Expanded เพื่อให้ Column แต่ละอันมีความกว้างเท่าๆ กันใน Row
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1, // Ensure value stays on one line
          ),
        ],
      ),
    );
  }

  // --- Widget สำหรับ History Card (UI ใหม่) ---
  Widget _buildHistoryCard(BookingRequest request, BuildContext context) {
    final bool isRejected = request.status == 'rejected';
    final Color statusColor = isRejected ? Colors.red : Colors.green;
    final String statusText = isRejected ? 'Rejected' : 'Approved';
    // ใช้ approvedOn / rejectedOn จาก Model โดยตรง
    final String decisionOn = request.approvedOn ?? request.rejectedOn ?? 'N/A';
    // ⭐️ ใช้ processedBy สำหรับ Approved By / Rejected By ใน Card
    final String processedBy = request.processedBy ?? 'System';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12), // โค้งมน
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
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
                    const SizedBox(height: 4),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Time: ${request.time}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[800]),
                  ),
                ],
              ),
            ],
          ),
          Divider(height: 24, color: Colors.grey[200]),

          // --- ส่วนกลาง: รูปภาพ, Booked By/ApprovedBy, RequestedOn/ApprovedOn ---
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8), // โค้งมนเล็กน้อย
                child: Image.asset(
                  request.image,
                  width: 80,
                  height: 80,
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
              Expanded(
                // ⭐️ ใช้ Column ครอบ Row ทั้งสองแถว
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- ⭐️ Row 1: Booked By | Approved/Rejected By ---
                    Row(
                      children: [
                        _buildDetailColumn("Booked By:", request.bookedBy),
                        const SizedBox(width: 16), // ⭐️ ช่องว่าง
                        if (request.status == 'approved')
                          _buildDetailColumn(
                            "Approved By:",
                            request.approvedBy ?? processedBy,
                          )
                        else if (request.status == 'rejected')
                          _buildDetailColumn("Rejected By:", processedBy)
                        else // Handle cases where status might not be set or is pending (though unlikely in history)
                          Expanded(
                            child: Container(),
                          ), // Add an empty expanded widget to maintain layout
                      ],
                    ),
                    const SizedBox(height: 6), // ⭐️ ระยะห่างระหว่าง Row
                    // --- ⭐️ Row 2: Requested On | Approved/Rejected On ---
                    Row(
                      children: [
                        _buildDetailColumn(
                          "Requested On:",
                          request.requestedOn,
                        ),
                        const SizedBox(width: 16), // ⭐️ ช่องว่าง
                        if (request.status == 'approved')
                          _buildDetailColumn("Approved On:", decisionOn)
                        else if (request.status == 'rejected')
                          _buildDetailColumn("Rejected On:", decisionOn)
                        else // Handle cases where status might not be set or is pending (though unlikely in history)
                          Expanded(
                            child: Container(),
                          ), // Add an empty expanded widget to maintain layout
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- ส่วนล่าง: ปุ่มสถานะ และ ปุ่ม More ---
          const SizedBox(height: 16),
          // ⭐️ ใช้ Row และ Expanded เพื่อแบ่งพื้นที่ปุ่มเท่าๆ กัน
          Row(
            children: [
              // ⭐️ ปุ่ม Status (ซ้าย)
              Expanded(
                // <--- เปลี่ยนจาก Flexible เป็น Expanded
                child: SizedBox(
                  // ⭐️ ลดความสูงของ SizedBox
                  height: 25,
                  child: ElevatedButton(
                    onPressed: () {}, // ทำให้กดไม่ได้
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                      ), // อาจจะปรับ padding
                      minimumSize: Size(0, 40), // ⭐️ ลด minimumSize height
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // ⭐️ เหมือนปุ่ม Approve/Reject
                      ),
                    ),
                    child: Center(
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14, // ⭐️ ปรับขนาดให้เท่าปุ่ม More
                        ),
                        overflow: TextOverflow.ellipsis, // ป้องกันข้อความล้น
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16), // ⭐️ ช่องว่างเหมือนหน้า Request
              // ⭐️ ปุ่ม More (ขวา)
              Expanded(
                // <--- เปลี่ยนจาก Flexible เป็น Expanded
                child: SizedBox(
                  // ⭐️ ลดความสูงของ SizedBox
                  height: 25,
                  child: ElevatedButton(
                    onPressed: () => _showMoreDetailsDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[600],
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        horizontal: 20,
                      ), // อาจจะปรับ padding
                      minimumSize: Size(0, 40), // ⭐️ ลด minimumSize height
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          10,
                        ), // ⭐️ เหมือนปุ่ม Approve/Reject
                      ),
                    ),
                    child: Text(
                      'More', // ⭐️ เพิ่ม ...
                      style: TextStyle(
                        fontSize: 14, // ⭐️ ปรับขนาดให้เท่าปุ่ม Status
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis, // ป้องกันข้อความล้น
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
