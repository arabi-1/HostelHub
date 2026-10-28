import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../core/widgets/status_chip.dart';
import '../../data/models/rent_charge.dart';
import '../../data/models/resident.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/widgets/write_lock_guard.dart';
import '../receipts/services/whatsapp_service.dart';
import 'providers/rent_providers.dart';
import 'record_payment_sheet.dart';

class RentScreen extends ConsumerWidget {
  const RentScreen({super.key});

  Future<void> _sendWhatsAppReminder(
    BuildContext context,
    WidgetRef ref,
    RentCharge charge,
    Resident resident,
  ) async {
    final profile = await ref.read(currentProfileProvider.future);
    final bName = profile?.businessName;
    final businessName = (bName != null && bName.trim().isNotEmpty) ? bName.trim() : 'HostelHub';

    final message = WhatsAppService.buildReminderMessage(
      residentName: resident.fullName,
      businessName: businessName,
      balance: charge.balance,
      period: charge.period,
      dueDate: charge.dueDate,
      isOverdue: charge.status == 'overdue',
    );

    if (context.mounted) {
      await WhatsAppService.launchOrCopy(
        context: context,
        phone: resident.phone,
        message: message,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedRentMonthProvider);
    final chargesAsync = ref.watch(filteredChargesProvider);
    final summary = ref.watch(rentMonthSummaryProvider);
    final currentFilter = ref.watch(rentFilterProvider);

    final monthFormat = DateFormat('MMMM yyyy');
    final currencyFormatter = NumberFormat('#,##0');
    final dateFormat = DateFormat('dd MMM');

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navRent),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Month Switcher Header
          Container(
            color: Theme.of(context).cardColor,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  tooltip: 'Previous Month',
                  onPressed: () => ref.read(selectedRentMonthProvider.notifier).previousMonth(),
                ),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedMonth,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      ref.read(selectedRentMonthProvider.notifier).setMonth(picked);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, size: 20, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          monthFormat.format(selectedMonth),
                          style: AppText.titleMedium.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  tooltip: 'Next Month',
                  onPressed: () => ref.read(selectedRentMonthProvider.notifier).nextMonth(),
                ),
              ],
            ),
          ),

          // Summary Statistics Counters Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.background,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSummaryBadge(
                    context: context,
                    ref: ref,
                    label: 'Overdue',
                    count: summary.countOverdue,
                    amount: summary.totalOverdue,
                    color: AppColors.danger,
                    filterKey: 'overdue',
                    isSelected: currentFilter == 'overdue',
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryBadge(
                    context: context,
                    ref: ref,
                    label: 'Pending',
                    count: summary.countPending,
                    amount: summary.totalPending,
                    color: AppColors.warning,
                    filterKey: 'pending',
                    isSelected: currentFilter == 'pending',
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryBadge(
                    context: context,
                    ref: ref,
                    label: 'Partial',
                    count: summary.countPartial,
                    amount: 0,
                    color: AppColors.accent,
                    filterKey: 'partial',
                    isSelected: currentFilter == 'partial',
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryBadge(
                    context: context,
                    ref: ref,
                    label: 'Paid',
                    count: summary.countPaid,
                    amount: summary.totalCollected,
                    color: AppColors.success,
                    filterKey: 'paid',
                    isSelected: currentFilter == 'paid',
                  ),
                ],
              ),
            ),
          ),

          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip(ref, 'All', 'all', currentFilter),
                const SizedBox(width: 8),
                _buildFilterChip(ref, 'Overdue', 'overdue', currentFilter),
                const SizedBox(width: 8),
                _buildFilterChip(ref, 'Pending', 'pending', currentFilter),
                const SizedBox(width: 8),
                _buildFilterChip(ref, 'Paid', 'paid', currentFilter),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.muted),
                  tooltip: 'Refresh Charges',
                  onPressed: () => ref.invalidate(monthlyChargesProvider),
                ),
              ],
            ),
          ),

          // Charges List
          Expanded(
            child: chargesAsync.when(
              loading: () => const LoadingView(message: 'Loading monthly rent dues...'),
              error: (err, _) => ErrorView(
                message: err.toString(),
                onRetry: () => ref.refresh(monthlyChargesProvider),
              ),
              data: (charges) {
                if (charges.isEmpty) {
                  return EmptyState(
                    title: 'No Rent Charges',
                    message: currentFilter == 'all'
                        ? 'No active residents or charges for ${monthFormat.format(selectedMonth)}.'
                        : 'No charges matching filter "$currentFilter".',
                    icon: Icons.receipt_long_outlined,
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 4, bottom: 24),
                  itemCount: charges.length,
                  separatorBuilder: (_, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = charges[index];
                    final c = item.charge;
                    final resident = item.resident;
                    final room = item.room;

                    final residentName = resident?.fullName ?? 'Unknown Resident';
                    final roomLabel = room != null ? 'Room ${room.roomNumber}' : 'No Room';
                    final isFullyPaid = c.balance <= 0;

                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          if (resident != null) {
                            context.push('/residents/${resident.id}/ledger');
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: AppColors.primaryContainer,
                                    child: Text(
                                      residentName.isNotEmpty ? residentName[0].toUpperCase() : 'R',
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          residentName,
                                          style: AppText.titleLarge.copyWith(fontSize: 16),
                                        ),
                                        Text(
                                          roomLabel,
                                          style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  StatusChip.fromString(c.status),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(),
                              const SizedBox(height: 8),

                              // Amounts & due date
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Due Date: ${dateFormat.format(c.dueDate)}',
                                        style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Billed: Rs ${currencyFormatter.format(c.amount.toInt())}',
                                        style: AppText.bodySmall,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Balance Dues:',
                                        style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                      ),
                                      Text(
                                        'Rs ${currencyFormatter.format(c.balance.toInt())}',
                                        style: AppText.titleLarge.copyWith(
                                          color: isFullyPaid ? AppColors.success : AppColors.danger,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Actions
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.history_rounded, size: 18),
                                      label: const Text('Ledger'),
                                      onPressed: resident != null
                                          ? () => context.push('/residents/${resident.id}/ledger')
                                          : null,
                                    ),
                                  ),
                                  if (!isFullyPaid && resident != null) ...[
                                    const SizedBox(width: 8),
                                    IconButton.filledTonal(
                                      icon: const Icon(Icons.chat_outlined, size: 18),
                                      tooltip: 'Remind on WhatsApp',
                                      onPressed: () => _sendWhatsAppReminder(context, ref, c, resident),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: AppButton(
                                      text: isFullyPaid ? 'Paid in Full' : 'Record Pay',
                                      variant: isFullyPaid
                                          ? AppButtonVariant.secondary
                                          : AppButtonVariant.primary,
                                      height: 40,
                                      onPressed: isFullyPaid
                                          ? null
                                          : () {
                                              if (!WriteLockGuard.checkAndNavigate(context, ref)) return;
                                              RecordPaymentSheet.show(
                                                context: context,
                                                charge: c,
                                                resident: resident,
                                              );
                                            },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(WidgetRef ref, String label, String key, String currentFilter) {
    return ChoiceChip(
      label: Text(label),
      selected: currentFilter == key,
      selectedColor: AppColors.primaryContainer,
      onSelected: (selected) {
        if (selected) {
          ref.read(rentFilterProvider.notifier).setFilter(key);
        }
      },
    );
  }

  Widget _buildSummaryBadge({
    required BuildContext context,
    required WidgetRef ref,
    required String label,
    required int count,
    required double amount,
    required Color color,
    required String filterKey,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        final current = ref.read(rentFilterProvider);
        if (current == filterKey) {
          ref.read(rentFilterProvider.notifier).setFilter('all');
        } else {
          ref.read(rentFilterProvider.notifier).setFilter(filterKey);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              '$label: $count',
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: AppColors.ink,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
