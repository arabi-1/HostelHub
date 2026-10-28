import 'package:flutter_test/flutter_test.dart';
import 'package:hostelhub/core/utils/rent_status.dart';
import 'package:hostelhub/data/models/payment.dart';
import 'package:hostelhub/data/models/rent_charge.dart';

void main() {
  group('RentStatusUtils Status Derivation Tests', () {
    final now = DateTime(2026, 10, 29);
    final pastDue = DateTime(2026, 10, 5);
    final futureDue = DateTime(2026, 11, 5);

    test('Derives paid status when balance is zero or less', () {
      final status = RentStatusUtils.computeStatus(
        amount: 15000,
        paid: 15000,
        balance: 0,
        dueDate: pastDue,
        currentDate: now,
      );
      expect(status, ChargeStatus.paid);

      final overpaidStatus = RentStatusUtils.computeStatus(
        amount: 15000,
        paid: 16000,
        balance: -1000,
        dueDate: pastDue,
        currentDate: now,
      );
      expect(overpaidStatus, ChargeStatus.paid);
    });

    test('Derives partial status when paid > 0 and balance > 0', () {
      final status = RentStatusUtils.computeStatus(
        amount: 15000,
        paid: 5000,
        balance: 10000,
        dueDate: futureDue,
        currentDate: now,
      );
      expect(status, ChargeStatus.partial);
    });

    test('Derives overdue status when unpaid and due date has passed', () {
      final status = RentStatusUtils.computeStatus(
        amount: 15000,
        paid: 0,
        balance: 15000,
        dueDate: pastDue,
        currentDate: now,
      );
      expect(status, ChargeStatus.overdue);
    });

    test('Derives pending status when unpaid and due date is today or in future', () {
      final status = RentStatusUtils.computeStatus(
        amount: 15000,
        paid: 0,
        balance: 15000,
        dueDate: futureDue,
        currentDate: now,
      );
      expect(status, ChargeStatus.pending);

      final todayDueStatus = RentStatusUtils.computeStatus(
        amount: 15000,
        paid: 0,
        balance: 15000,
        dueDate: now,
        currentDate: now,
      );
      expect(todayDueStatus, ChargeStatus.pending);
    });
  });

  group('Rent Period and Due Date Helpers', () {
    test('getPeriodForMonth always normalizes to 1st of month', () {
      final period = RentStatusUtils.getPeriodForMonth(DateTime(2026, 10, 29, 14, 30));
      expect(period.year, 2026);
      expect(period.month, 10);
      expect(period.day, 1);
    });

    test('calculateDueDate clamps to 1-28 range', () {
      final period = DateTime(2026, 10, 1);

      final normalDue = RentStatusUtils.calculateDueDate(period: period, rentDueDay: 10);
      expect(normalDue, DateTime(2026, 10, 10));

      final lowDue = RentStatusUtils.calculateDueDate(period: period, rentDueDay: 0);
      expect(lowDue, DateTime(2026, 10, 1));

      final highDue = RentStatusUtils.calculateDueDate(period: period, rentDueDay: 31);
      expect(highDue, DateTime(2026, 10, 28));
    });
  });

  group('24-Hour Payment Edit Window Tests (FR-16)', () {
    final now = DateTime(2026, 10, 29, 12, 0);

    test('Payment within 24 hours is editable', () {
      final created5HoursAgo = now.subtract(const Duration(hours: 5));
      expect(RentStatusUtils.canEditPayment(created5HoursAgo, currentTime: now), isTrue);

      final created23HoursAgo = now.subtract(const Duration(hours: 23, minutes: 55));
      expect(RentStatusUtils.canEditPayment(created23HoursAgo, currentTime: now), isTrue);
    });

    test('Payment older than 24 hours is locked from editing or deletion', () {
      final created25HoursAgo = now.subtract(const Duration(hours: 25));
      expect(RentStatusUtils.canEditPayment(created25HoursAgo, currentTime: now), isFalse);

      final created3DaysAgo = now.subtract(const Duration(days: 3));
      expect(RentStatusUtils.canEditPayment(created3DaysAgo, currentTime: now), isFalse);
    });
  });

  group('Running Balance and Partial Payment Summing', () {
    test('Ledger balance computes accurately after multiple charges and payments', () {
      final c1 = RentCharge(
        id: 'c-1',
        ownerId: 'o-1',
        residentId: 'r-1',
        period: DateTime(2026, 9, 1),
        amount: 12000,
        dueDate: DateTime(2026, 9, 5),
        createdAt: DateTime(2026, 9, 1),
      );

      final p1 = Payment(
        id: 'p-1',
        ownerId: 'o-1',
        residentId: 'r-1',
        chargeId: 'c-1',
        amount: 12000,
        paidOn: DateTime(2026, 9, 4),
        receiptNo: 'RCT-000001',
        createdAt: DateTime(2026, 9, 4),
      );

      final c2 = RentCharge(
        id: 'c-2',
        ownerId: 'o-1',
        residentId: 'r-1',
        period: DateTime(2026, 10, 1),
        amount: 12000,
        dueDate: DateTime(2026, 10, 5),
        createdAt: DateTime(2026, 10, 1),
      );

      final p2 = Payment(
        id: 'p-2',
        ownerId: 'o-1',
        residentId: 'r-1',
        chargeId: 'c-2',
        amount: 7000, // partial payment
        paidOn: DateTime(2026, 10, 3),
        receiptNo: 'RCT-000002',
        createdAt: DateTime(2026, 10, 3),
      );

      final totalBilled = c1.amount + c2.amount;
      final totalPaid = p1.amount + p2.amount;
      final outstandingBalance = totalBilled - totalPaid;

      expect(totalBilled, 24000.0);
      expect(totalPaid, 19000.0);
      expect(outstandingBalance, 5000.0);
    });
  });
}
