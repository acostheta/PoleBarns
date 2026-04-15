class PoleBarn {
  final int? id;
  final double largo;
  final double ancho;
  final double alto;
  final double spacing;
  final double sheet;
  final String tamano;
  final double total; // Sales price related
  final double labour;
  final double cost; // Purchase cost (materials)
  final double precioVenta;
  final double budgetLimit;
  final String alertStatus;
  final String? name;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PoleBarn({
    this.id,
    this.name,
    required this.largo,
    required this.ancho,
    required this.alto,
    required this.spacing,
    required this.sheet,
    this.tamano = '',
    this.total = 0,
    this.labour = 0,
    this.cost = 0,
    this.precioVenta = 0,
    this.budgetLimit = 0,
    this.alertStatus = 'OK',
    this.createdAt,
    this.updatedAt,
  });

  factory PoleBarn.fromJson(Map<String, dynamic> json) {
    return PoleBarn(
      id: json['id'],
      name: json['name'],
      largo: (json['Largo'] as num?)?.toDouble() ?? 0.0,
      ancho: (json['Ancho'] as num?)?.toDouble() ?? 0.0,
      alto: (json['Alto'] as num?)?.toDouble() ?? 0.0,
      spacing: (json['Spacing'] as num?)?.toDouble() ?? 0.0,
      sheet: (json['Sheet'] as num?)?.toDouble() ?? 0.0,
      tamano: json['Tamano']?.toString() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      labour: (json['labour'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      precioVenta: (json['precio_venta'] as num?)?.toDouble() ?? 0.0,
      budgetLimit: (json['budget_limit'] as num?)?.toDouble() ?? 0.0,
      alertStatus: json['alert_status'] ?? 'OK',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'Largo': largo,
      'Ancho': ancho,
      'Alto': alto,
      'Spacing': spacing,
      'Sheet': sheet,
      'Tamano': tamano,
      'labour': labour,
      'cost': cost,
      'precio_venta': precioVenta,
      'budget_limit': budgetLimit,
    };
  }

  PoleBarn copyWith({
    int? id,
    String? name,
    double? largo,
    double? ancho,
    double? alto,
    double? spacing,
    double? sheet,
    String? tamano,
    double? total,
    double? labour,
    double? cost,
    double? precioVenta,
    double? budgetLimit,
    String? alertStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PoleBarn(
      id: id ?? this.id,
      name: name ?? this.name,
      largo: largo ?? this.largo,
      ancho: ancho ?? this.ancho,
      alto: alto ?? this.alto,
      spacing: spacing ?? this.spacing,
      sheet: sheet ?? this.sheet,
      tamano: tamano ?? this.tamano,
      total: total ?? this.total,
      labour: labour ?? this.labour,
      cost: cost ?? this.cost,
      precioVenta: precioVenta ?? this.precioVenta,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      alertStatus: alertStatus ?? this.alertStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
