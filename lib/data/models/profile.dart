import 'package:flutter/foundation.dart';
import '../../core/utils/subscription_utils.dart';

@immutable
class Profile {
  final String id;
  final String fullName;
  final String? phone;
  final String? businessName;
  final DateTime trialStartedAt;
  final String subscriptionStatus; // 'trial', 'active', 'expired', 'canceled'
  final String? subscriptionPlan; // 'monthly', 'yearly'
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;

  const Profile({
    required this.id,
    required this.fullName,
    this.phone,
    this.businessName,
    required this.trialStartedAt,
    this.subscriptionStatus = 'trial',
    this.subscriptionPlan,
    this.subscriptionExpiresAt,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String?,
      businessName: json['business_name'] as String?,
      trialStartedAt: json['trial_started_at'] != null
          ? DateTime.parse(json['trial_started_at'] as String)
          : DateTime.now(),
      subscriptionStatus: json['subscription_status'] as String? ?? 'trial',
      subscriptionPlan: json['subscription_plan'] as String?,
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.parse(json['subscription_expires_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'business_name': businessName,
      'trial_started_at': trialStartedAt.toIso8601String(),
      'subscription_status': subscriptionStatus,
      'subscription_plan': subscriptionPlan,
      'subscription_expires_at': subscriptionExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Profile copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? businessName,
    DateTime? trialStartedAt,
    String? subscriptionStatus,
    String? subscriptionPlan,
    DateTime? subscriptionExpiresAt,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      trialStartedAt: trialStartedAt ?? this.trialStartedAt,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiresAt: subscriptionExpiresAt ?? this.subscriptionExpiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Business logic getters (Section 7.4 via SubscriptionUtils)
  int get trialDaysLeft => SubscriptionUtils.computeTrialDaysLeft(trialStartedAt);

  bool get isPremium => SubscriptionUtils.computeIsPremium(
        subscriptionStatus: subscriptionStatus,
        expiresAt: subscriptionExpiresAt,
      );

  bool get isTrial => SubscriptionUtils.computeIsTrial(
        isPremium: isPremium,
        trialDaysLeft: trialDaysLeft,
      );

  bool get isLocked => SubscriptionUtils.computeIsLocked(
        isPremium: isPremium,
        isTrial: isTrial,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          phone == other.phone &&
          businessName == other.businessName &&
          trialStartedAt == other.trialStartedAt &&
          subscriptionStatus == other.subscriptionStatus &&
          subscriptionPlan == other.subscriptionPlan &&
          subscriptionExpiresAt == other.subscriptionExpiresAt;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      phone.hashCode ^
      businessName.hashCode ^
      trialStartedAt.hashCode ^
      subscriptionStatus.hashCode ^
      subscriptionPlan.hashCode ^
      subscriptionExpiresAt.hashCode;
}
