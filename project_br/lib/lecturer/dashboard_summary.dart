import 'package:flutter/material.dart';

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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSummaryCard(
          Icons.check_circle,
          Colors.green,
          freeSlots,
          "Free Slots",
        ),
        _buildSummaryCard(
          Icons.calendar_today,
          Colors.blue,
          reservedSlots,
          "Reserved Slots",
        ),
        _buildSummaryCard(
          Icons.hourglass_bottom,
          Colors.amber,
          pendingSlots,
          "Pending Slots",
        ),
        _buildSummaryCard(
          Icons.lock,
          Colors.red,
          disabledRooms,
          "Disable Slots",
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    IconData icon,
    Color color,
    int number,
    String label,
  ) {
    return Container(
      width: 70,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            number.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}
