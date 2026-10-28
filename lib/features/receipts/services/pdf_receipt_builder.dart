import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/payment.dart';
import '../../../data/models/rent_charge.dart';
import '../../../data/models/resident.dart';
import '../../../data/models/room.dart';

abstract final class PdfReceiptBuilder {
  static const PdfColor primaryTeal = PdfColor.fromInt(0xFF0F766E);
  static const PdfColor accentGold = PdfColor.fromInt(0xFFC9922E);
  static const PdfColor lightBg = PdfColor.fromInt(0xFFF5F8F7);
  static const PdfColor textInk = PdfColor.fromInt(0xFF10201D);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF5F706B);
  static const PdfColor borderOutline = PdfColor.fromInt(0xFFDCE5E2);

  static Future<Uint8List> build({
    required Payment payment,
    required RentCharge charge,
    required Resident resident,
    Room? room,
    required String businessName,
  }) async {
    final pdf = pw.Document();

    final currencyFormatter = NumberFormat('#,##0');
    final monthFormat = DateFormat('MMMM yyyy');
    final dateFormat = DateFormat('dd MMM yyyy');

    final formattedAmount = 'Rs ${currencyFormatter.format(payment.amount.toInt())}';
    final formattedBalance = 'Rs ${currencyFormatter.format(charge.balance.toInt())}';
    final roomStr = room != null ? 'Room ${room.roomNumber}' : 'Unassigned';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderOutline, width: 1.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Header Banner
                pw.Container(
                  padding: const pw.EdgeInsets.all(14),
                  decoration: const pw.BoxDecoration(
                    color: primaryTeal,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            businessName.isNotEmpty ? businessName : 'HostelHub',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 18,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'Rent Payment Receipt',
                            style: const pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: const pw.BoxDecoration(
                          color: PdfColors.white,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                        ),
                        child: pw.Text(
                          payment.receiptNo,
                          style: pw.TextStyle(
                            color: primaryTeal,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),

                // Details Grid
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Left Column
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildField('Resident Name', resident.fullName),
                          pw.SizedBox(height: 10),
                          _buildField('Assigned Room', roomStr),
                          pw.SizedBox(height: 10),
                          _buildField('Payment Method', payment.method.toUpperCase()),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 20),
                    // Right Column
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildField('Billing Period', monthFormat.format(charge.period)),
                          pw.SizedBox(height: 10),
                          _buildField('Payment Date', dateFormat.format(payment.paidOn)),
                          pw.SizedBox(height: 10),
                          _buildField(
                            'Status',
                            charge.balance <= 0 ? 'PAID IN FULL' : 'PARTIAL PAYMENT',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.Divider(color: borderOutline, thickness: 1),
                pw.SizedBox(height: 12),

                // Amount Breakdown Box
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const pw.BoxDecoration(
                    color: lightBg,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'AMOUNT RECEIVED',
                            style: pw.TextStyle(
                              color: textMuted,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            formattedAmount,
                            style: pw.TextStyle(
                              color: primaryTeal,
                              fontSize: 22,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'REMAINING BALANCE',
                            style: pw.TextStyle(
                              color: textMuted,
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            formattedBalance,
                            style: pw.TextStyle(
                              color: charge.balance > 0 ? PdfColors.red800 : PdfColors.green800,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (payment.note != null && payment.note!.isNotEmpty) ...[
                  pw.SizedBox(height: 12),
                  pw.Text(
                    'Note: ${payment.note!}',
                    style: const pw.TextStyle(color: textMuted, fontSize: 10),
                  ),
                ],

                pw.Spacer(),

                // Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Thank you for your payment!',
                      style: pw.TextStyle(
                        color: textMuted,
                        fontSize: 10,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                    pw.Text(
                      'Generated by HostelHub',
                      style: const pw.TextStyle(color: textMuted, fontSize: 9),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildField(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label.toUpperCase(),
          style: const pw.TextStyle(
            color: textMuted,
            fontSize: 9,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(
            color: textInk,
            fontSize: 13,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
