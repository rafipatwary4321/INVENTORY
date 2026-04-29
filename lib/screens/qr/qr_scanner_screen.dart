import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/utils/qr_payload.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../models/qr_scan_args.dart';

/// Camera QR scanner: requests **camera** permission, then decodes product ids.
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key, required this.mode});

  final QRScanMode mode;

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with WidgetsBindingObserver {
  MobileScannerController? _controller;
  final _manualController = TextEditingController();
  bool _checkingPermission = true;
  bool _hasPermission = false;
  bool _permanentlyDenied = false;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolvePermission());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _resolvePermission();
    }
  }

  Future<void> _resolvePermission() async {
    if (kIsWeb) {
      if (!mounted) return;
      setState(() {
        _checkingPermission = false;
        _hasPermission = true;
        _permanentlyDenied = false;
        _controller ??= MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
        );
      });
      return;
    }

    var status = await Permission.camera.status;

    if (status.isDenied) {
      status = await Permission.camera.request();
    }

    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _checkingPermission = false;
        _hasPermission = true;
        _permanentlyDenied = false;
        _controller ??= MobileScannerController(
          formats: const [BarcodeFormat.qrCode],
        );
      });
      return;
    }

    if (status.isPermanentlyDenied) {
      setState(() {
        _checkingPermission = false;
        _hasPermission = false;
        _permanentlyDenied = true;
      });
      return;
    }

    setState(() {
      _checkingPermission = false;
      _hasPermission = false;
      _permanentlyDenied = false;
    });
  }

  void _onDetect(BarcodeCapture cap) {
    if (_handled) return;
    final codes = cap.barcodes;
    if (codes.isEmpty) return;
    final raw = codes.first.rawValue;
    if (raw == null || raw.isEmpty) return;
    final id = QrPayload.decodeToProductId(raw);
    if (id == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Not an INVENTORY product QR. Try another code.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _handled = true;
    Navigator.pop(context, id);
  }

  void _submitManual() {
    final raw = _manualController.text.trim();
    final id = QrPayload.decodeToProductId(raw) ?? raw;
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a product ID or QR payload.')),
      );
      return;
    }
    Navigator.pop(context, id);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _manualController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (widget.mode) {
      QRScanMode.stockIn => 'Scan — Stock in',
      QRScanMode.sell => 'Scan — Sell',
    };

    return Scaffold(
      appBar: PremiumAppBar(
        title: title,
        actions: [
          if (_hasPermission && _controller != null)
            IconButton(
              icon: const Icon(Icons.flash_on_rounded),
              tooltip: 'Torch',
              onPressed: () => _controller!.toggleTorch(),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final scheme = Theme.of(context).colorScheme;
    if (_checkingPermission) {
      return const LoadingWidget(
        message: 'Checking camera permission…',
      );
    }

    if (!_hasPermission) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050C18),
              Color(0xFF0A1C35),
              Color(0xFF0F2F57),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: PremiumGlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const FeatureHeaderCard(
                      title: 'QR Scanner',
                      subtitle: 'Use camera access to scan inventory product labels.',
                      icon: Icons.qr_code_scanner_rounded,
                      trailingIcon: Icons.camera_alt_outlined,
                    ),
                      const AnimatedFeatureHero(
                        title: 'Scanner Visualization',
                        subtitle: 'QR capture and barcode intake workflow.',
                        icon: Icons.qr_code_scanner_rounded,
                        gradientColors: [Color(0xFF7A37FF), Color(0xFF13A7FF), Color(0xFF1DE2B0)],
                        animationType: FeatureHeroAnimationType.scanner,
                      ),
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 72,
                      color: scheme.outline,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _permanentlyDenied
                          ? 'Camera is blocked for this app.'
                          : 'Camera permission is required to scan QR codes.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _permanentlyDenied
                          ? 'Open Settings → Permissions and allow Camera, then return here.'
                          : 'Tap below to allow access when the system dialog appears.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        if (_permanentlyDenied) {
                          await openAppSettings();
                        } else {
                          await _resolvePermission();
                        }
                      },
                      icon: Icon(_permanentlyDenied ? Icons.settings : Icons.camera_alt),
                      label: Text(_permanentlyDenied ? 'Open settings' : 'Try again'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(height: 8),
                    _manualFallbackCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final c = _controller!;
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: c,
          onDetect: _onDetect,
          errorBuilder: (context, error, child) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'Camera error',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.errorDetails?.message ?? error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'If camera is unavailable, enter product ID manually.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _manualFallbackCard(compact: true),
                  ],
                ),
              ),
            );
          },
          overlayBuilder: (context, constraints) {
            final side = constraints.maxWidth * 0.72;
            return IgnorePointer(
              child: Align(
                child: Container(
                  width: side,
                  height: side,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white, width: 3),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 24,
                        spreadRadius: 2,
                        color: Colors.black.withValues(alpha: 0.35),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0),
                ],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: IgnorePointer(
                      child: AnimatedFeatureHero(
                        title: 'Live Scan Mode',
                        subtitle: 'Align QR inside frame for instant decode.',
                        icon: Icons.qr_code_2_rounded,
                        compact: true,
                        gradientColors: [
                          Color(0xCC7A37FF),
                          Color(0xCC13A7FF),
                          Color(0xCC1DE2B0),
                        ],
                        animationType: FeatureHeroAnimationType.scanner,
                      ),
                    ),
                  ),
                  Text(
                    'Point at the product QR code',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _OverlayTag(icon: Icons.inventory_2_outlined, label: 'Inventory'),
                      const SizedBox(width: 8),
                      _OverlayTag(icon: Icons.qr_code_2_outlined, label: 'QR only'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.black.withValues(alpha: 0),
                ],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Text(
                'Codes must start with “inv:product:” or be a product UUID.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _manualFallbackCard({bool compact = false}) {
    return PremiumGlassCard(
      padding: EdgeInsets.all(compact ? 12 : 16),
      borderColor: Colors.cyanAccent.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manual product ID',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _manualController,
            decoration: const InputDecoration(
              hintText: 'Paste product ID or inv:product:... payload',
              prefixIcon: Icon(Icons.edit_note_outlined),
            ),
            onSubmitted: (_) => _submitManual(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: PremiumButton(
              label: 'Use ID',
              icon: Icons.arrow_forward_rounded,
              onPressed: _submitManual,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverlayTag extends StatelessWidget {
  const _OverlayTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
