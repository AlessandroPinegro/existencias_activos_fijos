import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../../../data/models/existencia_model.dart';
import '../../../data/models/user_model.dart';

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
  final ImagePicker _imagePicker = ImagePicker();

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
        } else if (_selectedFilter == 'CONFORME') {
          matchesCondition = item.condicion == 'CONFORME';
        } else if (_selectedFilter == 'DIFERENCIA') {
          matchesCondition = item.condicion == 'FALTANTE' || item.condicion == 'SOBRANTE';
        } else if (_selectedFilter == 'ADICIONAL') {
          matchesCondition = item.condicion == 'ADICIONAL';
        }

        return matchesQuery && matchesCondition;
      }).toList();
    });
  }

  int get _totalCount => _existencias.length;
  int get _pendingCount => _existencias.where((e) => e.condicion == 'PENDIENTE').length;
  int get _conformeCount => _existencias.where((e) => e.condicion == 'CONFORME').length;
  int get _diferenciaCount =>
      _existencias.where((e) => e.condicion == 'FALTANTE' || e.condicion == 'SOBRANTE').length;

  void _openConteoModal(ExistenciaModel item) {
    final countCtrl = TextEditingController(
      text: item.cantidadContada > 0
          ? item.cantidadContada.toStringAsFixed(item.cantidadContada.truncateToDouble() == item.cantidadContada ? 0 : 2)
          : '',
    );
    final obsCtrl = TextEditingController(text: item.observacion ?? '');
    String? localImagePath;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            double currentVal = double.tryParse(countCtrl.text) ?? 0.0;
            double diff = currentVal - item.stockSistema;

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Item #${item.item} • ${item.codigo}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.nombreProducto,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(builderCtx),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Stock Sistema',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${item.stockSistema} ${item.unidadMedida}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 35, color: Colors.grey.shade300),
                          Expanded(
                            child: Column(
                              children: [
                                const Text(
                                  'Diferencia',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${diff > 0 ? "+$diff" : "$diff"} ${item.unidadMedida}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: diff == 0
                                        ? Colors.green.shade700
                                        : (diff > 0 ? Colors.blue.shade700 : Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Cantidad Contada (Física):',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () {
                            double v = (double.tryParse(countCtrl.text) ?? 0) - 1;
                            if (v < 0) v = 0;
                            setModalState(() {
                              countCtrl.text = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
                            });
                          },
                          icon: const Icon(Icons.remove),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade200,
                            foregroundColor: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: countCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: item.unidadMedida,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            double v = (double.tryParse(countCtrl.text) ?? 0) + 1;
                            setModalState(() {
                              countCtrl.text = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
                            });
                          },
                          icon: const Icon(Icons.add),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación (Opcional)',
                        hintText: 'Ej. Producto dañado, empaque abierto...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await _imagePicker.pickImage(
                              source: ImageSource.camera,
                              imageQuality: 75,
                            );
                            if (picked != null) {
                              setModalState(() {
                                localImagePath = picked.path;
                              });
                            }
                          },
                          icon: const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text('Tomar Foto', style: TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await _imagePicker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 75,
                            );
                            if (picked != null) {
                              setModalState(() {
                                localImagePath = picked.path;
                              });
                            }
                          },
                          icon: const Icon(Icons.photo_library_outlined, size: 18),
                          label: const Text('Galería', style: TextStyle(fontSize: 12)),
                        ),
                        if (localImagePath != null) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final count = double.tryParse(countCtrl.text.trim());
                              if (count == null) {
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  const SnackBar(content: Text('Ingrese una cantidad válida')),
                                );
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                              });

                              try {
                                await ApiClient.put(
                                  ApiEndpoints.registrarConteo(item.id),
                                  {
                                    'cantidad_contada': count,
                                    'observacion': obsCtrl.text.trim(),
                                  },
                                );

                                if (localImagePath != null) {
                                  await ApiClient.postMultipart(
                                    ApiEndpoints.subirImagen(item.id),
                                    {},
                                    localImagePath,
                                    'imagen',
                                  );
                                }

                                if (!mounted) return;
                                if (!builderCtx.mounted) return;
                                Navigator.pop(builderCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Conteo guardado exitosamente'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchExistencias();
                              } catch (e) {
                                setModalState(() {
                                  isSaving = false;
                                });
                                if (!builderCtx.mounted) return;
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'GUARDAR CONTEO FÍSICO',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openAdicionalModal() {
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'UND');
    final locCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Registrar Producto Adicional',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () => Navigator.pop(builderCtx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Producto *',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: countCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Cantidad Contada *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: 'Unidad',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.all(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: locCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ubicación Física',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final count = double.tryParse(countCtrl.text.trim());
                              if (name.isEmpty || count == null) {
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  const SnackBar(content: Text('Complete los campos obligatorios')),
                                );
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                              });

                              try {
                                await ApiClient.post(
                                  ApiEndpoints.adicional,
                                  {
                                    'nombre_producto': name,
                                    'cantidad_contada': count,
                                    'unidad_medida': unitCtrl.text.trim(),
                                    'ubicacion': locCtrl.text.trim(),
                                    'observacion': obsCtrl.text.trim(),
                                    'empresa_id': _currentUser?.empresaId ?? 1,
                                    'sucursal_id': _currentUser?.sucursalId ?? 1,
                                  },
                                );

                                if (!mounted) return;
                                if (!builderCtx.mounted) return;
                                Navigator.pop(builderCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Producto adicional registrado'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                _fetchExistencias();
                              } catch (e) {
                                setModalState(() {
                                  isSaving = false;
                                });
                                if (!builderCtx.mounted) return;
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              'GUARDAR ADICIONAL',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Existencias / Carga Masiva',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            if (_currentUser != null)
              Text(
                'Empresa ID: ${_currentUser!.empresaId ?? 1} • Sucursal ID: ${_currentUser!.sucursalId ?? 1}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Actualizar',
            onPressed: _fetchExistencias,
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              children: [
                _buildStatBadge('TOTAL', '$_totalCount', Colors.white, Colors.white24),
                const SizedBox(width: 8),
                _buildStatBadge('PENDIENTES', '$_pendingCount', const Color(0xFFFBBF24), const Color(0xFF78350F)),
                const SizedBox(width: 8),
                _buildStatBadge('CONFORMES', '$_conformeCount', const Color(0xFF34D399), const Color(0xFF064E3B)),
                const SizedBox(width: 8),
                _buildStatBadge('DIFERENCIAS', '$_diferenciaCount', const Color(0xFFF87171), const Color(0xFF7F1D1D)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _applyFilters(),
                  decoration: InputDecoration(
                    hintText: 'Buscar por código, nombre, ubicación...',
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
                      _buildFilterChip('TODOS', 'Todos (${_existencias.length})'),
                      _buildFilterChip('PENDIENTE', 'Pendientes ($_pendingCount)'),
                      _buildFilterChip('CONFORME', 'Conformes ($_conformeCount)'),
                      _buildFilterChip('DIFERENCIA', 'Diferencias ($_diferenciaCount)'),
                      _buildFilterChip('ADICIONAL', 'Adicionales'),
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
                            mainAxisAlignment: MainAxisAlignment.center,
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
                                mainAxisAlignment: MainAxisAlignment.center,
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
                                return _buildProductCard(item);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBadge(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
            Text(label, style: TextStyle(fontSize: 8, color: textColor.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _selectedFilter == key;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: const Color(0xFF2563EB),
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF475569)),
        backgroundColor: Colors.white,
        side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : Colors.grey.shade300),
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

  Widget _buildProductCard(ExistenciaModel item) {
    Color badgeColor;
    Color badgeTextColor;

    switch (item.condicion) {
      case 'CONFORME':
        badgeColor = const Color(0xFFDCFCE7);
        badgeTextColor = const Color(0xFF15803D);
        break;
      case 'FALTANTE':
        badgeColor = const Color(0xFFFEE2E2);
        badgeTextColor = const Color(0xFFB91C1C);
        break;
      case 'SOBRANTE':
        badgeColor = const Color(0xFFDBEAFE);
        badgeTextColor = const Color(0xFF1D4ED8);
        break;
      case 'ADICIONAL':
        badgeColor = const Color(0xFFF3E8FF);
        badgeTextColor = const Color(0xFF7E22CE);
        break;
      default:
        badgeColor = const Color(0xFFFEF3C7);
        badgeTextColor = const Color(0xFFB45309);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: item.condicion == 'PENDIENTE' ? const Color(0xFFFDE68A) : Colors.grey.shade200,
          width: item.condicion == 'PENDIENTE' ? 1.5 : 1,
        ),
      ),
      elevation: item.condicion == 'PENDIENTE' ? 2 : 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${item.item}',
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.codigo,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2563EB)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.condicion,
                    style: TextStyle(color: badgeTextColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.nombreProducto,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (item.almacenNombre != null)
                  _buildTag(Icons.warehouse_rounded, item.almacenNombre!),
                if (item.ubicacion != null && item.ubicacion!.isNotEmpty)
                  _buildTag(Icons.location_on_outlined, item.ubicacion!),
                if (item.lote != null && item.lote!.isNotEmpty)
                  _buildTag(Icons.qr_code_2_rounded, 'Lote: ${item.lote}'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildStockCol('Stock Sistema', '${item.stockSistema} ${item.unidadMedida}', const Color(0xFF334155)),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                  _buildStockCol(
                    'Contado',
                    item.cantidadContada > 0 ? '${item.cantidadContada} ${item.unidadMedida}' : '---',
                    item.condicion == 'PENDIENTE' ? Colors.grey : const Color(0xFF0F172A),
                  ),
                  Container(width: 1, height: 28, color: Colors.grey.shade300),
                  _buildStockCol(
                    'Diferencia',
                    item.condicion == 'PENDIENTE'
                        ? '---'
                        : '${item.diferencia > 0 ? "+${item.diferencia}" : item.diferencia} ${item.unidadMedida}',
                    item.diferencia == 0
                        ? Colors.green.shade700
                        : (item.diferencia > 0 ? Colors.blue.shade700 : Colors.red.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openConteoModal(item),
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.condicion == 'PENDIENTE' ? const Color(0xFF2563EB) : const Color(0xFF0F172A),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                icon: Icon(
                  item.condicion == 'PENDIENTE' ? Icons.touch_app_rounded : Icons.edit_note_rounded,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  item.condicion == 'PENDIENTE' ? 'REGISTRAR CONTEO' : 'MODIFICAR CONTEO',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFF475569)),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCol(String label, String value, Color valColor) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valColor)),
        ],
      ),
    );
  }
}
