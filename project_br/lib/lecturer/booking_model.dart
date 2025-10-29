class BookingRequest {
  final String id;
  final String roomName;
  final String image;
  final String date;
  final String time;
  final String bookedBy;
  final String requestedOn;
  String status; // 'pending', 'approved', 'rejected'
  String? rejectReason;
  String? approvedBy; // Keep track of who approved
  String?
  approvedOn; // Keep track of when it was approved (as String for display)
  String?
  rejectedOn; // Keep track of when it was rejected (as String for display)
  String?
  processedBy; // To store who processed it (e.g., "System" or Lecturer ID)
  // ⭐️ เพิ่ม Field นี้
  final DateTime?
  decisionTimestamp; // Store the actual DateTime of the decision

  BookingRequest({
    required this.id,
    required this.roomName,
    required this.image,
    required this.date,
    required this.time,
    required this.bookedBy,
    required this.requestedOn,
    this.status = 'pending',
    this.rejectReason,
    this.approvedBy,
    this.approvedOn,
    this.rejectedOn,
    this.processedBy,
    // ⭐️ เพิ่มใน Constructor
    this.decisionTimestamp,
  });

  // ⭐️ เพิ่ม copyWith เพื่อให้ง่ายต่อการอัปเดต
  BookingRequest copyWith({
    String? id,
    String? roomName,
    String? image,
    String? date,
    String? time,
    String? bookedBy,
    String? requestedOn,
    String? status,
    String? rejectReason,
    String? approvedBy,
    String? approvedOn,
    String? rejectedOn,
    String? processedBy,
    DateTime? decisionTimestamp,
  }) {
    return BookingRequest(
      id: id ?? this.id,
      roomName: roomName ?? this.roomName,
      image: image ?? this.image,
      date: date ?? this.date,
      time: time ?? this.time,
      bookedBy: bookedBy ?? this.bookedBy,
      requestedOn: requestedOn ?? this.requestedOn,
      status: status ?? this.status,
      // Handle nullable fields carefully in copyWith
      rejectReason: rejectReason ?? this.rejectReason,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedOn: approvedOn ?? this.approvedOn,
      rejectedOn: rejectedOn ?? this.rejectedOn,
      processedBy: processedBy ?? this.processedBy,
      decisionTimestamp: decisionTimestamp ?? this.decisionTimestamp,
    );
  }
}
