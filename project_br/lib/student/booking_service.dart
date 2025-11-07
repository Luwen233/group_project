// lib/student/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class BookingService {
  // เปลี่ยนเป็น 'static List' ธรรมดา (ไม่ final) เพื่อให้ใส่ค่าจาก API ได้
  static List<Map<String, dynamic>> bookings = [];

  // ⚠️ สำคัญสำหรับ Android Emulator (10.0.2.2 คือ localhost ของเครื่อง Host)
  static const String BASE_URL = 'http://10.0.2.2:3000';
  // ถ้าใช้ LDPlayer/มือถือจริง ต้องเปลี่ยนเป็น IP เครื่อง เช่น 'http://192.168.1.23:3000'

  // ====== MOCK: เก็บไว้ใช้ตอนออฟไลน์ก็ได้ ======
  static final List<Map<String, dynamic>> _mock = [
    {
      'id': '00014',
      'roomName': 'Study Room',
      'image': 'assets/images/room1.jpg',
      'date': 'Wed 29 Oct 2025',
      'time': '03:00 - 05:00 PM',
      'name': 'Mr. John',
      'bookingDate': '01:12 AM',
      'status': 'Pending',
      'reason': 'Need a quiet place for project work.',
    },
    {
      'id': '00013',
      'roomName': 'Study Room',
      'image': 'assets/images/room1.jpg',
      'date': 'Mon 22 Sep 2025',
      'time': '01:00 - 03:00 PM',
      'name': 'Mr. John',
      'bookingDate': '07:12 AM',
      'status': 'Approved',
      'approver': 'Mr. John',
      'actionDate': 'Sep 22, 2025',
      'reason': 'Study group meeting.',
    },
    {
      'id': '00012',
      'roomName': 'Law Study Room',
      'image': 'assets/images/room2.jpg',
      'date': 'Mon 22 Sep 2025',
      'time': '01:00 - 03:00 PM',
      'name': 'Mr. John',
      'bookingDate': '07:12 AM',
      'status': 'Rejected',
      'approver': 'Mr. Surapong',
      'actionDate': 'Sep 22, 2025',
      'reason': 'Need for mock trial practice.',
      'lecturerNote': 'Room is reserved for official use during this time.',
    },
    {
      'id': '00011',
      'roomName': 'Meeting Room',
      'image': 'assets/images/room3.jpg',
      'date': 'Sun 11 Sep 2025',
      'time': '01:00 - 03:00 PM',
      'name': 'Mr. John',
      'bookingDate': '07:12 AM',
      'status': 'Cancelled',
      'approver': 'Mr. Kakaka',
      'actionDate': 'Sep 11, 2025',
      'reason': 'Team meeting.',
    },
  ];

  // เรียกอันนี้ถ้าต้องการใช้ mock
  static Future<void> useMock() async {
    bookings = List<Map<String, dynamic>>.from(_mock);
  }

  // ====== API ======
  static Future<void> fetchAllLogs() async {
    final res = await http.get(Uri.parse('$BASE_URL/logs'));
    if (res.statusCode != 200) {
      throw Exception('GET /logs failed: ${res.statusCode}');
    }
    final List list = jsonDecode(res.body);
    bookings = list.map<Map<String, dynamic>>((row) => _mapRow(row)).toList();
  }

  static Future<void> fetchLogsByUser(String? userId) async {
    final res = await http.get(Uri.parse('$BASE_URL/logs/user/$userId'));
    if (res.statusCode != 200) {
      throw Exception('GET /logs/user/$userId failed: ${res.statusCode}');
    }
    final List list = jsonDecode(res.body);
    bookings = list.map<Map<String, dynamic>>((row) => _mapRow(row)).toList();
  }

  static Future<void> fetchLogsByRoom(String roomId) async {
    final res = await http.get(Uri.parse('$BASE_URL/logs/room/$roomId'));
    if (res.statusCode != 200) {
      throw Exception('GET /logs/room/$roomId failed: ${res.statusCode}');
    }
    final List list = jsonDecode(res.body);
    bookings = list.map<Map<String, dynamic>>((row) => _mapRow(row)).toList();
  }

  // ====== MAPPER: แปลงฟิลด์จาก DB → ให้ "คีย์ตรงกับ UI เดิมของคุณ" ======
  static Map<String, dynamic> _mapRow(Map<String, dynamic> r) {
    // เดา schema ทั่วไป: ปรับชื่อคอลัมน์ตรงนี้ให้ตรงของจริง
    final id = (r['log_id'] ?? r['id'] ?? '').toString();
    final roomName = (r['room_name'] ?? 'Room ${r['room_id'] ?? ''}')
        .toString();
    final status = (r['status'] ?? 'Cancelled').toString();
    final bookedByName = (r['booked_by_name'] ?? r['booked_by'] ?? 'Mr. John')
        .toString();
    final approver = (r['approved_by_name'] ?? r['approved_by'] ?? '')
        .toString();
    final reason = (r['reason'] ?? r['request_reason'] ?? 'No reason provided.')
        .toString();
    final lecturerNote = (r['lecturer_note'] ?? r['note'] ?? '').toString();

    // วันที่/เวลา
    final requestedAt =
        r['requested_at']?.toString() ?? r['date']?.toString() ?? 'N/A';
    final actionAt =
        r['action_at']?.toString() ?? r['actionDate']?.toString() ?? '';

    // เวลาแสดงในบัตร
    final timeText = _composeTime(r);

    // รูป: ถ้าไม่มีจาก API ให้ map ด้วย room_id → asset เดิม
    final imagePath = _imageForRoom(r['room_id']);

    return {
      'id': id.isEmpty ? '00000' : id,
      'roomName': roomName,
      'image': imagePath, // ยังใช้ Image.asset ได้เหมือนเดิม
      'date': requestedAt, // ตรงคีย์กับ UI เดิม
      'time': timeText, // ตรงคีย์กับ UI เดิม
      'name': bookedByName, // 'Booked By'
      'bookingDate': '', // ถ้าอยากเติมเวลา request จริง ให้ map เพิ่มเอง
      'status': status,
      'approver': approver,
      'actionDate': actionAt,
      'reason': reason,
      'lecturerNote': lecturerNote,
    };
  }

  static String _composeTime(Map<String, dynamic> r) {
    final st = r['start_time'] ?? r['startTime'];
    final et = r['end_time'] ?? r['endTime'];
    if (st != null && et != null) return '${st.toString()} - ${et.toString()}';
    return (r['time'] ?? 'N/A').toString();
  }

  static String _imageForRoom(dynamic roomId) {
    final id = roomId?.toString() ?? '';
    const fallback = 'assets/images/room1.jpg';
    const map = {
      '1': 'assets/images/room1.jpg',
      '2': 'assets/images/room2.jpg',
      '3': 'assets/images/room3.jpg',
      '101': 'assets/images/room1.jpg',
      '201': 'assets/images/room2.jpg',
      '301': 'assets/images/room3.jpg',
    };
    return map[id] ?? fallback;
  }
}
