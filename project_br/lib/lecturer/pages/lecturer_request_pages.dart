import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:project_br/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LecturerRequestPages extends StatefulWidget {
  const LecturerRequestPages({super.key});

  @override
  State<LecturerRequestPages> createState() => _LecturerRequestPagesState();
}

class _LecturerRequestPagesState extends State<LecturerRequestPages> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isWaiting = true;
  String? _error;

  final TextEditingController _rejectReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  @override
  void dispose() {
    _rejectReasonController.dispose();
    super.dispose();
  }

  String _mapSlotIdToTime(int? slotId) {
    switch (slotId) {
      case 1:
        return '08.00 - 10.00 AM';
      case 2:
        return '10.00 - 12.00 AM';
      case 3:
        return '01.00 - 03.00 PM';
      case 4:
        return '03.00 - 05.00 PM';
      default:
        return 'Unknown Time';
    }
  }

  String _formatRequestDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMM d, y').format(dt);
    } catch (e) {
      return dateStr;
    }
  }

  Future<void> _loadRequests() async {
    if (!_isWaiting) {
      setState(() => _isWaiting = true);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token'); 
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }
      final uri = Uri.parse('${ApiConfig.baseUrl}/bookings/requests');

      final res = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _pendingRequests = data.map<Map<String, dynamic>>((b) {
              final status =
                  (b['status'] ?? 'unknown').toString().toLowerCase();
              return {
                'id':
                    b['id']?.toString() ?? b['booking_id']?.toString() ?? 'N/A',
                'roomName': b['room_name'] ?? 'Unknown Room',
                'date': _formatRequestDate(b['booking_date']),
                'time': _mapSlotIdToTime(b['slot_id']),
                'status': status[0].toUpperCase() + status.substring(1),
                'reason': b['reason'] ?? 'No reason provided.', // Add default
                'actionDate': b['action_date'] ?? '', // 'formattedRequestedOn'
                'image': b['image'] ?? b['room_image'], // รองรับทั้งสอง key
                'name': b['booked_by_name'] ??
                    b['user_name'] ??
                    'Unknown', // 'bookedBy'
              };
            }).toList();
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

  Future<void> _approveRequest(Map<String, dynamic> request) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/bookings/${request['id']}/approve',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request has been approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadRequests(); // Refresh the list
      }
    } catch (e) {
      if (mounted) {
        _snack('Failed to approve request.');
      }
    }
  }

  Future<void> _rejectRequest(
    Map<String, dynamic> request,
    String reason,
  ) async {
    if (reason.trim().isEmpty) {
      _snack('Please enter the reason for rejection');
      return;
    }
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/bookings/${request['id']}/reject',
    );
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reject_reason': reason}),
      );

      if (res.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request has been rejected successfully'),
            backgroundColor: Color.fromARGB(255, 94, 28, 23),
          ),
        );
        await _loadRequests();
      }
    } catch (e) {
      if (mounted) {
        _snack('Failed to reject request.');
      }
    }
  }

  void _snack(String message, {Color color = const Color(0xffDB5151)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
  }

  Future<void> _approveDialog(Map<String, dynamic> request) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(
          Icons.check_circle_outline_rounded,
          color: Color(0xff3BCB53),
          size: 100,
        ),
        title: const Text('Confirm Approval'),
        content: const Text('Are you sure you want to approve this request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // close dialog
              _approveRequest(request);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(Map<String, dynamic> requestToReject) {
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
                "Reason for Rejection:", // Changed text
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _rejectReasonController,
                maxLines: 5,
                maxLength: 200,
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
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffDB5151),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () async {
                        final reason = _rejectReasonController.text;
                        if (mounted) Navigator.pop(context);
                        await _rejectRequest(
                          requestToReject,
                          reason,
                        );
                      },
                      child: const Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white),
                      ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          "Coming Request",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF7F7F7),
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
      itemBuilder: (_, index) => _buildMyNewCard(_pendingRequests[index]),
    );
  }

  Widget _buildEmptyState() => const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "No upcoming requests yet.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );

  Widget _buildMyNewCard(Map<String, dynamic> request) {
    final String imageUrl = (request['image'] as String?) ?? '';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(
          color: Color.fromARGB(255, 207, 207, 207),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "Request ID : ${request['id']}",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "Date: ${request['date']}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Time: ${request['time']}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 120,
            width: double.infinity,
            child: imageUrl.startsWith("http")
                ? Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                  )
                : Image.asset(
                    imageUrl.isNotEmpty
                        ? 'assets/images/$imageUrl'
                        : 'assets/images/placeholder.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        'assets/images/placeholder.png',
                        fit: BoxFit.cover,
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room Name
                    Flexible(
                      child: Text(
                        request['roomName'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Booked By
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.person_outline_rounded, size: 16),
                            const SizedBox(width: 4),
                            const Text(
                              "Booked By:",
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                        Text(
                          request['name'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Reason:',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  request['reason'],
                  style: const TextStyle(fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _showRejectDialog(request),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffDB5151),
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
                      await _approveDialog(request);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff3BCB53),
                    ),
                    child: const Text(
                      "Approve",
                      style: TextStyle(color: Colors.white),
                    ),
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
