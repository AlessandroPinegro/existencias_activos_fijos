import 'package:flutter/material.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../data/models/existencia_model.dart';
import '../../../../../data/models/user_model.dart';

class HistorialModalWidget {
  static void show(
    BuildContext context, {
    required ExistenciaModel item,
    UserModel? currentUser,
    VoidCallback? onModified,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return _HistorialModalContent(
          item: item,
          currentUser: currentUser,
          onModified: onModified,
        );
      },
    );
  }
}

class _HistorialModalContent extends StatefulWidget {
  final ExistenciaModel item;
  final UserModel? currentUser;
  final VoidCallback? onModified;

  const _HistorialModalContent({
    required this.item,
    required this.currentUser,
    this.onModified,
  });

  @override
  State<_HistorialModalContent> createState() => _HistorialModalContentState();
}

class _HistorialModalContentState extends State<_HistorialModalContent> {
  late Future<dynamic> _historialFuture;

  @override
  void initState() {
    super.initState();
    _loadHistorial();
  }

  void _loadHistorial() {
    setState(() {
      _historialFuture = ApiClient.get(ApiEndpoints.historial(widget.item.id));
    });
  }

  String _formatFecha(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'Reciente';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      final hour = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$min';
    } catch (_) {
      return dateStr.replaceAll('T', ' ').split('.').first;
    }
  }

  void _openEditDialog(BuildContext context, ExistenciaHistorialModel hist) {
    // La cantidad que se tomó en este movimiento específico
    final double cantidadTomada = (hist.cantidadContadaNueva - hist.cantidadContadaAnterior) > 0
        ? (hist.cantidadContadaNueva - hist.cantidadContadaAnterior)
        : hist.cantidadContadaNueva;

    final countCtrl = TextEditingController(
      text: cantidadTomada.toStringAsFixed(
        cantidadTomada.truncateToDouble() == cantidadTomada ? 0 : 2,
      ),
    );
    final ubicacionCtrl = TextEditingController(text: hist.ubicacion ?? '');
    final obsCtrl = TextEditingController(text: hist.observacion ?? '');
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (builderCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              actionsPadding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.edit_note_rounded, color: Color(0xFF2563EB), size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Modificar Conteo',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      widget.item.nombreProducto,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 14),

                    // Input: Cantidad Contada en esta toma
                    const Text(
                      'Cantidad Física de esta toma:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: countCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      decoration: InputDecoration(
                        suffixText: widget.item.unidadMedida,
                        suffixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input: Ubicación
                    TextField(
                      controller: ubicacionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Ubicación (Opcional)',
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.place_rounded, size: 18, color: Color(0xFF2563EB)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Input: Observación
                    TextField(
                      controller: obsCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Observación',
                        labelStyle: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        prefixIcon: const Icon(Icons.note_alt_outlined, size: 18, color: Color(0xFF64748B)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final count = double.tryParse(countCtrl.text.trim());
                          if (count == null || count < 0) {
                            ScaffoldMessenger.of(builderCtx).showSnackBar(
                              const SnackBar(content: Text('Ingrese una cantidad válida')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            await ApiClient.put(
                              ApiEndpoints.modificarHistorial(hist.id),
                              {
                                'cantidad_contada': count,
                                'ubicacion': ubicacionCtrl.text.trim(),
                                'observacion': obsCtrl.text.trim(),
                              },
                            );

                            if (!context.mounted) return;
                            if (!dialogCtx.mounted) return;
                            Navigator.pop(dialogCtx);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Conteo modificado correctamente'),
                                backgroundColor: Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );

                            _loadHistorial();
                            widget.onModified?.call();
                          } catch (e) {
                            setDialogState(() {
                              isSaving = false;
                            });
                            if (!dialogCtx.mounted) return;
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString().replaceAll('Exception:', '')}'),
                                backgroundColor: const Color(0xFFDC2626),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('GUARDAR CAMBIO', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHistorialCard(
    ExistenciaHistorialModel hist,
    String unidadMedida,
  ) {
    IconData icon;
    String tipoLabel;
    Color color;
    Color bgColor;

    switch (hist.tipoMovimiento) {
      case 'CONTEO_FISICO':
        icon = Icons.edit_note_rounded;
        tipoLabel = 'CONTEO FÍSICO';
        color = const Color(0xFF15803D);
        bgColor = const Color(0xFFDCFCE7);
        break;
      case 'REGISTRO_ADICIONAL':
        icon = Icons.add_circle_outline_rounded;
        tipoLabel = 'REGISTRO ADICIONAL';
        color = const Color(0xFF7E22CE);
        bgColor = const Color(0xFFF3E8FF);
        break;
      case 'CAMBIO_IMAGEN':
        icon = Icons.camera_alt_rounded;
        tipoLabel = 'FOTOGRAFÍA';
        color = const Color(0xFFD97706);
        bgColor = const Color(0xFFFEF3C7);
        break;
      case 'SUSTENTO_DIFERENCIA':
        icon = Icons.description_rounded;
        tipoLabel = 'SUSTENTO';
        color = const Color(0xFF2563EB);
        bgColor = const Color(0xFFEFF6FF);
        break;
      case 'CARGA_INICIAL':
      default:
        icon = Icons.file_upload_outlined;
        tipoLabel = hist.tipoMovimiento.replaceAll('_', ' ');
        color = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
    }

    // Validación de coincidencia de usuario: solo el usuario que registró este conteo puede modificarlo
    final bool canEdit = (widget.currentUser != null &&
        hist.userId != null &&
        hist.userId == widget.currentUser!.id &&
        (hist.tipoMovimiento == 'CONTEO_FISICO' || hist.tipoMovimiento == 'REGISTRO_ADICIONAL'));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: canEdit ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
          width: canEdit ? 1.2 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 13, color: color),
                    const SizedBox(width: 4),
                    Text(
                      tipoLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  const Icon(
                    Icons.access_time_rounded,
                    size: 12,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatFecha(hist.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Usuario y Ubicación
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  hist.userName ?? 'Usuario del Sistema',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hist.ubicacion != null && hist.ubicacion!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.place_rounded, size: 11, color: Color(0xFFE11D48)),
                      const SizedBox(width: 2),
                      Text(
                        hist.ubicacion!,
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Cantidad Contada y Botón de Modificar (si coincide el usuario)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Físico: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      hist.cantidadContadaAnterior > 0
                          ? '${hist.cantidadContadaAnterior} → ${hist.cantidadContadaNueva} $unidadMedida'
                          : '${hist.cantidadContadaNueva} $unidadMedida',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),

              // Botón de Modificar exclusivo si el usuario autenticado es quien contó
              if (canEdit)
                TextButton.icon(
                  onPressed: () => _openEditDialog(context, hist),
                  icon: const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF2563EB)),
                  label: const Text(
                    'Modificar',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFFEFF6FF),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
            ],
          ),

          if (hist.observacion != null && hist.observacion!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Obs: ${hist.observacion!}',
              style: const TextStyle(
                fontSize: 11.5,
                color: Color(0xFF475569),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header del Modal de Historial
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
                  child: const Icon(
                    Icons.history_rounded,
                    size: 22,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Historial de Movimientos',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'Item #${widget.item.item} • ${widget.item.codigo} - ${widget.item.nombreProducto}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Carga asíncrona del Historial desde la API
          Expanded(
            child: FutureBuilder<dynamic>(
              future: _historialFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            size: 40,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Error al cargar historial: ${snapshot.error.toString().replaceAll('Exception:', '')}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final res = snapshot.data;
                final rawList = (res != null &&
                        res['success'] == true &&
                        res['data'] is List)
                    ? (res['data'] as List)
                    : [];

                if (rawList.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history_toggle_off_rounded,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Sin movimientos registrados aún',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'El historial se genera automáticamente al registrar conteos físicos o adicionales.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final items = rawList
                    .map((json) => ExistenciaHistorialModel.fromJson(json))
                    .toList();

                return RefreshIndicator(
                  onRefresh: () async => _loadHistorial(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final hist = items[idx];
                      return _buildHistorialCard(hist, widget.item.unidadMedida);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
