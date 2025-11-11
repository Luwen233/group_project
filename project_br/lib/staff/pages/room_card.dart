import 'package:flutter/material.dart';

class RoomCard extends StatelessWidget {
  final String title;
  final String imagePath;
  final Map<String, String> roomData;
  final VoidCallback onEdit;

  const RoomCard({
    super.key,
    required this.title,
    required this.imagePath,
    required this.roomData,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final String roomStatus = roomData['roomStatus'] ?? 'Free';
    final bool isFree = roomStatus.toLowerCase() == 'free';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.asset(
                imagePath,
                height: 165,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.settings, color: Colors.white, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),

          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isFree ? Colors.green : Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    isFree ? Icons.check_circle : Icons.block,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    roomStatus,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
