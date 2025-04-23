import '../../domain/entities/repair_job.dart';
import '../../../../core/widgets/repair_job_card.dart';

class RepairJobModel extends RepairJob {
  const RepairJobModel({
    required super.id,
    required super.customerName,
    required super.customerPhone,
    super.customerEmail,
    required super.deviceModel,
    required super.deviceBrand,
    required super.deviceColor,
    super.devicePassword,
    super.devicePattern,
    super.deviceImei,
    required super.problem,
    super.diagnosis,
    super.partsToReplace,
    required super.estimatedCost,
    required super.advanceAmount,
    required super.createdAt,
    super.completedAt,
    super.deliveredAt,
    required super.status,
    super.notes,
    super.imageUrls,
    super.warrantyPeriod,
  });

  factory RepairJobModel.fromJson(Map<String, dynamic> json) {
    return RepairJobModel(
      id: json['id'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      customerEmail: json['customerEmail'] as String? ?? '',
      deviceModel: json['deviceModel'] as String,
      deviceBrand: json['deviceBrand'] as String,
      deviceColor: json['deviceColor'] as String,
      devicePassword: json['devicePassword'] as String? ?? '',
      devicePattern: json['devicePattern'] as String? ?? '',
      deviceImei: json['deviceImei'] as String? ?? '',
      problem: json['problem'] as String,
      diagnosis: json['diagnosis'] as String? ?? '',
      partsToReplace: json['partsToReplace'] != null
          ? List<String>.from(json['partsToReplace'] as List)
          : const [],
      estimatedCost: (json['estimatedCost'] as num).toDouble(),
      advanceAmount: json['advanceAmount'] != null
          ? (json['advanceAmount'] as num).toDouble()
          : 0.0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : null,
      status: RepairStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RepairStatus.pending,
      ),
      notes: json['notes'] as String?,
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : null,
      warrantyPeriod: json['warrantyPeriod'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerEmail': customerEmail,
      'deviceModel': deviceModel,
      'deviceBrand': deviceBrand,
      'deviceColor': deviceColor,
      'devicePassword': devicePassword,
      'devicePattern': devicePattern,
      'deviceImei': deviceImei,
      'problem': problem,
      'diagnosis': diagnosis,
      'partsToReplace': partsToReplace,
      'estimatedCost': estimatedCost,
      'advanceAmount': advanceAmount,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
      'status': status.name,
      'notes': notes,
      'imageUrls': imageUrls,
      'warrantyPeriod': warrantyPeriod,
    };
  }

  factory RepairJobModel.fromEntity(RepairJob entity) {
    return RepairJobModel(
      id: entity.id,
      customerName: entity.customerName,
      customerPhone: entity.customerPhone,
      customerEmail: entity.customerEmail,
      deviceModel: entity.deviceModel,
      deviceBrand: entity.deviceBrand,
      deviceColor: entity.deviceColor,
      devicePassword: entity.devicePassword,
      devicePattern: entity.devicePattern,
      deviceImei: entity.deviceImei,
      problem: entity.problem,
      diagnosis: entity.diagnosis,
      partsToReplace: entity.partsToReplace,
      estimatedCost: entity.estimatedCost,
      advanceAmount: entity.advanceAmount,
      createdAt: entity.createdAt,
      completedAt: entity.completedAt,
      deliveredAt: entity.deliveredAt,
      status: entity.status,
      notes: entity.notes,
      imageUrls: entity.imageUrls,
      warrantyPeriod: entity.warrantyPeriod,
    );
  }
}
