import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../data/models/user_model.dart';

class AdicionalModalWidget {
  static void show(
    BuildContext context, {
    required UserModel? currentUser,
    required VoidCallback onSaved,
  }) {
    final codigoCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final countCtrl = TextEditingController();
    final unitCtrl = TextEditingController(text: 'UND');
    final almacenCtrl = TextEditingController(text: 'DEPOVENT');
    final locCtrl = TextEditingController();
    final obsCtrl = TextEditingController();
    final imagePicker = ImagePicker();

    String? localImagePath;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(builderCtx).size.height * 0.90,
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(builderCtx).viewInsets.bottom + 20,
                left: 20,
                right: 20,
                top: 18,
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
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.add_business_rounded,
                            color: Color(0xFF2563EB),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Registrar Producto Adicional',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Ítem físico no contemplado en la carga inicial',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                          onPressed: () => Navigator.pop(builderCtx),
                        ),
                      ],
                    ),
                    const Divider(height: 22),

                    // Campo: Código del Producto
                    TextField(
                      controller: codigoCtrl,
                      decoration: InputDecoration(
                        labelText: 'Código del Producto (Opcional)',
                        hintText: 'ej: 001009001 o código de barras',
                        prefixIcon: const Icon(Icons.qr_code_rounded, size: 18, color: Color(0xFF2563EB)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo: Nombre del Producto (Requerido)
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Producto *',
                        hintText: 'ej: TUBO PVC SP 2" X 5MTRS',
                        prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 18, color: Color(0xFF475569)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Fila: Cantidad Contada y Unidad
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: countCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Cantidad Contada *',
                              hintText: '0.00',
                              prefixIcon: const Icon(Icons.calculate_outlined, size: 18, color: Color(0xFF16A34A)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            controller: unitCtrl,
                            decoration: InputDecoration(
                              labelText: 'Unidad',
                              hintText: 'UND',
                              prefixIcon: const Icon(Icons.straighten_rounded, size: 16, color: Color(0xFF475569)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fila: Almacén y Ubicación Física
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: almacenCtrl,
                            decoration: InputDecoration(
                              labelText: 'Almacén',
                              hintText: 'DEPOVENT',
                              prefixIcon: const Icon(Icons.warehouse_rounded, size: 18, color: Color(0xFF1D4ED8)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: locCtrl,
                            decoration: InputDecoration(
                              labelText: 'Ubicación Física',
                              hintText: 'ej: 10A4, PABELLON-1',
                              prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFFBE123C)),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Sección: Fotografía del Producto
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: localImagePath != null ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.photo_camera_rounded,
                                size: 16,
                                color: localImagePath != null ? const Color(0xFF16A34A) : const Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Fotografía del Producto (Evidencia)',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                              if (localImagePath != null) ...[
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Foto adjunta ✓',
                                    style: TextStyle(
                                      color: Color(0xFF15803D),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Vista previa si se seleccionó foto
                          if (localImagePath != null) ...[
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(localImagePath!),
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        localImagePath!.split(Platform.pathSeparator).last,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0F172A),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Se guardará en el servidor y base de datos',
                                        style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          InkWell(
                                            onTap: () async {
                                              final picked = await imagePicker.pickImage(
                                                source: ImageSource.camera,
                                                imageQuality: 80,
                                              );
                                              if (picked != null) {
                                                setModalState(() {
                                                  localImagePath = picked.path;
                                                });
                                              }
                                            },
                                            child: const Text(
                                              'Retomar',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF2563EB),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          InkWell(
                                            onTap: () {
                                              setModalState(() {
                                                localImagePath = null;
                                              });
                                            },
                                            child: const Text(
                                              'Quitar',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFFDC2626),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Botones para elegir cámara o galería
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await imagePicker.pickImage(
                                        source: ImageSource.camera,
                                        imageQuality: 80,
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          localImagePath = picked.path;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF2563EB)),
                                    label: const Text(
                                      'Tomar Foto',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFFBFDBFE)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      final picked = await imagePicker.pickImage(
                                        source: ImageSource.gallery,
                                        imageQuality: 80,
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          localImagePath = picked.path;
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF475569)),
                                    label: const Text(
                                      'Galería',
                                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Campo: Observación
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación (Opcional)',
                        hintText: 'Detalles del estado físico, empaque, etc.',
                        prefixIcon: const Icon(Icons.note_alt_outlined, size: 18, color: Color(0xFF64748B)),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Botón: Guardar Adicional
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final count = double.tryParse(countCtrl.text.trim());
                              if (name.isEmpty || count == null || count < 0) {
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingrese el nombre y una cantidad contada válida'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                return;
                              }

                              setModalState(() {
                                isSaving = true;
                              });

                              try {
                                final fields = <String, String>{
                                  'nombre_producto': name,
                                  'cantidad_contada': count.toString(),
                                  'unidad_medida': unitCtrl.text.trim().isNotEmpty ? unitCtrl.text.trim() : 'UND',
                                  'almacen_nombre': almacenCtrl.text.trim().isNotEmpty ? almacenCtrl.text.trim() : 'DEPOVENT',
                                  'ubicacion': locCtrl.text.trim(),
                                  'observacion': obsCtrl.text.trim(),
                                  'empresa_id': (currentUser?.empresaId ?? 1).toString(),
                                  'sucursal_id': (currentUser?.sucursalId ?? 1).toString(),
                                };

                                if (codigoCtrl.text.trim().isNotEmpty) {
                                  fields['codigo'] = codigoCtrl.text.trim();
                                }

                                if (localImagePath != null) {
                                  await ApiClient.postMultipart(
                                    ApiEndpoints.adicional,
                                    fields,
                                    localImagePath,
                                    'imagen',
                                  );
                                } else {
                                  await ApiClient.post(
                                    ApiEndpoints.adicional,
                                    fields,
                                  );
                                }

                                if (!context.mounted) return;
                                if (!builderCtx.mounted) return;
                                Navigator.pop(builderCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Producto adicional registrado correctamente'),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
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
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'GUARDAR ADICIONAL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
