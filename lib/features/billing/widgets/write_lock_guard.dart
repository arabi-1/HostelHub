import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/subscription_provider.dart';

abstract final class WriteLockGuard {
  /// Checks whether write actions (creating residents, rooms, recording payments) are permitted.
  /// If the account is locked (free trial expired with no subscription), intercepts with
  /// an informative paywall dialog and returns false.
  /// If unlocked, returns true.
  static bool checkAndNavigate(BuildContext context, WidgetRef ref) {
    final sub = ref.read(subscriptionProvider);
    if (sub.isLocked) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.danger),
              SizedBox(width: 8),
              Text('Account Locked'),
            ],
          ),
          content: const Text(
            'Your 30-day free trial has ended. Creating new residents, rooms, or recording payments requires an active subscription.\n\nYour existing data, PDF receipts, and settings remain safe and fully accessible.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.push('/paywall');
              },
              child: const Text('View Plans'),
            ),
          ],
        ),
      );
      return false;
    }
    return true;
  }
}
