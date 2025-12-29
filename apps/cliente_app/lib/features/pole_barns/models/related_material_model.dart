class RelatedMaterial {
  final int? id;
  final int? poleBarnsRef;
  final String? materialId;
  final String? medida;
  final double qty;
  final double wastePercent;
  final double pricePorUnidad;
  final double? total;
  final String? materialName; // Added for display convenience

  RelatedMaterial({
    this.id,
    this.poleBarnsRef,
    this.materialId,
    this.medida,
    required this.qty,
    required this.wastePercent,
    required this.pricePorUnidad,
    this.total,
    this.materialName,
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
      total: (json['Total'] ?? json['total'] as num?)?.toDouble(),
      materialName: json['raw_materials']?['name'],
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
    double? total,
    String? materialName,
  }) {
    return RelatedMaterial(
      id: id ?? this.id,
      poleBarnsRef: poleBarnsRef ?? this.poleBarnsRef,
      materialId: materialId ?? this.materialId,
      medida: medida ?? this.medida,
      qty: qty ?? this.qty,
      wastePercent: wastePercent ?? this.wastePercent,
      pricePorUnidad: pricePorUnidad ?? this.pricePorUnidad,
      total: total ?? this.total,
      materialName: materialName ?? this.materialName,
    );
  }

  double get calculatedTotal =>
      (qty * pricePorUnidad) * (1 + (wastePercent / 100));
}
