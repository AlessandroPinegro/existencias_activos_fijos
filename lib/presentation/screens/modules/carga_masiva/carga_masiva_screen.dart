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

        return matchesQuery && matchesCondition;
      }).toList();
    });
  }

  int get _totalCount => _existencias.length;
  int get _pendingCount => _existencias.where((e) => e.condicion == 'PENDIENTE').length;
  int get _conciliadoCount =>
      _existencias.where((e) => e.condicion == 'CONCILIADO' || e.condicion == 'CONFORME').length;
  int get _sobranteCount => _existencias.where((e) => e.condicion == 'SOBRANTE').length;
  int get _faltanteCount => _existencias.where((e) => e.condicion == 'FALTANTE').length;
  int get _adicionalCount => _existencias.where((e) => e.condicion == 'ADICIONAL').length;

  void _openConteoModal(ExistenciaModel item) {
    ConteoModalWidget.show(
      context,
      item: item,
      onSaved: _fetchExistencias,
      onOpenHistorial: () => _openHistorialModal(item),
    );
  }

  void _openHistorialModal(ExistenciaModel item) {
    HistorialModalWidget.show(
      context,
      item: item,
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
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
