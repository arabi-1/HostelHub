import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhub/data/models/payment.dart';
import 'package:hostelhub/data/models/profile.dart';
import 'package:hostelhub/data/models/property.dart';
import 'package:hostelhub/data/models/rent_charge.dart';
import 'package:hostelhub/data/models/resident.dart';
import 'package:hostelhub/data/models/room.dart';
import 'package:hostelhub/features/auth/providers/auth_provider.dart';

void main() {
  group('Profile Model Tests', () {
    test('Profile fromJson and toJson serialization roundtrip', () {
      final now = DateTime.now();
      final profile = Profile(
        id: 'usr-123',
        fullName: 'Muhammad Arabi',
        phone: '03001234567',
        businessName: 'Hostel One',
        trialStartedAt: now,
        subscriptionStatus: 'trial',
        createdAt: now,
      );

      final json = profile.toJson();
      final restored = Profile.fromJson(json);

      expect(restored.id, profile.id);
      expect(restored.fullName, profile.fullName);
      expect(restored.phone, profile.phone);
      expect(restored.businessName, profile.businessName);
      expect(restored.subscriptionStatus, 'trial');
    });

    test('Subscription logic computes trial, premium, and locked states', () {
      final freshProfile = Profile(
        id: 'usr-fresh',
        fullName: 'Fresh Owner',
        trialStartedAt: DateTime.now().subtract(const Duration(days: 5)),
        subscriptionStatus: 'trial',
        createdAt: DateTime.now(),
      );
      expect(freshProfile.isTrial, isTrue);
      expect(freshProfile.isPremium, isFalse);
      expect(freshProfile.isLocked, isFalse);
      expect(freshProfile.trialDaysLeft, closeTo(25, 1));

      final expiredProfile = Profile(
        id: 'usr-expired',
        fullName: 'Expired Owner',
        trialStartedAt: DateTime.now().subtract(const Duration(days: 35)),
        subscriptionStatus: 'trial',
        createdAt: DateTime.now().subtract(const Duration(days: 35)),
      );
      expect(expiredProfile.isTrial, isFalse);
      expect(expiredProfile.isPremium, isFalse);
      expect(expiredProfile.isLocked, isTrue);
      expect(expiredProfile.trialDaysLeft, 0);

      final activeProfile = Profile(
        id: 'usr-active',
        fullName: 'Paid Owner',
        trialStartedAt: DateTime.now().subtract(const Duration(days: 45)),
        subscriptionStatus: 'active',
        subscriptionPlan: 'monthly',
        subscriptionExpiresAt: DateTime.now().add(const Duration(days: 20)),
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      );
      expect(activeProfile.isPremium, isTrue);
      expect(activeProfile.isTrial, isFalse);
      expect(activeProfile.isLocked, isFalse);
    });
  });

  group('Property & Room Model Tests', () {
    test('Property fromJson and toJson roundtrip', () {
      final prop = Property(
        id: 'prop-1',
        ownerId: 'usr-1',
        name: 'Gulberg Branch',
        address: 'Main Blvd',
        city: 'Lahore',
        createdAt: DateTime.now(),
      );

      final json = prop.toJson();
      final restored = Property.fromJson(json);

      expect(restored.id, prop.id);
      expect(restored.name, 'Gulberg Branch');
      expect(restored.city, 'Lahore');
      expect(restored.isActive, isTrue);
    });

    test('Room fromJson and toJson roundtrip', () {
      final room = Room(
        id: 'room-101',
        ownerId: 'usr-1',
        propertyId: 'prop-1',
        roomNumber: '101',
        floor: '1st',
        capacity: 4,
        defaultRent: 15000,
        createdAt: DateTime.now(),
      );

      final json = room.toJson();
      final restored = Room.fromJson(json);

      expect(restored.roomNumber, '101');
      expect(restored.capacity, 4);
      expect(restored.defaultRent, 15000.0);
    });
  });

  group('Resident Model Tests', () {
    test('Resident masked CNIC formats properly', () {
      final resident = Resident(
        id: 'res-1',
        ownerId: 'usr-1',
        fullName: 'Ali Khan',
        phone: '923001234567',
        cnic: '3520112345671',
        monthlyRent: 12000,
        joinDate: DateTime(2026, 1, 1),
        createdAt: DateTime.now(),
      );

      expect(resident.maskedCnic, '•••••-•••••67-1');
      expect(resident.isActive, isTrue);
    });
  });

  group('Rent Charge & Payment Model Tests', () {
    test('RentCharge derives status correctly', () {
      final now = DateTime.now();
      final pastDue = DateTime(now.year, now.month - 1, 5);
      final futureDue = DateTime(now.year, now.month + 1, 5);

      final paidCharge = RentCharge(
        id: 'chg-1',
        ownerId: 'usr-1',
        residentId: 'res-1',
        period: DateTime(now.year, now.month, 1),
        amount: 10000,
        paid: 10000,
        dueDate: futureDue,
        createdAt: now,
      );
      expect(paidCharge.status, 'paid');
      expect(paidCharge.balance, 0.0);

      final partialCharge = RentCharge(
        id: 'chg-2',
        ownerId: 'usr-1',
        residentId: 'res-1',
        period: DateTime(now.year, now.month, 1),
        amount: 10000,
        paid: 4000,
        dueDate: futureDue,
        createdAt: now,
      );
      expect(partialCharge.status, 'partial');
      expect(partialCharge.balance, 6000.0);

      final overdueCharge = RentCharge(
        id: 'chg-3',
        ownerId: 'usr-1',
        residentId: 'res-1',
        period: DateTime(now.year, now.month - 1, 1),
        amount: 10000,
        paid: 0,
        dueDate: pastDue,
        createdAt: now,
      );
      expect(overdueCharge.status, 'overdue');

      final pendingCharge = RentCharge(
        id: 'chg-4',
        ownerId: 'usr-1',
        residentId: 'res-1',
        period: DateTime(now.year, now.month, 1),
        amount: 10000,
        paid: 0,
        dueDate: futureDue,
        createdAt: now,
      );
      expect(pendingCharge.status, 'pending');
    });

    test('Payment fromJson and toJson roundtrip', () {
      final payment = Payment(
        id: 'pay-1',
        ownerId: 'usr-1',
        residentId: 'res-1',
        chargeId: 'chg-1',
        amount: 5000,
        paidOn: DateTime(2026, 10, 29),
        method: 'easypaisa',
        receiptNo: 'RCT-000042',
        note: 'Advance payment',
        createdAt: DateTime.now(),
      );

      final json = payment.toJson();
      final restored = Payment.fromJson(json);

      expect(restored.receiptNo, 'RCT-000042');
      expect(restored.method, 'easypaisa');
      expect(restored.amount, 5000.0);
    });
  });

  group('AuthStateModel Tests', () {
    test('copyWith updates state correctly', () {
      const initial = AuthStateModel();
      expect(initial.isLoading, isFalse);
      expect(initial.errorMessage, isNull);

      final loading = initial.copyWith(isLoading: true);
      expect(loading.isLoading, isTrue);

      final error = loading.copyWith(isLoading: false, errorMessage: 'Invalid login');
      expect(error.isLoading, isFalse);
      expect(error.errorMessage, 'Invalid login');
    });
  });
}
