import 'dart:math';

import 'package:flutter/material.dart';

class StudentBookingPages extends StatefulWidget {
  const StudentBookingPages({super.key});

  @override
  State<StudentBookingPages> createState() => _StudentBookingPagesState();
}

class _StudentBookingPagesState extends State<StudentBookingPages> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFF7F7F7),
        elevation: 3,
        shadowColor: Colors.black54,
        title: Text(
          'My Books',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(67),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Divider(thickness: sqrt1_2, height: 0),
              Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Upcoming',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xff3C9CBF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
