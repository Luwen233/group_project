import 'package:flutter/material.dart';
import 'package:project_br/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LecturerRequestPages extends StatefulWidget {
  const LecturerRequestPages({super.key});

  @override
  State<LecturerRequestPages> createState() => _LecturerRequestPagesState();
}

class _LecturerRequestPagesState extends State<LecturerRequestPages> {
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _isWaiting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequests();
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
      final res = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (mounted) {
          setState(() {
            _pendingRequests = data.map<Map<String, dynamic>>((b) {
              final status = (b['status'] ?? 'unknown')
                  .toString()
                  .toLowerCase();
              return {
                'id':
                    b['id']?.toString() ?? b['booking_id']?.toString() ?? 'N/A',
                'roomName': b['room_name'] ?? 'Unknown Room',
                'date': (b['booking_date'] ?? '').toString().split('T')[0],
                'time': _mapSlotIdToTime(b['slot_id']),
                'status': status[0].toUpperCase() + status.substring(1),
                'reason': b['reason'] ?? '',
                'actionDate': b['action_date'] ?? '', // 'formattedRequestedOn'
                'image': b['image'] ?? b['room_image'], // รองรับทั้งสอง key
                'name':
                    b['booked_by_name'] ??
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
      final res = await http.patch(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        await _loadRequests(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request has approved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('🔥 approveRequest() error: $e');
    }
  }

  Future<void> _rejectRequest(Map<String, dynamic> request,String reason,
  ) async {
    if (reason.trim().isEmpty){
      _snack('Please enter the reason for reject');
      return;
    }
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/bookings/${request['id']}/reject',
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
        body: jsonEncode({'reject_reason': reason}),
      );

      if (res.statusCode == 200) {
        await _loadRequests(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request has rejected successfully'),
            backgroundColor: Color.fromARGB(255, 94, 28, 23),
          ),
        );
      }
    } catch (e) {
      print('🔥 rejectRequest() error: $e');
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
        title: const Text('Confirm approval'),
        content: Text('Are you sure you want to approved this request?'),
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

  final TextEditingController _rejectReasonController = TextEditingController();

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
                "Reason Of Request :",
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
                        backgroundColor: Color(0xffDB5151),
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

  Widget _buildEmptyState() =>
      const Center(child: Text("No upcoming requests yet."));

  Widget _buildMyNewCard(Map<String, dynamic> request) {
    final String statusText = "Status";
    final Color statusColor = Colors.grey;
    final String imageUrl = (request['image'] as String?) ?? '';
    print(request);

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
      child: Column(
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: imageUrl.startsWith("http")
                  ? Image.network(
                      imageUrl,
                      width: 160,
                      height: 110,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      imageUrl.isNotEmpty
                          ? 'assets/images/$imageUrl'
                          : 'assets/images/placeholder.png',
                      width: 160,
                      height: 110,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/images/placeholder.png',
                          fit: BoxFit.cover,
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            request['roomName'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Spacer(),
                      Row(
                        children: [
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
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(children: [Text('Reason:')]),
                Row(children: [Text(request['reason'])]),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
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
                      // await _approveRequest(request);
                      await _approveDialog(request);
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
