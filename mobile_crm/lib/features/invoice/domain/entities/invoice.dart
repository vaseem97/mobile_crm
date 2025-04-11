import 'package:equatable/equatable.dart';
import '../../../repair/domain/entities/repair_job.dart';

class Invoice extends Equatable {
  final String id;
  final String invoiceNumber;
  final DateTime invoiceDate;
  final RepairJob repairJob;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final double amountPaid;
  final double amountDue;
  final String? notes;
  final String? termsAndConditions;
  final String? shopName;
  final String? shopAddress;
  final String? shopPhone;
  final String? shopEmail;
  final String? shopLogo;

  const Invoice({
    required this.id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.repairJob,
    required this.subtotal,
    required this.taxRate,
    required this.taxAmount,
    required this.total,
    required this.amountPaid,
    required this.amountDue,
    this.notes,
    this.termsAndConditions,
    this.shopName,
    this.shopAddress,
    this.shopPhone,
    this.shopEmail,
    this.shopLogo,
  });

  @override
  List<Object?> get props => [
        id,
        invoiceNumber,
        invoiceDate,
        repairJob,
        subtotal,
        taxRate,
        taxAmount,
        total,
        amountPaid,
        amountDue,
        notes,
        termsAndConditions,
        shopName,
        shopAddress,
        shopPhone,
        shopEmail,
        shopLogo,
      ];

  Invoice copyWith({
    String? id,
    String? invoiceNumber,
    DateTime? invoiceDate,
    RepairJob? repairJob,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    double? amountPaid,
    double? amountDue,
    String? notes,
    String? termsAndConditions,
    String? shopName,
    String? shopAddress,
    String? shopPhone,
    String? shopEmail,
    String? shopLogo,
  }) {
    return Invoice(
      id: id ?? this.id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      repairJob: repairJob ?? this.repairJob,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      amountPaid: amountPaid ?? this.amountPaid,
      amountDue: amountDue ?? this.amountDue,
      notes: notes ?? this.notes,
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      shopName: shopName ?? this.shopName,
      shopAddress: shopAddress ?? this.shopAddress,
      shopPhone: shopPhone ?? this.shopPhone,
      shopEmail: shopEmail ?? this.shopEmail,
      shopLogo: shopLogo ?? this.shopLogo,
    );
  }
}
