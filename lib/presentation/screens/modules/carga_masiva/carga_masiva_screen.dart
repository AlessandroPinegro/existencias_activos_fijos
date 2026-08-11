import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../data/models/existencia_model.dart';
import '../../../../data/models/user_model.dart';
import 'widgets/product_card_widget.dart';
import 'widgets/conteo_modal_widget.dart';
import 'widgets/adicional_modal_widget.dart';
import 'widgets/historial_modal_widget.dart';

class CargaMasivaScreen extends StatefulWidget {
  const CargaMasivaScreen({super.key});

  @override
  State<CargaMasivaScreen> createState() => _CargaMasivaScreenState();
}

class _CargaMasivaScreenState extends State<CargaMasivaScreen> {
  UserModel? _currentUser;
  List<ExistenciaModel> _existencias = [];
  List<ExistenciaModel> _filteredExistencias = [];

  bool _isLoading = true;
  String? _errorMsg;
  String _selectedFilter = 'TODOS';
  String? _selectedAlmacen;
  String? _selectedUbicacion;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final userStr = await SecureStorageService.getUserData();
    if (userStr != null) {
      _currentUser = UserModel.fromJson(jsonDecode(userStr));
    }
    await _fetchExistencias();
  }

  Future<void> _fetchExistencias() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final empresaId = _currentUser?.empresaId ?? 1;
      final sucursalId = _currentUser?.sucursalId;

      String url = '${ApiEndpoints.existencias}?empresa_id=$empresaId';
      if (sucursalId != null && sucursalId > 0) {
        url += '&sucursal_id=$sucursalId';
      }

      final res = await ApiClient.get(url);

      if (res['success'] == true && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) => ExistenciaModel.fromJson(item))
            .toList();

        if (mounted) {
          setState(() {
            _existencias = list;
            _applyFilters();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMsg = res['message'] ?? 'No se pudieron cargar los productos.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception:', '').trim();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    final query = _searchCtrl.text.trim().toLowerCase();
    setState(() {
      _filteredExistencias = _existencias.where((item) {
        final matchesQuery = query.isEmpty ||
            item.nombreProducto.toLowerCase().contains(query) ||
            item.codigo.toLowerCase().contains(query) ||
            (item.ubicacion?.toLowerCase().contains(query) ?? false) ||
            (item.lote?.toLowerCase().contains(query) ?? false) ||
            (item.almacenNombre?.toLowerCase().contains(query) ?? false);

        bool matchesCondition = true;
        if (_selectedFilter == 'PENDIENTE') {
          matchesCondition = item.condicion == 'PENDIENTE';
        } else if (_selectedFilter == 'CONCILIADO') {
          matchesCondition = item.condicion == 'CONCILIADO' || item.condicion == 'CONFORME';
        } else if (_selectedFilter == 'SOBRANTE') {
          matchesCondition = item.condicion == 'SOBRANTE';
        } else if (_selectedFilter == 'FALTANTE') {
          matchesCondition = item.condicion == 'FALTANTE';
        } else if (_selectedFilter == 'ADICIONAL') {
          matchesCondition = item.condicion == 'ADICIONAL';
        }

        final matchesAlmacen = _selectedAlmacen == null || item.almacenNombre == _selectedAlmacen;
        final matchesUbicacion = _selectedUbicacion == null || item.ubicacion == _selectedUbicacion;

        return matchesQuery && matchesCondition && matchesAlmacen && matchesUbicacion;
      }).toList();
    });
  }

  void _limpiarFiltros() {
    setState(() {
      _selectedFilter = 'TODOS';
      _selectedAlmacen = null;
      _selectedUbicacion = null;
      _searchCtrl.clear();
      _applyFilters();
    });
  }

  bool get _hasActiveFilters =>
      _selectedFilter != 'TODOS' ||
      _selectedAlmacen != null ||
      _selectedUbicacion != null ||
      _searchCtrl.text.isNotEmpty;

  List<String> get _almacenesDisponibles {
    final set = <String>{};
    for (final e in _existencias) {
      if (e.almacenNombre != null && e.almacenNombre!.trim().isNotEmpty) {
        set.add(e.almacenNombre!.trim());
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  List<String> get _ubicacionesDisponibles {
    final set = <String>{};
    for (final e in _existencias) {
      if (e.ubicacion != null && e.ubicacion!.trim().isNotEmpty) {
        set.add(e.ubicacion!.trim());
      }
    }
    final list = set.toList();
    list.sort((a, b) => a.compareTo(b));
    return list;
  }

  int _countPorAlmacen(String almacen) {
    return _existencias.where((e) => e.almacenNombre == almacen).length;
  }

  int _countPorUbicacion(String ubicacion) {
    return _existencias.where((e) => e.ubicacion == ubicacion).length;
  }

  int get _totalCount => _existencias.length;
  int get _pendingCount => _existencias.where((e) => e.condicion == 'PENDIENTE').length;
  int get _conciliadoCount =>
      _existencias.where((e) => e.condicion == 'CONCILIADO' || e.condicion == 'CONFORME').length;
  int get _sobranteCount => _existencias.where((e) => e.condicion == 'SOBRANTE').length;
  int get _faltanteCount => _existencias.where((e) => e.condicion == 'FALTANTE').length;
  int get _adicionalCount => _existencias.where((e) => e.condicion == 'ADICIONAL').length;

  void _mostrarSelectorAlmacen() {
    final almacenes = _almacenesDisponibles;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filterText = '';
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final filteredList = almacenes
                .where((a) => a.toLowerCase().contains(filterText.toLowerCase()))
                .toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.store_rounded, color: Color(0xFF2563EB), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Filtrar por Almacén',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  if (almacenes.length > 5)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: TextField(
                        onChanged: (val) {
                          setSheetState(() {
                            filterText = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar almacén...',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF2563EB)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          tileColor: _selectedAlmacen == null ? const Color(0xFFEFF6FF) : null,
                          leading: Icon(
                            Icons.all_inclusive_rounded,
                            color: _selectedAlmacen == null ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                            size: 20,
                          ),
                          title: Text(
                            'Todos los almacenes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedAlmacen == null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedAlmacen == null ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                            ),
                          ),
                          trailing: Text(
                            '($_totalCount)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedAlmacen = null;
                              _applyFilters();
                            });
                          },
                        ),
                        const Divider(height: 12),
                        ...filteredList.map((alm) {
                          final isSelected = _selectedAlmacen == alm;
                          final count = _countPorAlmacen(alm);
                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            tileColor: isSelected ? const Color(0xFFEFF6FF) : null,
                            leading: Icon(
                              Icons.store_outlined,
                              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              size: 20,
                            ),
                            title: Text(
                              alm,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFDBEAFE) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedAlmacen = alm;
                                _applyFilters();
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _mostrarSelectorUbicacion() {
    final ubicaciones = _ubicacionesDisponibles;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String filterText = '';
        return StatefulBuilder(
          builder: (sheetCtx, setSheetState) {
            final filteredList = ubicaciones
                .where((u) => u.toLowerCase().contains(filterText.toLowerCase()))
                .toList();

            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.place_rounded, color: Color(0xFFE11D48), size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Filtrar por Ubicación',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                  ),
                  if (ubicaciones.length > 5)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                      child: TextField(
                        onChanged: (val) {
                          setSheetState(() {
                            filterText = val;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar ubicación (ej: 10A4, PABELLON)...',
                          hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                          prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFFE11D48)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          tileColor: _selectedUbicacion == null ? const Color(0xFFFFF1F2) : null,
                          leading: Icon(
                            Icons.all_inclusive_rounded,
                            color: _selectedUbicacion == null ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                            size: 20,
                          ),
                          title: Text(
                            'Todas las ubicaciones',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _selectedUbicacion == null ? FontWeight.bold : FontWeight.normal,
                              color: _selectedUbicacion == null ? const Color(0xFFBE123C) : const Color(0xFF0F172A),
                            ),
                          ),
                          trailing: Text(
                            '($_totalCount)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold),
                          ),
                          onTap: () {
                            Navigator.pop(ctx);
                            setState(() {
                              _selectedUbicacion = null;
                              _applyFilters();
                            });
                          },
                        ),
                        const Divider(height: 12),
                        ...filteredList.map((ubi) {
                          final isSelected = _selectedUbicacion == ubi;
                          final count = _countPorUbicacion(ubi);
                          return ListTile(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            tileColor: isSelected ? const Color(0xFFFFF1F2) : null,
                            leading: Icon(
                              Icons.location_on_outlined,
                              color: isSelected ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                              size: 20,
                            ),
                            title: Text(
                              ubi,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFFBE123C) : const Color(0xFF0F172A),
                              ),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFECDD3) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '$count',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF9F1239) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              setState(() {
                                _selectedUbicacion = ubi;
                                _applyFilters();
                              });
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openConteoModal(ExistenciaModel item) {
    ConteoModalWidget.show(
      context,
      item: item,
      currentUser: _currentUser,
      onSaved: _fetchExistencias,
      onOpenHistorial: () => _openHistorialModal(item),
    );
  }

  void _openHistorialModal(ExistenciaModel item) {
    HistorialModalWidget.show(
      context,
      item: item,
      currentUser: _currentUser,
      onModified: _fetchExistencias,
    );
  }

  void _openAdicionalModal() {
    AdicionalModalWidget.show(
      context,
      currentUser: _currentUser,
      onSaved: _fetchExistencias,
    );
  }

  @override
  Widget build(BuildContext context) {
    final empresaName = _currentUser?.empresaNombre?.isNotEmpty == true
        ? _currentUser!.empresaNombre!
        : (_currentUser?.empresaId != null ? 'Empresa #${_currentUser!.empresaId}' : 'Empresa Principal');

    final sucursalName = _currentUser?.sucursalNombre?.isNotEmpty == true
        ? _currentUser!.sucursalNombre!
        : (_currentUser?.sucursalId != null ? 'Sucursal #${_currentUser!.sucursalId}' : 'Sucursal Principal');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF0F172A),
        leading: Container(
          margin: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
            tooltip: 'Volver',
            style: IconButton.styleFrom(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Carga Masiva',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            Text(
              '$empresaName • $sucursalName',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569), size: 22),
              tooltip: 'Actualizar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onPressed: _fetchExistencias,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAdicionalModal,
        backgroundColor: const Color(0xFF2563EB),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Item Adicional',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Column(
              children: [
                // Barra de Búsqueda de Texto
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por código, nombre, almacén, ubicación...',
                    hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF2563EB)),
                    suffixIcon: _searchCtrl.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchCtrl.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Filtros de Almacén y Ubicaciones (Fila interactiva)
                Row(
                  children: [
                    // Botón Filtro Almacén
                    Expanded(
                      child: InkWell(
                        onTap: _mostrarSelectorAlmacen,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedAlmacen != null ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedAlmacen != null ? const Color(0xFF2563EB) : Colors.grey.shade300,
                              width: _selectedAlmacen != null ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.store_rounded,
                                size: 16,
                                color: _selectedAlmacen != null ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _selectedAlmacen != null ? _selectedAlmacen! : 'Almacén: Todos',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _selectedAlmacen != null ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedAlmacen != null ? const Color(0xFF1D4ED8) : const Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedAlmacen != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedAlmacen = null;
                                      _applyFilters();
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 2),
                                    child: Icon(Icons.close_rounded, size: 14, color: Color(0xFF2563EB)),
                                  ),
                                )
                              else
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Botón Filtro Ubicación
                    Expanded(
                      child: InkWell(
                        onTap: _mostrarSelectorUbicacion,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: _selectedUbicacion != null ? const Color(0xFFFFF1F2) : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedUbicacion != null ? const Color(0xFFE11D48) : Colors.grey.shade300,
                              width: _selectedUbicacion != null ? 1.4 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.place_rounded,
                                size: 16,
                                color: _selectedUbicacion != null ? const Color(0xFFE11D48) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _selectedUbicacion != null ? _selectedUbicacion! : 'Ubicación: Todas',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: _selectedUbicacion != null ? FontWeight.bold : FontWeight.w500,
                                    color: _selectedUbicacion != null ? const Color(0xFFBE123C) : const Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (_selectedUbicacion != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedUbicacion = null;
                                      _applyFilters();
                                    });
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(left: 2),
                                    child: Icon(Icons.close_rounded, size: 14, color: Color(0xFFE11D48)),
                                  ),
                                )
                              else
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    if (_hasActiveFilters) ...[
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: 'Limpiar todos los filtros',
                        icon: const Icon(Icons.filter_alt_off_rounded, size: 18, color: Color(0xFFDC2626)),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFFEE2E2),
                          padding: const EdgeInsets.all(8),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _limpiarFiltros,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Chips de Estados / Condición
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('TODOS', 'Todos ($_totalCount)'),
                      _buildFilterChip('PENDIENTE', 'Pendientes ($_pendingCount)'),
                      _buildFilterChip('CONCILIADO', 'Conciliados ($_conciliadoCount)'),
                      _buildFilterChip('SOBRANTE', 'Sobrantes ($_sobranteCount)'),
                      _buildFilterChip('FALTANTE', 'Faltantes ($_faltanteCount)'),
                      _buildFilterChip('ADICIONAL', 'Adicionales ($_adicionalCount)'),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Lista de Productos Filtrados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMsg != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.red),
                              const SizedBox(height: 12),
                              Text(_errorMsg!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                              const SizedBox(height: 16),
                              ElevatedButton(onPressed: _fetchExistencias, child: const Text('Reintentar')),
                            ],
                          ),
                        ),
                      )
                    : _filteredExistencias.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    _existencias.isEmpty
                                        ? 'No hay productos importados para esta empresa y sucursal.\nImporte el archivo Excel desde la plataforma Web.'
                                        : 'No se encontraron productos con los filtros aplicados.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                  ),
                                  if (_hasActiveFilters) ...[
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _limpiarFiltros,
                                      icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                      label: const Text('Limpiar Filtros'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchExistencias,
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: _filteredExistencias.length,
                              itemBuilder: (context, index) {
                                final item = _filteredExistencias[index];
                                return ProductCardWidget(
                                  item: item,
                                  onConteo: () => _openConteoModal(item),
                                  onHistorial: () => _openHistorialModal(item),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        selectedColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : const Color(0xFF475569),
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = key;
              _applyFilters();
            });
          }
        },
      ),
    );
  }
}
