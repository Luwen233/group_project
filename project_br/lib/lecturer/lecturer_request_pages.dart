import 'package:flutter/material.dart';
import 'package:project_br/lecturer/booking_model.dart';
import 'package:project_br/lecturer/booking_notifiers.dart';
import 'package:project_br/lecturer/booking_service.dart';

class LecturerRequestPages extends StatefulWidget {
  const LecturerRequestPages({super.key});

  @override
  State<LecturerRequestPages> createState() => _LecturerRequestPagesState();
}

class _LecturerRequestPagesState extends State<LecturerRequestPages> {
  @override
  void initState() {
    super.initState();
    fetchPendingRequests();
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
                "Reject Of Request :",
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
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () async {
                      await rejectRequest(
                        requestToReject,
                        _rejectReasonController.text,
                      );
                      await fetchPendingRequests();
                      setState(() {}); // ✅ Refresh UI
                      Navigator.pop(context);
                    },
                    child: const Text("Confirm"),
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
              child: ValueListenableBuilder<List<BookingRequest>>(
                valueListenable: pendingRequestsNotifier,
                builder: (context, list, _) {
                  if (list.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (_, index) => _buildRequestCard(list[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    "Time: ${request.formattedTime}",
                    style: const TextStyle(fontSize: 12),
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
                    const Text("Booked By:", style: TextStyle(fontSize: 13)),
                    Text(
                      request.bookedBy,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text("Requested On:", style: TextStyle(fontSize: 13)),
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
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text("Reject"),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await approveRequest(request);
                    await fetchPendingRequests();
                    setState(() {}); // ✅ Refresh UI
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  child: const Text("Approve"),
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
