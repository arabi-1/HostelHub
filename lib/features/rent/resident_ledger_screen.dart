import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/rent_status.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/models/payment.dart';
import 'providers/rent_providers.dart';

class ResidentLedgerScreen extends ConsumerWidget {
  final String residentId;

  const ResidentLedgerScreen({super.key, required this.residentId});

  Future<void> _handleDeletePayment(BuildContext context, WidgetRef ref, Payment payment) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Payment',
      message: 'Are you sure you want to delete payment ${payment.receiptNo} of Rs ${payment.amount.toInt()}? This correction is only allowed within 24 hours of entry.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      try {
        final paymentRepo = ref.read(paymentRepoProvider);
        await paymentRepo.deletePayment(payment.id, payment.createdAt);
        ref.invalidate(residentLedgerProvider(residentId));
        ref.invalidate(monthlyChargesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment deleted successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleEditPayment(BuildContext context, WidgetRef ref, Payment payment) async {
    final amountController = TextEditingController(text: payment.amount.toInt().toString());
    final noteController = TextEditingController(text: payment.note ?? '');
    String selectedMethod = payment.method;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Edit Payment (${payment.receiptNo})'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: amountController,
                  label: 'Corrected Amount',
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return AppStrings.requiredField;
                    final n = double.tryParse(val.trim());
                    if (n == null || n <= 0) return 'Must be > 0';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('Bank Transfer')),
                    DropdownMenuItem(value: 'easypaisa', child: Text('Easypaisa')),
                    DropdownMenuItem(value: 'jazzcash', child: Text('JazzCash')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (val) {
                    if (val != null) setState(() => selectedMethod = val);
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: noteController,
                  label: 'Correction Note',
                  hint: 'Reason for correction',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.muted)),
            ),
            AppButton(
              text: 'Save',
              width: 90,
              height: 40,
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(ctx).pop(true);
                }
              },
            ),
          ],
        ),
      ),
    );

    if (saved == true && context.mounted) {
      try {
        final paymentRepo = ref.read(paymentRepoProvider);
        final correctedAmount = double.parse(amountController.text.trim());
        final updated = payment.copyWith(
          amount: correctedAmount,
          method: selectedMethod,
          note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
        );

        await paymentRepo.updatePayment(updated);
        ref.invalidate(residentLedgerProvider(residentId));
        ref.invalidate(monthlyChargesProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment corrected successfully.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ledgerAsync = ref.watch(residentLedgerProvider(residentId));
    final currencyFormatter = NumberFormat('#,##0');
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Resident Ledger'),
      ),
      body: ledgerAsync.when(
        loading: () => const LoadingView(message: 'Loading ledger history...'),
        error: (err, _) => ErrorView(
          message: err.toString(),
          onRetry: () => ref.refresh(residentLedgerProvider(residentId)),
        ),
        data: (data) {
          final res = data.resident;
          final room = data.room;
          final roomText = room != null ? 'Room ${room.roomNumber}' : 'No Room';

          return Column(
            children: [
              // Resident Summary Card
              Container(
                color: Theme.of(context).cardColor,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            res.fullName.isNotEmpty ? res.fullName[0].toUpperCase() : 'R',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(res.fullName, style: AppText.titleLarge.copyWith(fontSize: 18)),
                              Text(roomText, style: AppText.bodySmall.copyWith(color: AppColors.muted)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Total Billed', 'Rs ${currencyFormatter.format(data.totalBilled.toInt())}', AppColors.ink),
                        _buildStat('Total Paid', 'Rs ${currencyFormatter.format(data.totalPaid.toInt())}', AppColors.success),
                        _buildStat(
                          'Balance Due',
                          'Rs ${currencyFormatter.format(data.totalBalance.toInt())}',
                          data.totalBalance > 0 ? AppColors.danger : AppColors.success,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Ledger Transactions List
              Expanded(
                child: data.entries.isEmpty
                  ? const EmptyState(
                      title: 'No Ledger Entries',
                      message: 'Monthly charges and recorded payments will appear here.',
                      icon: Icons.receipt_long_outlined,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: data.entries.length,
                      separatorBuilder: (_, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final entry = data.entries[index];
                        final isPayment = entry.type == LedgerEntryType.payment;

                        Widget? trailingMenu;
                        if (isPayment) {
                          final payment = entry.rawItem as Payment;
                          final isEditable = RentStatusUtils.canEditPayment(payment.createdAt);

                          if (isEditable) {
                            trailingMenu = PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20, color: AppColors.muted),
                              onSelected: (val) {
                                if (val == 'edit') {
                                  _handleEditPayment(context, ref, payment);
                                } else if (val == 'delete') {
                                  _handleDeletePayment(context, ref, payment);
                                }
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit Payment (24h)')),
                                PopupMenuItem(value: 'delete', child: Text('Delete Payment (24h)')),
                              ],
                            );
                          }
                        }

                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isPayment
                                        ? AppColors.successContainer
                                        : AppColors.primaryContainer,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    isPayment ? Icons.payment_rounded : Icons.receipt_long_rounded,
                                    color: isPayment ? AppColors.success : AppColors.primary,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        entry.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${dateFormat.format(entry.date)} • ${entry.subtitle}',
                                        style: AppText.bodySmall.copyWith(color: AppColors.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isPayment ? '-' : '+'} Rs ${currencyFormatter.format(entry.amount.toInt())}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isPayment ? AppColors.success : AppColors.ink,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Bal: Rs ${currencyFormatter.format(entry.runningBalance.toInt())}',
                                      style: AppText.bodySmall.copyWith(
                                        color: entry.runningBalance > 0
                                            ? AppColors.danger
                                            : AppColors.muted,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                if (trailingMenu != null) trailingMenu,
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
