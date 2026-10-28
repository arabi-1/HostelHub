import 'package:flutter/material.dart';
import '../../core/strings.dart';
import '../../core/widgets/empty_state.dart';

class ResidentsScreen extends StatelessWidget {
  const ResidentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navResidents),
      ),
      body: const EmptyState(
        title: 'No Residents Yet',
        message: 'Add residents to assign rooms and track rent collection.',
        icon: Icons.people_outline_rounded,
        actionLabel: 'Add Resident',
      ),
    );
  }
}
