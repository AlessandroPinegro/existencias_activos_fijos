import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../data/models/existencia_model.dart';

class ConteoModalWidget {
  static void show(
    BuildContext context, {
    required ExistenciaModel item,
    required VoidCallback onSaved,
    required VoidCallback onOpenHistorial,
  }) {
    final countCtrl = TextEditingController(
      text: item.cantidadContada > 0
          ? item.cantidadContada.toStringAsFixed(
              item.cantidadContada.truncateToDouble() == item.cantidadContada
                  ? 0
                  : 2,
            )
          : '',
    );
    final obsCtrl = TextEditingController(text: item.observacion ?? '');
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
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.history_rounded,
                                color: Color(0xFF2563EB),
                              ),
                              tooltip: 'Ver Historial',
                              onPressed: () {
                                Navigator.pop(builderCtx);
                                onOpenHistorial();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () => Navigator.pop(builderCtx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Información del Almacén y Ubicación (Sin mostrar stock de sistema)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFCBD5E1)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.warehouse_rounded,
                                  size: 18,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Almacén',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      item.almacenNombre != null &&
                                              item.almacenNombre!.isNotEmpty
                                          ? item.almacenNombre!
                                          : 'Almacén Principal',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE11D48)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.location_on_rounded,
                                  size: 18,
                                  color: Color(0xFFE11D48),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ubicación',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      item.ubicacion != null &&
                                              item.ubicacion!.isNotEmpty
                                          ? item.ubicacion!
                                          : 'Sin ubicación asignada',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (item.lote != null && item.lote!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF7C3AED)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_2_rounded,
                                    size: 18,
                                    color: Color(0xFF7C3AED),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Lote',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF64748B),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        item.lote!,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Cantidad Contada (Física):',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () {
                            double v =
                                (double.tryParse(countCtrl.text) ?? 0) - 1;
                            if (v < 0) v = 0;
                            setModalState(() {
                              countCtrl.text = v.toStringAsFixed(
                                  v.truncateToDouble() == v ? 0 : 2);
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: item.unidadMedida,
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onChanged: (_) => setModalState(() {}),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filled(
                          onPressed: () {
                            double v =
                                (double.tryParse(countCtrl.text) ?? 0) + 1;
                            setModalState(() {
                              countCtrl.text = v.toStringAsFixed(
                                  v.truncateToDouble() == v ? 0 : 2);
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        OutlinedButton.icon(
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
                          icon:
                              const Icon(Icons.camera_alt_outlined, size: 18),
                          label: const Text(
                            'Tomar Foto',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
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
                          icon: const Icon(Icons.photo_library_outlined,
                              size: 18),
                          label: const Text(
                            'Galería',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        if (localImagePath != null) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Colors.green,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final count =
                                  double.tryParse(countCtrl.text.trim());
                              if (count == null) {
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text('Ingrese una cantidad válida'),
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
                                    content:
                                        Text('Conteo guardado exitosamente'),
                                    backgroundColor: Colors.green,
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
                                    content: Text(
                                        'Error: ${e.toString().replaceAll('Exception:', '')}'),
                                    backgroundColor: Colors.red,
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
                          : const Text(
                              'GUARDAR CONTEO FÍSICO',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
