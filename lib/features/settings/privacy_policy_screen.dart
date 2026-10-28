import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri.parse('mailto:support@hostelhub.app?subject=Privacy%20Inquiry%20-%20HostelHub');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact email: support@hostelhub.app')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'HostelHub Privacy Policy\nEffective Date: October 29, 2026',
                      style: AppText.labelMedium.copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            _buildSection(
              title: '1. Overview & Who We Are',
              content:
                  'HostelHub ("we", "our", or "us") provides a mobile rent and resident management application built specifically for hostel, paying guest (PG), and rental property owners in Pakistan. This Privacy Policy explains how we collect, store, protect, and use your data and your residents\' data.',
            ),

            _buildSection(
              title: '2. Information We Collect',
              content:
                  'To provide hostel management features, we collect the following information:\n\n'
                  '• Account Information: Your full name, email address, phone number, and hostel/business name provided during registration.\n'
                  '• Resident & Accommodation Details: Resident names, phone numbers, assigned room/bed numbers, monthly rent amount, security deposit, join date, leave date, and optional guardian contact details.\n'
                  '• National Identity (CNIC): An optional 13-digit Pakistani CNIC for resident verification.\n'
                  '• Rent & Payment Transactions: Monthly charge periods, amounts due, payment amounts, payment dates, payment methods (Cash, Bank Transfer, Easypaisa, JazzCash), and auto-generated receipt numbers.\n'
                  '• Subscription Information: Status of your subscription (Free Trial, Monthly, or Yearly plan) processed through Google Play Billing.',
            ),

            _buildSection(
              title: '3. Sensitive Data & CNIC Safeguards',
              content:
                  'Pakistani CNIC numbers are considered sensitive personal information. We enforce strict data protection safeguards:\n\n'
                  '• Collection is completely optional: Property owners choose whether to record a resident\'s CNIC.\n'
                  '• In-app masking: CNIC numbers are masked by default (•••••-•••••XX-X). Viewing requires an explicit confirmation and auto-hides after 5 seconds.\n'
                  '• Zero leakage: CNICs are NEVER included in WhatsApp reminder messages, payment receipts, printable PDF documents, push notifications, or application logs.\n'
                  '• Database encryption: Stored in encrypted tables protected by PostgreSQL Row Level Security (RLS).',
            ),

            _buildSection(
              title: '4. Third-Party Data & Owner Responsibility',
              content:
                  'HostelHub is designed for property owners. Because residents and guardians do not directly log into the application, property owners represent and warrant that they have obtained all necessary consents from residents and their guardians to lawfully collect and store their contact and identification details.',
            ),

            _buildSection(
              title: '5. How We Use and Share Information',
              content:
                  'We use the collected information solely to provide, operate, and maintain HostelHub services, including calculating room occupancy, generating monthly rent charges, producing printable PDF receipts, and formatting WhatsApp messages.\n\n'
                  'We NEVER sell, trade, or monetize your personal or financial data to data brokers, advertisers, or any third party.\n\n'
                  'Trusted Service Processors:\n'
                  '• Supabase Inc.: Provides our cloud database, authentication, and secure Row Level Security infrastructure.\n'
                  '• Google Play Billing: Processes in-app subscription purchases securely.',
            ),

            _buildSection(
              title: '6. WhatsApp & Communications',
              content:
                  'WhatsApp rent reminders and payment receipts are generated as prefilled links and sent only through your installed WhatsApp application. HostelHub does NOT connect to the WhatsApp Business API, does NOT send automated background messages, and does NOT perform bulk messaging.',
            ),

            _buildSection(
              title: '7. Data Security & Multi-Tenant Isolation',
              content:
                  'All data in transit is encrypted using HTTPS / TLS 1.3. In our database, Row Level Security (RLS) policies isolate each owner\'s properties, rooms, residents, charges, and payments. A property owner can never query or view another owner\'s records.',
            ),

            _buildSection(
              title: '8. Data Retention & Account Deletion',
              content:
                  'You retain complete ownership over your data. You may export receipts at any time.\n\n'
                  'You can delete your entire account and all associated data directly inside the application under Settings → Delete Account. Deleting your account executes a secure database procedure that immediately and irrevocably deletes your user record and all associated properties, rooms, residents, ledger entries, and payment history.',
            ),

            _buildSection(
              title: '9. Children\'s Privacy',
              content:
                  'HostelHub is strictly intended for property managers and adults aged 18 and older. We do not knowingly collect information from children under 18.',
            ),

            _buildSection(
              title: '10. Contact Us',
              content:
                  'If you have questions, feedback, or data privacy requests regarding this Privacy Policy or your personal information, please contact us:',
            ),

            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: const Text('support@hostelhub.app', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Tap to email our data privacy team'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => _launchEmail(context),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppText.bodyMedium.copyWith(
              color: AppColors.ink.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
