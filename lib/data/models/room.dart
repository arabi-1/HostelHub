import 'package:flutter/foundation.dart';

@immutable
class Room {
  final String id;
  final String ownerId;
  final String propertyId;
  final String roomNumber;
  final String? floor;
  final int capacity;
  final double defaultRent;
  final String? notes;
  final bool isActive;
  final DateTime createdAt;

  const Room({
    required this.id,
    required this.ownerId,
    required this.propertyId,
    required this.roomNumber,
    this.floor,
    required this.capacity,
    this.defaultRent = 0.0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      propertyId: json['property_id'] as String,
      roomNumber: json['room_number'] as String,
      floor: json['floor'] as String?,
      capacity: (json['capacity'] as num).toInt(),
      defaultRent: (json['default_rent'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'property_id': propertyId,
      'room_number': roomNumber,
      'floor': floor,
      'capacity': capacity,
      'default_rent': defaultRent,
      'notes': notes,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Room copyWith({
    String? id,
    String? ownerId,
    String? propertyId,
    String? roomNumber,
    String? floor,
    int? capacity,
    double? defaultRent,
    String? notes,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Room(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      propertyId: propertyId ?? this.propertyId,
      roomNumber: roomNumber ?? this.roomNumber,
      floor: floor ?? this.floor,
      capacity: capacity ?? this.capacity,
      defaultRent: defaultRent ?? this.defaultRent,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Room &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          propertyId == other.propertyId &&
          roomNumber == other.roomNumber &&
          floor == other.floor &&
          capacity == other.capacity &&
          defaultRent == other.defaultRent &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      propertyId.hashCode ^
      roomNumber.hashCode ^
      floor.hashCode ^
      capacity.hashCode ^
      defaultRent.hashCode ^
      isActive.hashCode;
}
