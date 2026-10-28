import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import '../../../data/repositories/profile_repo.dart';
import 'billing_service.dart';

class PlayBillingService implements BillingService {
  /// Toggle flag for Google Play Billing (FR-26).
  /// Kept false during development and testing until Google Play Console products are fully activated.
  static const bool enablePlayBilling = false;

  static const String monthlyProductId = 'premium_monthly';
  static const String yearlyProductId = 'premium_yearly';
  static const Set<String> productIds = {monthlyProductId, yearlyProductId};

  final iap.InAppPurchase _iap = iap.InAppPurchase.instance;
  final ProfileRepo _profileRepo;
  final String Function() _getCurrentUserId;
  final StreamController<BillingPurchaseStatus> _statusController =
      StreamController<BillingPurchaseStatus>.broadcast();

  StreamSubscription<List<iap.PurchaseDetails>>? _subscription;
  BillingPurchaseStatus _status = BillingPurchaseStatus.idle;

  PlayBillingService({
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
    if (!enablePlayBilling) {
      debugPrint('[PlayBillingService] Play billing flag is disabled; running in stub mode.');
      _status = BillingPurchaseStatus.idle;
      _statusController.add(_status);
      return;
    }

    final available = await _iap.isAvailable();
    if (!available) {
      debugPrint('[PlayBillingService] InAppPurchase service unavailable on this device.');
      _status = BillingPurchaseStatus.error;
      _statusController.add(_status);
      return;
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        debugPrint('[PlayBillingService] Purchase stream error: $error');
        _status = BillingPurchaseStatus.error;
        _statusController.add(_status);
      },
    );
  }

  Future<void> _handlePurchaseUpdates(List<iap.PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == iap.PurchaseStatus.pending) {
        _status = BillingPurchaseStatus.pending;
        _statusController.add(_status);
      } else if (purchase.status == iap.PurchaseStatus.error) {
        _status = BillingPurchaseStatus.error;
        _statusController.add(_status);
      } else if (purchase.status == iap.PurchaseStatus.canceled) {
        _status = BillingPurchaseStatus.canceled;
        _statusController.add(_status);
      } else if (purchase.status == iap.PurchaseStatus.purchased ||
          purchase.status == iap.PurchaseStatus.restored) {
        final userId = _getCurrentUserId();
        if (userId.isNotEmpty) {
          final profile = await _profileRepo.getProfile(userId);
          if (profile != null) {
            final now = DateTime.now();
            final isYearly = purchase.productID == yearlyProductId;
            final expiry = isYearly
                ? now.add(const Duration(days: 365))
                : now.add(const Duration(days: 30));

            final updated = profile.copyWith(
              subscriptionStatus: 'active',
              subscriptionPlan: isYearly ? 'yearly' : 'monthly',
              subscriptionExpiresAt: expiry,
            );
            await _profileRepo.updateProfile(updated);
          }
        }

        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

        _status = purchase.status == iap.PurchaseStatus.restored
            ? BillingPurchaseStatus.restored
            : BillingPurchaseStatus.purchased;
        _statusController.add(_status);
      }
    }
  }

  @override
  Future<bool> purchase(String planId) async {
    if (!enablePlayBilling) {
      debugPrint('[PlayBillingService] Play billing flag is disabled; cannot purchase.');
      return false;
    }

    final productId = (planId == 'yearly' || planId == yearlyProductId)
        ? yearlyProductId
        : monthlyProductId;

    final response = await _iap.queryProductDetails({productId});
    if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
      debugPrint('[PlayBillingService] Product $productId not found in Play store.');
      _status = BillingPurchaseStatus.error;
      _statusController.add(_status);
      return false;
    }

    final productDetails = response.productDetails.first;
    final purchaseParam = iap.PurchaseParam(productDetails: productDetails);

    _status = BillingPurchaseStatus.pending;
    _statusController.add(_status);
    return _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  @override
  Future<bool> restorePurchases() async {
    if (!enablePlayBilling) {
      debugPrint('[PlayBillingService] Play billing flag is disabled; cannot restore.');
      return false;
    }

    try {
      _status = BillingPurchaseStatus.pending;
      _statusController.add(_status);
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      debugPrint('[PlayBillingService] Error restoring purchases: $e');
      _status = BillingPurchaseStatus.error;
      _statusController.add(_status);
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
