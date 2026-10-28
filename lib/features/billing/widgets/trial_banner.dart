import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/subscription_utils.dart';
import '../providers/subscription_provider.dart';

class TrialBanner extends ConsumerWidget {
  const TrialBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sub = ref.watch(subscriptionProvider);

    // Premium subscribers do not see any banner
    if (sub.isPremium) {
      return const SizedBox.shrink();
    }

    if (sub.isLocked) {
      return Container(
        color: AppColors.danger,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              const Icon(Icons.lock_clock_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Trial Expired • Write access is locked',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.danger,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: const Size(0, 30),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => context.push('/paywall'),
                child: const Text(
                  'Unlock',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Active Free Trial State
    final text = SubscriptionUtils.formatTrialDaysLeft(sub.trialDaysLeft);
    final isUrgent = sub.trialDaysLeft <= 5;

    return Container(
      color: isUrgent ? AppColors.warning : AppColors.primaryContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Icon(
              isUrgent ? Icons.warning_amber_rounded : Icons.access_time_rounded,
              color: isUrgent ? Colors.white : AppColors.primaryDark,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isUrgent ? Colors.white : AppColors.primaryDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: isUrgent ? Colors.white : AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: const Size(0, 28),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => context.push('/paywall'),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Upgrade', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
