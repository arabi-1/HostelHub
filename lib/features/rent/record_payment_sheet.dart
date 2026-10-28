import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../data/models/rent_charge.dart';
import '../../data/models/resident.dart';
import 'providers/rent_providers.dart';

class RecordPaymentSheet extends ConsumerStatefulWidget {
  final RentCharge charge;
  final Resident? resident;

  const RecordPaymentSheet({
    super.key,
    required this.charge,
    this.resident,
  });

  static Future<void> show({
    required BuildContext context,
    required RentCharge charge,
    Resident? resident,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: RecordPaymentSheet(charge: charge, resident: resident),
      ),
    );
  }

  @override
  ConsumerState<RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<RecordPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;

  String _selectedMethod = 'cash';
  DateTime _paidOn = DateTime.now();
  bool _isLoading = false;

  final _paymentMethods = const [
    {'key': 'cash', 'label': 'Cash'},
    {'key': 'bank_transfer', 'label': 'Bank Transfer'},
    {'key': 'easypaisa', 'label': 'Easypaisa'},
    {'key': 'jazzcash', 'label': 'JazzCash'},
    {'key': 'other', 'label': 'Other'},
  ];

  @override
  void initState() {
    super.initState();
    // Default amount to the remaining balance for convenient 1-tap full payment
    _amountController = TextEditingController(
      text: widget.charge.balance.toInt().toString(),
    );
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidOn,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _paidOn = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment amount must be greater than zero.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (amount > widget.charge.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment amount cannot exceed remaining balance (Rs ${widget.charge.balance.toInt()}).'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final payment = await ref.read(monthlyChargesProvider.notifier).recordPayment(
            residentId: widget.charge.residentId,
            chargeId: widget.charge.id,
            amount: amount,
            method: _selectedMethod,
            paidOn: _paidOn,
            note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payment of Rs ${amount.toInt()} recorded. Receipt: ${payment.receiptNo}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording payment: ${e.toString()}'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat('#,##0');
    final monthFormat = DateFormat('MMMM yyyy');
    final dateFormat = DateFormat('dd MMM yyyy');

    final residentName = widget.resident?.fullName ?? 'Resident';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Record Rent Payment', style: AppText.headlineLarge.copyWith(fontSize: 20)),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Summary Card
            Card(
              color: AppColors.primaryContainer.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(residentName, style: AppText.titleLarge.copyWith(fontSize: 16)),
                        Text(
                          monthFormat.format(widget.charge.period),
                          style: AppText.bodyMedium.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total Bill: Rs ${currencyFormatter.format(widget.charge.amount.toInt())}'),
                        Text(
                          'Balance: Rs ${currencyFormatter.format(widget.charge.balance.toInt())}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Amount Input
            AppTextField(
              controller: _amountController,
              label: 'Amount Paying (PKR)',
              hint: 'e.g. 15000',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              prefixIcon: const Icon(Icons.payments_outlined),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return AppStrings.requiredField;
                }
                final amt = double.tryParse(val.trim());
                if (amt == null || amt <= 0) {
                  return 'Must be greater than zero';
                }
                if (amt > widget.charge.balance) {
                  return 'Cannot exceed remaining balance';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Payment Method Selector
            const Text(
              'Payment Method',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _paymentMethods.map((m) {
                final isSelected = _selectedMethod == m['key'];
                return ChoiceChip(
                  label: Text(m['label']!),
                  selected: isSelected,
                  selectedColor: AppColors.primaryContainer,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedMethod = m['key']!);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Payment Date Picker
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Date',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                ),
                child: Text(dateFormat.format(_paidOn)),
              ),
            ),
            const SizedBox(height: 16),

            // Note (Optional)
            AppTextField(
              controller: _noteController,
              label: 'Note / Transaction ID (Optional)',
              hint: 'e.g. JazzCash TID #987654321, Cash in hand',
            ),
            const SizedBox(height: 24),

            AppButton(
              text: 'Confirm & Save Payment',
              isLoading: _isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
