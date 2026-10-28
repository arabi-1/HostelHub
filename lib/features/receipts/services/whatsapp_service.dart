import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/utils/phone.dart';

abstract final class WhatsAppService {
  /// Builds the standardized reminder message (Section 8.1)
  static String buildReminderMessage({
    required String residentName,
    required String businessName,
    required double balance,
    required DateTime period,
    required DateTime dueDate,
    required bool isOverdue,
  }) {
    final currencyFormatter = NumberFormat('#,##0');
    final monthYear = DateFormat('MMMM yyyy').format(period);
    final dueDateStr = DateFormat('dd MMM yyyy').format(dueDate);
    final duePhrase = isOverdue ? 'was due on' : 'is due on';
    final formattedBalance = currencyFormatter.format(balance.toInt());

    return 'Assalam o Alaikum $residentName,\n'
        'This is a reminder from $businessName: your rent of Rs $formattedBalance for $monthYear $duePhrase $dueDateStr.\n'
        'Kindly pay at your earliest convenience. Thank you.';
  }

  /// Builds the standardized payment receipt message (Section 8.1)
  static String buildReceiptMessage({
    required String receiptNo,
    required String businessName,
    required double amount,
    required String residentName,
    required DateTime period,
    required DateTime paidOn,
    required String method,
    required double balance,
  }) {
    final currencyFormatter = NumberFormat('#,##0');
    final monthYear = DateFormat('MMMM yyyy').format(period);
    final paidOnStr = DateFormat('dd MMM yyyy').format(paidOn);
    final formattedAmount = currencyFormatter.format(amount.toInt());
    final formattedBalance = currencyFormatter.format(balance.toInt());

    return 'Receipt $receiptNo — $businessName\n'
        'Received Rs $formattedAmount from $residentName for $monthYear on $paidOnStr via $method.\n'
        'Remaining balance: Rs $formattedBalance.\n'
        'Thank you.';
  }

  /// Builds a `https://wa.me/<phone>?text=<encoded_text>` URL
  static Uri buildWhatsAppUri({
    required String phone,
    required String message,
  }) {
    final normalized = PhoneUtils.normalize(phone);
    final encodedText = Uri.encodeComponent(message);
    return Uri.parse('https://wa.me/$normalized?text=$encodedText');
  }

  /// Launches WhatsApp with external application mode.
  /// If launch fails, copies message to system clipboard and informs user.
  static Future<bool> launchOrCopy({
    required BuildContext context,
    required String phone,
    required String message,
  }) async {
    final uri = buildWhatsAppUri(phone: phone, message: message);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) return true;
    } catch (_) {
      // Fallback below
    }

    // Fallback: Copy to clipboard
    await Clipboard.setData(ClipboardData(text: message));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open WhatsApp. Message copied to clipboard!'),
        ),
      );
    }
    return false;
  }
}
