import 'package:flutter/material.dart';
import 'package:project_br/staff/pages/staff_service.dart';

class EditRoomPage extends StatefulWidget {
  final int roomId;
  final Map<String, String> roomData;

  const EditRoomPage({super.key, required this.roomId, required this.roomData});

  @override
  State<EditRoomPage> createState() => _EditRoomPageState();
}

class _EditRoomPageState extends State<EditRoomPage> {
  late TextEditingController _typeController;
  late TextEditingController _descController;
  late TextEditingController _imageController;
  late int _capacity;
  late bool isFree;
  bool _isSaving = false;
  bool _hasBookingsToday = false; // มีการจองวันนี้หรือไม่
  bool _loadingBookingCheck = true; // กำลังเช็คสถานะการจอง

  ImageProvider _imageProvider() {
    final name = _filenameOnly(_imageController.text);
    if (name.isEmpty) return const AssetImage('assets/images/room1.jpg');
    return AssetImage('assets/images/$name');
  }

  // Ensure we always use filename only (strip assets/ prefix or any folders)
  String _filenameOnly(String value) {
    final v = (value).trim();
    if (v.isEmpty) return 'room1.jpg';
    final normalized = v.replaceAll('\\', '/');
    final last = normalized.split('/').last;
    return last.isEmpty ? 'room1.jpg' : last;
  }

  Future<void> _promptImageFilename() async {
    final controller = TextEditingController(text: _imageController.text);
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Image filename'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. room1.jpg',
            helperText: 'Available: room1.jpg, room2.jpg, room3.jpg',
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Use'),
          ),
        ],
      ),
    );

    if (picked != null) {
      setState(() => _imageController.text = _filenameOnly(picked));
    }
  }

  @override
  void initState() {
    super.initState();
    _typeController = TextEditingController(text: widget.roomData['name']);
    _descController = TextEditingController(
      text: widget.roomData['description'],
    );
    // Extract filename from full path (e.g., "assets/images/room1.jpg" -> "room1.jpg")
    final String imagePath = widget.roomData['img'] ?? 'room1.jpg';
    final String imageFilename = imagePath.split('/').last;
    _imageController = TextEditingController(text: imageFilename);
    _capacity = int.tryParse(widget.roomData['capacity'] ?? '1') ?? 1;
    isFree = (widget.roomData['roomStatus'] ?? 'Free').toLowerCase() == 'free';
    // เช็คว่าห้องมีการจองวันนี้หรือไม่ เพื่อกำหนดสิทธิ์ในการแก้ไขสถานะ
    _checkBookings();
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  Future<void> _checkBookings() async {
    try {
      final has = await hasRoomBookingsToday(widget.roomId);
      if (!mounted) return;
      setState(() {
        _hasBookingsToday = has;
        _loadingBookingCheck = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasBookingsToday = false; // ให้แก้ไขได้ถ้าเช็คไม่สำเร็จ (fail-open)
        _loadingBookingCheck = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit room"), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // Image preview with tap-to-edit overlay (like Add)
            InkWell(
              onTap: _promptImageFilename,
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: _imageProvider(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.file_upload_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Upload image',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Room Type and Quantity Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Room name",
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 4),
                      TextField(
                        controller: _typeController,
                        decoration: InputDecoration(
                          hintText: "Room name...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            "Quantity",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          if (_hasBookingsToday) ...[
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Locked: room has bookings today',
                              child: Icon(
                                Icons.lock,
                                size: 16,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: _hasBookingsToday
                                  ? null
                                  : () {
                                      if (_capacity > 1) {
                                        setState(() => _capacity--);
                                      }
                                    },
                              padding: EdgeInsets.zero,
                            ),
                            Expanded(
                              child: Text(
                                _capacity.toString(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: _hasBookingsToday
                                  ? null
                                  : () {
                                      setState(() => _capacity++);
                                    },
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Room Status Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Room Status",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    if (_loadingBookingCheck)
                      const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (_hasBookingsToday)
                      const Tooltip(
                        message: 'Room has active bookings today',
                        child: Icon(Icons.lock, size: 18, color: Colors.orange),
                      ),
                    const SizedBox(width: 6),
                    Text(
                      isFree ? "Free" : "Disabled",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isFree ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: isFree,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: _loadingBookingCheck
                          ? null
                          : (value) {
                              // value == false หมายถึงกำลังจะเปลี่ยนเป็น Disabled
                              if (!value && _hasBookingsToday) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Cannot disable: Room has bookings today',
                                    ),
                                    backgroundColor: Colors.orange,
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                                return;
                              }
                              setState(() => isFree = value);
                            },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Description
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Description",
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: _descController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "Insert information...",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Confirm Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _isSaving ? null : _saveChanges,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Confirm",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // ถ้ามีการจองวันนี้ ห้ามปิดห้อง (disabled)
      if (_hasBookingsToday && !isFree) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot disable room: There are bookings today'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
        setState(() {
          _isSaving = false;
        });
        return;
      }

      // Always sanitize image to filename only
      final imgFilename = _filenameOnly(_imageController.text);

      // If the room has bookings today, allow updating ONLY the image field.
      final Map<String, dynamic> updates = _hasBookingsToday
          ? {'image': imgFilename}
          : {
              'room_name': _typeController.text.trim(),
              'room_description': _descController.text.trim(),
              'room_status': isFree ? 'free' : 'disabled',
              // capacity can be changed only if no bookings today
              'capacity': _capacity,
              'image': imgFilename,
            };

      // If locked, ensure capacity didn't change unintentionally
      // When locked due to bookings, ignore other changes; no need to revert UI here

      final result = await updateRoom(widget.roomId, updates);

      if (!mounted) return;

      if (result != null && result.containsKey('message')) {
        // Success
        final message = result['message'] as String;
        final isCloned = result.containsKey('newRoomId');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isCloned
                  ? 'Room updated! New room created (ID: ${result['newRoomId']})'
                  : message,
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: isCloned ? 4 : 2),
          ),
        );
        Navigator.pop(context, true);
      } else if (result != null && result.containsKey('error')) {
        // Error with message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        // Unknown error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unknown error occurred'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
