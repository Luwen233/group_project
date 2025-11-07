// lib/config/api_config.dart
// 🔧 Central API Configuration - แก้ IP ที่นี่ที่เดียว!

class ApiConfig {
  // ⚠️ เปลี่ยน IP ตามสถานการณ์:
  // - Android Emulator → '10.0.2.2'
  // - iOS Simulator → 'localhost' หรือ '127.0.0.1'
  // - มือถือจริง/LDPlayer → IP ของเครื่อง เช่น '192.168.1.100'

  static const String _host = '10.0.2.2'; // เปลี่ยนตรงนี้
  static const String _port = '3000'; // 3000

  // Base URL สำหรับทุก HTTP requests
  static String get baseUrl => 'http://$_host:$_port';

  // Endpoints แยกตามหมวดหมู่ (optional - ถ้าต้องการใช้)
  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegister => '$baseUrl/auth/register';
  static String get rooms => '$baseUrl/rooms';
  static String get bookings => '$baseUrl/bookings';

  // Helper methods
  static String roomDetail(int roomId) => '$baseUrl/rooms/$roomId';
  static String userPendingBookings(int userId) =>
      '$baseUrl/bookings/user/$userId/pending';
  static String userHistoryBookings(int userId) =>
      '$baseUrl/bookings/user/$userId/history';
  static String cancelBooking(String bookingId) =>
      '$baseUrl/bookings/$bookingId/cancel';
}
