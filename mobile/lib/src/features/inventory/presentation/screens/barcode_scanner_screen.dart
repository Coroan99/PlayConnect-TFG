import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.code93,
      BarcodeFormat.codabar,
      BarcodeFormat.itf2of5,
      BarcodeFormat.itf14,
    ],
  );

  StreamSubscription<BarcodeCapture>? _barcodeSubscription;
  bool _isHandlingBarcode = false;
  MobileScannerException? _scannerError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _barcodeSubscription = _controller.barcodes.listen(
      _handleBarcodeCapture,
      onError: _handleScannerError,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_startScanner());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_barcodeSubscription?.cancel());
    _barcodeSubscription = null;
    unawaited(_controller.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_controller.value.hasCameraPermission) {
      return;
    }

    switch (state) {
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        unawaited(_controller.stop());
        return;
      case AppLifecycleState.resumed:
        unawaited(_startScanner());
        return;
      case AppLifecycleState.inactive:
        unawaited(_controller.stop());
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Escanear codigo'),
        actions: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (context, state, child) {
              final torchAvailable = state.torchState != TorchState.unavailable;

              return IconButton(
                tooltip: 'Flash',
                onPressed: torchAvailable ? _controller.toggleTorch : null,
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Reintentar',
            onPressed: _restartScanner,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final scanWindow = Rect.fromCenter(
            center: constraints.biggest.center(Offset.zero),
            width: constraints.maxWidth * 0.72,
            height: constraints.maxHeight * 0.26,
          );

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                scanWindow: scanWindow,
                placeholderBuilder: (context) {
                  return const ColoredBox(
                    color: Colors.black,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error) {
                  return _ScannerErrorState(
                    error: error,
                    onRetry: _restartScanner,
                  );
                },
                overlayBuilder: (context, constraints) {
                  return ScanWindowOverlay(
                    controller: _controller,
                    scanWindow: scanWindow,
                    borderColor: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    borderWidth: 3,
                    color: Colors.black.withValues(alpha: 0.52),
                  );
                },
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 24,
                child: _ScannerHintCard(
                  hasPermissionError:
                      _scannerError?.errorCode ==
                      MobileScannerErrorCode.permissionDenied,
                  onRetry: _restartScanner,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _startScanner() async {
    if (!mounted || _isHandlingBarcode) {
      return;
    }

    try {
      setState(() {
        _scannerError = null;
      });

      await _controller.start();
    } on MobileScannerException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _scannerError = error;
      });
    }
  }

  Future<void> _restartScanner() async {
    _isHandlingBarcode = false;

    try {
      await _controller.stop();
    } catch (_) {
      // Ignore stop errors and try to start again.
    }

    await _startScanner();
  }

  Future<void> _handleBarcodeCapture(BarcodeCapture capture) async {
    if (_isHandlingBarcode) {
      return;
    }

    final rawValue = capture.barcodes
        .map((barcode) => barcode.rawValue?.trim())
        .firstWhere(
          (value) => value != null && value.isNotEmpty,
          orElse: () => null,
        );

    if (rawValue == null || rawValue.isEmpty) {
      return;
    }

    _isHandlingBarcode = true;
    await _controller.stop();

    if (!mounted) {
      return;
    }

    Navigator.of(context).pop(rawValue);
  }

  void _handleScannerError(Object error) {
    if (!mounted) {
      return;
    }

    setState(() {
      _scannerError = error is MobileScannerException
          ? error
          : const MobileScannerException(
              errorCode: MobileScannerErrorCode.genericError,
            );
    });
  }
}

class _ScannerHintCard extends StatelessWidget {
  const _ScannerHintCard({
    required this.hasPermissionError,
    required this.onRetry,
  });

  final bool hasPermissionError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: colorScheme.surface.withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hasPermissionError
                  ? 'Permiso de camara requerido'
                  : 'Coloca el codigo dentro del marco',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              hasPermissionError
                  ? 'Si has denegado el permiso, vuelve a intentarlo para permitir el acceso a la camara.'
                  : 'El escaner consultara PlayConnect automaticamente en cuanto detecte un codigo valido.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(
                  hasPermissionError
                      ? 'Solicitar permiso'
                      : 'Reiniciar escaner',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScannerErrorState extends StatelessWidget {
  const _ScannerErrorState({required this.error, required this.onRetry});

  final MobileScannerException error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPermissionError =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isPermissionError
                        ? colorScheme.secondaryContainer
                        : colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPermissionError
                        ? Icons.videocam_off_outlined
                        : Icons.qr_code_scanner_outlined,
                    color: isPermissionError
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onErrorContainer,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isPermissionError
                      ? 'No hay acceso a la camara'
                      : 'No se pudo iniciar el escaner',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  error.errorDetails?.message ?? error.errorCode.message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
