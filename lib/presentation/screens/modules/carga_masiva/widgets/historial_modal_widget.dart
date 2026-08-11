import 'package:flutter/material.dart';
import '../../../../../core/constants/api_endpoints.dart';
import '../../../../../core/network/api_client.dart';
import '../../../../../data/models/existencia_model.dart';

class HistorialModalWidget {
  static void show(
    BuildContext context, {
    required ExistenciaModel item,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(modalCtx).size.height * 0.85,
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
                            'Item #${item.item} • ${item.codigo} - ${item.nombreProducto}',
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
                      onPressed: () => Navigator.pop(modalCtx),
                    ),
                  ],
                ),
              ),

              // Carga asíncrona del Historial desde la API
              Expanded(
                child: FutureBuilder<dynamic>(
                  future: ApiClient.get(ApiEndpoints.historial(item.id)),
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

                    return ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, idx) {
                        final hist = items[idx];
                        return _buildHistorialCard(hist, item.unidadMedida);
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

  static String _formatFecha(String? dateStr) {
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

  static Widget _buildHistorialCard(
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

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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

          // Usuario y Detalle
          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                hist.userName ?? 'Usuario del Sistema',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Cantidad Contada
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
}
