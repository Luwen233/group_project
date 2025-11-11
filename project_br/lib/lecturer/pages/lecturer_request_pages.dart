import 'package:flutter/material.dart';
import 'package:project_br/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:project_br/lecturer/pages/booking_model.dart';

class LecturerRequestPages extends StatefulWidget {
  const LecturerRequestPages({super.key});

  @override
  State<LecturerRequestPages> createState() => _LecturerRequestPagesState();
}

class _LecturerRequestPagesState extends State<LecturerRequestPages> {
  List<BookingRequest> _pendingRequests = [];
  bool _isWaiting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    if (!_isWaiting) {
      setState(() => _isWaiting = true);
    }

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/bookings/requests');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _pendingRequests = data
                .map((json) => BookingRequest.fromJson(json))
                .toList();
            _isWaiting = false;
            _error = null;
          });
        }
      } else {
        throw Exception('Server error: ${res.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst("Exception: ", "");
          _isWaiting = false;
        });
      }
    }
  }

  Future<void> _approveRequest(BookingRequest request) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/bookings/${request.id}/approve',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final res = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        await _loadRequests(); // Refresh the list
      }
    } catch (e) {
      print('🔥 approveRequest() error: $e');
    }
  }

  Future<void> _rejectRequest(BookingRequest request, String reason) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/bookings/${request.id}/reject');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final res = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reject_reason': reason}),
      );

      if (res.statusCode == 200) {
        await _loadRequests(); // Refresh the list
      }
    } catch (e) {
      print('🔥 rejectRequest() error: $e');
    }
  }

  final TextEditingController _rejectReasonController = TextEditingController();

  void _showRejectDialog(BookingRequest requestToReject) {
    _rejectReasonController.clear();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Reason Of Request :",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rejectReasonController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Description...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xffDB5151),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await _rejectRequest(
                        requestToReject,
                        _rejectReasonController.text,
                      );
                      if (mounted) Navigator.pop(context);
                    },
                    child: const Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 4. MAIN BUILD METHOD ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Coming Request",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(height: 1, color: Colors.grey[300]),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildBodyContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent() {
    if (_isWaiting) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: const TextStyle(color: Color(0xffDB5151))),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadRequests,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_pendingRequests.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      itemCount: _pendingRequests.length,
      itemBuilder: (_, index) => _buildRequestCard(_pendingRequests[index]),
    );
  }

  Widget _buildEmptyState() =>
      const Center(child: Text("No upcoming requests yet."));

  Widget _buildRequestCard(BookingRequest request) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Text(
                  "Request ID : ${request.id}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "Date: ${request.formattedDate}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Time: ${request.formattedTime}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Divider(color: Colors.grey[300]),

          // Middle
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: request.image.startsWith("http")
                    ? Image.network(
                        request.image,
                        width: 160,
                        height: 110,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        request.image,
                        width: 160,
                        height: 110,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.room_outlined, size: 18),
                        Text(
                          request.roomName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded, size: 18),
                        const Text(
                          "Booked By:",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),

                    Text(
                      request.bookedBy,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.domain_verification_outlined, size: 18),
                        const Text(
                          "Requested On:",
                          style: TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      request.formattedRequestedOn,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(color: Colors.grey[300]),

          // Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _showRejectDialog(request),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xffDB5151),
                  ),
                  child: const Text(
                    "Reject",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    // 4. Calls the method inside this class
                    await _approveRequest(request);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff3BCB53),
                  ),
                  child: const Text(
                    "Approve",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }
}
