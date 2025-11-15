import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project_br/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String? _currentImageName;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.rooms['name']);
    _descController = TextEditingController(text: widget.rooms['description']);
    _capacityController = TextEditingController(
      text: (widget.rooms['capacity']?.toString() ?? '0').replaceAll(
        'N/A',
        '0',
      ),
    );
    _isFree = (widget.rooms['status'] ?? 'Free').toLowerCase() == 'free';

    _currentImageName = (widget.rooms['image'] ?? '').toString();
    if (_currentImageName == null || _currentImageName!.isEmpty) {
      _currentImageName = 'placeholder.png';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateRoom() async {
    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final roomId = widget.rooms['id'];

      final uri = Uri.parse('${ApiConfig.baseUrl}/rooms/$roomId');

      final request = http.MultipartRequest('PUT', uri);

      request.headers['Authorization'] = 'Bearer $token';

      request.fields['room_name'] = _nameController.text;
      request.fields['room_description'] = _descController.text;
      request.fields['room_status'] = _isFree ? 'free' : 'disabled';
      request.fields['capacity'] = (int.tryParse(_capacityController.text) ?? 0)
          .toString();

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', _imageFile!.path),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

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
    Widget imageWidget;
    if (_imageFile != null) {
      imageWidget = Image.file(
        _imageFile!,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    } else {
      final String imagePath =
          'assets/images/${_currentImageName ?? 'placeholder.png'}';
      imageWidget = Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Edit Room",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
                    height: 330,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: imageWidget,
                  ),
                  Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
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

            // Capacity
            TextField(
              controller: _capacityController,
              decoration: const InputDecoration(
                labelText: "Capacity",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),

            // Description
            TextField(
              controller: _descController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Confirm button
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
