import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../core/storage/secure_storage_service.dart';
import '../../data/models/mobile_menu_model.dart';
import '../../data/models/user_model.dart';
import 'login_screen.dart';
import 'modules/carga_masiva/carga_masiva_screen.dart';

class HomeMobileScreen extends StatefulWidget {
  const HomeMobileScreen({super.key});

  @override
  State<HomeMobileScreen> createState() => _HomeMobileScreenState();
}

class _HomeMobileScreenState extends State<HomeMobileScreen> {
  UserModel? _currentUser;
  List<MobileModuleModel> _mobileModules = [];
  List<MobileModuleModel> _filteredModules = [];
  bool _isLoading = true;
  String? _errorMsg;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserAndMenu();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserAndMenu({int? overrideEmpresaId}) async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final userStr = await SecureStorageService.getUserData();
      if (userStr != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
      }

      final activeEmpresaId = overrideEmpresaId ?? _currentUser?.empresaId;
      final res = await ApiClient.get(ApiEndpoints.mobileMenuUrl(activeEmpresaId));

      if (res['success'] == true && res['data'] is List) {
        final rawList = res['data'] as List;
        final modules = rawList
            .map((item) => MobileModuleModel.fromJson(item))
            .where((m) => m.opciones.isNotEmpty)
            .toList();

        if (mounted) {
          setState(() {
            _mobileModules = modules;
            _filterModules();
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _errorMsg = res['message'] ?? 'No se pudo cargar el menú móvil.';
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

  void _filterModules() {
    final query = _searchCtrl.text.toLowerCase().trim();
    if (query.isEmpty) {
      _filteredModules = List.from(_mobileModules);
    } else {
      _filteredModules = _mobileModules
          .map((module) {
            final matchingOptions = module.opciones.where((opt) {
              return opt.opcion.toLowerCase().contains(query) ||
                  opt.codigoNivel.toLowerCase().contains(query);
            }).toList();

            return MobileModuleModel(
              moduleId: module.moduleId,
              moduleNombre: module.moduleNombre,
              moduleIcono: module.moduleIcono,
              opciones: matchingOptions,
            );
          })
          .where((m) => m.opciones.isNotEmpty)
          .toList();
    }
  }

  void _mostrarSelectorEmpresa() {
    if (_currentUser == null) return;
    final empresas = _currentUser!.empresasDisponibles;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.70,
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
                      child: const Icon(Icons.business_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Seleccionar Empresa Global',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'El menú y módulos se sincronizan según la empresa',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: empresas.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, index) {
                    final emp = empresas[index];
                    final int empId = emp['id'];
                    final String empNombre = emp['nombre'];
                    final isSelected = _currentUser!.empresaId == empId;

                    return InkWell(
                      onTap: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.pop(ctx);
                        if (isSelected) return;

                        // Consultar todas las sucursales de esta empresa desde la API
                        int? nuevaSucursalId;
                        String? nuevaSucursalNom;

                        try {
                          final sucRes = await ApiClient.get(ApiEndpoints.sucursales(empId));
                          if (sucRes['success'] == true && sucRes['data'] is List) {
                            final list = sucRes['data'] as List;
                            if (list.isNotEmpty) {
                              final principal = list.firstWhere(
                                (s) => s['es_principal'] == true || s['es_principal'] == 1,
                                orElse: () => list.first,
                              );
                              nuevaSucursalId = principal['id'] is int
                                  ? principal['id']
                                  : int.tryParse(principal['id'].toString()) ?? 0;
                              nuevaSucursalNom = principal['nombre']?.toString();
                            }
                          }
                        } catch (_) {}

                        // Fallback a relaciones si la API no retornó lista
                        if (nuevaSucursalId == null || nuevaSucursalId == 0) {
                          final sucsDeEmp = _currentUser!.sucursalesDeEmpresa(empId);
                          if (sucsDeEmp.isNotEmpty) {
                            final principal = sucsDeEmp.firstWhere(
                              (s) => s.esPrincipal,
                              orElse: () => sucsDeEmp.first,
                            );
                            nuevaSucursalId = principal.sucursalId;
                            nuevaSucursalNom = principal.sucursalNombre;
                          }
                        }

                        final updatedUser = _currentUser!.copyWith(
                          empresaId: empId,
                          empresaNombre: empNombre,
                          sucursalId: nuevaSucursalId,
                          sucursalNombre: nuevaSucursalNom,
                        );

                        await SecureStorageService.saveUserData(jsonEncode(updatedUser.toJson()));

                        if (mounted) {
                          setState(() {
                            _currentUser = updatedUser;
                          });

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Empresa: $empNombre${nuevaSucursalNom != null ? ' • $nuevaSucursalNom' : ''}'),
                              backgroundColor: const Color(0xFF2563EB),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 2),
                            ),
                          );

                          await _loadUserAndMenu(overrideEmpresaId: empId);
                        }
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFDBEAFE) : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.business_rounded,
                                size: 20,
                                color: isSelected ? const Color(0xFF1D4ED8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                empNombre,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB), size: 22)
                            else
                              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _mostrarSelectorSucursal() {
    if (_currentUser == null) return;
    final int activeEmpId = _currentUser!.empresaId ?? 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.70,
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
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.storefront_rounded, color: Color(0xFF7C3AED), size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Seleccionar Sucursal',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Sucursales de ${_currentUser!.empresaNombre}',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<dynamic>(
                  future: ApiClient.get(ApiEndpoints.sucursales(activeEmpId)),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                        ),
                      );
                    }

                    List<Map<String, dynamic>> sucursales = [];
                    if (snapshot.hasData &&
                        snapshot.data is Map &&
                        snapshot.data['success'] == true &&
                        snapshot.data['data'] is List) {
                      sucursales = (snapshot.data['data'] as List).map((s) {
                        return {
                          'id': s['id'] is int ? s['id'] : int.tryParse(s['id'].toString()) ?? 0,
                          'nombre': s['nombre']?.toString() ?? 'Sucursal #${s['id']}',
                          'es_principal': s['es_principal'] == true || s['es_principal'] == 1,
                          'codigo': s['codigo']?.toString(),
                        };
                      }).toList();
                    }

                    // Fallback si la API no devolvió registros
                    if (sucursales.isEmpty) {
                      final sucsDeEmp = _currentUser!.sucursalesDeEmpresa(activeEmpId);
                      sucursales = sucsDeEmp.map((s) => {
                        'id': s.sucursalId,
                        'nombre': s.sucursalNombre,
                        'es_principal': s.esPrincipal,
                        'codigo': 'SUC-${s.sucursalId}',
                      }).toList();
                    }

                    if (sucursales.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.storefront_outlined, size: 40, color: Color(0xFF94A3B8)),
                              const SizedBox(height: 8),
                              Text(
                                'No se encontraron sucursales para ${_currentUser!.empresaNombre}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: sucursales.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, index) {
                        final suc = sucursales[index];
                        final int sucId = suc['id'];
                        final String sucNombre = suc['nombre'];
                        final bool esPrincipal = suc['es_principal'] == true;
                        final isSelected = _currentUser!.sucursalId == sucId;

                        return InkWell(
                          onTap: () async {
                            final messenger = ScaffoldMessenger.of(context);
                            Navigator.pop(ctx);
                            if (isSelected) return;

                            final updatedUser = _currentUser!.copyWith(
                              sucursalId: sucId,
                              sucursalNombre: sucNombre,
                            );

                            await SecureStorageService.saveUserData(jsonEncode(updatedUser.toJson()));

                            if (mounted) {
                              setState(() {
                                _currentUser = updatedUser;
                              });

                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Sucursal activa: $sucNombre'),
                                  backgroundColor: const Color(0xFF7C3AED),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFF5F3FF) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFFE2E8F0),
                                width: isSelected ? 1.5 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFFEDE9FE) : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.storefront_rounded,
                                    size: 20,
                                    color: isSelected ? const Color(0xFF6D28D9) : const Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              sucNombre,
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                                color: isSelected ? const Color(0xFF5B21B6) : const Color(0xFF0F172A),
                                              ),
                                            ),
                                          ),
                                          if (esPrincipal)
                                            Container(
                                              margin: const EdgeInsets.only(left: 6),
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFDCFCE7),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Principal',
                                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                              ),
                                            ),
                                        ],
                                      ),
                                      if (suc['codigo'] != null && suc['codigo'].toString().isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(
                                          'Código: ${suc['codigo']}',
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 22)
                                else
                                  const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: const [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 24),
            SizedBox(width: 10),
            Text(
              'Cerrar Sesión',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
          ],
        ),
        content: const Text(
          '¿Estás seguro de que deseas salir de tu cuenta?',
          style: TextStyle(color: Color(0xFF475569), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sí, Cerrar Sesión', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await SecureStorageService.clearAll();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  int get _totalOpcionesCount {
    return _mobileModules.fold<int>(0, (sum, mod) => sum + mod.opciones.length);
  }

  @override
  Widget build(BuildContext context) {
    final userName = _currentUser?.name.isNotEmpty == true ? _currentUser!.name : 'Usuario';
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
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '¡HOLA, BIENVENIDO!',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2563EB),
                letterSpacing: 0.8,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569), size: 22),
              tooltip: 'Actualizar Menú',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onPressed: () => _loadUserAndMenu(),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 20),
              tooltip: 'Cerrar Sesión',
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFFEF2F2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFECDD3)),
                ),
              ),
              onPressed: _logout,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF2563EB)),
                  SizedBox(height: 16),
                  Text(
                    'Cargando menú móvil...',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              color: const Color(0xFF2563EB),
              onRefresh: () => _loadUserAndMenu(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta Interactiva de Empresa y Sucursal
                    _buildLocationCard(empresaName, sucursalName),
                    const SizedBox(height: 16),

                    if (_errorMsg != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: Color(0xFF991B1B)),
                              onPressed: () => setState(() => _errorMsg = null),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Buscador Rápido
                    if (_mobileModules.isNotEmpty) ...[
                      TextField(
                        controller: _searchCtrl,
                        onChanged: (_) => setState(() => _filterModules()),
                        decoration: InputDecoration(
                          hintText: 'Buscar módulo u opción...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF2563EB)),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF64748B)),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _filterModules());
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Encabezado de Sección con Contador
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.grid_view_rounded,
                                size: 18,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Módulos Asignados',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_totalOpcionesCount ${_totalOpcionesCount == 1 ? 'Opción' : 'Opciones'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Lista de Módulos
                    if (_filteredModules.isEmpty)
                      _buildEmptyState()
                    else
                      for (final modulo in _filteredModules) ...[
                        _buildModuleSection(modulo),
                        const SizedBox(height: 16),
                      ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLocationCard(String empresaName, String sucursalName) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Selector Interactivo de Empresa
          Expanded(
            child: InkWell(
              onTap: _mostrarSelectorEmpresa,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business_rounded, size: 16, color: Color(0xFF2563EB)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'EMPRESA',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Color(0xFF2563EB)),
                            ],
                          ),
                          Text(
                            empresaName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFE2E8F0),
          ),
          // Selector Interactivo de Sucursal
          Expanded(
            child: InkWell(
              onTap: _mostrarSelectorSucursal,
              borderRadius: const BorderRadius.horizontal(right: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF7C3AED)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Text(
                                'SUCURSAL',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF94A3B8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 2),
                              Icon(Icons.keyboard_arrow_down_rounded, size: 13, color: Color(0xFF7C3AED)),
                            ],
                          ),
                          Text(
                            sucursalName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleSection(MobileModuleModel modulo) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del Módulo
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                Icon(
                  _parseModuleIcon(modulo.moduleIcono),
                  size: 18,
                  color: const Color(0xFF2563EB),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    modulo.moduleNombre,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${modulo.opciones.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Opciones del Módulo
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: modulo.opciones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (ctx, idx) {
              final opcion = modulo.opciones[idx];
              return _buildOptionCard(opcion);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(MobileOptionModel opcion) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navegarAOpcion(context, opcion),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              // Icono Grande con Fondo
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  _parseOptionIcon(opcion.icono, opcion.opcion),
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),

              // Información de la Opción
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            opcion.opcion,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (opcion.codigoNivel.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text(
                              'CÓD. ${opcion.codigoNivel}',
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getOptionDescription(opcion.opcion),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Flecha de Navegación
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _parseModuleIcon(String? iconName) {
    if (iconName == null) return Icons.folder_rounded;
    final lower = iconName.toLowerCase();
    if (lower.contains('box') || lower.contains('existenc') || lower.contains('inven')) {
      return Icons.inventory_2_rounded;
    }
    if (lower.contains('shop') || lower.contains('cart') || lower.contains('vent')) {
      return Icons.point_of_sale_rounded;
    }
    if (lower.contains('hotel') || lower.contains('bed') || lower.contains('reser')) {
      return Icons.hotel_rounded;
    }
    if (lower.contains('shield') || lower.contains('lock') || lower.contains('segur')) {
      return Icons.shield_rounded;
    }
    return Icons.folder_rounded;
  }

  IconData _parseOptionIcon(String? iconName, String title) {
    final lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('carga masiva') || lowerTitle.contains('conteo')) {
      return Icons.qr_code_scanner_rounded;
    }
    if (lowerTitle.contains('stock') || lowerTitle.contains('existenc')) {
      return Icons.inventory_rounded;
    }
    if (lowerTitle.contains('report') || lowerTitle.contains('grafic')) {
      return Icons.insert_chart_outlined_rounded;
    }

    if (iconName != null) {
      final lower = iconName.toLowerCase();
      if (lower.contains('mobile') || lower.contains('phone')) return Icons.phone_android_rounded;
      if (lower.contains('task')) return Icons.task_alt_rounded;
      if (lower.contains('user')) return Icons.person_rounded;
    }

    return Icons.widgets_rounded;
  }

  String _getOptionDescription(String optionTitle) {
    final lower = optionTitle.toLowerCase();
    if (lower.contains('carga masiva')) {
      return 'Conteo físico, toma de inventario y registro de existencias';
    }
    if (lower.contains('reporte')) {
      return 'Consulta de avances, conciliaciones y diferencias';
    }
    if (lower.contains('tarea')) {
      return 'Tareas y productos asignados al usuario';
    }
    return 'Módulo operativo móvil';
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'No se encontraron opciones',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Prueba buscando con otro término o limpia el filtro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navegarAOpcion(BuildContext context, MobileOptionModel opcion) {
    if (opcion.codigoNivel == '32' || opcion.opcion.toLowerCase().contains('carga masiva')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CargaMasivaScreen()),
      ).then((_) {
        // Al regresar de carga masiva, refrescar si es necesario
        _loadUserAndMenu();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Módulo "${opcion.opcion}" en desarrollo.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
