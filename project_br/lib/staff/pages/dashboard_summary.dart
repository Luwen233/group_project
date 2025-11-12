import 'package:flutter/material.dart';

class DashboardSummary extends StatelessWidget {
  final int totalRooms;
  final int freeSlots;
  final int reservedSlots;
  final int disabledRooms;

  const DashboardSummary({
    super.key,
    required this.totalRooms,
    required this.freeSlots,
    required this.reservedSlots,
    required this.disabledRooms,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ⭐ เพิ่ม Total Room ซ้ายสุด
        Expanded(
          child: _buildSummaryCard(
            Icons.meeting_room,
            Colors.deepPurple,
            totalRooms,
            "Total Rooms",
            null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            Icons.check_circle,
            Colors.green,
            freeSlots,
            "Free Slots",
            null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            Icons.calendar_month,
            Colors.blue,
            reservedSlots,
            "Reserved Slots",
            null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            Icons.lock,
            Colors.red,
            disabledRooms,
            "Disabled",
            null,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    IconData icon,
    Color color,
    int number,
    String label,
    VoidCallback? onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 6),
            Text(
              number.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
