import 'package:flutter/material.dart';

class AddRoomPage extends StatefulWidget {
  const AddRoomPage({super.key});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  int quantity = 1;
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar title updated to match image
      appBar: AppBar(title: const Text("Add room")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 2. Image Upload Area - Styled to match image
            Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon and text updated to match image
                    Icon(Icons.upload_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Upload image", style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. Row for Type and Quantity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Type's room" input
                Expanded(
                  flex: 2, // Gives more space to the text field
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label above the text field
                      Text("Type's room",
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _typeController,
                        decoration: const InputDecoration(
                          hintText: "Room...", // Hint text as in image
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // "Quantity" selector
                Expanded(
                  flex: 1, // Gives less space to the quantity
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label above the selector
                      Text("Quantity",
                          style: TextStyle(color: Colors.grey.shade700)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Remove Button
                            IconButton(
                              // --- THIS IS THE FIX ---
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              // -------------------------
                              onPressed: () {
                                if (quantity > 1) setState(() => quantity--);
                              },
                              icon: const Icon(Icons.remove, size: 18),
                            ),
                            // Quantity Text
                            Text(quantity.toString(),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16)),
                            // Add Button
                            IconButton(
                              // --- THIS IS THE FIX ---
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              // -------------------------
                              onPressed: () => setState(() => quantity++),
                              icon: const Icon(Icons.add, size: 18),
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

            // 4. Description Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label above the text field
                Text("Description",
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 8),
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    hintText: "Insert information...", // Hint text as in image
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 5. Confirm Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  // Rounded corners to match image
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Room added successfully")),
                );
              },
              child: const Text("Confirm",
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}