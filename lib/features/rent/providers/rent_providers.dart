import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/rent_status.dart';
import '../../../data/models/payment.dart';
import '../../../data/models/rent_charge.dart';
import '../../../data/models/resident.dart';
import '../../../data/models/room.dart';
import '../../../data/repositories/payment_repo.dart';
import '../../../data/repositories/rent_repo.dart';
import '../../residents/providers/resident_providers.dart';
import '../../rooms/providers/room_providers.dart';

// Repository Providers
final rentRepoProvider = Provider<RentRepo>((ref) => RentRepo());
final paymentRepoProvider = Provider<PaymentRepo>((ref) => PaymentRepo());

// Selected Month Notifier
class SelectedRentMonthNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => RentStatusUtils.getPeriodForMonth(DateTime.now());

  void setMonth(DateTime month) {
    state = RentStatusUtils.getPeriodForMonth(month);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1, 1);
  }
}

final selectedRentMonthProvider =
    NotifierProvider<SelectedRentMonthNotifier, DateTime>(SelectedRentMonthNotifier.new);

// Rent Filter: 'all', 'overdue', 'pending', 'partial', 'paid'
class RentFilterNotifier extends Notifier<String> {
  @override
  String build() => 'all';

  void setFilter(String filter) {
    state = filter.toLowerCase();
  }
}

final rentFilterProvider =
    NotifierProvider<RentFilterNotifier, String>(RentFilterNotifier.new);

// Combined Charge Item Model for UI
class ChargeItem {
  final RentCharge charge;
  final Resident? resident;
  final Room? room;

  const ChargeItem({
    required this.charge,
    this.resident,
    this.room,
  });

  String get status => charge.status;
}

// Monthly Charges AsyncNotifier
class MonthlyChargesNotifier extends AsyncNotifier<List<ChargeItem>> {
  @override
  Future<List<ChargeItem>> build() async {
    final month = ref.watch(selectedRentMonthProvider);
    final rentRepo = ref.watch(rentRepoProvider);
    final residentRepo = ref.watch(residentRepoProvider);
    final roomRepo = ref.watch(roomRepoProvider);

    // 1. Auto-generate missing charges for active residents for this month (UC8)
    try {
      await rentRepo.generateMonthlyCharges(month);
    } catch (_) {
      // Continue fetching existing charges even if auto-generation hits RLS/network edge cases
    }

    // 2. Query charge_balances view
    final charges = await rentRepo.getChargesForMonth(month);

    // 3. Fetch residents and rooms metadata for display
    final residents = await residentRepo.getResidents(activeOnly: false);
    final rooms = await roomRepo.getAllRooms(activeOnly: false);

    final residentsMap = <String, Resident>{for (final r in residents) r.id: r};
    final roomsMap = <String, Room>{for (final rm in rooms) rm.id: rm};

    return charges.map((charge) {
      final resident = residentsMap[charge.residentId];
      final room = resident?.roomId != null ? roomsMap[resident!.roomId!] : null;
      return ChargeItem(
        charge: charge,
        resident: resident,
        room: room,
      );
    }).toList();
  }

  Future<Payment> recordPayment({
    required String residentId,
    required String chargeId,
    required double amount,
    required String method,
    required DateTime paidOn,
    String? note,
  }) async {
    final paymentRepo = ref.read(paymentRepoProvider);
    final newPayment = Payment(
      id: '',
      ownerId: '',
      residentId: residentId,
      chargeId: chargeId,
      amount: amount,
      paidOn: paidOn,
      method: method,
      receiptNo: '',
      note: note,
      createdAt: DateTime.now(),
    );

    final recorded = await paymentRepo.recordPayment(newPayment);
    ref.invalidateSelf();
    ref.invalidate(residentLedgerProvider(residentId));
    return recorded;
  }
}

final monthlyChargesProvider =
    AsyncNotifierProvider<MonthlyChargesNotifier, List<ChargeItem>>(MonthlyChargesNotifier.new);

// Filtered Charges Provider
final filteredChargesProvider = Provider<AsyncValue<List<ChargeItem>>>((ref) {
  final chargesAsync = ref.watch(monthlyChargesProvider);
  final filter = ref.watch(rentFilterProvider);

  return chargesAsync.whenData((items) {
    if (filter == 'all') return items;
    return items.where((item) => item.status == filter).toList();
  });
});

// Summary Totals Provider for Selected Month
class RentMonthSummary {
  final double totalBilled;
  final double totalCollected;
  final double totalPending;
  final double totalOverdue;
  final int countOverdue;
  final int countPending;
  final int countPartial;
  final int countPaid;

  const RentMonthSummary({
    this.totalBilled = 0,
    this.totalCollected = 0,
    this.totalPending = 0,
    this.totalOverdue = 0,
    this.countOverdue = 0,
    this.countPending = 0,
    this.countPartial = 0,
    this.countPaid = 0,
  });
}

final rentMonthSummaryProvider = Provider<RentMonthSummary>((ref) {
  final charges = ref.watch(monthlyChargesProvider).value ?? [];

  double billed = 0;
  double collected = 0;
  double pending = 0;
  double overdue = 0;

  int countOverdue = 0;
  int countPending = 0;
  int countPartial = 0;
  int countPaid = 0;

  for (final item in charges) {
    final c = item.charge;
    billed += c.amount;
    collected += c.paid;

    if (c.status == 'overdue') {
      overdue += c.balance;
      countOverdue++;
    } else if (c.status == 'partial') {
      pending += c.balance;
      countPartial++;
    } else if (c.status == 'pending') {
      pending += c.balance;
      countPending++;
    } else if (c.status == 'paid') {
      countPaid++;
    }
  }

  return RentMonthSummary(
    totalBilled: billed,
    totalCollected: collected,
    totalPending: pending,
    totalOverdue: overdue,
    countOverdue: countOverdue,
    countPending: countPending,
    countPartial: countPartial,
    countPaid: countPaid,
  );
});

// Resident Ledger Data Models
enum LedgerEntryType { charge, payment }

class LedgerEntry {
  final LedgerEntryType type;
  final DateTime date;
  final String title;
  final String subtitle;
  final double amount;
  final double runningBalance;
  final dynamic rawItem; // RentCharge or Payment

  const LedgerEntry({
    required this.type,
    required this.date,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.runningBalance,
    required this.rawItem,
  });
}

class ResidentLedgerData {
  final Resident resident;
  final Room? room;
  final double totalBilled;
  final double totalPaid;
  final double totalBalance;
  final List<LedgerEntry> entries;

  const ResidentLedgerData({
    required this.resident,
    this.room,
    required this.totalBilled,
    required this.totalPaid,
    required this.totalBalance,
    required this.entries,
  });
}

// Resident Ledger Provider
final residentLedgerProvider =
    FutureProvider.family<ResidentLedgerData, String>((ref, residentId) async {
  final resident = await ref.watch(residentDetailProvider(residentId).future);
  if (resident == null) {
    throw Exception('Resident not found');
  }

  final roomRepo = ref.watch(roomRepoProvider);
  Room? room;
  if (resident.roomId != null) {
    final rooms = await roomRepo.getAllRooms(activeOnly: false);
    room = rooms.where((r) => r.id == resident.roomId).firstOrNull;
  }

  final rentRepo = ref.watch(rentRepoProvider);
  final paymentRepo = ref.watch(paymentRepoProvider);

  final charges = await rentRepo.getChargesForResident(residentId);
  final payments = await paymentRepo.getPaymentsForResident(residentId);

  // Combine and sort chronologically (oldest first to compute running balance)
  final rawEvents = <Map<String, dynamic>>[];
  for (final c in charges) {
    rawEvents.add({
      'type': LedgerEntryType.charge,
      'date': c.period,
      'item': c,
    });
  }
  for (final p in payments) {
    rawEvents.add({
      'type': LedgerEntryType.payment,
      'date': p.paidOn,
      'item': p,
    });
  }

  rawEvents.sort((a, b) {
    final dateA = a['date'] as DateTime;
    final dateB = b['date'] as DateTime;
    final comp = dateA.compareTo(dateB);
    if (comp != 0) return comp;
    // If on same date, charges come before payments
    if (a['type'] == LedgerEntryType.charge && b['type'] == LedgerEntryType.payment) {
      return -1;
    }
    return 1;
  });

  double balance = 0;
  double billed = 0;
  double paid = 0;
  final entries = <LedgerEntry>[];

  for (final event in rawEvents) {
    final isCharge = event['type'] == LedgerEntryType.charge;
    if (isCharge) {
      final charge = event['item'] as RentCharge;
      billed += charge.amount;
      balance += charge.amount;
      entries.add(
        LedgerEntry(
          type: LedgerEntryType.charge,
          date: charge.period,
          title: 'Rent Charge',
          subtitle: 'Due: ${charge.dueDate.toIso8601String().substring(0, 10)}',
          amount: charge.amount,
          runningBalance: balance,
          rawItem: charge,
        ),
      );
    } else {
      final payment = event['item'] as Payment;
      paid += payment.amount;
      balance -= payment.amount;
      entries.add(
        LedgerEntry(
          type: LedgerEntryType.payment,
          date: payment.paidOn,
          title: 'Payment Received',
          subtitle: '${payment.receiptNo} (${payment.method})',
          amount: payment.amount,
          runningBalance: balance,
          rawItem: payment,
        ),
      );
    }
  }

  return ResidentLedgerData(
    resident: resident,
    room: room,
    totalBilled: billed,
    totalPaid: paid,
    totalBalance: balance,
    entries: entries.reversed.toList(), // Most recent first for UI display
  );
});
