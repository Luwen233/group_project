import 'package:intl/intl.dart';

class BookingRequest {
  final String id;
  final String roomName;
  final String image;
  final String date;
  final String time;
  final String bookedBy;
  final String requestedOn;

  String status;
  String? rejectReason;
  String? approvedBy;
  String? approvedOn; // ⬅️ เราจะปล่อยให้เป็น null
  String? rejectedOn; // ⬅️ เราจะปล่อยให้เป็น null
  String? processedBy;
  final DateTime? decisionTimestamp; // ⬅️ เราจะใช้ตัวนี้แทน

  BookingRequest({
    required this.id,
    required this.roomName,
    required this.image,
    required this.date,
    required this.time,
    required this.bookedBy,
    required this.requestedOn,
    this.status = 'pending',
    this.rejectReason,
    this.approvedBy,
    this.approvedOn,
    this.rejectedOn,
    this.processedBy,
    this.decisionTimestamp,
  });

  // ⭐️ [โค้ดที่แก้ไข] ⭐️
  // ฟังก์ชันนี้ถูกแก้ไขให้อ่านข้อมูลได้
  // ทั้งจากหน้า 'Pending' (key: 'booking_status', 'user_name')
  // และจากหน้า 'History' (key: 'action', 'booked_by', 'timestamp')
  factory BookingRequest.fromJson(Map<String, dynamic> json) {
    String formattedTime = '';

    // 1. จัดการ Time
    if (json['start_time'] != null && json['end_time'] != null) {
      // (มาจาก Pending list)
      formattedTime =
          "${json['start_time'].toString().substring(0, 5)} - ${json['end_time'].toString().substring(0, 5)}";
    } else {
      // (มาจาก History list)
      formattedTime = json['slot_name'] ?? '-';
    }

    // 2. จัดการ Status
    // (Pending ใช้ 'booking_status', History ใช้ 'action')
    String status =
        json['booking_status']?.toString().toLowerCase() ??
        json['action']?.toString().toLowerCase() ??
        'pending';

    // 3. จัดการ Date
    // (Pending ใช้ 'booking_date', History ก็ควรใช้ 'booking_date' ที่ JOIN มา)
    // ถ้าไม่มีจริงๆ ให้ใช้ 'timestamp' (วันที่กด approve) เป็นตัวสำรอง
    String date = (json['booking_date'] ?? json['timestamp'] ?? '')
        .toString()
        .split('T')[0];

    // 4. จัดการ Timestamp (เวลาที่กด Approve/Reject)
    DateTime? decisionTs = json['timestamp'] != null
        ? DateTime.tryParse(json['timestamp'])
        : null;

    // 5. จัดการชื่อคนจอง
    // (Pending ใช้ 'user_name', History ใช้ 'booked_by')
    String bookedBy = json['booked_by'] ?? json['user_name'] ?? 'Unknown';

    // 6. จัดการชื่อคนอนุมัติ
    // (มาจาก History list 'approved_by')
    String? processedBy = json['approved_by'];

    // 7. 'requestedOn' ควรเป็น 'booking_date' เสมอ (วันที่จองมา)
    String requestedOn = (json['booking_date'] ?? '').toString().split('T')[0];

    return BookingRequest(
      id: json['booking_id'].toString(),
      roomName: json['room_name'] ?? '',
      image: json['room_image'] ?? 'assets/images/default_room.jpg',
      date: date,
      time: formattedTime,
      bookedBy: bookedBy,
      requestedOn: requestedOn, // ⭐️ ใช้ค่าที่ถูกต้อง

      status: status, // ⭐️ ใช้ค่าที่แก้แล้ว
      rejectReason: json['reject_reason'], // (มาจาก History)

      approvedBy: processedBy, // ⭐️ ใช้ค่าที่แก้แล้ว
      processedBy: processedBy, // ⭐️ ใช้ค่าที่แก้แล้ว
      // ⭐️⭐️⭐️ สำคัญ ⭐️⭐️⭐️
      // เราไม่ใช้ _at แล้ว ตั้งเป็น null และใช้ decisionTimestamp แทน
      approvedOn: null,
      rejectedOn: null,
      decisionTimestamp: decisionTs,
    );
  }

  String get formattedDate {
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('EEE d MMM yyyy').format(parsed);
    } catch (_) {
      return date;
    }
  }

  String get formattedRequestedOn {
    try {
      // ⭐️ ป้องกัน Error ถ้า requestedOn เป็นค่าว่าง
      if (requestedOn.isEmpty) return '-';
      final parsed = DateTime.parse(requestedOn);
      return DateFormat('EEE d MMM yyyy').format(parsed);
    } catch (_) {
      return requestedOn;
    }
  }

  String get formattedTime => time;
}
