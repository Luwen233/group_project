import 'package:flutter/material.dart';

class TimeSlot {
  final int id;
  final String display;
  final TimeOfDay endTime;
  const TimeSlot({
    required this.id,
    required this.display,
    required this.endTime,
  });
}

class RoomCard extends StatelessWidget {
  final Map<String, dynamic> room;
  final List<TimeSlot> timeSlots;
  final VoidCallback? onEdit;

  const RoomCard({
    super.key,
    required this.room,
    required this.timeSlots,
    this.onEdit,
  });

  double _t2d(TimeOfDay t) => t.hour + t.minute / 60.0;

  @override
  Widget build(BuildContext context) {
    final List<int> bookedSlots = room['booked_slots'] ?? [];
    final String capacityRoom = (room['capacity'] as String?) ?? '-';
    final String displayStatus = room['status'] ?? 'disabled';

    final Color displayColor;
    if (displayStatus.toLowerCase() == 'free') {
      displayColor = const Color(0xff3BCB53);
    } else {
      displayColor = const Color(0xff4E534E);
    }

    final String imagePath = room['image']?.isNotEmpty ?? false
        ? 'assets/images/${room['image']}'
        : 'assets/images/placeholder.png';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: Image.asset(
                  imagePath,
                  height: 165,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(
                    height: 165,
                    child: Center(child: Icon(Icons.broken_image)),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.settings, size: 20),
                    color: Colors.white,
                    onPressed: onEdit,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    room['name'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 8),
                    const Icon(Icons.group, size: 16, color: Color(0xFF3C9CBF)),
                    const SizedBox(width: 4),
                    Text(
                      capacityRoom,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.lock_clock, size: 15),
                    const SizedBox(width: 6),
                    Text(
                      'Available Times',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: List.generate(timeSlots.length, (slotIndex) {
                    final slot = timeSlots[slotIndex];
                    final double nowDouble = _t2d(TimeOfDay.now());
                    final bool isBooked = bookedSlots.contains(slot.id);
                    final bool isPast = nowDouble >= _t2d(slot.endTime);
                    final bool isDisabled =
                        displayStatus.toLowerCase() == 'disabled';
                    final Color barColor;
                    final Color textColor;

                    if (isDisabled) {
                      barColor = Colors.grey[350]!;
                      textColor = Colors.grey[700]!;
                    } else if (isBooked) {
                      barColor = const Color(0xffDB5151);
                      textColor = Colors.white;
                    } else if (isPast) {
                      barColor = Colors.grey[350]!;
                      textColor = Colors.grey[700]!;
                    } else {
                      barColor = const Color(0xff3BCB53);
                      textColor = Colors.white;
                    }
                    return Expanded(
                      child: Column(
                        children: [
                          Container(
                            height: 25,
                            margin: const EdgeInsets.symmetric(horizontal: 2.0),
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Center(
                              child: Text(
                                slot.display,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 15),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: displayColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  displayStatus,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
