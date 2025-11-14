import 'package:flutter/material.dart';

ValueNotifier<int> selectedPageNotifer = ValueNotifier(0);

final reloadRoomsNotifier = ValueNotifier(0);

enum UserRole { lecturer, staff }

final tapPendingNotifier = ValueNotifier(1);
