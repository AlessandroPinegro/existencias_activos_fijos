class UserModel {
  final int id;
  final String name;
  final String email;
  final int? empresaId;
  final int? sucursalId;
  final String? empresaNombre;
  final String? sucursalNombre;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.empresaId,
    this.sucursalId,
    this.empresaNombre,
    this.sucursalNombre,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedRoles = [];
    if (json['roles'] is List) {
      parsedRoles = (json['roles'] as List).map((r) {
        if (r is Map && r.containsKey('nombre')) {
          return r['nombre'].toString();
        }
        return r.toString();
      }).toList();
    }

    String? empNombre;
    if (json['empresa'] is Map) {
      empNombre = json['empresa']['nombre_comercial'] ?? json['empresa']['razon_social'];
    }

    String? sucNombre;
    if (json['sucursal'] is Map) {
      sucNombre = json['sucursal']['nombre'];
    }

    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['nombres'] ?? '',
      email: json['email'] ?? '',
      empresaId: json['empresa_id'],
      sucursalId: json['sucursal_id'],
      empresaNombre: empNombre ?? json['empresa_nombre'],
      sucursalNombre: sucNombre ?? json['sucursal_nombre'],
      roles: parsedRoles,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'empresa_id': empresaId,
        'sucursal_id': sucursalId,
        'empresa_nombre': empresaNombre,
        'sucursal_nombre': sucursalNombre,
        'roles': roles,
      };
}
