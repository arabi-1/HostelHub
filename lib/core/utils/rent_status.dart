enum ChargeStatus {
  paid,
  partial,
  overdue,
  pending,
}

abstract final class RentStatusUtils {
  /// Computes the [ChargeStatus] based on amount, paid, balance, and due date.
  /// Dates are compared on day resolution (ignoring time-of-day).
  static ChargeStatus computeStatus({
    required double amount,
    required double paid,
    double? balance,
    required DateTime dueDate,
    DateTime? currentDate,
  }) {
    final effectiveBalance = balance ?? (amount - paid);
    if (effectiveBalance <= 0) {
      return ChargeStatus.paid;
    }

    if (paid > 0 && effectiveBalance > 0) {
      return ChargeStatus.partial;
    }

    final now = currentDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);

    if (effectiveBalance > 0 && dueDay.isBefore(today)) {
      return ChargeStatus.overdue;
    }

    return ChargeStatus.pending;
  }

  /// Returns the canonical 1st of the month period as a [DateTime]:
  /// e.g. for 2026-10-29 -> 2026-10-01 00:00:00
  static DateTime getPeriodForMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Calculates the due date for a given period and resident's due day (1-28):
  /// e.g. period = 2026-10-01, dueDay = 5 -> 2026-10-05
  static DateTime calculateDueDate({
    required DateTime period,
    required int rentDueDay,
  }) {
    final clampedDay = rentDueDay.clamp(1, 28);
    return DateTime(period.year, period.month, clampedDay);
  }

  /// Checks if a payment was created within the editable 24-hour window (FR-16).
  static bool canEditPayment(DateTime createdAt, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now();
    final difference = now.difference(createdAt);
    return !difference.isNegative && difference.inHours < 24;
  }
}
