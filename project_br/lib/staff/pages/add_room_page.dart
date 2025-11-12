import 'package:flutter/material.dart';
import 'package:project_br/staff/pages/staff_service.dart';

class AddRoomPage extends StatefulWidget {
  final VoidCallback? onRoomAdded;

  const AddRoomPage({super.key, this.onRoomAdded});

  @override
  State<AddRoomPage> createState() => _AddRoomPageState();
}

class _AddRoomPageState extends State<AddRoomPage> {
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _imageFilename = '';
  int _capacity = 1;
  bool _isFree = true;
  bool _isSaving = false;

  // Ensure we always use filename only (strip assets/ prefix or any folders)
  String _filenameOnly(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'room1.jpg';
    final normalized = v.replaceAll('\\', '/');
    final last = normalized.split('/').last;
    return last.isEmpty ? 'room1.jpg' : last;
  }

  @override
  void dispose() {
    _typeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  ImageProvider _imageProvider() {
    final name = _filenameOnly(_imageFilename);
    if (name.isEmpty) return const AssetImage('assets/images/room1.jpg');
    return AssetImage('assets/images/$name');
  }

  Future<void> _promptImageFilename() async {
    final controller = TextEditingController(text: _imageFilename);
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
      setState(() => _imageFilename = _filenameOnly(picked));
    }
  }

  Future<void> _save() async {
    // Close keyboard first to prevent dialog issues
    FocusScope.of(context).unfocus();

    if (_typeController.text.trim().isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Warning'),
          content: const Text('Please enter the room name'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Always sanitize image to filename only before sending
      final imgFilename = _filenameOnly(_imageFilename);

      final payload = {
        'room_name': _typeController.text.trim(),
        'room_description': _descController.text.trim(),
        'room_status': _isFree ? 'free' : 'disabled',
        'capacity': _capacity,
        'image': imgFilename,
      };

      print('🚀 Sending createRoom request...');
      print('📦 Payload: $payload');

      // Add timeout to prevent infinite waiting
      final result = await createRoom(payload).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('⏱️ Request timeout!');
          return {
            'error': 'Connection timeout. Please check your backend server.',
          };
        },
      );

      print('✅ createRoom response: $result');

      if (!mounted) return;

      // Check for error first
      if (result != null && result.containsKey('error')) {
        print('❌ Error in response: ${result['error']}');
        setState(() => _isSaving = false);
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('❌ Error'),
            content: Text(result['error']),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Check for success
      if (result != null &&
          (result.containsKey('message') || result.containsKey('room_id'))) {
        final msg = result['message'] ?? 'Room created successfully!';
        print('✅ Success: $msg');
        print('📱 Showing success dialog...');

        // Reset loading state before showing dialog
        setState(() => _isSaving = false);

        // Show success popup
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Text('✅ Success'),
            content: Text(msg),
            actions: [
              TextButton(
                onPressed: () {
                  print('👆 OK button clicked');
                  Navigator.of(ctx).pop();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );

        print('📱 Dialog closed');

        // Navigate back to home after dialog closes
        if (mounted) {
          print('🏠 Calling onRoomAdded callback...');
          // ใช้ callback แทน Navigator.pop เพราะเป็น tab ไม่ใช่ pushed route
          widget.onRoomAdded?.call();

          // ถ้าเป็น pushed route (มี route ให้ pop) ก็ pop กลับไป
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }

          // Clear form
          _typeController.clear();
          _descController.clear();
          setState(() {
            _imageFilename = '';
            _capacity = 1;
            _isFree = true;
          });
        }
        return;
      }

      // Fallback - no clear success or error
      print('⚠️ Unexpected response format: $result');
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('⚠️ Warning'),
          content: const Text(
            'Server returned unexpected response. Please check if room was created.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      print('🔥 Exception in _save(): $e');
      if (!mounted) return;

      setState(() => _isSaving = false);

      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('❌ Error'),
          content: Text(
            'Network error: $e\n\nPlease check:\n1. Backend server is running\n2. API endpoint is correct',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 1. AppBar title updated to match image
      appBar: AppBar(title: const Text("Add room")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // 2. Image Upload Area - Tap to type filename
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
            const SizedBox(height: 16),

            // 3. Row for Type and Quantity
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // "Type's room" input
                Expanded(
                  flex: 3, // Gives more space to the text field
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Label above the text field
                      Text(
                        "Room name",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _typeController,
                        decoration: const InputDecoration(
                          hintText: "Room name...", // Updated hint
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Quantity
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capacity',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              onPressed: () {
                                if (_capacity > 1) setState(() => _capacity--);
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
                              onPressed: () => setState(() => _capacity++),
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
            const SizedBox(height: 16),

            // 3.5 Room Status Toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Room Status',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Row(
                  children: [
                    Text(
                      _isFree ? 'Free' : 'Disabled',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _isFree ? Colors.green : Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _isFree,
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.red,
                      onChanged: (v) => setState(() => _isFree = v),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. Description Field
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Label above the text field
                Text(
                  "Description",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
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
              onPressed: _isSaving ? null : _save,
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
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
