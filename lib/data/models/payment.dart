import 'package:flutter/foundation.dart';

@immutable
class Payment {
  final String id;
  final String ownerId;
  final String residentId;
  final String chargeId;
  final double amount;
  final DateTime paidOn;
  final String method; // 'cash', 'bank_transfer', 'easypaisa', 'jazzcash', 'other'
  final String receiptNo;
  final String? note;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.ownerId,
    required this.residentId,
    required this.chargeId,
    required this.amount,
    required this.paidOn,
    this.method = 'cash',
    required this.receiptNo,
    this.note,
    required this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      residentId: json['resident_id'] as String,
      chargeId: json['charge_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      paidOn: json['paid_on'] != null
          ? DateTime.parse(json['paid_on'] as String)
          : DateTime.now(),
      method: json['method'] as String? ?? 'cash',
      receiptNo: json['receipt_no'] as String? ?? '',
      note: json['note'] as String?,
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
      'charge_id': chargeId,
      'amount': amount,
      'paid_on': paidOn.toIso8601String().substring(0, 10),
      'method': method,
      'receipt_no': receiptNo,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? ownerId,
    String? residentId,
    String? chargeId,
    double? amount,
    DateTime? paidOn,
    String? method,
    String? receiptNo,
    String? note,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      residentId: residentId ?? this.residentId,
      chargeId: chargeId ?? this.chargeId,
      amount: amount ?? this.amount,
      paidOn: paidOn ?? this.paidOn,
      method: method ?? this.method,
      receiptNo: receiptNo ?? this.receiptNo,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Payment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          residentId == other.residentId &&
          chargeId == other.chargeId &&
          amount == other.amount &&
          receiptNo == other.receiptNo &&
          method == other.method;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      residentId.hashCode ^
      chargeId.hashCode ^
      amount.hashCode ^
      receiptNo.hashCode ^
      method.hashCode;
}
