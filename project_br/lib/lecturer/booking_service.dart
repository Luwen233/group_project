import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'dart:math'; // สำหรับสร้าง ID สุ่ม
import 'package:intl/intl.dart'; // สำหรับ Format วันที่
import 'package:flutter/foundation.dart';

// --- Service Logic ---

void approveRequest(BookingRequest request) {
  final now = DateTime.now();
  // ⭐️ เปลี่ยน Format วันที่ ให้แสดงแค่ วัน เดือน ปี
  final formattedDate = DateFormat('MMM d, yyyy').format(now);

  // สร้าง Request ใหม่ที่เป็น Approved และย้ายไปยัง History
  final approvedRequest = request.copyWith(
    status: 'approved',
    processedBy: 'System', // ตัวอย่าง: คนที่ Approve คือ System
    approvedBy:
        'Mr. John', // ⭐️ เพิ่ม approvedBy (อาจจะเปลี่ยนเป็น Lecturer ID จริง)
    approvedOn: formattedDate, // เก็บ String ที่ Format แล้ว
    rejectedOn: null,
    rejectReason: null,
    decisionTimestamp: now,
  );

  // อัปเดต Notifiers
  final currentPending = List<BookingRequest>.from(
    pendingRequestsNotifier.value,
  );
  currentPending.removeWhere((req) => req.id == request.id);
  pendingRequestsNotifier.value = currentPending;

  final currentHistory = List<BookingRequest>.from(
    historyRequestsNotifier.value,
  );
  currentHistory.insert(0, approvedRequest);
  historyRequestsNotifier.value = currentHistory;
}

void rejectRequest(BookingRequest request, String reason) {
  final now = DateTime.now();
  // ⭐️ เปลี่ยน Format วันที่ ให้แสดงแค่ วัน เดือน ปี
  final formattedDate = DateFormat('MMM d, yyyy').format(now);

  // สร้าง Request ใหม่ที่เป็น Rejected และย้ายไปยัง History
  final rejectedRequest = request.copyWith(
    status: 'rejected',
    rejectReason: reason.isNotEmpty ? reason : null,
    processedBy: 'Mr. John', // หรือ ID ของ Lecturer
    rejectedOn: formattedDate, // เก็บ String ที่ Format แล้ว
    approvedOn: null,
    approvedBy: null, // ⭐️ ตรวจสอบว่า approvedBy เป็น null ตอน Reject
    decisionTimestamp: now,
  );

  // อัปเดต Notifiers
  final currentPending = List<BookingRequest>.from(
    pendingRequestsNotifier.value,
  );
  currentPending.removeWhere((req) => req.id == request.id);
  pendingRequestsNotifier.value = currentPending;

  final currentHistory = List<BookingRequest>.from(
    historyRequestsNotifier.value,
  );
  currentHistory.insert(0, rejectedRequest);
  historyRequestsNotifier.value = currentHistory;
}

// --- ฟังก์ชันจำลองการ Booking ใหม่ ---
void simulateNewBooking() {
  final random = Random();
  final DateTime today = DateTime.now();
  final DateTime futureDateRaw = today.add(
    Duration(days: random.nextInt(7) + 1),
  );
  final String futureDate = DateFormat('E d MMM yyyy').format(futureDateRaw);

  final List<String> availableTimeSlots = [
    '08:00 - 10:00 AM',
    '10:00 - 12:00 PM',
    '01:00 - 03:00 PM', // 13:00 - 15:00
    '03:00 - 05:00 PM', // 15:00 - 17:00
  ];
  final String selectedTimeSlot =
      availableTimeSlots[random.nextInt(availableTimeSlots.length)];

  final List<Map<String, String>> rooms = [
    {'name': 'Study Room A', 'image': 'assets/images/room1.jpg'},
    {'name': 'Law Study Room', 'image': 'assets/images/room2.jpg'},
    {'name': 'Room B101', 'image': 'assets/images/room3.jpg'},
    {'name': 'Room B102', 'image': 'assets/images/room4.jpg'},
  ];
  final selectedRoom = rooms[random.nextInt(rooms.length)];

  final String newId = DateTime.now().millisecondsSinceEpoch
      .toString()
      .substring(5);

  final newRequest = BookingRequest(
    id: newId,
    roomName: selectedRoom['name']!,
    image: selectedRoom['image']!,
    date: futureDate,
    time: selectedTimeSlot,
    bookedBy: 'User ${random.nextInt(100)}',
    requestedOn: DateFormat('MMM, d, yyyy').format(today),
    status: 'pending',
  );

  final currentPending = List<BookingRequest>.from(
    pendingRequestsNotifier.value,
  );
  currentPending.insert(0, newRequest);
  pendingRequestsNotifier.value = currentPending;

  if (kDebugMode) {
    print('Simulated new booking: ${newRequest.id} for ${newRequest.roomName}');
  }
}
