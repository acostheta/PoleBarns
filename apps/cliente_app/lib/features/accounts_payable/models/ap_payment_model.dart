import 'package:cliente_app/features/settings/models/payment_method_model.dart';

class APPaymentModel {
  final String id;
  final String apId; // Account Payable ID
  final DateTime date;
  final double amount;
  final String? paymentMethodId;
  final String? notes;
  final DateTime? createdAt;

  // Relations
  final PaymentMethodModel? paymentMethod;

  APPaymentModel({
    required this.id,
    required this.apId,
    required this.date,
    required this.amount,
    this.paymentMethodId,
    this.notes,
    this.createdAt,
    this.paymentMethod,
  });

  factory APPaymentModel.fromJson(Map<String, dynamic> json) {
    return APPaymentModel(
      id: json['id'] as String,
      apId: json['ap_id'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      paymentMethodId: json['payment_method_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      paymentMethod: json['payment_methods'] != null
          ? PaymentMethodModel.fromJson(
              json['payment_methods'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ap_id': apId,
      'date': date.toIso8601String(),
      'amount': amount,
      'payment_method_id': paymentMethodId,
      'notes': notes,
    };
  }
}
