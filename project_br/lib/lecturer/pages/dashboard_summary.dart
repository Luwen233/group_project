import 'package:flutter/material.dart';
import 'package:project_br/notifiers.dart';

class DashboardSummary extends StatelessWidget {
  final int totalSlots;
  final int freeSlots;
  final int reservedSlots;
  final int pendingSlots;
  final int disabledRooms;

  const DashboardSummary({
    super.key,
    required this.totalSlots,
    required this.freeSlots,
    required this.reservedSlots,
    required this.pendingSlots,
    required this.disabledRooms,
  });

  @override
  Widget build(BuildContext context) {
    final cardWidth = MediaQuery.of(context).size.width / 4.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal, // scroll horizontal
      child: Row(
        children: [
          SizedBox(
            width: cardWidth,
            child: _buildSummaryCard(
              Icons.view_list,
              Colors.blueGrey,
              totalSlots,
              "Total Slots",
              null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: cardWidth,
            child: _buildSummaryCard(
              Icons.check_circle,
              Colors.green,
              freeSlots,
              "Free Slots",
              null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: cardWidth,
            child: _buildSummaryCard(
              Icons.calendar_month,
              Colors.blue,
              reservedSlots,
              "Reserved Slots",
              null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: cardWidth,
            child: _buildSummaryCard(
              Icons.hourglass_bottom,
              Colors.amber,
              pendingSlots,
              "Pending Slots",
              () {
                selectedPageNotifer.value = 1;
              },
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: cardWidth,
            child: _buildSummaryCard(
              Icons.lock,
              Colors.red,
              disabledRooms,
              "Disable Slots",
              null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    IconData icon,
    Color color,
    int number,
    String label,
    VoidCallback? onTap,
  ) {
    return Tooltip(
      message: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 8),
              Text(
                number.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
