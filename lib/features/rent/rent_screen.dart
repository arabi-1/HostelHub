import 'package:flutter/material.dart';
import '../../core/strings.dart';
import '../../core/widgets/empty_state.dart';

class RentScreen extends StatelessWidget {
  const RentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navRent),
      ),
      body: const EmptyState(
        title: 'No Rent Dues',
        message: 'Active residents and generated charges will appear here.',
        icon: Icons.receipt_long_outlined,
      ),
    );
  }
}
