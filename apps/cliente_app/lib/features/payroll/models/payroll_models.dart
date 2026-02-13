class NominaPagoDiario {
  final String id;
  final String idEmpleado;
  final DateTime fecha;
  final String? nroCheque;
  final String? conceptoPeriodo;
  final double? dias;
  final String? formaPago;
  final double? monto;
  final double? pagoParcial;
  final String? notas;

  NominaPagoDiario({
    required this.id,
    required this.idEmpleado,
    required this.fecha,
    this.nroCheque,
    this.conceptoPeriodo,
    this.dias,
    this.formaPago,
    this.monto,
    this.pagoParcial,
    this.notas,
  });

  factory NominaPagoDiario.fromJson(Map<String, dynamic> json) {
    return NominaPagoDiario(
      id: json['id'],
      idEmpleado: json['id_empleado'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      nroCheque: json['nro_cheque'],
      conceptoPeriodo: json['concepto_periodo'],
      dias: json['dias'] != null ? (json['dias'] as num).toDouble() : null,
      formaPago: json['forma_pago'],
      monto: json['monto'] != null ? (json['monto'] as num).toDouble() : null,
      pagoParcial: json['pago_parcial'] != null
          ? (json['pago_parcial'] as num).toDouble()
          : 0,
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'fecha': fecha.toIso8601String().split('T')[0], // YYYY-MM-DD
      'nro_cheque': nroCheque,
      'concepto_periodo': conceptoPeriodo,
      'dias': dias,
      'forma_pago': formaPago,
      'monto': monto,
      'pago_parcial': pagoParcial,
      'notas': notas,
    };
  }
}

class NominaSoldador {
  final String id;
  final String idEmpleado;
  final DateTime fecha;
  final String? trussProducto;
  final double? cantidad;
  final double? montoUnitario;
  final double? total;
  final double? pagoParcial;
  final String? formaPago;
  final String? notas;

  NominaSoldador({
    required this.id,
    required this.idEmpleado,
    required this.fecha,
    this.trussProducto,
    this.cantidad,
    this.montoUnitario,
    this.total,
    this.pagoParcial,
    this.formaPago,
    this.notas,
  });

  factory NominaSoldador.fromJson(Map<String, dynamic> json) {
    return NominaSoldador(
      id: json['id'],
      idEmpleado: json['id_empleado'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      trussProducto: json['truss_producto'],
      cantidad: json['cantidad'] != null
          ? (json['cantidad'] as num).toDouble()
          : null,
      montoUnitario: json['monto_unitario'] != null
          ? (json['monto_unitario'] as num).toDouble()
          : null,
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      pagoParcial: json['pago_parcial'] != null
          ? (json['pago_parcial'] as num).toDouble()
          : 0,
      formaPago: json['forma_pago'],
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'fecha': fecha.toIso8601String().split('T')[0],
      'truss_producto': trussProducto,
      'cantidad': cantidad,
      'monto_unitario': montoUnitario,
      'forma_pago': formaPago,
      // 'total' is generated always, usually
      'notas': notas,
    };
  }
}

class NominaInstalacion {
  final String id;
  final String idEmpleado;
  final String idProyecto;
  final DateTime? fechaCulminacion;
  final double? pagoProyecto;
  final bool proyectoCerrado;
  final double? pagoParcial;
  final double? saldo;
  final double? descuentos;

  NominaInstalacion({
    required this.id,
    required this.idEmpleado,
    required this.idProyecto,
    this.fechaCulminacion,
    this.pagoProyecto,
    required this.proyectoCerrado,
    this.pagoParcial,
    this.saldo,
    this.descuentos,
  });

  factory NominaInstalacion.fromJson(Map<String, dynamic> json) {
    return NominaInstalacion(
      id: json['id'],
      idEmpleado: json['id_empleado'] ?? '',
      idProyecto: json['id_proyecto'] ?? '',
      fechaCulminacion: json['fecha_culminacion'] != null
          ? DateTime.parse(json['fecha_culminacion'])
          : null,
      pagoProyecto: json['pago_proyecto'] != null
          ? (json['pago_proyecto'] as num).toDouble()
          : null,
      proyectoCerrado: json['proyecto_cerrado'] ?? false,
      pagoParcial: json['pago_parcial'] != null
          ? (json['pago_parcial'] as num).toDouble()
          : 0,
      saldo: json['saldo'] != null ? (json['saldo'] as num).toDouble() : null,
      descuentos: json['descuentos'] != null
          ? (json['descuentos'] as num).toDouble()
          : 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'id_proyecto': idProyecto,
      'fecha_culminacion': fechaCulminacion?.toIso8601String().split('T')[0],
      'pago_proyecto': pagoProyecto,
      'proyecto_cerrado': proyectoCerrado,
      'descuentos': descuentos,
    };
  }
}

class NominaPago {
  final String id;
  final String tipo; // 'Instalación', 'Soldadura', 'Pago Diario', 'Chofer'
  final String? idNominaSoldadura;
  final String? idNominaInstalacion;
  final String? idNominaPagoDiario;
  final String? idNominaChofer;
  final double amount;
  final String? metodoPago;
  final String? category;
  final String? nota;
  final DateTime? createdAt;

  NominaPago({
    required this.id,
    required this.tipo,
    this.idNominaSoldadura,
    this.idNominaInstalacion,
    this.idNominaPagoDiario,
    this.idNominaChofer,
    required this.amount,
    this.metodoPago,
    this.category,
    this.nota,
    this.createdAt,
  });

  factory NominaPago.fromJson(Map<String, dynamic> json) {
    return NominaPago(
      id: json['id'],
      tipo: json['tipo'],
      idNominaSoldadura: json['id_nomina_soldadura'],
      idNominaInstalacion: json['id_nomina_instalacion'],
      idNominaPagoDiario: json['id_nomina_pago_diario'],
      idNominaChofer: json['id_nomina_chofer'],
      amount: (json['amount'] as num).toDouble(),
      metodoPago: json['metodo_pago'],
      category: json['category'],
      nota: json['nota'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tipo': tipo,
      'id_nomina_soldadura': idNominaSoldadura,
      'id_nomina_instalacion': idNominaInstalacion,
      'id_nomina_pago_diario': idNominaPagoDiario,
      'id_nomina_chofer': idNominaChofer,
      'amount': amount,
      'metodo_pago': metodoPago,
      'category': category,
      'nota': nota,
    };
  }
}

class NominaChofer {
  final String id;
  final String idEmpleado;
  final DateTime fecha;
  final String? tareas;
  final double? horas;
  final double? ratePorHora;
  final double? total;
  final double? pagoParcial;
  final String? notas;

  NominaChofer({
    required this.id,
    required this.idEmpleado,
    required this.fecha,
    this.tareas,
    this.horas,
    this.ratePorHora,
    this.total,
    this.pagoParcial,
    this.notas,
  });

  factory NominaChofer.fromJson(Map<String, dynamic> json) {
    return NominaChofer(
      id: json['id'],
      idEmpleado: json['id_empleado'] ?? '',
      fecha: DateTime.parse(json['fecha']),
      tareas: json['tareas'],
      horas: json['horas'] != null ? (json['horas'] as num).toDouble() : null,
      ratePorHora: json['rate_por_hora'] != null
          ? (json['rate_por_hora'] as num).toDouble()
          : null,
      total: json['total'] != null ? (json['total'] as num).toDouble() : null,
      pagoParcial: json['pago_parcial'] != null
          ? (json['pago_parcial'] as num).toDouble()
          : 0,
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_empleado': idEmpleado,
      'fecha': fecha.toIso8601String().split('T')[0],
      'tareas': tareas,
      'horas': horas,
      'rate_por_hora': ratePorHora,
      'notas': notas,
    };
  }
}
