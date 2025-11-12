import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:project_br/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditRoomPage extends StatefulWidget {
  final Map<String, dynamic> rooms;
  const EditRoomPage({super.key, required this.rooms});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _capacityController; 
  late bool _isFree;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rooms['name']);
    _descController = TextEditingController(
      text: widget.rooms['description'],
    );
    _capacityController = TextEditingController(
      text: (widget.rooms['capacity']?.toString() ?? '0').replaceAll(
        'N/A',
        '0',
      ),
    );
    _isFree = (widget.rooms['status'] ?? 'Free').toLowerCase() == 'free';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _updateRoom() async {
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final roomId = widget.rooms['id'];

      final url = Uri.parse('${ApiConfig.baseUrl}/rooms/$roomId');

      // 👈 4. UPDATED BODY
      final body = jsonEncode({
        'room_name': _nameController.text,
        'room_description': _descController.text,
        'room_status': _isFree ? 'free' : 'disabled',
        'capacity': int.tryParse(_capacityController.text) ?? 0,
      });

      final response = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: ${response.body}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String imagePath = widget.rooms['image']?.isNotEmpty ?? false
        ? 'assets/images/${widget.rooms['image']}'
        : 'assets/images/placeholder.png';

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
                  image: AssetImage(imagePath),
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
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: "Room Name",
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
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _isFree ? "Free" : "Disable",
                          style: TextStyle(
                            fontSize: 16,
                            color: _isFree ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: _isFree,
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          onChanged: (value) => setState(() => _isFree = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: "Capacity",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number, // Shows number keyboard
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
              onPressed: _isSubmitting ? null : _updateRoom,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
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
