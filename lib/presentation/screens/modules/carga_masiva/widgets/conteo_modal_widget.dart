import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../data/models/existencia_model.dart';
import '../../../../../data/models/user_model.dart';
import 'image_viewer_dialog.dart';

class ConteoModalWidget {
  static void show(
    BuildContext context, {
    required ExistenciaModel item,
    UserModel? currentUser,
    required VoidCallback onSaved,
    required VoidCallback onOpenHistorial,
  }) {
    final countCtrl = TextEditingController();
    final ubicacionCtrl = TextEditingController();
    final obsCtrl = TextEditingController(text: item.observacion ?? '');
    final imagePicker = ImagePicker();
    String? localImagePath;
    bool isSaving = false;

    final empresaName = currentUser?.empresaNombre?.isNotEmpty == true
        ? currentUser!.empresaNombre!
        : (currentUser?.empresaId != null ? 'Empresa #${currentUser!.empresaId}' : 'Empresa Principal');

    final sucursalName = currentUser?.sucursalNombre?.isNotEmpty == true
        ? currentUser!.sucursalNombre!
        : (currentUser?.sucursalId != null ? 'Sucursal #${currentUser!.sucursalId}' : 'Sucursal Principal');

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
                    // Header del Producto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: Text(
                                  'ITEM #${item.item} • ${item.codigo}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1D4ED8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.nombreProducto,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF2563EB),
                                size: 22,
                              ),
                              tooltip: 'Ver Historial',
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFEFF6FF),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () {
                                Navigator.pop(builderCtx);
                                onOpenHistorial();
                              },
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF64748B)),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => Navigator.pop(builderCtx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tarjeta Contextual: Empresa, Sucursal, Almacén y Ubicación Actual
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          // Fila 1: Empresa & Sucursal
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.business_rounded, size: 15, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 8),
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
                                            ),
                                          ),
                                          Text(
                                            empresaName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
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
                                height: 26,
                                color: const Color(0xFFE2E8F0),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F3FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.storefront_rounded, size: 15, color: Color(0xFF7C3AED)),
                                    ),
                                    const SizedBox(width: 8),
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
                                            ),
                                          ),
                                          Text(
                                            sucursalName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
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
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),

                          // Fila 2: Almacén & Ubicación Actual
                          Row(
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEFF6FF),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.warehouse_rounded, size: 15, color: Color(0xFF2563EB)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'ALMACÉN',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          Text(
                                            item.almacenNombre != null && item.almacenNombre!.isNotEmpty
                                                ? item.almacenNombre!
                                                : 'Almacén Principal',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
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
                                height: 26,
                                color: const Color(0xFFE2E8F0),
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                              ),
                              Expanded(
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF1F2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.place_rounded, size: 15, color: Color(0xFFE11D48)),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'UBIC. ACTUAL',
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                          Text(
                                            item.ubicacion != null && item.ubicacion!.isNotEmpty
                                                ? item.ubicacion!
                                                : 'Sin asignar',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
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
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Input 1: Cantidad Contada (Física)
                    const Text(
                      'Cantidad Contada (Física):',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
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
                          icon: const Icon(Icons.remove, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFFF1F5F9),
                            foregroundColor: const Color(0xFF0F172A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: countCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                              suffixText: item.unidadMedida,
                              suffixStyle: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF475569)),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                              ),
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
                          icon: const Icon(Icons.add, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF2563EB),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.all(12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Input 2: Nueva Ubicación
                    TextField(
                      controller: ubicacionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nueva Ubicación',
                        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        hintText: 'Ej. 10A4, Estante B-2, Pasillo 3...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF2563EB), size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input 3: Observación (Opcional)
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación (Opcional)',
                        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        hintText: 'Ej. Producto dañado, empaque abierto...',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF64748B), size: 22),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Selector de Foto
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await imagePicker.pickImage(
                                source: ImageSource.camera,
                                imageQuality: 75,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  localImagePath = picked.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF2563EB)),
                            label: const Text(
                              'Tomar Foto',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFBFDBFE)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await imagePicker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 75,
                              );
                              if (picked != null) {
                                setModalState(() {
                                  localImagePath = picked.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF475569)),
                            label: const Text(
                              'Galería',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                            ),
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        if (localImagePath != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Color(0xFFDCFCE7),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF16A34A),
                              size: 18,
                            ),
                          ),
                        ] else if (item.imagenPath != null && item.imagenPath!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Ver foto actual',
                            onPressed: () {
                              final imgUrl = ApiEndpoints.resolveImageUrl(item.imagenPath);
                              if (imgUrl != null) {
                                ImageViewerDialog.show(
                                  context,
                                  imageUrl: imgUrl,
                                  title: item.codigo,
                                  subtitle: item.nombreProducto,
                                  almacen: item.almacenNombre,
                                  ubicacion: item.ubicacion,
                                );
                              }
                            },
                            icon: const Icon(Icons.image_outlined, color: Color(0xFF16A34A), size: 22),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Botón Principal de Envío
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final count = double.tryParse(countCtrl.text.trim());
                              if (count == null) {
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingrese una cantidad válida'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
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
                                    'ubicacion': ubicacionCtrl.text.trim(),
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

                                if (!context.mounted) return;
                                if (!builderCtx.mounted) return;
                                Navigator.pop(builderCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Conteo guardado exitosamente'),
                                    backgroundColor: Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                onSaved();
                              } catch (e) {
                                setModalState(() {
                                  isSaving = false;
                                });
                                if (!builderCtx.mounted) return;
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                                    backgroundColor: const Color(0xFFDC2626),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'GUARDAR CONTEO FÍSICO',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                letterSpacing: 0.3,
                              ),
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
}
