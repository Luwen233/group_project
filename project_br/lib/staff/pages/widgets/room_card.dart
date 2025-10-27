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
    // Get the quantity from the roomData, default to '1' if not provided
    final String quantity = roomData['quantity'] ?? '1';

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Stack( // The Stack allows layering widgets
        children: [
          // Base content (Image and Title)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Image.asset(imagePath,
                    fit: BoxFit.cover, width: double.infinity),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 1, // Prevent title from overlapping badge
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          
          // Edit Button (top-left)
          Positioned(
            top: 4,
            left: 4,
            child: IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.settings, color: Colors.white, size: 24),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                minimumSize: Size.zero,
                padding: const EdgeInsets.all(4),
              ),
            ),
          ),

          // --- NEW: Quantity Badge (bottom-right) ---
          Positioned(
            bottom: 8,
            right: 8,
            child: Row(
              children: [
                // Quantity Text (e.g., "x5")
                Text(
                  'x$quantity',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 4),
                // Home Icon with green background
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: const Icon(
                    Icons.home,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}