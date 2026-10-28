import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/payment.dart';
import '../../rent/providers/rent_providers.dart';

@immutable
class DashboardSummary {
  final double billed;
  final double collected;
  final double pending;
  final double overdue;
  final int bedsTotal;
  final int bedsOccupied;
  final int activeResidents;

  const DashboardSummary({
    required this.billed,
    required this.collected,
    required this.pending,
    required this.overdue,
    required this.bedsTotal,
    required this.bedsOccupied,
    required this.activeResidents,
  });

  double get occupancyRate =>
      bedsTotal > 0 ? (bedsOccupied / bedsTotal) * 100 : 0.0;

  bool get isEmpty => bedsTotal == 0 && activeResidents == 0;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      billed: (json['billed'] as num?)?.toDouble() ?? 0.0,
      collected: (json['collected'] as num?)?.toDouble() ?? 0.0,
      pending: (json['pending'] as num?)?.toDouble() ?? 0.0,
      overdue: (json['overdue'] as num?)?.toDouble() ?? 0.0,
      bedsTotal: (json['beds_total'] as num?)?.toInt() ?? 0,
      bedsOccupied: (json['beds_occupied'] as num?)?.toInt() ?? 0,
      activeResidents: (json['active_residents'] as num?)?.toInt() ?? 0,
    );
  }

  factory DashboardSummary.empty() => const DashboardSummary(
        billed: 0,
        collected: 0,
        pending: 0,
        overdue: 0,
        bedsTotal: 0,
        bedsOccupied: 0,
        activeResidents: 0,
      );
}

@immutable
class RecentPaymentFeedItem {
  final Payment payment;
  final String residentName;

  const RecentPaymentFeedItem({
    required this.payment,
    required this.residentName,
  });
}

/// Fetches financial and occupancy summary for the dashboard
final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final rentRepo = ref.watch(rentRepoProvider);
  final data = await rentRepo.getDashboardSummary();
  return DashboardSummary.fromJson(data);
});

/// Fetches the recent 5 payments with resident names
final recentPaymentsProvider =
    FutureProvider.autoDispose<List<RecentPaymentFeedItem>>((ref) async {
  final paymentRepo = ref.watch(paymentRepoProvider);
  final rows = await paymentRepo.getRecentPayments(limit: 5);

  return rows.map((row) {
    final payment = Payment.fromJson(row);
    final residentMap = row['residents'] as Map<String, dynamic>?;
    final residentName = residentMap?['full_name'] as String? ?? 'Resident';

    return RecentPaymentFeedItem(
      payment: payment,
      residentName: residentName,
    );
  }).toList();
});
