import 'package:flutter/material.dart';
import '../../core/strings.dart';
import '../../core/widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navDashboard),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          StatCard(
            title: 'Monthly Collection',
            value: 'Rs 0',
            subtitle: 'Collected this month',
            isGradient: true,
            icon: Icons.account_balance_wallet_outlined,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Pending Dues',
                  value: 'Rs 0',
                  icon: Icons.hourglass_top_rounded,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Overdue Dues',
                  value: 'Rs 0',
                  icon: Icons.warning_amber_rounded,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Beds Occupancy',
                  value: '0 / 0',
                  icon: Icons.hotel_outlined,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Active Residents',
                  value: '0',
                  icon: Icons.people_outline_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
