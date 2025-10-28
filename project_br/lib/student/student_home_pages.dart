import 'package:flutter/material.dart';
import 'package:project_br/student/student_room_detail_pages.dart';

class StudentHomePages extends StatefulWidget {
  const StudentHomePages({super.key});

  @override
  State<StudentHomePages> createState() => _StudentHomePagesState();
}

class _StudentHomePagesState extends State<StudentHomePages> {
  final List<Map<String, dynamic>> _rooms = [
    {
      'name': 'Study Room A',
      'status': 'Free',
      'image': 'assets/images/room1.jpg',
    },
    {
      'name': 'Law Study Room',
      'status': 'Disable',
      'image': 'assets/images/room2.jpg',
    },
    {'name': 'Room B101', 'status': 'Free', 'image': 'assets/images/room3.jpg'},
    {
      'name': 'Room B102',
      'status': 'Disable',
      'image': 'assets/images/room4.jpg',
    },
    {
      'name': 'Law Study Room',
      'status': 'Full',
      'image': 'assets/images/room2.jpg',
    },
    {
      'name': 'Law Study Room',
      'status': 'Full',
      'image': 'assets/images/room2.jpg',
    },
  ];

  final _searchBox = TextEditingController();

  List<Map<String, dynamic>> _filteredRooms() {
    final q = _searchBox.text.trim().toLowerCase();
    if (q.isEmpty) return _rooms;
    return _rooms
        .where((r) => (r['name'] as String).toLowerCase().contains(q))
        .toList();
  }

  @override
  void dispose() {
    _searchBox.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3C9CBF),
        toolbarHeight: 284,
        centerTitle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
        ),

        flexibleSpace: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      height: 40,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Color.fromARGB(80, 33, 33, 40),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Sep 20, 2025',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    ),

                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.black, size: 40),
                        SizedBox(width: 6),
                        Text(
                          'Mr. John',
                          style: TextStyle(color: Colors.black, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 150),
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: TextField(
                    controller: _searchBox,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Study Room',
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search),
                      contentPadding: EdgeInsets.all(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: GridView.builder(
          itemCount: _filteredRooms().length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 16,
            childAspectRatio: 3 / 3.7,
          ),
          itemBuilder: (context, index) {
            final room = _filteredRooms()[index];
            final isFree = (room['status'] as String) == 'Free';

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RoomDetailPage(room: room)),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      child: Image.asset(
                        room['image'] as String,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Text(
                        room['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 12,
                        right: 12,
                        bottom: 15,
                      ),
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isFree
                                ? Color(0xff3BCB53)
                                : Color(0xff4E534E),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            room['status'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
