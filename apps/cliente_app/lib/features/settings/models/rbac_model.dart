class AppModule {
  final String id;
  final String name;
  final String key;

  AppModule({
    required this.id,
    required this.name,
    required this.key,
  });

  factory AppModule.fromJson(Map<String, dynamic> json) {
    return AppModule(
      id: json['id'] as String,
      name: json['name'] as String,
      key: json['key'] as String,
    );
  }
}

class RolePermission {
  final String id;
  final String roleName;
  final String moduleId;
  final bool canAccess;

  RolePermission({
    required this.id,
    required this.roleName,
    required this.moduleId,
    required this.canAccess,
  });

  factory RolePermission.fromJson(Map<String, dynamic> json) {
    return RolePermission(
      id: json['id'] as String,
      roleName: json['role_name'] as String,
      moduleId: json['module_id'] as String,
      canAccess: json['can_access'] as bool,
    );
  }
}
