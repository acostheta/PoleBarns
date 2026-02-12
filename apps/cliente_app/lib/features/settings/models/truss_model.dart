class Truss {
  final String id;
  final String name;
  final double cost;
  final DateTime? createdAt;

  Truss({
    required this.id,
    required this.name,
    required this.cost,
    this.createdAt,
  });

  factory Truss.fromJson(Map<String, dynamic> json) {
    return Truss(
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

class SpecificTruss {
  final String id;
  final String nominaSoldadorId;
  final String trussId;
  final String trussName;
  final double quantity;
  final double unitPrice;
  final double total;
  final DateTime? createdAt;

  SpecificTruss({
    required this.id,
    required this.nominaSoldadorId,
    required this.trussId,
    required this.trussName,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.createdAt,
  });

  factory SpecificTruss.fromJson(Map<String, dynamic> json) {
    return SpecificTruss(
      id: json['id'],
      nominaSoldadorId: json['nomina_soldador_id'] ?? '',
      trussId: json['truss_id'] ?? '',
      trussName: json['truss_name'] ?? '',
      quantity: (json['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomina_soldador_id': nominaSoldadorId,
      'truss_id': trussId,
      'truss_name': trussName,
      'quantity': quantity,
      'unit_price': unitPrice,
    };
  }
}
