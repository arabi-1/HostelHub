import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../billing/widgets/trial_banner.dart';
import '../billing/widgets/write_lock_guard.dart';
import 'providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final recentPaymentsAsync = ref.watch(recentPaymentsProvider);
    final currencyFormat = NumberFormat('#,##0');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navDashboard),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () {
              ref.invalidate(dashboardSummaryProvider);
              ref.invalidate(recentPaymentsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const TrialBanner(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(dashboardSummaryProvider);
                ref.invalidate(recentPaymentsProvider);
                await Future.wait([
                  ref.read(dashboardSummaryProvider.future),
                  ref.read(recentPaymentsProvider.future),
                ]);
              },
              child: summaryAsync.when(
                loading: () => const LoadingView(message: 'Loading financial overview...'),
                error: (err, _) => ErrorView(
                  message: err.toString(),
                  onRetry: () {
                    ref.invalidate(dashboardSummaryProvider);
                    ref.invalidate(recentPaymentsProvider);
                  },
                ),
                data: (summary) {
                  if (summary.isEmpty) {
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        EmptyState(
                          title: 'Welcome to HostelHub',
                          message:
                              'Add your first room and resident to start tracking rent collection and bed occupancy.',
                          icon: Icons.hotel_outlined,
                          actionLabel: 'Add Resident',
                          onAction: () {
                            if (WriteLockGuard.checkAndNavigate(context, ref)) {
                              context.push('/residents/add');
                            }
                          },
                        ),
                      ],
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      // 1. Signature Teal Gradient Summary Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.25),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'MONTHLY COLLECTION',
                                  style: AppText.labelMedium.copyWith(
                                    color: Colors.white70,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.calendar_month_rounded, size: 14, color: Colors.white),
                                      const SizedBox(width: 4),
                                      Text(
                                        DateFormat('MMM yyyy').format(DateTime.now()),
                                        style: AppText.bodySmall.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Rs ${currencyFormat.format(summary.collected.toInt())}',
                              style: AppText.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 32,
                              ),
                            ),
                            // Gold accent underline
                            Container(
                              margin: const EdgeInsets.only(top: 6, bottom: 12),
                              height: 3.5,
                              width: 72,
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              'Total Billed: Rs ${currencyFormat.format(summary.billed.toInt())}',
                              style: AppText.bodyMedium.copyWith(color: Colors.white.withValues(alpha: 0.85)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 2. Financial & Occupancy Breakdown Tiles
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              title: 'Pending Dues',
                              value: 'Rs ${currencyFormat.format(summary.pending.toInt())}',
                              icon: Icons.hourglass_top_rounded,
                              iconColor: AppColors.warning,
                              iconBg: AppColors.warningContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              title: 'Overdue Dues',
                              value: 'Rs ${currencyFormat.format(summary.overdue.toInt())}',
                              icon: Icons.warning_amber_rounded,
                              iconColor: AppColors.danger,
                              iconBg: AppColors.dangerContainer,
                              highlightColor: summary.overdue > 0 ? AppColors.danger : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              title: 'Beds Occupancy',
                              value: '${summary.bedsOccupied} / ${summary.bedsTotal}',
                              badge: '${summary.occupancyRate.toStringAsFixed(0)}%',
                              icon: Icons.hotel_outlined,
                              iconColor: AppColors.primary,
                              iconBg: AppColors.primaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatTile(
                              title: 'Active Residents',
                              value: '${summary.activeResidents}',
                              icon: Icons.people_outline_rounded,
                              iconColor: AppColors.primary,
                              iconBg: AppColors.primaryContainer,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 3. Quick Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                if (WriteLockGuard.checkAndNavigate(context, ref)) {
                                  context.push('/residents/add');
                                }
                              },
                              icon: const Icon(Icons.person_add_rounded, size: 20),
                              label: const Text('Add Resident'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.tonalIcon(
                              onPressed: () {
                                context.go('/rent');
                              },
                              icon: const Icon(Icons.payments_rounded, size: 20),
                              label: const Text('Record Payment'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 4. Recent 5 Payments Feed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Payments',
                            style: AppText.titleLarge.copyWith(fontWeight: FontWeight.bold),
                          ),
                          TextButton(
                            onPressed: () => context.go('/rent'),
                            child: const Text('View All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      recentPaymentsAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: (err, _) => Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            'Could not load recent payments: $err',
                            style: AppText.bodySmall.copyWith(color: AppColors.danger),
                          ),
                        ),
                        data: (payments) {
                          if (payments.isEmpty) {
                            return Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                              ),
                              child: Center(
                                child: Text(
                                  'No payments recorded yet.',
                                  style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                                ),
                              ),
                            );
                          }

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: payments.length,
                              separatorBuilder: (_, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = payments[index];
                                final p = item.payment;

                                return ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primaryContainer,
                                    child: const Icon(
                                      Icons.receipt_rounded,
                                      size: 20,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  title: Text(
                                    item.residentName,
                                    style: AppText.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  subtitle: Text(
                                    '${p.receiptNo} • ${dateFormat.format(p.paidOn)} • ${p.method}',
                                    style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Rs ${currencyFormat.format(p.amount.toInt())}',
                                        style: AppText.bodyLarge.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.muted),
                                    ],
                                  ),
                                  onTap: () {
                                    context.push('/receipts/${p.id}');
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String title;
  final String value;
  final String? badge;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color? highlightColor;

  const _StatTile({
    required this.title,
    required this.value,
    this.badge,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: iconBg,
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge!,
                      style: AppText.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppText.titleLarge.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: highlightColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: AppText.bodySmall.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
