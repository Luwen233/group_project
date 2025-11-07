// lib/student/booking_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:project_br/config/api_config.dart';

class BookingService {
  // ✅ ใช้ ApiConfig แทน hardcode URL
  static String get BASE_URL => ApiConfig.baseUrl;

  // ⭐️ เช็คว่า user มี booking วันนี้แล้วหรือยัง (1 ID จองได้วันละครั้ง)
  static Future<bool> hasTodayBooking(int userId, String token) async {
    try {
      final res = await http.get(
        Uri.parse('$BASE_URL/bookings/user/$userId/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        // ถ้า API return { hasBooking: true/false }
        return data['hasBooking'] == true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // ⭐️ ดึง pending bookings ของ user
  static Future<List<Map<String, dynamic>>> fetchPendingBookings(
    int userId,
    String token,
  ) async {
    try {
      final res = await http.get(
        Uri.parse('$BASE_URL/bookings/user/$userId/pending'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        return list.map<Map<String, dynamic>>((row) => _mapRow(row)).toList();
      }
      return [];
    } catch (e) {
      throw Exception('Failed to fetch pending bookings: $e');
    }
  }

  // ⭐️ ดึง history bookings ของ user (Approved, Rejected, Cancelled)
  static Future<List<Map<String, dynamic>>> fetchHistoryBookings(
    int userId,
    String token,
  ) async {
    try {
      // ใช้ endpoint ใหม่ที่ backend มีอยู่แล้ว
      final url = Uri.parse('$BASE_URL/bookings/user/$userId/history');
      debugPrint('=== Fetching History ===');
      debugPrint('URL: $url');
      debugPrint('User ID: $userId');

      final res = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('Response Status: ${res.statusCode}');
      debugPrint('Response Body: ${res.body}');

      if (res.statusCode == 200) {
        final List list = jsonDecode(res.body);
        debugPrint('History count: ${list.length}');

        // Backend filter ให้แล้ว ไม่ต้อง filter ที่นี่
        return list.map<Map<String, dynamic>>((row) => _mapRow(row)).toList();
      } else {
        debugPrint('Error: Status ${res.statusCode}');
      }
      return [];
    } catch (e) {
      debugPrint('Failed to fetch history bookings: $e');
      return []; // Return empty list แทน throw exception
    }
  }

  // Helper: แปลงข้อมูลจาก database เป็น format ที่ UI ใช้
  static Map<String, dynamic> _mapRow(Map<String, dynamic> r) {
    final id = (r['booking_id'] ?? r['id'] ?? '').toString();
    final roomName = (r['room_name'] ?? 'Room ${r['room_id'] ?? ''}')
        .toString();
    final status = (r['status'] ?? 'Pending').toString();
    final bookedByName = (r['booked_by_name'] ?? r['username'] ?? '')
        .toString();
    final approver = (r['approved_by_name'] ?? r['approved_by'] ?? '')
        .toString();
    final reason = (r['booking_reason'] ?? r['reason'] ?? '').toString();
    final lecturerNote = (r['reject_reason'] ?? r['note'] ?? '').toString();

    // วันที่/เวลา - Format ให้อ่านง่าย
    final bookingDate = _formatDate(r['booking_date']);
    final actionAt = _formatDate(r['action_date']);

    // เวลา
    final slotDisplay =
        r['slot_display']?.toString() ??
        _composeTime(r['start_time'], r['end_time']);

    // รูปภาพ
    final imagePath = _imageForRoom(r['room_id']);

    return {
      'id': id.isEmpty ? '00000' : id,
      'roomName': roomName,
      'image': imagePath,
      'date': bookingDate,
      'time': slotDisplay,
      'name': bookedByName,
      'bookingDate': '',
      'status': status,
      'approver': approver,
      'actionDate': actionAt,
      'reason': reason,
      'lecturerNote': lecturerNote,
    };
  }

  static String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dateStr = date.toString();
      // Parse ISO date string
      final parsedDate = DateTime.parse(dateStr);
      // Format เป็น "22 Oct 2025" (ไม่มีชื่อวัน)
      return DateFormat('d MMM yyyy').format(parsedDate);
    } catch (e) {
      return date.toString();
    }
  }

  static String _composeTime(dynamic startTime, dynamic endTime) {
    if (startTime != null && endTime != null) {
      return '${startTime.toString()} - ${endTime.toString()}';
    }
    return 'N/A';
  }

  static String _imageForRoom(dynamic roomId) {
    final id = roomId?.toString() ?? '';
    const fallback = 'assets/images/room1.jpg';
    const map = {
      '1': 'assets/images/room1.jpg',
      '2': 'assets/images/room2.jpg',
      '3': 'assets/images/room3.jpg',
    };
    return map[id] ?? fallback;
  }

  // ⭐️ ยกเลิก booking
  static Future<void> cancelBooking(String bookingId, String token) async {
    try {
      final url = Uri.parse('$BASE_URL/bookings/$bookingId/cancel');
      debugPrint('🚫 === Cancelling Booking ===');
      debugPrint('   URL: $url');
      debugPrint('   Booking ID: $bookingId');
      debugPrint('   Token: ${token.substring(0, 20)}...');

      final res = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('📡 Response Status: ${res.statusCode}');
      debugPrint('📡 Response Body: ${res.body}');

      if (res.statusCode == 200) {
        debugPrint('✅ Cancel successful!');
      } else if (res.statusCode == 404) {
        debugPrint('❌ Booking not found or already cancelled');
        throw Exception('Booking not found or cannot be cancelled');
      } else {
        debugPrint('❌ Cancel failed with status ${res.statusCode}');
        throw Exception('Failed to cancel booking: ${res.body}');
      }
    } catch (e) {
      debugPrint('💥 Error cancelling booking: $e');
      rethrow;
    }
  }
}
