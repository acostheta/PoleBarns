class RelatedMaterial {
  final int? id;
  final int? poleBarnsRef;
  final String? materialId;
  final String? medida;
  final double qty;
  final double wastePercent;
  final double pricePorUnidad;
  final double costPorUnidad; // Added cost
  final double? total;
  final String? materialName;
  final int sortOrder;

  RelatedMaterial({
    this.id,
    this.poleBarnsRef,
    this.materialId,
    this.medida,
    required this.qty,
    required this.wastePercent,
    required this.pricePorUnidad,
    this.costPorUnidad = 0,
    this.total,
    this.materialName,
    this.sortOrder = 0,
  });

  factory RelatedMaterial.fromJson(Map<String, dynamic> json) {
    return RelatedMaterial(
      id: json['id'],
      poleBarnsRef: json['PoleBarns_Ref'] ?? json['pole_barns_ref'],
      materialId: json['Material'] ?? json['material_id'],
      medida: json['Medida'] ?? json['medida'],
      qty: (json['Qty'] ?? json['qty'] as num?)?.toDouble() ?? 0.0,
      wastePercent:
          (json['Waste %'] ?? json['waste_percent'] as num?)?.toDouble() ?? 0.0,
      pricePorUnidad: (json['Price por unidad'] ??
                  json['price_por_unidad'] ??
                  json['price_per_unit'] as num?)
              ?.toDouble() ??
          0.0,
      costPorUnidad:
          (json['raw_materials']?['cost'] as num?)?.toDouble() ?? 0.0,
      total: (json['Total'] ?? json['total'] as num?)?.toDouble(),
      materialName: json['raw_materials']?['name'],
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'PoleBarns_Ref': poleBarnsRef,
      'Material': materialId,
      'Medida': medida,
      'Qty': qty,
      'Waste %': wastePercent,
      'Price por unidad': pricePorUnidad,
      'sort_order': sortOrder,
    };
  }

  RelatedMaterial copyWith({
    int? id,
    int? poleBarnsRef,
    String? materialId,
    String? medida,
    double? qty,
    double? wastePercent,
    double? pricePorUnidad,
    double? costPorUnidad,
    double? total,
    String? materialName,
    int? sortOrder,
  }) {
    return RelatedMaterial(
      id: id ?? this.id,
      poleBarnsRef: poleBarnsRef ?? this.poleBarnsRef,
      materialId: materialId ?? this.materialId,
      medida: medida ?? this.medida,
      qty: qty ?? this.qty,
      wastePercent: wastePercent ?? this.wastePercent,
      pricePorUnidad: pricePorUnidad ?? this.pricePorUnidad,
      costPorUnidad: costPorUnidad ?? this.costPorUnidad,
      total: total ?? this.total,
      materialName: materialName ?? this.materialName,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  double get calculatedTotal =>
      (qty * pricePorUnidad) * (1 + (wastePercent / 100));

  double get calculatedCost =>
      (qty * costPorUnidad) * (1 + (wastePercent / 100));
}
