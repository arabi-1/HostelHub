import 'dart:async';

enum BillingPurchaseStatus {
  idle,
  pending,
  purchased,
  restored,
  canceled,
  error,
}

abstract class BillingService {
  Stream<BillingPurchaseStatus> get purchaseStatusStream;
  BillingPurchaseStatus get currentStatus;

  Future<void> initialize();
  Future<bool> purchase(String planId);
  Future<bool> restorePurchases();
  void dispose();
}
