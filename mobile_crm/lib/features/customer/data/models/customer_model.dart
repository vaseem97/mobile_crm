import '../../domain/entities/customer.dart';

class CustomerModel extends Customer {
  const CustomerModel({
    required super.id,
    required super.name,
    required super.phone,
    super.email,
    super.address,
    required super.createdAt,
    super.lastVisit,
    super.repairCount,
    super.totalSpent,
    super.repairIds,
    super.notes,
    super.isActive,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String? ?? '',
      address: json['address'] as String? ?? '',
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastVisit: json['lastVisit'] != null
          ? DateTime.parse(json['lastVisit'] as String)
          : null,
      repairCount: json['repairCount'] as int? ?? 0,
      totalSpent: json['totalSpent'] != null
          ? (json['totalSpent'] as num).toDouble()
          : 0.0,
      repairIds: json['repairIds'] != null
          ? List<String>.from(json['repairIds'] as List)
          : null,
      notes: json['notes'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'createdAt': createdAt.toIso8601String(),
      'lastVisit': lastVisit?.toIso8601String(),
      'repairCount': repairCount,
      'totalSpent': totalSpent,
      'repairIds': repairIds,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory CustomerModel.fromEntity(Customer entity) {
    return CustomerModel(
      id: entity.id,
      name: entity.name,
      phone: entity.phone,
      email: entity.email,
      address: entity.address,
      createdAt: entity.createdAt,
      lastVisit: entity.lastVisit,
      repairCount: entity.repairCount,
      totalSpent: entity.totalSpent,
      repairIds: entity.repairIds,
      notes: entity.notes,
      isActive: entity.isActive,
    );
  }
}
