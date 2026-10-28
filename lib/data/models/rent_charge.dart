import 'package:flutter/foundation.dart';

@immutable
class RentCharge {
  final String id;
  final String ownerId;
  final String residentId;
  final DateTime period;
  final double amount;
  final DateTime dueDate;
  final double paid;
  final double balance;
  final DateTime createdAt;

  const RentCharge({
    required this.id,
    required this.ownerId,
    required this.residentId,
    required this.period,
    required this.amount,
    required this.dueDate,
    this.paid = 0.0,
    double? balance,
    required this.createdAt,
  }) : balance = balance ?? (amount - paid);

  factory RentCharge.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num).toDouble();
    final paid = (json['paid'] as num?)?.toDouble() ?? 0.0;
    final balance = (json['balance'] as num?)?.toDouble() ?? (amount - paid);

    return RentCharge(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      residentId: json['resident_id'] as String,
      period: json['period'] != null
          ? DateTime.parse(json['period'] as String)
          : DateTime.now(),
      amount: amount,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : DateTime.now(),
      paid: paid,
      balance: balance,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'resident_id': residentId,
      'period': period.toIso8601String().substring(0, 10),
      'amount': amount,
      'due_date': dueDate.toIso8601String().substring(0, 10),
      'created_at': createdAt.toIso8601String(),
    };
  }

  RentCharge copyWith({
    String? id,
    String? ownerId,
    String? residentId,
    DateTime? period,
    double? amount,
    DateTime? dueDate,
    double? paid,
    double? balance,
    DateTime? createdAt,
  }) {
    return RentCharge(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      residentId: residentId ?? this.residentId,
      period: period ?? this.period,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paid: paid ?? this.paid,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Derived status matching Section 7.1
  String get status {
    if (balance <= 0) return 'paid';
    if (paid > 0 && balance > 0) return 'partial';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    if (balance > 0 && due.isBefore(today)) return 'overdue';
    return 'pending';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RentCharge &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          residentId == other.residentId &&
          period == other.period &&
          amount == other.amount &&
          dueDate == other.dueDate &&
          paid == other.paid &&
          balance == other.balance;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      residentId.hashCode ^
      period.hashCode ^
      amount.hashCode ^
      dueDate.hashCode ^
      paid.hashCode ^
      balance.hashCode;
}
