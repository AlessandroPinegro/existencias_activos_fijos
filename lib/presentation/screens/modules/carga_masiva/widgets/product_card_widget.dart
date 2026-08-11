import 'package:flutter/material.dart';
import '../../../../../data/models/existencia_model.dart';

class ProductCardWidget extends StatelessWidget {
  final ExistenciaModel item;
  final VoidCallback onConteo;
  final VoidCallback onHistorial;

  const ProductCardWidget({
    super.key,
    required this.item,
    required this.onConteo,
    required this.onHistorial,
  });

  @override
  Widget build(BuildContext context) {
    final isPendiente = item.condicion == 'PENDIENTE';

    Color badgeBg;
    Color badgeText;
    Color borderColor;
    String estadoTexto;

    switch (item.condicion) {
      case 'CONCILIADO':
      case 'CONFORME':
        badgeBg = const Color(0xFFDCFCE7);
        badgeText = const Color(0xFF15803D);
        borderColor = const Color(0xFF86EFAC);
        estadoTexto = 'CONCILIADO';
        break;
      case 'SOBRANTE':
        badgeBg = const Color(0xFFDBEAFE);
        badgeText = const Color(0xFF1D4ED8);
        borderColor = const Color(0xFF93C5FD);
        estadoTexto = 'SOBRANTE';
        break;
      case 'FALTANTE':
        badgeBg = const Color(0xFFFEE2E2);
        badgeText = const Color(0xFFB91C1C);
        borderColor = const Color(0xFFFCA5A5);
        estadoTexto = 'FALTANTE';
        break;
      case 'ADICIONAL':
        badgeBg = const Color(0xFFF3E8FF);
        badgeText = const Color(0xFF7E22CE);
        borderColor = const Color(0xFFD8B4FE);
        estadoTexto = 'ADICIONAL';
        break;
      case 'PENDIENTE':
      default:
        badgeBg = const Color(0xFFFEF3C7);
        badgeText = const Color(0xFFB45309);
        borderColor = const Color(0xFFFDE68A);
        estadoTexto = 'PENDIENTE';
        break;
    }

    final almacenTxt = item.almacenNombre != null && item.almacenNombre!.isNotEmpty
        ? item.almacenNombre!
        : 'Principal';
    final ubicacionTxt = item.ubicacion != null && item.ubicacion!.isNotEmpty
        ? item.ubicacion!
        : 'Sin ubicación';

    // Texto descriptivo del estado de conteo a la izquierda
    String conteoStatusText;
    Color conteoStatusColor;
    IconData conteoStatusIcon;

    if (item.condicion == 'PENDIENTE') {
      conteoStatusText = 'Sin contar';
      conteoStatusColor = const Color(0xFFB45309);
      conteoStatusIcon = Icons.schedule_rounded;
    } else if (item.condicion == 'CONCILIADO' || item.condicion == 'CONFORME') {
      conteoStatusText =
          'Conciliado: ${item.cantidadContada.toStringAsFixed(item.cantidadContada.truncateToDouble() == item.cantidadContada ? 0 : 2)} ${item.unidadMedida}';
      conteoStatusColor = const Color(0xFF15803D);
      conteoStatusIcon = Icons.check_circle_rounded;
    } else if (item.condicion == 'SOBRANTE') {
      conteoStatusText =
          'Sobrante: ${item.cantidadContada.toStringAsFixed(item.cantidadContada.truncateToDouble() == item.cantidadContada ? 0 : 2)} ${item.unidadMedida}';
      conteoStatusColor = const Color(0xFF1D4ED8);
      conteoStatusIcon = Icons.arrow_upward_rounded;
    } else if (item.condicion == 'FALTANTE') {
      conteoStatusText =
          'Faltante: ${item.cantidadContada.toStringAsFixed(item.cantidadContada.truncateToDouble() == item.cantidadContada ? 0 : 2)} ${item.unidadMedida}';
      conteoStatusColor = const Color(0xFFB91C1C);
      conteoStatusIcon = Icons.arrow_downward_rounded;
    } else {
      // ADICIONAL
      conteoStatusText =
          'Adicional: ${item.cantidadContada.toStringAsFixed(item.cantidadContada.truncateToDouble() == item.cantidadContada ? 0 : 2)} ${item.unidadMedida}';
      conteoStatusColor = const Color(0xFF7E22CE);
      conteoStatusIcon = Icons.add_circle_outline_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: borderColor,
          width: isPendiente ? 1.2 : 1.4,
        ),
      ),
      elevation: isPendiente ? 1.5 : 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onConteo,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fila 1: Código con Item # y Estado
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      '#${item.item}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.codigo,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: badgeBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      estadoTexto,
                      style: TextStyle(
                        color: badgeText,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),

              // Fila 2: Nombre del Producto
              Text(
                item.nombreProducto,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 7),

              // Fila 3: Almacén, Ubicación, Lote y Unidad en pills compactos
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _buildCompactPill(
                    Icons.warehouse_rounded,
                    almacenTxt,
                    const Color(0xFFEFF6FF),
                    const Color(0xFF1D4ED8),
                  ),
                  _buildCompactPill(
                    Icons.location_on_rounded,
                    ubicacionTxt,
                    const Color(0xFFFFF1F2),
                    const Color(0xFFBE123C),
                  ),
                  if (item.lote != null && item.lote!.isNotEmpty)
                    _buildCompactPill(
                      Icons.qr_code_2_rounded,
                      'Lote: ${item.lote}',
                      const Color(0xFFFAF5FF),
                      const Color(0xFF7E22CE),
                    ),
                  _buildCompactPill(
                    Icons.straighten_rounded,
                    item.unidadMedida,
                    const Color(0xFFF1F5F9),
                    const Color(0xFF475569),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Fila 4: Estado del conteo, botón de historial y botón de acción
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          conteoStatusIcon,
                          size: 14,
                          color: conteoStatusColor,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            conteoStatusText,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: conteoStatusColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Botón Historial
                  SizedBox(
                    height: 30,
                    width: 32,
                    child: OutlinedButton(
                      onPressed: onHistorial,
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                        backgroundColor: const Color(0xFFF8FAFC),
                      ),
                      child: const Icon(
                        Icons.history_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Botón Registrar/Modificar Conteo
                  SizedBox(
                    height: 30,
                    child: ElevatedButton.icon(
                      onPressed: onConteo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPendiente
                            ? const Color(0xFF2563EB)
                            : const Color(0xFF0F172A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      icon: Icon(
                        isPendiente
                            ? Icons.touch_app_rounded
                            : Icons.edit_note_rounded,
                        size: 14,
                      ),
                      label: Text(
                        isPendiente ? 'REGISTRAR' : 'MODIFICAR',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactPill(
    IconData icon,
    String text,
    Color bgColor,
    Color textColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: textColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 3.5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(
              text,
              style: TextStyle(
                fontSize: 10.5,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
