class ClientModel {
  final String id;
  final String nombre;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? notas;

  ClientModel({
    required this.id,
    required this.nombre,
    this.telefono,
    this.email,
    this.direccion,
    this.notas,
  });

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      nombre: json['nombre'],
      telefono: json['telefono'],
      email: json['email'],
      direccion: json['direccion'],
      notas: json['notas'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'telefono': telefono,
      'email': email,
      'direccion': direccion,
      'notas': notas,
    };
  }
}
