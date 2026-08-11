class MobileModuleModel {
  final int moduleId;
  final String moduleNombre;
  final String? moduleIcono;
  final List<MobileOptionModel> opciones;

  MobileModuleModel({
    required this.moduleId,
    required this.moduleNombre,
    this.moduleIcono,
    required this.opciones,
  });

  factory MobileModuleModel.fromJson(Map<String, dynamic> json) {
    return MobileModuleModel(
      moduleId: json['module_id'] ?? 0,
      moduleNombre: json['module_nombre'] ?? '',
      moduleIcono: json['module_icono'],
      opciones: (json['opciones'] as List? ?? [])
          .map((item) => MobileOptionModel.fromJson(item))
          .where((opt) => opt.esMovil == true) // Filtra exclusivamente opciones móviles
          .toList(),
    );
  }
}

class MobileOptionModel {
  final String codigoNivel;
  final String opcion;
  final String? urlFrom;
  final String? icono;
  final int orden;
  final bool esMovil;
  final List<MobileAccionModel> acciones;

  MobileOptionModel({
    required this.codigoNivel,
    required this.opcion,
    this.urlFrom,
    this.icono,
    required this.orden,
    required this.esMovil,
    required this.acciones,
  });

  factory MobileOptionModel.fromJson(Map<String, dynamic> json) {
    return MobileOptionModel(
      codigoNivel: json['codigo_nivel'] ?? '',
      opcion: json['opcion'] ?? '',
      urlFrom: json['url_from'],
      icono: json['icono'],
      orden: json['orden'] ?? 0,
      esMovil: json['es_movil'] ?? false,
      acciones: (json['acciones'] as List? ?? [])
          .map((item) => MobileAccionModel.fromJson(item))
          .toList(),
    );
  }
}

class MobileAccionModel {
  final String codigoNivel;
  final String opcion;
  final int orden;
  final bool esMovil;

  MobileAccionModel({
    required this.codigoNivel,
    required this.opcion,
    required this.orden,
    required this.esMovil,
  });

  factory MobileAccionModel.fromJson(Map<String, dynamic> json) {
    return MobileAccionModel(
      codigoNivel: json['codigo_nivel'] ?? '',
      opcion: json['opcion'] ?? '',
      orden: json['orden'] ?? 0,
      esMovil: json['es_movil'] ?? false,
    );
  }
}
