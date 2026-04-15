class ProjectModel {
  final String id;
  final String refCliente;
  final String? responsable;
  final String? estatus;
  final DateTime? fechaInicio;
  final DateTime? fechaFinalizacion;
  final String? grupoAsignado;
  final String? address;
  final String? direccion;
  final double ventaTotal;
  final double costosTotales;
  final double profit;
  final String? comments;
  final DateTime? fechaUltimaEvidencia;
  final DateTime createdAt;

  ProjectModel({
    required this.id,
    required this.refCliente,
    this.responsable,
    this.estatus,
    this.fechaInicio,
    this.fechaFinalizacion,
    this.grupoAsignado,
    this.address,
    this.direccion,
    this.ventaTotal = 0.0,
    this.costosTotales = 0.0,
    this.profit = 0.0,
    this.comments,
    this.fechaUltimaEvidencia,
    required this.createdAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      try {
        return DateTime.tryParse(value.toString());
      } catch (_) {
        return null;
      }
    }

    return ProjectModel(
      id: json['id'] ?? '',
      refCliente: json['ref_cliente'] ?? '',
      responsable: json['responsable'],
      estatus: json['estatus'],
      fechaInicio: parseDate(json['fecha_inicio']),
      fechaFinalizacion: parseDate(json['fecha_finalizacion']),
      grupoAsignado: json['grupo_asignado'],
      address: json['address'],
      direccion: json['direccion'],
      ventaTotal: parseDouble(json['venta_total']),
      costosTotales: parseDouble(json['costos_totales']),
      profit: parseDouble(json['profit']),
      comments: json['comments'],
      fechaUltimaEvidencia: parseDate(json['fecha_ultima_evidencia']),
      createdAt: parseDate(json['created_at']) ?? DateTime.now(),
    );
  }

  ProjectModel copyWith({
    String? id,
    String? refCliente,
    String? responsable,
    String? estatus,
    DateTime? fechaInicio,
    DateTime? fechaFinalizacion,
    String? grupoAsignado,
    String? address,
    String? direccion,
    double? ventaTotal,
    double? costosTotales,
    double? profit,
    String? comments,
    DateTime? fechaUltimaEvidencia,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      refCliente: refCliente ?? this.refCliente,
      responsable: responsable ?? this.responsable,
      estatus: estatus ?? this.estatus,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFinalizacion: fechaFinalizacion ?? this.fechaFinalizacion,
      grupoAsignado: grupoAsignado ?? this.grupoAsignado,
      address: address ?? this.address,
      direccion: direccion ?? this.direccion,
      ventaTotal: ventaTotal ?? this.ventaTotal,
      costosTotales: costosTotales ?? this.costosTotales,
      profit: profit ?? this.profit,
      comments: comments ?? this.comments,
      fechaUltimaEvidencia: fechaUltimaEvidencia ?? this.fechaUltimaEvidencia,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty)
        'id': id, // Only include ID if present (for updates), inserts may omit
      'ref_cliente': refCliente,
      'responsable': responsable,
      'estatus': estatus,
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_finalizacion': fechaFinalizacion?.toIso8601String(),
      'grupo_asignado': grupoAsignado,
      'address': address,
      'direccion': direccion,
      'venta_total': ventaTotal,
      'costos_totales': costosTotales,
      'comments': comments,
      'fecha_ultima_evidencia': fechaUltimaEvidencia?.toIso8601String(),
      // profit excluded as it's computed
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProjectCostModel {
  final String id;
  final String projectRef;
  final String concepto;
  final double monto;
  final String? notas;
  final DateTime createdAt;

  ProjectCostModel({
    required this.id,
    required this.projectRef,
    required this.concepto,
    required this.monto,
    this.notas,
    required this.createdAt,
  });

  factory ProjectCostModel.fromJson(Map<String, dynamic> json) {
    return ProjectCostModel(
      id: json['id'],
      projectRef: json['project_ref'],
      concepto: json['concepto'],
      monto: (json['monto'] as num?)?.toDouble() ?? 0.0,
      notas: json['notas'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_ref': projectRef,
      'concepto': concepto,
      'monto': monto,
      'notas': notas,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ProjectMediaModel {
  final String id;
  final String projectRef;
  final String urlMedia;
  final DateTime fecha;
  final String? descripcion;
  final String usuarioCargaRef;
  final String? usuarioNombre;
  final DateTime createdAt;

  final int orderIndex;

  ProjectMediaModel({
    required this.id,
    required this.projectRef,
    required this.urlMedia,
    required this.fecha,
    this.descripcion,
    required this.usuarioCargaRef,
    this.usuarioNombre,
    required this.createdAt,
    this.orderIndex = 0,
  });

  factory ProjectMediaModel.fromJson(Map<String, dynamic> json) {
    return ProjectMediaModel(
      id: json['id'],
      projectRef: json['project_ref'],
      urlMedia: json['url_media'],
      fecha: json['fecha'] != null
          ? DateTime.parse(json['fecha'])
          : DateTime.parse(json['created_at']),
      descripcion: json['descripcion'],
      usuarioCargaRef: json['usuario_carga_ref'],
      usuarioNombre: json['usuario_nombre'],
      createdAt: DateTime.parse(json['created_at']),
      orderIndex: json['order_index'] ?? 0,
    );
  }

  ProjectMediaModel copyWith({
    String? id,
    String? projectRef,
    String? urlMedia,
    DateTime? fecha,
    String? descripcion,
    String? usuarioCargaRef,
    String? usuarioNombre,
    DateTime? createdAt,
    int? orderIndex,
  }) {
    return ProjectMediaModel(
      id: id ?? this.id,
      projectRef: projectRef ?? this.projectRef,
      urlMedia: urlMedia ?? this.urlMedia,
      fecha: fecha ?? this.fecha,
      descripcion: descripcion ?? this.descripcion,
      usuarioCargaRef: usuarioCargaRef ?? this.usuarioCargaRef,
      usuarioNombre: usuarioNombre ?? this.usuarioNombre,
      createdAt: createdAt ?? this.createdAt,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_ref': projectRef,
      'url_media': urlMedia,
      'fecha': fecha.toIso8601String().split('T')[0],
      'descripcion': descripcion,
      'usuario_carga_ref': usuarioCargaRef,
      'usuario_nombre': usuarioNombre,
      'created_at': createdAt.toIso8601String(),
      'order_index': orderIndex,
    };
  }
}

class ProjectChatModel {
  final String id;
  final String projectRef;
  final String usuarioRef;
  final String? nombreDesnormalizado;
  final String? photoDesnormalizado;
  final String mensaje;
  final DateTime createdAt;

  ProjectChatModel({
    required this.id,
    required this.projectRef,
    required this.usuarioRef,
    this.nombreDesnormalizado,
    this.photoDesnormalizado,
    required this.mensaje,
    required this.createdAt,
  });

  factory ProjectChatModel.fromJson(Map<String, dynamic> json) {
    return ProjectChatModel(
      id: json['id'],
      projectRef: json['project_ref'],
      usuarioRef: json['usuario_ref'],
      nombreDesnormalizado: json['nombre_desnormalizado'],
      photoDesnormalizado: json['photo_desnormalizado'],
      mensaje: json['mensaje'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_ref': projectRef,
      'usuario_ref': usuarioRef,
      'nombre_desnormalizado': nombreDesnormalizado,
      'photo_desnormalizado': photoDesnormalizado,
      'mensaje': mensaje,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class ClientSimpleModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? photoUrl;
  final String? phone;
  final String? address;

  ClientSimpleModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.photoUrl,
    this.phone,
    this.address,
  });

  String get fullName => '$firstName $lastName';

  factory ClientSimpleModel.fromJson(Map<String, dynamic> json) {
    return ClientSimpleModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
    );
  }
}

class ProjectPoleBarnModel {
  final String id;
  final String projectId;
  final int poleBarnId;
  final double salePrice;
  final DateTime createdAt;
  // Join fields
  final String? poleBarnName;
  final String status;

  ProjectPoleBarnModel({
    required this.id,
    required this.projectId,
    required this.poleBarnId,
    required this.salePrice,
    required this.createdAt,
    this.poleBarnName,
    this.status = 'Pendiente',
  });

  factory ProjectPoleBarnModel.fromJson(Map<String, dynamic> json) {
    return ProjectPoleBarnModel(
      id: json['id'],
      projectId: json['project_id'],
      poleBarnId: json['pole_barn_id'],
      salePrice: (json['sale_price'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.parse(json['created_at']),
      poleBarnName: json['PoleBarns']?['name'],
      status: json['status'] ?? 'Pendiente',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'project_id': projectId,
      'pole_barn_id': poleBarnId,
      'sale_price': salePrice,
      'status': status,
    };
  }
}
