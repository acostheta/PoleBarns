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
    return InvoiceModel(
      id: json['id'],
      idProyecto: json['IdProyecto'],
      idCliente: json['IdCliente'],
      address: json['Address'],
      date: DateTime.parse(json['Date']),
      totalVenta: (json['Total Venta'] as num?)?.toDouble() ?? 0.0,
      totalPagado: (json['Total Pagado'] as num?)?.toDouble() ?? 0.0,
      saldo: (json['Saldo'] as num?)?.toDouble() ?? 0.0,
      reembolsado: (json['Reembolsado'] as num?)?.toDouble() ?? 0.0,
      comentario: json['Comentario'],
      createdAt: DateTime.parse(json['created_at']),
      groupId: json['group_id'],
      status: json['status'] ?? 'Pendiente',
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      endDate:
          json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
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
    // Assuming mapping from PoleBarns table
    return CatalogItemModel(
      id: json['id'], // pole_barn_id? or id? need to check PoleBarns schema.
      // In project_pole_barns usage: 'PoleBarns': {'name': ...}
      // Let's assume standard 'name' and 'sale_price' or 'price'.
      name: json['name'] ?? 'Item',
      salePrice: (json['precio_venta'] as num?)?.toDouble() ?? 0.0,
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
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
    return RelatedProductModel(
      id: json['id'],
      idInvoice: json['IdInvoice'],
      idProyecto: json['IdProyecto'],
      idPoleBarns: json['IdPoleBarns'],
      estatus: json['Estatus'] ?? 'Pendiente',
      cantidad: (json['Cantidad'] as num?)?.toDouble() ?? 0.0,
      precioPorUnidad: (json['Precio por unidad'] as num?)?.toDouble() ?? 0.0,
      tax: (json['Tax'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (json['Total Price'] as num?)?.toDouble() ?? 0.0,
      unitCost: (json['unit_cost'] as num?)?.toDouble() ??
          (json['cost'] as num?)?.toDouble() ??
          (json['Unit Cost'] as num?)?.toDouble() ??
          (json['PoleBarns']?['cost'] as num?)?.toDouble() ??
          0.0,
      createdAt: DateTime.parse(json['created_at']),
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
    return InvoicePaymentModel(
      id: json['id'],
      idInvoice: json['IdInvoice'],
      tipo: json['Tipo'],
      amount: (json['Amount'] as num?)?.toDouble() ?? 0.0,
      metodoDePagoId: json['Metodo de Pago'],
      category: json['Category'],
      nota: json['Nota'],
      feeAmount: (json['fee_amount'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
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
