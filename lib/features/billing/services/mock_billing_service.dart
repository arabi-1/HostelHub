import 'dart:async';
import '../../../data/repositories/profile_repo.dart';
import 'billing_service.dart';

class MockBillingService implements BillingService {
  final ProfileRepo _profileRepo;
  final String Function() _getCurrentUserId;
  final StreamController<BillingPurchaseStatus> _statusController =
      StreamController<BillingPurchaseStatus>.broadcast();
  BillingPurchaseStatus _status = BillingPurchaseStatus.idle;

  MockBillingService({
    ProfileRepo? profileRepo,
    required String Function() getCurrentUserId,
  })  : _profileRepo = profileRepo ?? ProfileRepo(),
        _getCurrentUserId = getCurrentUserId;

  @override
  Stream<BillingPurchaseStatus> get purchaseStatusStream => _statusController.stream;

  @override
  BillingPurchaseStatus get currentStatus => _status;

  @override
  Future<void> initialize() async {
    _status = BillingPurchaseStatus.idle;
    _statusController.add(_status);
  }

  @override
  Future<bool> purchase(String planId) async {
    _status = BillingPurchaseStatus.pending;
    _statusController.add(_status);

    // Simulate store dialog roundtrip
    await Future.delayed(const Duration(milliseconds: 600));

    final userId = _getCurrentUserId();
    if (userId.isEmpty) {
      _status = BillingPurchaseStatus.error;
      _statusController.add(_status);
      return false;
    }

    final currentProfile = await _profileRepo.getProfile(userId);
    if (currentProfile == null) {
      _status = BillingPurchaseStatus.error;
      _statusController.add(_status);
      return false;
    }

    final now = DateTime.now();
    final isYearly = planId == 'yearly' || planId == 'premium_yearly';
    final expiry = isYearly
        ? now.add(const Duration(days: 365))
        : now.add(const Duration(days: 30));
    final normalizedPlan = isYearly ? 'yearly' : 'monthly';

    final updated = currentProfile.copyWith(
      subscriptionStatus: 'active',
      subscriptionPlan: normalizedPlan,
      subscriptionExpiresAt: expiry,
    );

    await _profileRepo.updateProfile(updated);

    _status = BillingPurchaseStatus.purchased;
    _statusController.add(_status);
    return true;
  }

  @override
  Future<bool> restorePurchases() async {
    _status = BillingPurchaseStatus.pending;
    _statusController.add(_status);

    await Future.delayed(const Duration(milliseconds: 500));

    final userId = _getCurrentUserId();
    if (userId.isEmpty) {
      _status = BillingPurchaseStatus.error;
      _statusController.add(_status);
      return false;
    }

    final currentProfile = await _profileRepo.getProfile(userId);
    if (currentProfile == null) {
      _status = BillingPurchaseStatus.error;
      _statusController.add(_status);
      return false;
    }

    if (currentProfile.isPremium) {
      _status = BillingPurchaseStatus.restored;
      _statusController.add(_status);
      return true;
    }

    _status = BillingPurchaseStatus.idle;
    _statusController.add(_status);
    return false;
  }

  @override
  void dispose() {
    _statusController.close();
  }
}
