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

  final int? invoiceId;

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
    this.invoiceId,
    this.totalPaid = 0.0,
    this.currentBalance = 0.0,
    this.createdAt,
    this.provider,
    this.projectName,
  });

  factory AccountPayableModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return AccountPayableModel(
      id: (json['id'] ?? '').toString(),
      providerId: (json['provider_id'] ?? '').toString(),
      invoiceDate: DateTime.tryParse(json['invoice_date']?.toString() ?? '') ??
          DateTime.now(),
      invoiceInternRef: json['invoice_intern_ref']?.toString(),
      totalAmount: parseDouble(json['total_amount']),
      projectId: json['project_id']?.toString(),
      invoiceId: json['invoice_id'] is int
          ? json['invoice_id']
          : int.tryParse(json['invoice_id']?.toString() ?? ''),
      totalPaid: parseDouble(json['total_paid']),
      currentBalance: parseDouble(json['current_balance']),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      provider: json['providers'] != null
          ? ProviderModel.fromJson(json['providers'] as Map<String, dynamic>)
          : null,
      projectName: json['project_name']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'project_id': projectId,
      'invoice_id': invoiceId,
      'invoice_date': invoiceDate.toIso8601String(),
      'invoice_intern_ref': invoiceInternRef,
      'total_amount': totalAmount,
    };
  }
}
