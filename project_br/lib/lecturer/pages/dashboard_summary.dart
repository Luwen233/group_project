import 'package:flutter/material.dart';
import 'package:project_br/notifiers.dart';
// ⭐️ ตรวจสอบ Import นี้ให้แน่ใจว่าถูกต้อง (ถ้าไฟล์ lecturer_notifiers.dart ถูกย้ายไปที่ state/ ต้องแก้ path ตรงนี้)
// import 'package:project_br/lecturer/lecturer_notifiers.dart'; // <-- ลบ Path เก่า (ถ้ามี)

class DashboardSummary extends StatelessWidget {
  final int freeSlots;
  final int reservedSlots;
  final int pendingSlots;
  final int disabledRooms;

  const DashboardSummary({
    super.key,
    required this.freeSlots,
    required this.reservedSlots,
    required this.pendingSlots,
    required this.disabledRooms,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            Icons.check_circle,
            Colors.green,
            freeSlots,
            "Free Slots",
            null, // ไม่ต้องกดได้
          ),
        ),
        const SizedBox(width: 8), // ลดช่องว่าง
        Expanded(
          child: _buildSummaryCard(
            Icons.calendar_month,
            Colors.blue,
            reservedSlots,
            "Reserved Slots",
            null, // ไม่ต้องกดได้
          ),
        ),
        const SizedBox(width: 8), // ลดช่องว่าง
        // ทำให้ Pending กดได้
        Expanded(
          child: _buildSummaryCard(
            Icons.hourglass_bottom,
            Colors.amber,
            pendingSlots,
            "Pending Slots",
            () {
              // เมื่อกด ให้เปลี่ยน selectedPageNotifier ไปหน้าที่ 1 (Request Page)
              selectedPageNotifer.value = 1;
            },
          ),
        ),
        const SizedBox(width: 8), // ลดช่องว่าง
        Expanded(
          child: _buildSummaryCard(
            Icons.lock,
            Colors.red,
            disabledRooms,
            "Disable Slots",
            null, // ไม่ต้องกดได้
          ),
        ),
      ],
    );
  }

  // เพิ่ม Parameter onTap
  Widget _buildSummaryCard(
    IconData icon,
    Color color,
    int number,
    String label,
    VoidCallback? onTap, // Function ที่รับเข้ามา
  ) {
    // ครอบด้วย GestureDetector ถ้า onTap ไม่ใช่ null
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap, // กำหนด Function ที่จะทำงานเมื่อกด
        child: Container(
          height: 100, // ความสูงคงที่
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 3),
              ),
            ],
          ),
          // ลด padding แนวนอน
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 6),
              Text(
                number.toString(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1, // บังคับ 1 บรรทัด
                overflow: TextOverflow.ellipsis, // ตัด ... ถ้าล้น
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black54,
                ), // ลดขนาด font label
              ),
            ],
          ),
        ),
      ),
    );
  }
}
