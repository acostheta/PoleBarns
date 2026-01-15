import 'package:cliente_app/features/settings/models/provider_model.dart';

class AccountPayableModel {
  final String id;
  final String providerId;
  final DateTime invoiceDate;
  final String? invoiceInternRef;
  final double totalAmount;
  final String? projectId;
  final double totalPaid; // From view
  final double currentBalance; // From view
  final DateTime? createdAt;

  // Relations
  final ProviderModel? provider;
  final String? projectName; // Simplified project name from join

  AccountPayableModel({
    required this.id,
    required this.providerId,
    required this.invoiceDate,
    this.invoiceInternRef,
    required this.totalAmount,
    this.projectId,
    this.totalPaid = 0.0,
    this.currentBalance = 0.0,
    this.createdAt,
    this.provider,
    this.projectName,
  });

  factory AccountPayableModel.fromJson(Map<String, dynamic> json) {
    return AccountPayableModel(
      id: json['id'] as String,
      providerId: json['provider_id'] as String,
      invoiceDate: DateTime.parse(json['invoice_date'] as String),
      invoiceInternRef: json['invoice_intern_ref'] as String?,
      totalAmount: (json['total_amount'] as num).toDouble(),
      projectId: json['project_id'] as String?,
      totalPaid: (json['total_paid'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['current_balance'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      provider: json['providers'] != null
          ? ProviderModel.fromJson(json['providers'] as Map<String, dynamic>)
          : null,
      projectName: json['project_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'project_id': projectId,
      'invoice_date': invoiceDate.toIso8601String(),
      'invoice_intern_ref': invoiceInternRef,
      'total_amount': totalAmount,
    };
  }
}
