import 'package:flutter/material.dart';

// Assuming roomData is passed as a Map from the home page
class EditRoomPage extends StatefulWidget {
  final Map<String, String> roomData; // Data of the room to edit
  const EditRoomPage({super.key, required this.roomData});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  late int quantity;
  late TextEditingController _typeController;
  late TextEditingController _descController;
  
  @override
  void initState() {
    super.initState();
    // Initialize state with existing room data
    _typeController = TextEditingController(text: widget.roomData['name']);
    _descController = TextEditingController(text: widget.roomData['description'] ?? 'Insert information...'); 
    quantity = int.tryParse(widget.roomData['quantity'] ?? '5') ?? 5;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit room")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Image Upload/Display Section
            Container(
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                // Display current image (simulated)
                image: DecorationImage(
                  image: AssetImage(widget.roomData['img']!), 
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.3), BlendMode.darken),
                ),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload_outlined, size: 40, color: Colors.white),
                    SizedBox(height: 8),
                    Text("Upload image", style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Type's room and Quantity fields side-by-side
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _typeController,
                    decoration: const InputDecoration(
                      labelText: "Type's room",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Quantity", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (quantity > 1) setState(() => quantity--);
                              },
                              child: const Text("-", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                            Text(quantity.toString(), style: const TextStyle(fontSize: 16)),
                            GestureDetector(
                              onTap: () => setState(() => quantity++),
                              child: const Text("+", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description field
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
                hintText: "Insert information...",
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                // Logic to save changes
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text("Room ${_typeController.text} updated successfully")),
                );
                Navigator.pop(context); // Go back after update
              },
              child: const Text("Confirm", style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}