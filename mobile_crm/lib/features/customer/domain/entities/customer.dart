import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final DateTime createdAt;
  final DateTime? lastVisit;
  final int repairCount;
  final double totalSpent;
  final List<String>? repairIds;
  final String? notes;
  final bool isActive;

  const Customer({
    required this.id,
    required this.name,
    required this.phone,
    this.email = '',
    this.address = '',
    required this.createdAt,
    this.lastVisit,
    this.repairCount = 0,
    this.totalSpent = 0.0,
    this.repairIds,
    this.notes,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        phone,
        email,
        address,
        createdAt,
        lastVisit,
        repairCount,
        totalSpent,
        repairIds,
        notes,
        isActive,
      ];

  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    DateTime? createdAt,
    DateTime? lastVisit,
    int? repairCount,
    double? totalSpent,
    List<String>? repairIds,
    String? notes,
    bool? isActive,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
      lastVisit: lastVisit ?? this.lastVisit,
      repairCount: repairCount ?? this.repairCount,
      totalSpent: totalSpent ?? this.totalSpent,
      repairIds: repairIds ?? this.repairIds,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }
}
