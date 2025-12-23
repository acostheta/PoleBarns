class ProviderModel {
  final String id;
  final String name;
  final String address;
  final DateTime? createdAt;

  ProviderModel({
    required this.id,
    required this.name,
    this.address = '',
    this.createdAt,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, // Usually excluded on create depending on DB defaults
      'name': name,
      'address': address,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? name,
    String? address,
    DateTime? createdAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
