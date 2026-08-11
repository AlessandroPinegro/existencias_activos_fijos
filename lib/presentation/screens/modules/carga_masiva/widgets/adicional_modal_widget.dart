import 'package:flutter/material.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../data/models/user_model.dart';

class AdicionalModalWidget {
  static void show(
    BuildContext context, {
    required UserModel? currentUser,
    required VoidCallback onSaved,
  }) {
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
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Cantidad Contada *',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
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
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              final count =
                                  double.tryParse(countCtrl.text.trim());
                              if (name.isEmpty || count == null) {
                                ScaffoldMessenger.of(builderCtx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Complete los campos obligatorios'),
                                  ),
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
                                    'empresa_id': currentUser?.empresaId ?? 1,
                                    'sucursal_id': currentUser?.sucursalId ?? 1,
                                  },
                                );

                                if (!context.mounted) return;
                                if (!builderCtx.mounted) return;
                                Navigator.pop(builderCtx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Producto adicional registrado'),
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
                              'GUARDAR ADICIONAL',
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
