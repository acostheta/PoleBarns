class PaymentMethodModel {
  final String id;
  final String name;
  final double serviceFee; // Percentage, e.g., 3.5 for 3.5%
  final DateTime? createdAt;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.serviceFee = 0.0,
    this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      serviceFee: (json['service_fee'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'service_fee': serviceFee,
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    double? serviceFee,
    DateTime? createdAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      serviceFee: serviceFee ?? this.serviceFee,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
