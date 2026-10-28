import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/strings.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/subscription_utils.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/loading_view.dart';
import '../../data/models/profile.dart';
import '../auth/providers/auth_provider.dart';
import '../billing/providers/subscription_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _editProfile(BuildContext context, WidgetRef ref, Profile profile) async {
    final nameController = TextEditingController(text: profile.fullName);
    final phoneController = TextEditingController(text: profile.phone ?? '');
    final businessController = TextEditingController(text: profile.businessName ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(
                  controller: nameController,
                  label: AppStrings.fullName,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return AppStrings.requiredField;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: phoneController,
                  label: AppStrings.phone,
                  hint: '03XXXXXXXXX',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: businessController,
                  label: AppStrings.businessName,
                  hint: 'Al-Madina Hostel',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.muted)),
          ),
          AppButton(
            text: AppStrings.save,
            width: 100,
            height: 40,
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
          ),
        ],
      ),
    );

    if (saved == true && context.mounted) {
      final updated = profile.copyWith(
        fullName: nameController.text.trim(),
        phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
        businessName: businessController.text.trim().isEmpty ? null : businessController.text.trim(),
      );
      final success = await ref.read(authControllerProvider.notifier).updateProfile(updated);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
            backgroundColor: success ? AppColors.success : AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteAccount(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: AppStrings.deleteAccount,
      message: AppStrings.deleteAccountConfirmation,
      confirmLabel: AppStrings.delete,
      requiredTextToConfirm: AppStrings.deleteKeyword,
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      final success = await ref.read(authControllerProvider.notifier).deleteAccount();
      if (!success && context.mounted) {
        final error = ref.read(authControllerProvider).errorMessage ?? 'Account deletion failed';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _handleSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: AppStrings.signOut,
      message: 'Are you sure you want to sign out?',
      confirmLabel: AppStrings.signOut,
      isDestructive: true,
    );

    if (confirmed && context.mounted) {
      await ref.read(authControllerProvider.notifier).signOut();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);
    final currentUser = ref.watch(currentUserProvider);
    final sub = ref.watch(subscriptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.navSettings),
      ),
      body: profileAsync.when(
        loading: () => const LoadingView(message: 'Loading profile...'),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Error loading profile: $err'),
              const SizedBox(height: 12),
              AppButton(
                text: 'Retry',
                width: 120,
                onPressed: () => ref.refresh(currentProfileProvider),
              ),
            ],
          ),
        ),
        data: (profile) {
          final fullName = profile?.fullName ?? currentUser?.userMetadata?['full_name'] ?? 'Hostel Owner';
          final email = currentUser?.email ?? '';
          final business = profile?.businessName ?? 'No business name set';

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              // User Header Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primaryContainer,
                          child: Text(
                            fullName.isNotEmpty ? fullName[0].toUpperCase() : 'H',
                            style: AppText.headlineLarge.copyWith(color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(fullName, style: AppText.titleLarge),
                              const SizedBox(height: 2),
                              Text(email, style: AppText.bodySmall.copyWith(color: AppColors.muted)),
                              const SizedBox(height: 2),
                              Text(business, style: AppText.bodySmall.copyWith(color: AppColors.primaryDark)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                          onPressed: profile != null ? () => _editProfile(context, ref, profile) : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Subscription Status Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  color: sub.isPremium
                      ? AppColors.primaryContainer.withValues(alpha: 0.5)
                      : (sub.isLocked
                          ? AppColors.dangerContainer
                          : AppColors.primaryContainer.withValues(alpha: 0.5)),
                  child: InkWell(
                    onTap: () => context.push('/paywall'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          Icon(
                            sub.isPremium
                                ? Icons.workspace_premium_rounded
                                : (sub.isLocked
                                    ? Icons.lock_clock_rounded
                                    : Icons.access_time_rounded),
                            color: sub.isPremium
                                ? AppColors.accent
                                : (sub.isLocked ? AppColors.danger : AppColors.primaryDark),
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  SubscriptionUtils.formatPlanBadge(
                                    isPremium: sub.isPremium,
                                    isTrial: sub.isTrial,
                                    plan: sub.plan,
                                    daysLeft: sub.trialDaysLeft,
                                  ),
                                  style: AppText.labelLarge.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sub.isPremium
                                      ? 'Premium active • All features unlocked'
                                      : (sub.isLocked
                                          ? 'Trial expired • Tap to unlock features'
                                          : '${sub.trialDaysLeft} days left in free trial • Tap to upgrade'),
                                  style: AppText.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('Edit Profile Info'),
                subtitle: const Text('Full name, phone, business name'),
                trailing: const Icon(Icons.chevron_right),
                onTap: profile != null ? () => _editProfile(context, ref, profile) : null,
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text(AppStrings.privacyPolicy),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text(AppStrings.privacyPolicy),
                      content: const SingleChildScrollView(
                        child: Text(
                          'HostelHub values your privacy. All hostel resident data, payment ledgers, and contact information remain secure under Row-Level Security policies. Sensitive fields like CNIC are stored securely and masked across the UI. You may request complete account and data deletion at any time.',
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text(AppStrings.about),
                subtitle: const Text('HostelHub v1.0.0 — Pakistan Hostel Rent Manager'),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: AppColors.muted),
                title: const Text(AppStrings.signOut),
                onTap: () => _handleSignOut(context, ref),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.danger),
                title: const Text(
                  AppStrings.deleteAccount,
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Permanently delete account and all data',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () => _handleDeleteAccount(context, ref),
              ),
            ],
          );
        },
      ),
    );
  }
}
