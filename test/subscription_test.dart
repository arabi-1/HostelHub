import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhub/core/utils/subscription_utils.dart';
import 'package:hostelhub/data/models/profile.dart';
import 'package:hostelhub/data/repositories/profile_repo.dart';
import 'package:hostelhub/features/billing/services/billing_service.dart';
import 'package:hostelhub/features/billing/services/mock_billing_service.dart';

class FakeProfileRepo extends ProfileRepo {
  Profile? storedProfile;

  FakeProfileRepo(this.storedProfile);

  @override
  Future<Profile?> getProfile(String userId) async {
    return storedProfile;
  }

  @override
  Future<Profile> updateProfile(Profile profile) async {
    storedProfile = profile;
    return profile;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final baseDate = DateTime(2026, 10, 29, 12, 0);

  group('SubscriptionUtils Pure Domain Calculation Tests', () {
    test('Calculates trial days remaining accurately', () {
      // 0 days elapsed -> 30 days left
      expect(
        SubscriptionUtils.computeTrialDaysLeft(baseDate, baseDate),
        equals(30),
      );

      // 15 days elapsed -> 15 days left
      final date15Ago = baseDate.subtract(const Duration(days: 15));
      expect(
        SubscriptionUtils.computeTrialDaysLeft(date15Ago, baseDate),
        equals(15),
      );

      // 29 days elapsed -> 1 day left
      final date29Ago = baseDate.subtract(const Duration(days: 29));
      expect(
        SubscriptionUtils.computeTrialDaysLeft(date29Ago, baseDate),
        equals(1),
      );

      // 30 days elapsed -> 0 days left
      final date30Ago = baseDate.subtract(const Duration(days: 30));
      expect(
        SubscriptionUtils.computeTrialDaysLeft(date30Ago, baseDate),
        equals(0),
      );

      // 45 days elapsed -> clamps to 0 (never negative)
      final date45Ago = baseDate.subtract(const Duration(days: 45));
      expect(
        SubscriptionUtils.computeTrialDaysLeft(date45Ago, baseDate),
        equals(0),
      );
    });

    test('Derives isPremium based on status and expiration date', () {
      final futureExpiry = baseDate.add(const Duration(days: 30));
      final pastExpiry = baseDate.subtract(const Duration(days: 1));

      // Active status with future expiry
      expect(
        SubscriptionUtils.computeIsPremium(
          subscriptionStatus: 'active',
          expiresAt: futureExpiry,
          currentDate: baseDate,
        ),
        isTrue,
      );

      // Active status with null expiry (lifetime / indefinite)
      expect(
        SubscriptionUtils.computeIsPremium(
          subscriptionStatus: 'active',
          expiresAt: null,
          currentDate: baseDate,
        ),
        isTrue,
      );

      // Active status but past expiry -> false
      expect(
        SubscriptionUtils.computeIsPremium(
          subscriptionStatus: 'active',
          expiresAt: pastExpiry,
          currentDate: baseDate,
        ),
        isFalse,
      );

      // Trial or canceled status -> false
      expect(
        SubscriptionUtils.computeIsPremium(
          subscriptionStatus: 'trial',
          expiresAt: futureExpiry,
          currentDate: baseDate,
        ),
        isFalse,
      );
    });

    test('Derives isTrial and isLocked transitions properly', () {
      // Case 1: Fresh trial (30 days left, not premium) -> isTrial: true, isLocked: false
      final isTrial1 = SubscriptionUtils.computeIsTrial(
        isPremium: false,
        trialDaysLeft: 30,
      );
      final isLocked1 = SubscriptionUtils.computeIsLocked(
        isPremium: false,
        isTrial: isTrial1,
      );
      expect(isTrial1, isTrue);
      expect(isLocked1, isFalse);

      // Case 2: Expired trial (0 days left, not premium) -> isTrial: false, isLocked: true
      final isTrial2 = SubscriptionUtils.computeIsTrial(
        isPremium: false,
        trialDaysLeft: 0,
      );
      final isLocked2 = SubscriptionUtils.computeIsLocked(
        isPremium: false,
        isTrial: isTrial2,
      );
      expect(isTrial2, isFalse);
      expect(isLocked2, isTrue);

      // Case 3: Premium subscriber -> isTrial: false, isLocked: false
      final isTrial3 = SubscriptionUtils.computeIsTrial(
        isPremium: true,
        trialDaysLeft: 10,
      );
      final isLocked3 = SubscriptionUtils.computeIsLocked(
        isPremium: true,
        isTrial: isTrial3,
      );
      expect(isTrial3, isFalse);
      expect(isLocked3, isFalse);
    });

    test('Formats trial remaining strings and plan badges', () {
      expect(
        SubscriptionUtils.formatTrialDaysLeft(30),
        equals('30 days left in free trial'),
      );
      expect(
        SubscriptionUtils.formatTrialDaysLeft(1),
        equals('1 day left in free trial'),
      );
      expect(
        SubscriptionUtils.formatTrialDaysLeft(0),
        equals('Free trial expired'),
      );

      expect(
        SubscriptionUtils.formatPlanBadge(isPremium: true, isTrial: false, plan: 'yearly'),
        equals('PREMIUM YEARLY'),
      );
      expect(
        SubscriptionUtils.formatPlanBadge(isPremium: true, isTrial: false, plan: 'monthly'),
        equals('PREMIUM MONTHLY'),
      );
      expect(
        SubscriptionUtils.formatPlanBadge(isPremium: false, isTrial: true, daysLeft: 12),
        equals('FREE TRIAL (12D)'),
      );
      expect(
        SubscriptionUtils.formatPlanBadge(isPremium: false, isTrial: false),
        equals('TRIAL EXPIRED'),
      );
    });
  });

  group('MockBillingService Tests (FR-24)', () {
    test('Simulates Monthly purchase and updates profile subscription state', () async {
      final initialProfile = Profile(
        id: 'user-001',
        fullName: 'Ali Khan',
        trialStartedAt: baseDate.subtract(const Duration(days: 35)), // Expired
        subscriptionStatus: 'trial',
        createdAt: baseDate.subtract(const Duration(days: 35)),
      );

      final fakeRepo = FakeProfileRepo(initialProfile);
      final mockService = MockBillingService(
        profileRepo: fakeRepo,
        getCurrentUserId: () => 'user-001',
      );

      expect(mockService.currentStatus, equals(BillingPurchaseStatus.idle));

      final success = await mockService.purchase('monthly');
      expect(success, isTrue);
      expect(mockService.currentStatus, equals(BillingPurchaseStatus.purchased));

      final updatedProfile = fakeRepo.storedProfile!;
      expect(updatedProfile.subscriptionStatus, equals('active'));
      expect(updatedProfile.subscriptionPlan, equals('monthly'));
      expect(updatedProfile.subscriptionExpiresAt, isNotNull);
      expect(updatedProfile.isPremium, isTrue);
      expect(updatedProfile.isLocked, isFalse);
    });

    test('Simulates Yearly purchase with 365 days expiry', () async {
      final initialProfile = Profile(
        id: 'user-002',
        fullName: 'Zainab Bibi',
        trialStartedAt: baseDate.subtract(const Duration(days: 10)),
        subscriptionStatus: 'trial',
        createdAt: baseDate.subtract(const Duration(days: 10)),
      );

      final fakeRepo = FakeProfileRepo(initialProfile);
      final mockService = MockBillingService(
        profileRepo: fakeRepo,
        getCurrentUserId: () => 'user-002',
      );

      final success = await mockService.purchase('yearly');
      expect(success, isTrue);

      final updated = fakeRepo.storedProfile!;
      expect(updated.subscriptionPlan, equals('yearly'));
      expect(updated.subscriptionExpiresAt!.difference(DateTime.now()).inDays, inInclusiveRange(364, 366));
    });

    test('Restore purchases detects active subscription', () async {
      final premiumProfile = Profile(
        id: 'user-003',
        fullName: 'Omar Tariq',
        trialStartedAt: baseDate.subtract(const Duration(days: 40)),
        subscriptionStatus: 'active',
        subscriptionPlan: 'monthly',
        subscriptionExpiresAt: DateTime.now().add(const Duration(days: 20)),
        createdAt: baseDate.subtract(const Duration(days: 40)),
      );

      final fakeRepo = FakeProfileRepo(premiumProfile);
      final mockService = MockBillingService(
        profileRepo: fakeRepo,
        getCurrentUserId: () => 'user-003',
      );

      final restored = await mockService.restorePurchases();
      expect(restored, isTrue);
      expect(mockService.currentStatus, equals(BillingPurchaseStatus.restored));
    });
  });
}
