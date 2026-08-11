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

  Future<void> _loadUserAndMenu() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final userStr = await SecureStorageService.getUserData();
      if (userStr != null) {
        _currentUser = UserModel.fromJson(jsonDecode(userStr));
      }

      final res = await ApiClient.get(ApiEndpoints.mobileMenu);

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
              tooltip: 'Actualizar',
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onPressed: _loadUserAndMenu,
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
              onRefresh: _loadUserAndMenu,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tarjeta Limpia de Empresa y Sucursal
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
                                Icons.widgets_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
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
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$_totalOpcionesCount ${_totalOpcionesCount == 1 ? 'Opción' : 'Opciones'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Listado de Módulos
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          Expanded(
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
                      const Text(
                        'EMPRESA',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
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
          Container(
            width: 1,
            height: 28,
            color: const Color(0xFFE2E8F0),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
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
                      const Text(
                        'SUCURSAL',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.5,
                        ),
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
          // Header de la Categoría/Módulo
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_rounded,
                    color: Color(0xFF2563EB),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    modulo.moduleNombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${modulo.opciones.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),

          // Lista de Opciones
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: modulo.opciones.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, optIndex) {
              final opcion = modulo.opciones[optIndex];
              return _buildOptionTile(context, opcion);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, MobileOptionModel opcion) {
    final isCargaMasiva = opcion.codigoNivel == '32' || opcion.opcion.toLowerCase().contains('carga masiva');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navegarAOpcion(context, opcion),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isCargaMasiva ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
              width: isCargaMasiva ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Icono con Degradado Suave
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isCargaMasiva
                        ? [const Color(0xFF2563EB), const Color(0xFF3B82F6)]
                        : [const Color(0xFF475569), const Color(0xFF64748B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isCargaMasiva ? const Color(0xFF2563EB) : Colors.black).withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  isCargaMasiva ? Icons.qr_code_scanner_rounded : Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),

              // Contenido
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
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCargaMasiva ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isCargaMasiva ? const Color(0xFF93C5FD) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: Text(
                            'CÓD. ${opcion.codigoNivel}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: isCargaMasiva ? const Color(0xFF1D4ED8) : const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isCargaMasiva
                          ? 'Conteo físico, toma de inventario y registro de existencias'
                          : 'Acceso móvil al módulo del sistema',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Flecha de Acción
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isCargaMasiva ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isCargaMasiva ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phonelink_off_rounded, size: 36, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 14),
          const Text(
            'No hay módulos disponibles',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No se encontraron opciones móviles con el criterio de búsqueda o asignadas a tu rol.',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadUserAndMenu,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Recargar Menú'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  void _navegarAOpcion(BuildContext context, MobileOptionModel opcion) {
    if (opcion.codigoNivel == '32' || opcion.opcion.toLowerCase().contains('carga masiva')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CargaMasivaScreen()),
      );
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
