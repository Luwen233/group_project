import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:project_br/student/booking_service.dart';

//class's time slots
class TimeSlot {
  final String displayTime;
  final TimeOfDay endTime;
  TimeSlot({required this.displayTime, required this.endTime});
}

class RoomDetailPage extends StatefulWidget {
  final Map<String, dynamic> room;
  const RoomDetailPage({super.key, required this.room});

  @override
  State<RoomDetailPage> createState() => _RoomDetailPageState();
}

class _RoomDetailPageState extends State<RoomDetailPage> {
  TimeSlot? _selectedSlot;
  final _reasonController = TextEditingController();

  final List<TimeSlot> _timeSlots = [
    TimeSlot(
      displayTime: '08.00 - 10.00 AM',
      endTime: const TimeOfDay(hour: 10, minute: 0), 
    ),
    TimeSlot(
      displayTime: '10.00 - 12.00 AM',
      endTime: const TimeOfDay(hour: 12, minute: 0),
    ),
    TimeSlot(
      displayTime: '01.00 - 03.00 PM',
      endTime: const TimeOfDay(hour: 15, minute: 0), //15 > 3pm
    ),
    TimeSlot(
      displayTime: '03.00 - 05.00 PM',
      endTime: const TimeOfDay(hour: 17, minute: 0), //17> 5pm
    ),
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  double _timeToDouble(TimeOfDay time) {
    return time.hour + time.minute / 60.0;
  }

  void _showBookingAlert(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          icon: Icon(
            Icons.check_circle_outline_rounded,
            color: Color(0xff2EC200),
            size: 100,
          ),
          title: const Text('Booking Request Sent!'),
          content: const Text('You can check the status in My Bookings.'),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                // Get current date and time for booking
                final DateTime now = DateTime.now();
                final String bookingDate = DateFormat(
                  'h:mm a',
                ).format(now); // "1:01 AM"
                final String eventDate = DateFormat(
                  'E d MMM yyyy',
                ).format(now); // "Wed 29 Oct 2025"

                //from student_service
                final newBooking = {
                  'id': '000${BookingService.bookings.length + 1}',
                  'roomName': widget.room['name'],
                  'image': widget.room['image'],
                  'date': eventDate,
                  'time': _selectedSlot!.displayTime, 
                  'name': 'Mr. John', 
                  'bookingDate': bookingDate,
                  'status': 'Pending',
                };

                setState(() {
                  BookingService.bookings.add(newBooking);
                });

                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please select a time and enter a reason.'),
        backgroundColor: Colors.red,
        padding: EdgeInsets.all(10),
        duration: Durations.extralong3,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String roomStatus = widget.room['status'] as String;
    final bool isRoomBookable = (roomStatus == 'Free');
    const Color primaryBlue = Color(0xFF3C9CBF);
    const Color lightGrey = Color.fromARGB(115, 236, 236, 236);
    final currentTimeAsDouble = _timeToDouble(TimeOfDay.now());

    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(1),
          child: Row(
            children: [
              const Text(
                'Rooms Left',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(width: 8),
              const Text(
                '2',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFE53935),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: isRoomBookable
                      ? () {
                          if (_selectedSlot != null &&
                              _reasonController.text.isNotEmpty) {
                            _showBookingAlert(context);
                          } else {
                            _showErrorSnackbar(context);
                          }
                        }
                      : null, // not bookable
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRoomBookable
                        ? primaryBlue
                        : Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    isRoomBookable
                        ? 'Book Now'
                        : roomStatus, // Shows "Full" / "Disable"
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                widget.room['image'],
                height: 250.0,
                width: double.infinity,
                fit: BoxFit.cover,
                color: Colors.black12,
                colorBlendMode: BlendMode.darken,
              ),
              Positioned(
                top: 40.0,
                left: 10.0,
                child: CircleAvatar(
                  backgroundColor: Colors.black12,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.room['name'],
                          style: const TextStyle(
                            fontSize: 25,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isRoomBookable
                                ? const Color(0xff3BCB53)
                                : const Color(0xff4E534E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            roomStatus,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      Icons.people_outline_rounded,
                      'Room Capacity',
                      '6 People',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor.',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: lightGrey, thickness: 10),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Time Available'),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      alignment: WrapAlignment.center,
                      children: _timeSlots.map((slot) {
                        final bool isTimeInFuture =
                            currentTimeAsDouble < _timeToDouble(slot.endTime);
                        final bool isSlotBookable =
                            isRoomBookable && isTimeInFuture;
                        final bool isSelected = (_selectedSlot == slot);

                        return _buildTimeChip(
                          slot: slot,
                          isSelected: isSelected,
                          isBookable: isSlotBookable,
                          primaryBlue: primaryBlue,
                          lightGrey: lightGrey,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: lightGrey, thickness: 10),
                    const SizedBox(height: 16),
                    _buildSectionHeader('Reason Booking'),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _reasonController,
                      maxLines: 3,
                      maxLength: 100,
                      enabled: isRoomBookable,
                      decoration: InputDecoration(
                        hintText: isRoomBookable
                            ? 'Types Reason To Booking'
                            : 'This room is not available for booking',
                        fillColor: lightGrey,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //widget 

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[600]),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTimeChip({
    required TimeSlot slot,
    required bool isSelected,
    required bool isBookable,
    required Color primaryBlue,
    required Color lightGrey,
  }) {
    Color chipColor;
    Color textColor;

    if (isBookable) {
      chipColor = isSelected ? primaryBlue : lightGrey;
      textColor = isSelected ? Colors.white : Colors.black87;
    } else {
      //for bug
      chipColor = Colors.grey[300]!;
      textColor = Colors.grey[500]!;
    }

    return GestureDetector(
      onTap: () {
        if (isBookable) {
          setState(() {
            _selectedSlot = slot;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: chipColor,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          slot.displayTime,
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
