import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_br/config/api_config.dart';

import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'package:project_br/lecturer/rooms_notifier.dart';

/// ✅ ใช้ ApiConfig แทน hardcode URL
String get _baseUrl => ApiConfig.baseUrl;

/// ---------------------------------------------------------------------------
/// FETCH ROOMS
/// ---------------------------------------------------------------------------
Future<void> fetchRooms() async {
  final url = Uri.parse('$_baseUrl/rooms');
  print("📡 FETCH ROOMS → $url");

  try {
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      roomsNotifier.value = data.map((room) {
        final img = (room['image'] ?? '').toString().trim();
        // เพิ่ม assets/images/ prefix ถ้ายังไม่มี
        final imagePath = img.isEmpty
            ? 'assets/images/default_room.png'
            : (img.startsWith('assets/') ? img : 'assets/images/$img');

        return {
          'id': room['room_id'],
          'name': room['room_name'] ?? 'Unnamed Room',
          'status':
              (room['room_status'] ?? '').toString().toLowerCase() == 'free'
              ? 'Free'
              : 'Disable',
          'image': imagePath,
        };
      }).toList();
    } else {
      print('❌ fetchRooms() HTTP ${res.statusCode}');
    }
  } catch (e) {
    print('🔥 fetchRooms() error: $e');
  }
}

/// ---------------------------------------------------------------------------
/// FETCH PENDING REQUESTS (LECTURER)
/// ---------------------------------------------------------------------------
Future<void> fetchPendingRequests() async {
  final url = Uri.parse('$_baseUrl/bookings/requests');
  print("📡 FETCH REQUESTS → $url");

  try {
    final res = await http.get(url);
    print("🔍 STATUS: ${res.statusCode}");
    print("📥 RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      // ✅ กรองเฉพาะ pending
      pendingRequestsNotifier.value = data
          .map<BookingRequest>((e) => BookingRequest.fromJson(e))
          .where((b) => b.status == 'pending')
          .toList();

      print("✅ Updated pendingRequestsNotifier");
    } else {
      pendingRequestsNotifier.value = [];
    }
  } catch (e) {
    print('🔥 fetchPendingRequests() error: $e');
    pendingRequestsNotifier.value = [];
  }
}

/// ---------------------------------------------------------------------------
/// APPROVE REQUEST
/// ---------------------------------------------------------------------------
Future<void> approveRequest(BookingRequest request) async {
  final url = Uri.parse('$_baseUrl/bookings/${request.id}/approve');
  print("✅ APPROVE → $url");

  // 1. ดึง Token ที่บันทึกไว้
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  try {
    final res = await http.patch(
      url,
      // 2. แนบ Token ไปใน Headers
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ⬅️ เพิ่มบรรทัดนี้
      },
    );

    print("🔍 STATUS: ${res.statusCode}");
    print("📥 RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      // ⭐️ [ปรับปรุง] เราไม่จำเป็นต้อง fetchPendingRequests() ที่นี่
      // เพราะ Notifier ในหน้า Request จะ fetch ใหม่อยู่แล้ว
      // await fetchPendingRequests(); // ⬅️ ลบ/ปิดไปได้
    }
  } catch (e) {
    print('🔥 approveRequest() error: $e');
  }
}

// ⭐️⭐️⭐️ [โค้ด REJECT ใหม่] ⭐️⭐️⭐️
Future<void> rejectRequest(BookingRequest request, String reason) async {
  final url = Uri.parse('$_baseUrl/bookings/${request.id}/reject');
  print("❌ REJECT → $url | reason: $reason");

  // 1. ดึง Token ที่บันทึกไว้
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token') ?? '';

  try {
    final res = await http.patch(
      url,
      // 2. แนบ Token ไปใน Headers
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // ⬅️ เพิ่มบรรทัดนี้
      },
      body: jsonEncode({'reject_reason': reason}),
    );

    print("🔍 STATUS: ${res.statusCode}");
    print("📥 RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      // await fetchPendingRequests(); // ⬅️ ลบ/ปิดไปได้
    }
  } catch (e) {
    print('🔥 rejectRequest() error: $e');
  }
}

/// ---------------------------------------------------------------------------
/// HISTORY (แสดง approved / rejected)
/// ---------------------------------------------------------------------------
Future<void> fetchHistoryRequests() async {
  final url = Uri.parse('$_baseUrl/bookings/history');
  print("📡 FETCH HISTORY → $url");

  try {
    final res = await http.get(url);

    print("🔍 STATUS: ${res.statusCode}");
    print("📥 RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);

      historyRequestsNotifier.value = data
          .map<BookingRequest>((e) => BookingRequest.fromJson(e))
          .toList();
    }
  } catch (e) {
    print(" fetchHistoryRequests() error: $e");
  }
}

/// ---------------------------------------------------------------------------
/// DASHBOARD SUMMARY
/// ---------------------------------------------------------------------------
Future<Map<String, dynamic>> fetchDashboardSummary() async {
  final url = Uri.parse('$_baseUrl/dashboard/summary');
  print("📡 FETCH DASHBOARD → $url");

  try {
    final res = await http.get(url);
    return jsonDecode(res.body);
  } catch (e) {
    print('🔥 fetchDashboardSummary() error: $e');
    return {};
  }
}
