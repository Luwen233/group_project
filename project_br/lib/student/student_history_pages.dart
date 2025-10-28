import 'package:flutter/material.dart';

class StudentHistoryPages extends StatefulWidget {
  const StudentHistoryPages({super.key});

  @override
  State<StudentHistoryPages> createState() => _StudentHistoryPagesState();
}

class _StudentHistoryPagesState extends State<StudentHistoryPages> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
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
                Divider(thickness: 1, height: 0),
                Padding(
                  padding: EdgeInsets.all(16),
                  child: TabBar(tabs: [Tab(text: 'All',)]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
