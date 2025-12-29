class PoleBarn {
  final int? id;
  final double largo;
  final double ancho;
  final double alto;
  final double spacing;
  final double sheet;
  final double totalMaterials;
  final double totalSConcreto;
  final double precioVenta;
  final double budgetLimit;
  final String alertStatus;
  final String? name; // Added name field
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PoleBarn({
    this.id,
    this.name, // Added to constructor
    required this.largo,
    required this.ancho,
    required this.alto,
    required this.spacing,
    required this.sheet,
    this.totalMaterials = 0,
    this.totalSConcreto = 0,
    this.precioVenta = 0,
    this.budgetLimit = 0,
    this.alertStatus = 'OK',
    this.createdAt,
    this.updatedAt,
  });

  factory PoleBarn.fromJson(Map<String, dynamic> json) {
    return PoleBarn(
      id: json['id'],
      name: json['name'], // Added to fromJson
      largo: (json['Largo'] as num?)?.toDouble() ?? 0.0,
      ancho: (json['Ancho'] as num?)?.toDouble() ?? 0.0,
      alto: (json['Alto'] as num?)?.toDouble() ?? 0.0,
      spacing: (json['Spacing'] as num?)?.toDouble() ?? 0.0,
      sheet: (json['Sheet'] as num?)?.toDouble() ?? 0.0,
      totalMaterials: (json['total_materials'] as num?)?.toDouble() ?? 0.0,
      totalSConcreto: (json['total_s_concreto'] as num?)?.toDouble() ?? 0.0,
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
      'name': name, // Added to toJson
      'Largo': largo,
      'Ancho': ancho,
      'Alto': alto,
      'Spacing': spacing,
      'Sheet': sheet,
      'precio_venta': precioVenta,
      'budget_limit': budgetLimit,
      // total_materials, total_s_concreto, and alert_status are managed by triggers
    };
  }

  PoleBarn copyWith({
    int? id,
    String? name, // Added to copyWith
    double? largo,
    double? ancho,
    double? alto,
    double? spacing,
    double? sheet,
    double? totalMaterials,
    double? totalSConcreto,
    double? precioVenta,
    double? budgetLimit,
    String? alertStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PoleBarn(
      id: id ?? this.id,
      name: name ?? this.name, // Added to copyWith return
      largo: largo ?? this.largo,
      ancho: ancho ?? this.ancho,
      alto: alto ?? this.alto,
      spacing: spacing ?? this.spacing,
      sheet: sheet ?? this.sheet,
      totalMaterials: totalMaterials ?? this.totalMaterials,
      totalSConcreto: totalSConcreto ?? this.totalSConcreto,
      precioVenta: precioVenta ?? this.precioVenta,
      budgetLimit: budgetLimit ?? this.budgetLimit,
      alertStatus: alertStatus ?? this.alertStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
