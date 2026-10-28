import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/billing_service.dart';
import '../services/mock_billing_service.dart';
import '../services/play_billing_service.dart';

class SubscriptionState {
  final bool isPremium;
  final bool isTrial;
  final bool isLocked;
  final int trialDaysLeft;
  final String? plan;
  final DateTime? expiresAt;
  final String status;

  const SubscriptionState({
    this.isPremium = false,
    this.isTrial = true,
    this.isLocked = false,
    this.trialDaysLeft = 30,
    this.plan,
    this.expiresAt,
    this.status = 'trial',
  });
}

/// Provides the active billing service instance (Mock or Google Play based on flag).
final billingServiceProvider = Provider<BillingService>((ref) {
  final authRepo = ref.watch(authRepoProvider);
  final profileRepo = ref.watch(profileRepoProvider);

  if (PlayBillingService.enablePlayBilling) {
    final playService = PlayBillingService(
      profileRepo: profileRepo,
      getCurrentUserId: () => authRepo.currentUser?.id ?? '',
    );
    ref.onDispose(playService.dispose);
    return playService;
  } else {
    final mockService = MockBillingService(
      profileRepo: profileRepo,
      getCurrentUserId: () => authRepo.currentUser?.id ?? '',
    );
    ref.onDispose(mockService.dispose);
    return mockService;
  }
});

/// Exposes the current subscription state derived from the authenticated user's profile.
final subscriptionProvider = Provider<SubscriptionState>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  final profile = profileAsync.value;
  if (profile == null) {
    return const SubscriptionState();
  }

  return SubscriptionState(
    isPremium: profile.isPremium,
    isTrial: profile.isTrial,
    isLocked: profile.isLocked,
    trialDaysLeft: profile.trialDaysLeft,
    plan: profile.subscriptionPlan,
    expiresAt: profile.subscriptionExpiresAt,
    status: profile.subscriptionStatus,
  );
});

/// Async notifier for performing purchase and restore operations and refreshing state.
class SubscriptionController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<bool> purchase(String planId) async {
    state = const AsyncLoading();
    final billing = ref.read(billingServiceProvider);
    try {
      final success = await billing.purchase(planId);
      if (success) {
        ref.invalidate(currentProfileProvider);
        await ref.read(currentProfileProvider.future);
      }
      state = const AsyncData(null);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    state = const AsyncLoading();
    final billing = ref.read(billingServiceProvider);
    try {
      final success = await billing.restorePurchases();
      if (success) {
        ref.invalidate(currentProfileProvider);
        await ref.read(currentProfileProvider.future);
      }
      state = const AsyncData(null);
      return success;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final subscriptionControllerProvider =
    NotifierProvider<SubscriptionController, AsyncValue<void>>(
  SubscriptionController.new,
);
