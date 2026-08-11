class ExistenciaModel {
  final int id;
  final int item;
  final String codigo;
  final String nombreProducto;
  final String unidadMedida;
  final double valorUnitario;
  final String? lote;
  final int? almacenId;
  final String? almacenNombre;
  final String? fechaVencimiento;
  final String? ubicacion;
  final double stockSistema;
  final double cantidadContada;
  final double diferencia;
  final double valorTotalDiferencia;
  final String condicion;
  final int empresaId;
  final int? sucursalId;
  final String? observacion;
  final String? imagenPath;
  final String? fechaConteo;
  final String? sustentoObservacion;
  final String? sustentoArchivoPath;

  ExistenciaModel({
    required this.id,
    required this.item,
    required this.codigo,
    required this.nombreProducto,
    required this.unidadMedida,
    required this.valorUnitario,
    this.lote,
    this.almacenId,
    this.almacenNombre,
    this.fechaVencimiento,
    this.ubicacion,
    required this.stockSistema,
    required this.cantidadContada,
    required this.diferencia,
    required this.valorTotalDiferencia,
    required this.condicion,
    required this.empresaId,
    this.sucursalId,
    this.observacion,
    this.imagenPath,
    this.fechaConteo,
    this.sustentoObservacion,
    this.sustentoArchivoPath,
  });

  factory ExistenciaModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    return ExistenciaModel(
      id: parseInt(json['id']),
      item: parseInt(json['item']),
      codigo: json['codigo']?.toString() ?? '',
      nombreProducto: json['nombre_producto']?.toString() ?? '',
      unidadMedida: json['unidad_medida']?.toString() ?? 'UND',
      valorUnitario: parseDouble(json['valor_unitario']),
      lote: json['lote']?.toString(),
      almacenId: json['almacen_id'] != null ? parseInt(json['almacen_id']) : null,
      almacenNombre: json['almacen_nombre']?.toString() ?? json['almacen']?['nombre']?.toString(),
      fechaVencimiento: json['fecha_vencimiento']?.toString(),
      ubicacion: json['ubicacion']?.toString(),
      stockSistema: parseDouble(json['stock_sistema']),
      cantidadContada: parseDouble(json['cantidad_contada']),
      diferencia: parseDouble(json['diferencia']),
      valorTotalDiferencia: parseDouble(json['valor_total_diferencia']),
      condicion: json['condicion']?.toString().toUpperCase() ?? 'PENDIENTE',
      empresaId: parseInt(json['empresa_id']),
      sucursalId: json['sucursal_id'] != null ? parseInt(json['sucursal_id']) : null,
      observacion: json['observacion']?.toString(),
      imagenPath: json['imagen_path']?.toString(),
      fechaConteo: json['fecha_conteo']?.toString(),
      sustentoObservacion: json['sustento_observacion']?.toString(),
      sustentoArchivoPath: json['sustento_archivo_path']?.toString(),
    );
  }
}

class ExistenciaHistorialModel {
  final int id;
  final int existenciaId;
  final String tipoMovimiento;
  final double stockSistemaMomento;
  final double cantidadContadaAnterior;
  final double cantidadContadaNueva;
  final double diferenciaMomento;
  final String? condicionAnterior;
  final String? condicionNueva;
  final String? observacion;
  final String? archivoPath;
  final String? ubicacion;
  final String? userName;
  final String? createdAt;

  ExistenciaHistorialModel({
    required this.id,
    required this.existenciaId,
    required this.tipoMovimiento,
    required this.stockSistemaMomento,
    required this.cantidadContadaAnterior,
    required this.cantidadContadaNueva,
    required this.diferenciaMomento,
    this.condicionAnterior,
    this.condicionNueva,
    this.observacion,
    this.archivoPath,
    this.ubicacion,
    this.userName,
    this.createdAt,
  });

  factory ExistenciaHistorialModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is int) return val;
      return int.tryParse(val.toString()) ?? 0;
    }

    String? name;
    if (json['user'] is Map) {
      name = json['user']['name'] ?? json['user']['nombres'];
    }

    return ExistenciaHistorialModel(
      id: parseInt(json['id']),
      existenciaId: parseInt(json['existencia_id']),
      tipoMovimiento: json['tipo_movimiento']?.toString() ?? 'MOVIMIENTO',
      stockSistemaMomento: parseDouble(json['stock_sistema_momento']),
      cantidadContadaAnterior: parseDouble(json['cantidad_contada_anterior']),
      cantidadContadaNueva: parseDouble(json['cantidad_contada_nueva']),
      diferenciaMomento: parseDouble(json['diferencia_momento']),
      condicionAnterior: json['condicion_anterior']?.toString(),
      condicionNueva: json['condicion_nueva']?.toString(),
      observacion: json['observacion']?.toString(),
      archivoPath: json['archivo_path']?.toString(),
      ubicacion: json['ubicacion']?.toString(),
      userName: name,
      createdAt: json['created_at']?.toString(),
    );
  }
}

