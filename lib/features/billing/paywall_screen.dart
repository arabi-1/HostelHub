import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/app_button.dart';
import '../auth/providers/auth_provider.dart';
import 'providers/subscription_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  String _selectedPlan = 'yearly'; // 'monthly' or 'yearly'

  Future<void> _handlePurchase() async {
    final success = await ref
        .read(subscriptionControllerProvider.notifier)
        .purchase(_selectedPlan);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Welcome to HostelHub Premium! All features unlocked.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subscription purchase was not completed. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final success = await ref
        .read(subscriptionControllerProvider.notifier)
        .restorePurchases();

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchases successfully restored! Premium is active.'),
          backgroundColor: AppColors.success,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active subscriptions found for this account.'),
        ),
      );
    }
  }

  void _showPolicyDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: Text(content)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final subState = ref.watch(subscriptionProvider);
    final controllerState = ref.watch(subscriptionControllerProvider);
    final isLoading = controllerState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Gradient App Bar Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            automaticallyImplyLeading: false,
            leadingWidth: 90,
            leading: subState.isLocked
                ? TextButton(
                    onPressed: () async {
                      await ref.read(authRepoProvider).signOut();
                    },
                    child: const Text(
                      'Sign Out',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  )
                : null,
            actions: [
              if (!subState.isLocked)
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primaryDark],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          color: AppColors.accent,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'HostelHub Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subState.isLocked
                            ? 'Your free trial has ended. Subscribe to unlock.'
                            : 'Run your hostel with confidence and zero limits',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Paywall Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Value Propositions Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'What You Get with Premium',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 14),
                          _buildBenefitRow(
                            icon: Icons.group_outlined,
                            title: 'Unlimited Residents & Rooms',
                            subtitle: 'Manage all your hostels and branches with no capacity cap.',
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitRow(
                            icon: Icons.chat_outlined,
                            title: '1-Tap WhatsApp Reminders & Receipts',
                            subtitle: 'Professional, preformatted rent reminders & receipts.',
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitRow(
                            icon: Icons.picture_as_pdf_outlined,
                            title: 'Printable & Shareable PDF Invoices',
                            subtitle: 'Generate branded PDF receipts directly on your phone.',
                          ),
                          const SizedBox(height: 12),
                          _buildBenefitRow(
                            icon: Icons.account_balance_wallet_outlined,
                            title: 'Complete Ledger & Dues Tracking',
                            subtitle: 'Accurate chronological running balance for every resident.',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Plan Selectors
                  const Text(
                    'Choose Your Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Yearly Plan Card (Best Value)
                  _buildPlanCard(
                    id: 'yearly',
                    title: 'Yearly Plan',
                    price: 'Rs 14,000 / year',
                    subtext: 'Equivalent to Rs 1,166/month',
                    badge: 'SAVE 22% • BEST VALUE',
                    isSelected: _selectedPlan == 'yearly',
                  ),
                  const SizedBox(height: 12),

                  // Monthly Plan Card
                  _buildPlanCard(
                    id: 'monthly',
                    title: 'Monthly Plan',
                    price: 'Rs 1,500 / month',
                    subtext: 'Billed monthly, cancel anytime',
                    isSelected: _selectedPlan == 'monthly',
                  ),
                  const SizedBox(height: 24),

                  // Large Gold CTA Button
                  AppButton(
                    text: subState.isLocked
                        ? 'Unlock HostelHub (Rs ${_selectedPlan == 'yearly' ? '14,000/yr' : '1,500/mo'})'
                        : 'Start Subscription (Rs ${_selectedPlan == 'yearly' ? '14,000/yr' : '1,500/mo'})',
                    icon: Icons.lock_open_rounded,
                    isLoading: isLoading,
                    onPressed: isLoading ? null : _handlePurchase,
                  ),
                  const SizedBox(height: 12),

                  // Restore Purchases
                  Center(
                    child: TextButton.icon(
                      icon: const Icon(Icons.restore, size: 18),
                      label: const Text('Restore Purchases'),
                      onPressed: isLoading ? null : _handleRestore,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Google Play Policy Disclaimers
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Subscriptions automatically renew unless canceled at least 24 hours prior to the end of the current billing cycle. You can manage or cancel your subscription at any time in your Google Play account settings. Payment will be charged to your Google Play account upon purchase confirmation.',
                          style: TextStyle(fontSize: 11, color: AppColors.muted),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => _showPolicyDialog(
                                'Terms of Service',
                                'HostelHub subscription provides full access to resident management, PDF receipt generation, and WhatsApp integrations. By subscribing, you agree that your payment will be processed via Google Play and can be managed through your Play Store subscription management screen.',
                              ),
                              child: const Text(
                                'Terms of Service',
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const Text('  •  ', style: TextStyle(color: AppColors.muted, fontSize: 11)),
                            GestureDetector(
                              onTap: () => _showPolicyDialog(
                                'Privacy Policy',
                                'HostelHub respects your privacy. All your resident contact records and financial logs are securely stored with Row-Level Security encryption. We never share or sell your data to third parties. WhatsApp communications are initiated directly from your device.',
                              ),
                              child: const Text(
                                'Privacy Policy',
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.underline,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppText.bodySmall.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String subtext,
    String? badge,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedPlan = id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryContainer.withValues(alpha: 0.3) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.muted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    subtext,
                    style: AppText.bodySmall.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
