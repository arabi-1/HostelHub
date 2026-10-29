import 'package:flutter/foundation.dart';

@immutable
class Resident {
  final String id;
  final String ownerId;
  final String? roomId;
  final String fullName;
  final String phone;
  final String? cnic;
  final String? guardianName;
  final String? guardianPhone;
  final double monthlyRent;
  final double securityDeposit;
  final int rentDueDay;
  final DateTime joinDate;
  final String status; // 'active', 'left'
  final DateTime? leftDate;
  final String? notes;
  final DateTime createdAt;

  const Resident({
    required this.id,
    required this.ownerId,
    this.roomId,
    required this.fullName,
    required this.phone,
    this.cnic,
    this.guardianName,
    this.guardianPhone,
    required this.monthlyRent,
    this.securityDeposit = 0.0,
    this.rentDueDay = 5,
    required this.joinDate,
    this.status = 'active',
    this.leftDate,
    this.notes,
    required this.createdAt,
  });

  factory Resident.fromJson(Map<String, dynamic> json) {
    return Resident(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      roomId: json['room_id'] as String?,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String,
      cnic: json['cnic'] as String?,
      guardianName: json['guardian_name'] as String?,
      guardianPhone: json['guardian_phone'] as String?,
      monthlyRent: (json['monthly_rent'] as num).toDouble(),
      securityDeposit: (json['security_deposit'] as num?)?.toDouble() ?? 0.0,
      rentDueDay: (json['rent_due_day'] as num?)?.toInt() ?? 5,
      joinDate: json['join_date'] != null
          ? DateTime.parse(json['join_date'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'active',
      leftDate: json['left_date'] != null
          ? DateTime.parse(json['left_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      if (ownerId.isNotEmpty) 'owner_id': ownerId,
      'room_id': (roomId == null || roomId!.isEmpty) ? null : roomId,
      'full_name': fullName,
      'phone': phone,
      'cnic': cnic,
      'guardian_name': guardianName,
      'guardian_phone': guardianPhone,
      'monthly_rent': monthlyRent,
      'security_deposit': securityDeposit,
      'rent_due_day': rentDueDay,
      'join_date': joinDate.toIso8601String().substring(0, 10),
      'status': status,
      'left_date': leftDate?.toIso8601String().substring(0, 10),
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Resident copyWith({
    String? id,
    String? ownerId,
    String? roomId,
    String? fullName,
    String? phone,
    String? cnic,
    String? guardianName,
    String? guardianPhone,
    double? monthlyRent,
    double? securityDeposit,
    int? rentDueDay,
    DateTime? joinDate,
    String? status,
    DateTime? leftDate,
    String? notes,
    DateTime? createdAt,
  }) {
    return Resident(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      roomId: roomId ?? this.roomId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      guardianName: guardianName ?? this.guardianName,
      guardianPhone: guardianPhone ?? this.guardianPhone,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      rentDueDay: rentDueDay ?? this.rentDueDay,
      joinDate: joinDate ?? this.joinDate,
      status: status ?? this.status,
      leftDate: leftDate ?? this.leftDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isActive => status == 'active';

  // Masked CNIC helper (e.g., 35201-1234567-1 -> •••••-•••••67-1)
  String get maskedCnic {
    if (cnic == null || cnic!.length != 13) return cnic ?? '';
    final digits = cnic!;
    return '•••••-•••••${digits.substring(10, 12)}-${digits.substring(12)}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Resident &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          roomId == other.roomId &&
          fullName == other.fullName &&
          phone == other.phone &&
          cnic == other.cnic &&
          status == other.status;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      (roomId?.hashCode ?? 0) ^
      fullName.hashCode ^
      phone.hashCode ^
      (cnic?.hashCode ?? 0) ^
      status.hashCode;
}
