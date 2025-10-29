import 'package:flutter/foundation.dart';
import 'package:project_br/lecturer/booking_model.dart';

// --- ตัวเก็บ State (ข้อมูล) ---

// เริ่มต้นเป็น List ว่างเปล่า ตามที่คุณต้องการ
final ValueNotifier<List<BookingRequest>> pendingRequestsNotifier =
    ValueNotifier([]);

// History ก็เริ่มต้นว่างเปล่าเช่นกัน
final ValueNotifier<List<BookingRequest>> historyRequestsNotifier =
    ValueNotifier([]);

// Selected page for lecturer bottom navigation / widget tree
final ValueNotifier<int> selectedPageNotifier = ValueNotifier<int>(0);

// --- ฟังก์ชัน Helper (ถ้าต้องการ) ---
// (อาจจะมีฟังก์ชันอื่นๆ เพิ่มเติมได้ในอนาคต เช่น การโหลดข้อมูลจาก API)