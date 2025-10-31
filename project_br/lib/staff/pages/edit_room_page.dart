import 'package:flutter/material.dart';

class EditRoomPage extends StatefulWidget {
  final Map<String, String> roomData;
  const EditRoomPage({super.key, required this.roomData});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  late TextEditingController _typeController;
  late TextEditingController _descController;
  late bool isFree;

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.roomData['name']);
    _descController = TextEditingController(text: widget.roomData['description']);
    isFree = (widget.roomData['roomStatus'] ?? 'Free').toLowerCase() == 'free';
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
      appBar: AppBar(title: const Text("Edit Room")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Container(
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: AssetImage(widget.roomData['img']!),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),

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
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Room Status",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isFree ? "Free" : "Disable",
                          style: TextStyle(
                            fontSize: 16,
                            color: isFree ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: isFree,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (value) => setState(() => isFree = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () {
                final updatedData = {
                  'name': _typeController.text,
                  'description': _descController.text,
                  'roomStatus': isFree ? 'Free' : 'Disable',
                  'img': widget.roomData['img']!,
                };

                Navigator.pop(context, updatedData);
              },
              child: const Text(
                "Confirm",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
