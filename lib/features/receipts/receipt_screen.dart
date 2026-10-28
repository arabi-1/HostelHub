import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/loading_view.dart';
import 'providers/receipt_providers.dart';
import 'services/pdf_receipt_builder.dart';
import 'services/whatsapp_service.dart';

class ReceiptScreen extends ConsumerWidget {
  final String paymentId;

  const ReceiptScreen({
    super.key,
    required this.paymentId,
  });

  Future<void> _sendWhatsAppReceipt(
    BuildContext context,
    ReceiptBundle bundle, {
    required bool toGuardian,
  }) async {
    final phone = toGuardian ? bundle.resident.guardianPhone : bundle.resident.phone;
    if (phone == null || phone.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No phone number available.')),
      );
      return;
    }

    final message = WhatsAppService.buildReceiptMessage(
      receiptNo: bundle.payment.receiptNo,
      businessName: bundle.businessName,
      amount: bundle.payment.amount,
      residentName: bundle.resident.fullName,
      period: bundle.charge.period,
      paidOn: bundle.payment.paidOn,
      method: bundle.payment.method,
      balance: bundle.charge.balance,
    );

    await WhatsAppService.launchOrCopy(
      context: context,
      phone: phone,
      message: message,
    );
  }

  Future<void> _sharePdf(ReceiptBundle bundle) async {
    final bytes = await PdfReceiptBuilder.build(
      payment: bundle.payment,
      charge: bundle.charge,
      resident: bundle.resident,
      room: bundle.room,
      businessName: bundle.businessName,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'Receipt_${bundle.payment.receiptNo}.pdf',
    );
  }

  Future<void> _printPdf(ReceiptBundle bundle) async {
    final bytes = await PdfReceiptBuilder.build(
      payment: bundle.payment,
      charge: bundle.charge,
      resident: bundle.resident,
      room: bundle.room,
      businessName: bundle.businessName,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => bytes,
      name: 'Receipt_${bundle.payment.receiptNo}',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptBundleProvider(paymentId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
        actions: [
          receiptAsync.when(
            data: (bundle) {
              if (bundle == null) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Share PDF',
                onPressed: () => _sharePdf(bundle),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (err, stack) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: receiptAsync.when(
        data: (bundle) {
          if (bundle == null) {
            return const ErrorView(message: 'Receipt not found or has been deleted.');
          }

          final hasGuardian = bundle.resident.guardianPhone != null &&
              bundle.resident.guardianPhone!.trim().isNotEmpty;

          return Column(
            children: [
              Expanded(
                child: PdfPreview(
                  build: (format) => PdfReceiptBuilder.build(
                    payment: bundle.payment,
                    charge: bundle.charge,
                    resident: bundle.resident,
                    room: bundle.room,
                    businessName: bundle.businessName,
                  ),
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  useActions: false,
                  previewPageMargin: const EdgeInsets.all(16),
                  loadingWidget: const LoadingView(message: 'Rendering receipt preview...'),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  border: const Border(
                    top: BorderSide(color: AppColors.outline),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              text: 'Send on WhatsApp',
                              icon: Icons.chat,
                              onPressed: () => _sendWhatsAppReceipt(
                                context,
                                bundle,
                                toGuardian: false,
                              ),
                            ),
                          ),
                          if (hasGuardian) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: AppButton(
                                text: 'Send to Guardian',
                                icon: Icons.family_restroom,
                                variant: AppButtonVariant.secondary,
                                onPressed: () => _sendWhatsAppReceipt(
                                  context,
                                  bundle,
                                  toGuardian: true,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text('Share PDF'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              onPressed: () => _sharePdf(bundle),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.print, size: 18),
                              label: const Text('Print PDF'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppColors.primary),
                                foregroundColor: AppColors.primary,
                                minimumSize: const Size.fromHeight(44),
                              ),
                              onPressed: () => _printPdf(bundle),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(message: 'Loading receipt...'),
        error: (err, stack) => ErrorView(
          message: 'Failed to load receipt: $err',
          onRetry: () => ref.invalidate(receiptBundleProvider(paymentId)),
        ),
      ),
    );
  }
}
