class ProviderModel {
  final String id;
  final String ref;
  final String name;
  final String address;
  final DateTime? createdAt;

  ProviderModel({
    required this.id,
    required this.ref,
    required this.name,
    this.address = '',
    this.createdAt,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['id'] as String,
      ref: json['ref'] as String,
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
      'ref': ref,
      'name': name,
      'address': address,
    };
  }

  ProviderModel copyWith({
    String? id,
    String? ref,
    String? name,
    String? address,
    DateTime? createdAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      ref: ref ?? this.ref,
      name: name ?? this.name,
      address: address ?? this.address,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
