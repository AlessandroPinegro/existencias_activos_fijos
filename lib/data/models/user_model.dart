class EmpresaSucursalModel {
  final int id;
  final int empresaId;
  final String empresaNombre;
  final int sucursalId;
  final String sucursalNombre;
  final bool esPrincipal;

  EmpresaSucursalModel({
    required this.id,
    required this.empresaId,
    required this.empresaNombre,
    required this.sucursalId,
    required this.sucursalNombre,
    this.esPrincipal = false,
  });

  factory EmpresaSucursalModel.fromJson(Map<String, dynamic> json) {
    String empNom = 'Empresa #${json['empresa_id']}';
    if (json['empresa'] is Map) {
      empNom = json['empresa']['nombre_comercial'] ??
          json['empresa']['razon_social'] ??
          empNom;
    } else if (json['empresa_nombre'] != null) {
      empNom = json['empresa_nombre'].toString();
    }

    String sucNom = 'Sucursal #${json['sucursal_id']}';
    if (json['sucursal'] is Map) {
      sucNom = json['sucursal']['nombre'] ?? sucNom;
    } else if (json['sucursal_nombre'] != null) {
      sucNom = json['sucursal_nombre'].toString();
    }

    int parseId(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return EmpresaSucursalModel(
      id: parseId(json['id']),
      empresaId: parseId(json['empresa_id'] ?? (json['empresa'] is Map ? json['empresa']['id'] : null)),
      empresaNombre: empNom,
      sucursalId: parseId(json['sucursal_id'] ?? (json['sucursal'] is Map ? json['sucursal']['id'] : null)),
      sucursalNombre: sucNom,
      esPrincipal: json['es_principal'] == true || json['es_principal'] == 1,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa_id': empresaId,
        'empresa_nombre': empresaNombre,
        'sucursal_id': sucursalId,
        'sucursal_nombre': sucursalNombre,
        'es_principal': esPrincipal,
      };
}

class UserModel {
  final int id;
  final String name;
  final String email;
  final int? empresaId;
  final int? sucursalId;
  final String? empresaNombre;
  final String? sucursalNombre;
  final List<String> roles;
  final List<EmpresaSucursalModel> empresaSucursales;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.empresaId,
    this.sucursalId,
    this.empresaNombre,
    this.sucursalNombre,
    required this.roles,
    this.empresaSucursales = const [],
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

    List<EmpresaSucursalModel> parsedEmpresaSucursales = [];
    final rawEmpSuc = json['empresa_sucursales'] ?? json['empresaSucursales'];
    if (rawEmpSuc is List) {
      parsedEmpresaSucursales = rawEmpSuc
          .map((item) => EmpresaSucursalModel.fromJson(item is Map ? Map<String, dynamic>.from(item) : {}))
          .where((es) => es.empresaId > 0 && es.sucursalId > 0)
          .toList();
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
      empresaSucursales: parsedEmpresaSucursales,
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
        'empresa_sucursales': empresaSucursales.map((es) => es.toJson()).toList(),
      };

  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    int? empresaId,
    int? sucursalId,
    String? empresaNombre,
    String? sucursalNombre,
    List<String>? roles,
    List<EmpresaSucursalModel>? empresaSucursales,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      empresaId: empresaId ?? this.empresaId,
      sucursalId: sucursalId ?? this.sucursalId,
      empresaNombre: empresaNombre ?? this.empresaNombre,
      sucursalNombre: sucursalNombre ?? this.sucursalNombre,
      roles: roles ?? this.roles,
      empresaSucursales: empresaSucursales ?? this.empresaSucursales,
    );
  }

  /// Retorna la lista de empresas únicas a las que tiene acceso el usuario
  List<Map<String, dynamic>> get empresasDisponibles {
    final Map<int, String> map = {};
    for (final es in empresaSucursales) {
      if (!map.containsKey(es.empresaId)) {
        map[es.empresaId] = es.empresaNombre;
      }
    }

    // Si la lista de relaciones está vacía pero el usuario tiene empresaId/empresaNombre directa
    if (map.isEmpty && empresaId != null) {
      map[empresaId!] = empresaNombre ?? 'Empresa #$empresaId';
    }

    return map.entries
        .map((entry) => {'id': entry.key, 'nombre': entry.value})
        .toList();
  }

  /// Retorna las sucursales asignadas a una empresa específica
  List<EmpresaSucursalModel> sucursalesDeEmpresa(int empId) {
    return empresaSucursales.where((es) => es.empresaId == empId).toList();
  }
}
