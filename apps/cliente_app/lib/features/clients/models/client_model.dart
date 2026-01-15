class ClientModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? telefono;
  final String? email;
  final String? direccion;
  final String? notas;
  final String? photoUrl;

  ClientModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.telefono,
    this.email,
    this.direccion,
    this.notas,
    this.photoUrl,
  });

  String get nombre => "$firstName $lastName".trim();

  factory ClientModel.fromJson(Map<String, dynamic> json) {
    return ClientModel(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      telefono: json['phone'] ?? json['telefono'], // Handle both just in case
      email: json['email'],
      direccion: json['address'] ?? json['direccion'],
      notas: json['note'] ?? json['notas'],
      photoUrl: json['photo_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': telefono,
      'email': email,
      'address': direccion,
      'note': notas,
      'photo_url': photoUrl,
    };
  }
}
