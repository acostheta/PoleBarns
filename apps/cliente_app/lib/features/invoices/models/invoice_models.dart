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

  // Joined fields
  final String? clientName;
  final String? projectName;

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
    this.clientName,
    this.projectName,
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
      clientName: json['clients'] != null
          ? '${json['clients']['first_name']} ${json['clients']['last_name']}'
          : null,
      projectName:
          json['projects'] != null ? json['projects']['address'] : null,
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
    String? clientName,
    String? projectName,
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
      clientName: clientName ?? this.clientName,
      projectName: projectName ?? this.projectName,
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
    };
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
      createdAt: DateTime.parse(json['created_at']),
      poleBarnName:
          json['PoleBarns'] != null ? json['PoleBarns']['name'] : null,
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
    required this.createdAt,
    this.metodoDePagoNombre,
  });

  factory InvoicePaymentModel.fromJson(Map<String, dynamic> json) {
    return InvoicePaymentModel(
      id: json['id'],
      idInvoice: json['IdInvoice'],
      tipo: json['Tipo'],
      amount: (json['Amount'] as num?)?.toDouble() ?? 0.0,
      metodoDePagoId: json['Metodo de Pago'],
      category: json['Category'],
      nota: json['Nota'],
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
    };
  }
}
