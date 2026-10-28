abstract final class SubscriptionUtils {
  static const int trialDurationDays = 30;

  /// Computes remaining free trial days from trial_started_at.
  static int computeTrialDaysLeft(DateTime trialStartedAt, [DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final elapsed = now.difference(trialStartedAt).inDays;
    final remaining = trialDurationDays - elapsed;
    return remaining > 0 ? remaining : 0;
  }

  /// Evaluates whether the user holds an active premium subscription.
  static bool computeIsPremium({
    required String subscriptionStatus,
    DateTime? expiresAt,
    DateTime? currentDate,
  }) {
    if (subscriptionStatus != 'active') return false;
    if (expiresAt == null) return true;
    final now = currentDate ?? DateTime.now();
    return expiresAt.isAfter(now);
  }

  /// Evaluates whether the user is currently within their free trial period.
  static bool computeIsTrial({
    required bool isPremium,
    required int trialDaysLeft,
  }) {
    return !isPremium && trialDaysLeft > 0;
  }

  /// Evaluates whether the user account is locked to read-only mode due to expired trial and no active subscription.
  static bool computeIsLocked({
    required bool isPremium,
    required bool isTrial,
  }) {
    return !isPremium && !isTrial;
  }

  /// Formats human-readable trial remaining text.
  static String formatTrialDaysLeft(int daysLeft) {
    if (daysLeft <= 0) return 'Free trial expired';
    if (daysLeft == 1) return '1 day left in free trial';
    return '$daysLeft days left in free trial';
  }

  /// Formats status pill / badge labels.
  static String formatPlanBadge({
    required bool isPremium,
    required bool isTrial,
    String? plan,
    int? daysLeft,
  }) {
    if (isPremium) {
      if (plan == 'yearly' || plan == 'premium_yearly') return 'PREMIUM YEARLY';
      if (plan == 'monthly' || plan == 'premium_monthly') return 'PREMIUM MONTHLY';
      return 'PREMIUM ACTIVE';
    }
    if (isTrial) {
      return 'FREE TRIAL (${daysLeft ?? 0}D)';
    }
    return 'TRIAL EXPIRED';
  }
}
