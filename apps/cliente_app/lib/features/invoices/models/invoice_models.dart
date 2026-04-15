class InvoiceModel {
  final int id;
  final String? idProyecto; // UUID
  final String? idCliente; // UUID
  final String? address;
  final DateTime date;
  final double totalVenta;
  final double totalPagado;
  final double saldo;
  final double reembolsado;
  final String? comentario;
  final DateTime createdAt;
  final String? groupId;
  final String? responsible;
  final String status;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? notesForInvoice;

  // Joined fields
  final String? clientName;
  final String? projectName;
  final String? groupName;

  InvoiceModel({
    required this.id,
    this.idProyecto,
    this.idCliente,
    this.address,
    required this.date,
    this.totalVenta = 0.0,
    this.totalPagado = 0.0,
    this.saldo = 0.0,
    this.reembolsado = 0.0,
    this.comentario,
    required this.createdAt,
    this.groupId,
    this.responsible,
    this.status = 'Pendiente',
    this.startDate,
    this.endDate,
    this.notesForInvoice,
    this.clientName,
    this.projectName,
    this.groupName,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    // Utility to parse numbers safely from potential strings or numbers
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return InvoiceModel(
      id: json['id'] ?? 0,
      idProyecto: json['IdProyecto'],
      idCliente: json['IdCliente'],
      address: json['Address'],
      date: parseDate(json['Date']) ?? DateTime.now(),
      totalVenta: parseDouble(json['Total Venta']),
      totalPagado: parseDouble(json['Total Pagado']),
      saldo: parseDouble(json['Saldo']),
      reembolsado: parseDouble(json['Reembolsado']),
      comentario: json['Comentario'],
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      groupId: json['group_id'],
      status: json['status'] ?? 'Pendiente',
      startDate: parseDate(json['start_date']),
      endDate: parseDate(json['end_date']),
      clientName: json['client_full_name'] ??
          (json['clients'] != null
              ? '${json['clients']['first_name']} ${json['clients']['last_name']}'
              : null),
      projectName: json['project_name'] ??
          (json['projects'] != null ? json['projects']['address'] : null),
      groupName: json['worker_group_name'] ??
          (json['worker_groups'] != null
              ? json['worker_groups']['name']
              : null),
      responsible: json['responsible_name'] ??
          (json['worker_groups'] != null
              ? (json['worker_groups']['profiles'] != null
                  ? json['worker_groups']['profiles']['name']
                  : json['worker_groups']['supervisor_id'])
              : json['responsible']),
      notesForInvoice: json['notes_for_invoice'],
    );
  }

  InvoiceModel copyWith({
    int? id,
    String? idProyecto,
    String? idCliente,
    String? address,
    DateTime? date,
    double? totalVenta,
    double? totalPagado,
    double? saldo,
    double? reembolsado,
    String? comentario,
    DateTime? createdAt,
    String? groupId,
    String? responsible,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    String? clientName,
    String? projectName,
    String? groupName,
    String? notesForInvoice,
    String? paymentTerm,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      idProyecto: idProyecto ?? this.idProyecto,
      idCliente: idCliente ?? this.idCliente,
      address: address ?? this.address,
      date: date ?? this.date,
      totalVenta: totalVenta ?? this.totalVenta,
      totalPagado: totalPagado ?? this.totalPagado,
      saldo: saldo ?? this.saldo,
      reembolsado: reembolsado ?? this.reembolsado,
      comentario: comentario ?? this.comentario,
      createdAt: createdAt ?? this.createdAt,
      groupId: groupId ?? this.groupId,
      responsible: responsible ?? this.responsible,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
      groupName: groupName ?? this.groupName,
      notesForInvoice: notesForInvoice ?? this.notesForInvoice,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'IdProyecto': idProyecto,
      'IdCliente': idCliente,
      'Address': address,
      'Date': date.toIso8601String(),
      'Total Venta': totalVenta,
      'Comentario': comentario,
      'group_id': groupId,
      'responsible': responsible,
      'status': status,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'project_name': projectName,
      'notes_for_invoice': notesForInvoice,
    };
  }
}

class GroupModel {
  final String id;
  final String name;
  final String? responsible;

  GroupModel({required this.id, required this.name, this.responsible});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'],
      name: json['name'],
      responsible: json['profiles'] != null
          ? json['profiles']['name']
          : json['supervisor_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'supervisor_id': responsible,
    };
  }
}

class CatalogItemModel {
  final int id;
  final String name;
  final double salePrice;
  final double cost;

  CatalogItemModel({
    required this.id,
    required this.name,
    required this.salePrice,
    required this.cost,
  });

  factory CatalogItemModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CatalogItemModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Item',
      salePrice: parseDouble(json['precio_venta'] ?? json['sale_price']),
      cost: parseDouble(json['cost']),
    );
  }
}

class RelatedProductModel {
  final int id;
  final int idInvoice;
  final String? idProyecto;
  final int? idPoleBarns;
  final String estatus; // 'Pendiente', 'En Proceso', 'Completado'
  final double cantidad;
  final double precioPorUnidad;
  final double tax;
  final double totalPrice;
  final double unitCost;
  final DateTime createdAt;

  // Joined fields
  final String? poleBarnName;

  RelatedProductModel({
    required this.id,
    required this.idInvoice,
    this.idProyecto,
    this.idPoleBarns,
    required this.estatus,
    required this.cantidad,
    required this.precioPorUnidad,
    required this.tax,
    required this.totalPrice,
    required this.unitCost,
    required this.createdAt,
    this.poleBarnName,
  });

  factory RelatedProductModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.parse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return RelatedProductModel(
      id: json['id'] ?? 0,
      idInvoice: json['IdInvoice'] ?? 0,
      idProyecto: json['IdProyecto'],
      idPoleBarns: json['IdPoleBarns'],
      estatus: json['Estatus'] ?? 'Pendiente',
      cantidad: parseDouble(json['Cantidad']),
      precioPorUnidad: parseDouble(json['Precio por unidad']),
      tax: parseDouble(json['Tax']),
      totalPrice: parseDouble(json['Total Price']),
      unitCost: parseDouble(json['unit_cost'] ??
          json['cost'] ??
          json['Unit Cost'] ??
          json['PoleBarns']?['cost']),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
      poleBarnName: json['pole_barn_name'] ??
          (json['PoleBarns'] != null ? json['PoleBarns']['name'] : null),
    );
  }

  RelatedProductModel copyWith({
    int? id,
    int? idInvoice,
    String? idProyecto,
    int? idPoleBarns,
    String? estatus,
    double? cantidad,
    double? precioPorUnidad,
    double? tax,
    double? totalPrice,
    double? unitCost,
    DateTime? createdAt,
    String? poleBarnName,
  }) {
    return RelatedProductModel(
      id: id ?? this.id,
      idInvoice: idInvoice ?? this.idInvoice,
      idProyecto: idProyecto ?? this.idProyecto,
      idPoleBarns: idPoleBarns ?? this.idPoleBarns,
      estatus: estatus ?? this.estatus,
      cantidad: cantidad ?? this.cantidad,
      precioPorUnidad: precioPorUnidad ?? this.precioPorUnidad,
      tax: tax ?? this.tax,
      totalPrice: totalPrice ?? this.totalPrice,
      unitCost: unitCost ?? this.unitCost,
      createdAt: createdAt ?? this.createdAt,
      poleBarnName: poleBarnName ?? this.poleBarnName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'IdInvoice': idInvoice,
      'IdProyecto': idProyecto,
      'IdPoleBarns': idPoleBarns,
      'Estatus': estatus,
      'Cantidad': cantidad,
      'Precio por unidad': precioPorUnidad,
      'Tax': tax,
      'unit_cost': unitCost,
    };
  }
}

class InvoicePaymentModel {
  final int id;
  final int idInvoice;
  final String tipo; // 'Abono', 'Reembolso'
  final double amount;
  final String? metodoDePagoId; // UUID ref to payment_methods
  final String? category;
  final String? nota;
  final double feeAmount;
  final DateTime createdAt;

  // Joined fields
  final String? metodoDePagoNombre;

  InvoicePaymentModel({
    required this.id,
    required this.idInvoice,
    required this.tipo,
    required this.amount,
    this.metodoDePagoId,
    this.category,
    this.nota,
    this.feeAmount = 0.0,
    required this.createdAt,
    this.metodoDePagoNombre,
  });

  // Convenience getters for compatibility
  int? get paymentMethodId =>
      metodoDePagoId != null ? int.tryParse(metodoDePagoId!) : null;
  String? get paymentMethodName => metodoDePagoNombre;

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return InvoicePaymentModel(
      id: json['id'] ?? 0,
      idInvoice: json['IdInvoice'] ?? 0,
      tipo: json['Tipo'] ?? 'Abono',
      amount: parseDouble(json['Amount']),
      metodoDePagoId: json['Metodo de Pago'],
      category: json['Category'],
      nota: json['Nota'],
      feeAmount: parseDouble(json['fee_amount']),
      createdAt:
          DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      metodoDePagoNombre: json['payment_methods'] != null
          ? json['payment_methods']['name']
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != 0) 'id': id,
      'IdInvoice': idInvoice,
      'Tipo': tipo,
      'Amount': amount,
      'Metodo de Pago': metodoDePagoId,
      'Category': category,
      'Nota': nota,
      'fee_amount': feeAmount,
    };
  }
}
