import 'package:flutter/material.dart';
import '../../core/strings.dart';
import '../../core/widgets/empty_state.dart';

class RoomsScreen extends StatelessWidget {
  const RoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navRooms),
      ),
      body: const EmptyState(
        title: 'No Rooms Added',
        message: 'Create properties and rooms to start managing bed capacities.',
        icon: Icons.hotel_outlined,
        actionLabel: 'Add Room',
      ),
    );
  }
}
