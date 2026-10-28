import 'package:flutter/foundation.dart';

@immutable
class Property {
  final String id;
  final String ownerId;
  final String name;
  final String? address;
  final String? city;
  final bool isActive;
  final DateTime createdAt;

  const Property({
    required this.id,
    required this.ownerId,
    required this.name,
    this.address,
    this.city,
    this.isActive = true,
    required this.createdAt,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['id'] as String,
      ownerId: json['owner_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String?,
      city: json['city'] as String?,
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
      'name': name,
      'address': address,
      'city': city,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Property copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? address,
    String? city,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Property(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      address: address ?? this.address,
      city: city ?? this.city,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Property &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          ownerId == other.ownerId &&
          name == other.name &&
          address == other.address &&
          city == other.city &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      ownerId.hashCode ^
      name.hashCode ^
      address.hashCode ^
      city.hashCode ^
      isActive.hashCode;
}
