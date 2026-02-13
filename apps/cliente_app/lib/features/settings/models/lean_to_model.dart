class LeanTo {
  final String id;
  final String name;
  final double cost;
  final DateTime? createdAt;

  LeanTo({
    required this.id,
    required this.name,
    required this.cost,
    this.createdAt,
  });

  factory LeanTo.fromJson(Map<String, dynamic> json) {
    return LeanTo(
      id: json['id'],
      name: json['name'] ?? '',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cost': cost,
    };
  }
}
