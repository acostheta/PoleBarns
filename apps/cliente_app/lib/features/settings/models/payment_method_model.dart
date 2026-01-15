class PaymentMethodModel {
  final String id;
  final String name;
  final DateTime? createdAt;

  PaymentMethodModel({
    required this.id,
    required this.name,
    this.createdAt,
  });

  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'].toString(),
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }

  PaymentMethodModel copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
  }) {
    return PaymentMethodModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
