import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_br/config/api_config.dart';

String get _baseUrl => ApiConfig.baseUrl;

/// Fetch dashboard summary
Future<Map<String, dynamic>> fetchDashboardSummary() async {
  final url = Uri.parse('$_baseUrl/dashboard/summary');
  print("📡 FETCH DASHBOARD → $url");

  try {
    final res = await http.get(url);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      print('❌ fetchDashboardSummary() HTTP ${res.statusCode}');
      return {};
    }
  } catch (e) {
    print('🔥 fetchDashboardSummary() error: $e');
    return {};
  }
}

/// Fetch all rooms
Future<List<Map<String, dynamic>>> fetchRooms() async {
  final url = Uri.parse('$_baseUrl/rooms');
  print("📡 FETCH ROOMS → $url");

  try {
    final res = await http.get(url);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((room) => room as Map<String, dynamic>).toList();
    } else {
      print('❌ fetchRooms() HTTP ${res.statusCode}');
      return [];
    }
  } catch (e) {
    print('🔥 fetchRooms() error: $e');
    return [];
  }
}

/// Check if the room has any (approved or pending) bookings today.
/// Returns true if there is at least one booking, false otherwise.
/// NOTE: This assumes backend supports filtering by query params room_id & date.
/// If not, adjust endpoint or filtering logic accordingly.
Future<bool> hasRoomBookingsToday(int roomId) async {
  // Use existing endpoint GET /rooms/:id which already returns today's booked slots
  final url = Uri.parse('$_baseUrl/rooms/$roomId');
  print('📡 CHECK ROOM BOOKINGS TODAY → $url');
  try {
    final res = await http.get(url);
    print('🔍 hasRoomBookingsToday() STATUS: ${res.statusCode}');
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final List booked = (data['booked_slots'] as List?) ?? const [];
      final has = booked.isNotEmpty;
      print('📦 booked_slots today for room $roomId: ${booked.length}');
      return has;
    }
    return false;
  } catch (e) {
    print('🔥 hasRoomBookingsToday() error: $e');
    return false; // Fail open: allow UI, but server will still validate on save
  }
}

/// Update room (PATCH - ส่งเฉพาะฟิลด์ที่แก้ไข)
Future<Map<String, dynamic>?> updateRoom(
  int roomId,
  Map<String, dynamic> updates,
) async {
  final url = Uri.parse('$_baseUrl/rooms/$roomId');
  print("📡 PATCH ROOM → $url");
  print("📤 DATA: $updates");

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      print('❌ No token found');
      return {'error': 'No authentication token. Please login again.'};
    }

    print("🔑 TOKEN: ${token.substring(0, 20)}...");

    final res = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(updates),
    );

    print("🔍 STATUS: ${res.statusCode}");
    print("📥 RESPONSE: ${res.body}");

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 403) {
      return {
        'error': 'Permission denied. Only Staff/Lecturer can edit rooms.',
      };
    } else if (res.statusCode == 404) {
      return {'error': 'Room not found.'};
    } else if (res.statusCode == 400) {
      final errorData = jsonDecode(res.body);
      return {'error': errorData['message'] ?? 'Invalid input'};
    } else {
      return {'error': 'Failed to update room (${res.statusCode})'};
    }
  } catch (e) {
    print('🔥 updateRoom() error: $e');
    return {'error': 'Network error: $e'};
  }
}

/// Create a new room (POST)
Future<Map<String, dynamic>?> createRoom(Map<String, dynamic> payload) async {
  final url = Uri.parse('$_baseUrl/rooms');
  print("📡 CREATE ROOM → $url");
  print("📤 DATA: $payload");

  try {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    if (token.isEmpty) {
      print('❌ No token found');
      return {'error': 'No authentication token. Please login again.'};
    }

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(payload),
    );

    print("🔍 STATUS: ${res.statusCode}");
    print("📥 RESPONSE: ${res.body}");

    if (res.statusCode == 201 || res.statusCode == 200) {
      return jsonDecode(res.body);
    } else if (res.statusCode == 403) {
      return {
        'error': 'Permission denied. Only Staff/Lecturer can create rooms.',
      };
    } else if (res.statusCode == 400) {
      final errorData = jsonDecode(res.body);
      return {'error': errorData['message'] ?? 'Invalid input'};
    } else {
      return {'error': 'Failed to create room (${res.statusCode})'};
    }
  } catch (e) {
    print('🔥 createRoom() error: $e');
    return {'error': 'Network error: $e'};
  }
}
