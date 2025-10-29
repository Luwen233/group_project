class BookingService {
  static final List<Map<String, dynamic>> bookings = [
    // --- PENDING ---
    {
      'id': '00014',
      'roomName': 'Study Room',
      'image': 'assets/images/room1.jpg',
      'date': 'Wed 29 Oct 2025',
      'time': '03:00 - 05:00 PM',
      'name': 'Mr. John',
      'bookingDate': '01:12 AM',
      'status': 'Pending',
      'reason': 'Need a quiet place for project work.', 
    },

    // --- APPROVED ---
    {
      'id': '00013',
      'roomName': 'Study Room',
      'image': 'assets/images/room1.jpg',
      'date': 'Mon 22 Sep 2025',
      'time': '01:00 - 03:00 PM',
      'name': 'Mr. John',
      'bookingDate': '07:12 AM',
      'status': 'Approved',
      'approver': 'Mr. John',
      'actionDate': 'Sep 22, 2025',
      'reason': 'Study group meeting.', 
      // No lecturerNote for approved
    },

    // --- REJECTED ---
    {
      'id': '00012',
      'roomName': 'Law Study Room',
      'image': 'assets/images/room2.jpg',
      'date': 'Mon 22 Sep 2025',
      'time': '01:00 - 03:00 PM',
      'name': 'Mr. John',
      'bookingDate': '07:12 AM',
      'status': 'Rejected',
      'approver': 'Mr. Surapong',
      'actionDate': 'Sep 22, 2025',
      'reason': 'Need for mock trial practice.',
      'lecturerNote':
          'Room is reserved for official use during this time.', 
    },

    // --- CANCELLED ---
    {
      'id': '00011',
      'roomName': 'Meeting Room',
      'image': 'assets/images/room3.jpg',
      'date': 'Sun 11 Sep 2025',
      'time': '01:00 - 03:00 PM',
      'name': 'Mr. John',
      'bookingDate': '07:12 AM',
      'status': 'Cancelled',
      'approver': 'Mr. Kakaka',
      'actionDate': 'Sep 11, 2025',
      'reason': 'Team meeting.', 
      // No lecturerNote for cancelled
    },
  ];
}
