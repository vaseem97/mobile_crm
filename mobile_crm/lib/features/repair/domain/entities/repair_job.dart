import 'package:equatable/equatable.dart';
import '../../../../core/widgets/repair_job_card.dart';

class RepairJob extends Equatable {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String deviceModel;
  final String deviceBrand;
  final String deviceColor;
  final String devicePassword;
  final String devicePattern;
  final String deviceImei;
  final String problem;
  final String diagnosis;
  final List<String> partsToReplace;
  final double estimatedCost;
  final double advanceAmount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? deliveredAt;
  final RepairStatus status;
  final String? notes;
  final List<String>? imageUrls;
  final String? warrantyPeriod;

  const RepairJob({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail = '',
    required this.deviceModel,
    required this.deviceBrand,
    this.deviceColor = '',
    this.devicePassword = '',
    this.devicePattern = '',
    this.deviceImei = '',
    required this.problem,
    this.diagnosis = '',
    this.partsToReplace = const [],
    required this.estimatedCost,
    this.advanceAmount = 0.0,
    required this.createdAt,
    this.completedAt,
    this.deliveredAt,
    required this.status,
    this.notes,
    this.imageUrls,
    this.warrantyPeriod,
  });

  @override
  List<Object?> get props => [
        id,
        customerName,
        customerPhone,
        customerEmail,
        deviceModel,
        deviceBrand,
        deviceColor,
        devicePassword,
        devicePattern,
        deviceImei,
        problem,
        diagnosis,
        partsToReplace,
        estimatedCost,
        advanceAmount,
        createdAt,
        completedAt,
        deliveredAt,
        status,
        notes,
        imageUrls,
        warrantyPeriod,
      ];

  RepairJob copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? deviceModel,
    String? deviceBrand,
    String? deviceColor,
    String? devicePassword,
    String? devicePattern,
    String? deviceImei,
    String? problem,
    String? diagnosis,
    List<String>? partsToReplace,
    double? estimatedCost,
    double? advanceAmount,
    DateTime? createdAt,
    DateTime? completedAt,
    DateTime? deliveredAt,
    RepairStatus? status,
    String? notes,
    List<String>? imageUrls,
    String? warrantyPeriod,
  }) {
    return RepairJob(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      deviceModel: deviceModel ?? this.deviceModel,
      deviceBrand: deviceBrand ?? this.deviceBrand,
      deviceColor: deviceColor ?? this.deviceColor,
      devicePassword: devicePassword ?? this.devicePassword,
      devicePattern: devicePattern ?? this.devicePattern,
      deviceImei: deviceImei ?? this.deviceImei,
      problem: problem ?? this.problem,
      diagnosis: diagnosis ?? this.diagnosis,
      partsToReplace: partsToReplace ?? this.partsToReplace,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      advanceAmount: advanceAmount ?? this.advanceAmount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      imageUrls: imageUrls ?? this.imageUrls,
      warrantyPeriod: warrantyPeriod ?? this.warrantyPeriod,
    );
  }
}
