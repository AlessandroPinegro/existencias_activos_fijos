import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerWidget extends StatefulWidget {
  final String title;
  final String subtitle;

  const BarcodeScannerWidget({
    super.key,
    this.title = 'Escanear Código',
    this.subtitle = 'Apunta al código de barras o QR del producto',
  });

  /// Abre el escáner en pantalla completa y devuelve el código capturado,
  /// o `null` si el usuario cancela.
  static Future<String?> show(
    BuildContext context, {
    String title = 'Escanear Código',
    String subtitle = 'Apunta al código de barras o QR del producto',
  }) {
    return Navigator.of(context).push<String>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => BarcodeScannerWidget(
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget>
    with SingleTickerProviderStateMixin {
  late final MobileScannerController _controller;
  late final AnimationController _laserCtrl;
  final ImagePicker _imagePicker = ImagePicker();

  bool _hasCaptured = false;
  bool _useScanWindow = true;
  bool _isPaused = false;
  bool _isAnalyzingGallery = false;
  String? _capturedCode;

  double _zoomScale = 0.0;
  double _baseZoomScale = 0.0;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      cameraResolution: const Size(1280, 720),
      autoZoom: true,
      returnImage: false,
    );

    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _laserCtrl.dispose();
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _handleCapture(String rawValue) async {
    final code = rawValue.trim();
    if (_hasCaptured || code.isEmpty) return;

    setState(() {
      _hasCaptured = true;
      _capturedCode = code;
    });

    _laserCtrl.stop();
    await HapticFeedback.mediumImpact();

    // Pausa breve para feedback visual antes de retornar el código
    await Future<void>.delayed(const Duration(milliseconds: 160));
    if (mounted) {
      Navigator.of(context).pop(code);
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasCaptured || _isPaused) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue ?? barcode.displayValue;
      if (value != null && value.trim().isNotEmpty) {
        _handleCapture(value);
        return;
      }
    }
  }

  Future<void> _togglePause() async {
    if (_hasCaptured) return;
    try {
      if (_isPaused) {
        await _controller.start();
        _laserCtrl.repeat(reverse: true);
      } else {
        await _controller.pause();
        _laserCtrl.stop();
      }
      if (mounted) {
        setState(() => _isPaused = !_isPaused);
      }
    } catch (_) {
      // Ignora errores si la cámara está cambiando de estado
    }
  }

  Future<void> _setZoom(double value) async {
    final clamped = value.clamp(0.0, 1.0);
    setState(() => _zoomScale = clamped);
    try {
      await _controller.setZoomScale(clamped);
    } catch (_) {
      // Algunos dispositivos no soportan zoom por software
    }
  }

  Future<void> _scanFromGallery() async {
    if (_isAnalyzingGallery || _hasCaptured) return;
    setState(() => _isAnalyzingGallery = true);

    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );
      if (file == null) return;

      final capture = await _controller.analyzeImage(file.path);
      final barcodes = capture?.barcodes ?? const <Barcode>[];

      for (final barcode in barcodes) {
        final value = barcode.rawValue ?? barcode.displayValue;
        if (value != null && value.trim().isNotEmpty) {
          await _handleCapture(value);
          return;
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se detectó ningún código en la imagen seleccionada.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo analizar la imagen seleccionada.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFFDC2626),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzingGallery = false);
      }
    }
  }

  Future<void> _openManualInput() async {
    final inputCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Row(
            children: [
              Icon(Icons.keyboard_rounded, color: Color(0xFF2563EB), size: 22),
              SizedBox(width: 8),
              Text(
                'Ingresar código',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: TextField(
            controller: inputCtrl,
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Ej: 0010020018',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (val) {
              if (val.trim().isNotEmpty) {
                Navigator.of(dialogCtx).pop(val.trim());
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                final text = inputCtrl.text.trim();
                if (text.isNotEmpty) {
                  Navigator.of(dialogCtx).pop(text);
                }
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );

    inputCtrl.dispose();

    if (result != null && result.isNotEmpty && mounted) {
      await _handleCapture(result);
    }
  }

  Rect _computeScanWindow(Size size) {
    final width = (size.width * 0.84).clamp(220.0, 380.0);
    final height = (size.height * 0.28).clamp(170.0, 260.0);
    final center = Offset(size.width / 2, size.height * 0.43);
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final layoutSize = constraints.biggest;
          final scanRect = _computeScanWindow(layoutSize);

          return Stack(
            fit: StackFit.expand,
            children: [
              // Vista de cámara con gesto pinch-to-zoom y enfoque al tocar
              GestureDetector(
                onScaleStart: (_) => _baseZoomScale = _zoomScale,
                onScaleUpdate: (details) {
                  if (details.pointerCount < 2) return;
                  final delta = (details.scale - 1.0) * 0.5;
                  _setZoom(_baseZoomScale + delta);
                },
                child: MobileScanner(
                  controller: _controller,
                  fit: BoxFit.cover,
                  tapToFocus: true,
                  scanWindow: _useScanWindow ? scanRect : null,
                  onDetect: _onDetect,
                  errorBuilder: (context, error) => _buildErrorView(error),
                  placeholderBuilder: (_) => const ColoredBox(
                    color: Colors.black,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF2563EB)),
                          SizedBox(height: 12),
                          Text(
                            'Iniciando cámara...',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Overlay visual del marco de escaneo + línea láser
              IgnorePointer(
                child: AnimatedBuilder(
                  animation: _laserCtrl,
                  builder: (context, _) {
                    return CustomPaint(
                      size: layoutSize,
                      painter: _ScannerOverlayPainter(
                        scanRect: scanRect,
                        useScanWindow: _useScanWindow,
                        laserProgress: _laserCtrl.value,
                        isCaptured: _hasCaptured,
                        isPaused: _isPaused,
                      ),
                    );
                  },
                ),
              ),

              // Barra superior (Cerrar, Título, Linterna, Cambiar Cámara)
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          _buildCircleButton(
                            icon: Icons.close_rounded,
                            tooltip: 'Cerrar escáner',
                            onTap: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  widget.subtitle,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Botones reactivos al estado de la cámara
                          ValueListenableBuilder<MobileScannerState>(
                            valueListenable: _controller,
                            builder: (context, state, _) {
                              final torchOn = state.torchState == TorchState.on;
                              final torchAvailable =
                                  state.torchState != TorchState.unavailable &&
                                      state.isRunning;
                              final canSwitchCamera =
                                  (state.availableCameras ?? 2) >= 2 &&
                                      state.isInitialized;

                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildCircleButton(
                                    icon: torchOn
                                        ? Icons.flash_on_rounded
                                        : Icons.flash_off_rounded,
                                    tooltip: torchOn
                                        ? 'Apagar linterna'
                                        : 'Encender linterna',
                                    isActive: torchOn,
                                    activeColor: const Color(0xFFF59E0B),
                                    onTap: torchAvailable
                                        ? () => _controller.toggleTorch()
                                        : null,
                                  ),
                                  if (canSwitchCamera) ...[
                                    const SizedBox(width: 8),
                                    _buildCircleButton(
                                      icon: Icons.cameraswitch_rounded,
                                      tooltip: 'Cambiar cámara',
                                      onTap: () => _controller.switchCamera(),
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Etiqueta de estado / código capturado
                    if (_capturedCode != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _capturedCode!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Text(
                          _isPaused
                              ? 'Escáner en pausa'
                              : _useScanWindow
                                  ? 'Centra el código dentro del recuadro • Toca para enfocar'
                                  : 'Escaneo en pantalla completa • Toca para enfocar',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                    // Panel inferior de controles rápidos (Zoom + Acciones)
                    Container(
                      margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Control de Zoom (presets + slider)
                          Row(
                            children: [
                              const Icon(
                                Icons.zoom_out_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              Expanded(
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 3,
                                    thumbShape: const RoundSliderThumbShape(
                                      enabledThumbRadius: 7,
                                    ),
                                    overlayShape: const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                    activeTrackColor: const Color(0xFF3B82F6),
                                    inactiveTrackColor: Colors.white24,
                                    thumbColor: Colors.white,
                                  ),
                                  child: Slider(
                                    value: _zoomScale,
                                    min: 0.0,
                                    max: 1.0,
                                    onChanged: _setZoom,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.zoom_in_rounded,
                                color: Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              _buildZoomChip('1x', 0.0),
                              const SizedBox(width: 4),
                              _buildZoomChip('2x', 0.35),
                              const SizedBox(width: 4),
                              _buildZoomChip('3x', 0.7),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Fila de herramientas rápidas
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildActionTool(
                                icon: _useScanWindow
                                    ? Icons.crop_free_rounded
                                    : Icons.fullscreen_rounded,
                                label: _useScanWindow ? 'Enfocado' : 'Completo',
                                isActive: _useScanWindow,
                                onTap: () {
                                  setState(
                                    () => _useScanWindow = !_useScanWindow,
                                  );
                                },
                              ),
                              _buildActionTool(
                                icon: _isPaused
                                    ? Icons.play_arrow_rounded
                                    : Icons.pause_rounded,
                                label: _isPaused ? 'Reanudar' : 'Pausar',
                                isActive: _isPaused,
                                onTap: _togglePause,
                              ),
                              _buildActionTool(
                                icon: Icons.photo_library_outlined,
                                label: _isAnalyzingGallery
                                    ? 'Leyendo...'
                                    : 'Galería',
                                onTap: _isAnalyzingGallery
                                    ? null
                                    : _scanFromGallery,
                              ),
                              _buildActionTool(
                                icon: Icons.keyboard_alt_outlined,
                                label: 'Manual',
                                onTap: _openManualInput,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    bool isActive = false,
    Color activeColor = const Color(0xFF2563EB),
  }) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: isActive
            ? activeColor
            : Colors.black.withValues(alpha: enabled ? 0.55 : 0.3),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive
                    ? activeColor
                    : Colors.white.withValues(alpha: enabled ? 0.25 : 0.1),
              ),
            ),
            child: Icon(
              icon,
              color: enabled ? Colors.white : Colors.white38,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoomChip(String label, double value) {
    final isSelected = (_zoomScale - value).abs() < 0.08;
    return GestureDetector(
      onTap: () => _setZoom(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2563EB)
              : Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActionTool({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? const Color(0xFF2563EB).withValues(alpha: 0.28)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFF3B82F6)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Icon(
                icon,
                color: isActive ? const Color(0xFF60A5FA) : Colors.white,
                size: 19,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? const Color(0xFF93C5FD) : Colors.white70,
                fontSize: 10.5,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(MobileScannerException error) {
    String title;
    String message;

    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        title = 'Permiso de cámara denegado';
        message =
            'Habilita el permiso de cámara para esta aplicación en los ajustes del dispositivo.';
        break;
      case MobileScannerErrorCode.unsupported:
        title = 'Cámara no compatible';
        message = 'Este dispositivo no soporta el escaneo con cámara.';
        break;
      default:
        title = 'Error al abrir la cámara';
        message = error.errorDetails?.message ??
            'No se pudo inicializar el escáner. Intenta nuevamente.';
        break;
    }

    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.all(28),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.no_photography_rounded,
                color: Color(0xFFF87171),
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _controller.start(),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Reintentar'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white38),
                  ),
                  onPressed: _openManualInput,
                  icon: const Icon(Icons.keyboard_rounded, size: 18),
                  label: const Text('Ingresar manual'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  final bool useScanWindow;
  final double laserProgress;
  final bool isCaptured;
  final bool isPaused;

  _ScannerOverlayPainter({
    required this.scanRect,
    required this.useScanWindow,
    required this.laserProgress,
    required this.isCaptured,
    required this.isPaused,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final accentColor =
        isCaptured ? const Color(0xFF10B981) : const Color(0xFF3B82F6);

    if (useScanWindow) {
      // Fondo oscurecido fuera del recuadro
      final fullPath = Path()..addRect(Offset.zero & size);
      final cutoutPath = Path()
        ..addRRect(
          RRect.fromRectAndRadius(scanRect, const Radius.circular(18)),
        );
      final overlayPath = Path.combine(
        PathOperation.difference,
        fullPath,
        cutoutPath,
      );

      canvas.drawPath(
        overlayPath,
        Paint()..color = Colors.black.withValues(alpha: 0.58),
      );

      // Borde sutil del recuadro
      canvas.drawRRect(
        RRect.fromRectAndRadius(scanRect, const Radius.circular(18)),
        Paint()
          ..color = isCaptured
              ? accentColor
              : Colors.white.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = isCaptured ? 2.5 : 1.2,
      );

      // Esquinas destacadas
      _drawCorners(canvas, scanRect, accentColor);

      // Línea láser animada
      if (!isPaused && !isCaptured) {
        final laserY =
            scanRect.top + 16 + (scanRect.height - 32) * laserProgress;
        final laserRect = Rect.fromLTWH(
          scanRect.left + 14,
          laserY,
          scanRect.width - 28,
          2.6,
        );
        final laserPaint = Paint()
          ..shader = LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.0),
              accentColor,
              const Color(0xFF93C5FD),
              accentColor,
              accentColor.withValues(alpha: 0.0),
            ],
          ).createShader(laserRect);
        canvas.drawRRect(
          RRect.fromRectAndRadius(laserRect, const Radius.circular(2)),
          laserPaint,
        );
      }
    } else {
      // Modo pantalla completa: guía sutil sin oscurecer el resto
      final guidePaint = Paint()
        ..color = accentColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      _drawCorners(canvas, scanRect, guidePaint.color);
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, Color color) {
    const cornerLength = 26.0;
    const radius = 16.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Top-left
    final tl = Path()
      ..moveTo(rect.left, rect.top + cornerLength)
      ..lineTo(rect.left, rect.top + radius)
      ..quadraticBezierTo(rect.left, rect.top, rect.left + radius, rect.top)
      ..lineTo(rect.left + cornerLength, rect.top);
    canvas.drawPath(tl, paint);

    // Top-right
    final tr = Path()
      ..moveTo(rect.right - cornerLength, rect.top)
      ..lineTo(rect.right - radius, rect.top)
      ..quadraticBezierTo(rect.right, rect.top, rect.right, rect.top + radius)
      ..lineTo(rect.right, rect.top + cornerLength);
    canvas.drawPath(tr, paint);

    // Bottom-left
    final bl = Path()
      ..moveTo(rect.left, rect.bottom - cornerLength)
      ..lineTo(rect.left, rect.bottom - radius)
      ..quadraticBezierTo(
        rect.left,
        rect.bottom,
        rect.left + radius,
        rect.bottom,
      )
      ..lineTo(rect.left + cornerLength, rect.bottom);
    canvas.drawPath(bl, paint);

    // Bottom-right
    final br = Path()
      ..moveTo(rect.right - cornerLength, rect.bottom)
      ..lineTo(rect.right - radius, rect.bottom)
      ..quadraticBezierTo(
        rect.right,
        rect.bottom,
        rect.right,
        rect.bottom - radius,
      )
      ..lineTo(rect.right, rect.bottom - cornerLength);
    canvas.drawPath(br, paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.laserProgress != laserProgress ||
        oldDelegate.useScanWindow != useScanWindow ||
        oldDelegate.isCaptured != isCaptured ||
        oldDelegate.isPaused != isPaused ||
        oldDelegate.scanRect != scanRect;
  }
}
