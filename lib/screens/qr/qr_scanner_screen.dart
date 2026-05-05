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
      appBar: NeonAppBar(
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
              Color(0xFF0B0F1A),
              Color(0xFF101B32),
              Color(0xFF162643),
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: NeonGlassCard(
                radius: 26,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Camera permission required',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 72,
                      color: Colors.white70,
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0B0F1A),
            Color(0xFF101B32),
            Color(0xFF162643),
          ],
        ),
      ),
      child: ListView(
        padding: PremiumTokens.pagePadding(context),
        children: [
          NeonGlassCard(
            radius: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scanner Hero',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Align the QR inside the animated frame for stock operations.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 1.12,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        MobileScanner(
                          controller: c,
                          onDetect: _onDetect,
                          errorBuilder: (context, error, child) {
                            return Container(
                              color: const Color(0xD0111827),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.white),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Camera error',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(color: Colors.white),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    error.errorDetails?.message ?? error.toString(),
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.white70),
                                  ),
                                ],
                              ),
                            );
                          },
                          overlayBuilder: (context, constraints) {
                            final side = constraints.maxWidth * 0.72;
                            return IgnorePointer(
                              child: Align(
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0.94, end: 1.0),
                                  duration: const Duration(milliseconds: 1200),
                                  curve: Curves.easeInOut,
                                  builder: (context, t, child) => Transform.scale(
                                    scale: t,
                                    child: child,
                                  ),
                                  child: Container(
                                    width: side,
                                    height: side,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF22D3EE),
                                        width: 3,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          blurRadius: 24,
                                          color:
                                              const Color(0xFF22D3EE).withValues(alpha: 0.35),
                                        ),
                                        BoxShadow(
                                          blurRadius: 18,
                                          color:
                                              const Color(0xFFA855F7).withValues(alpha: 0.28),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          _manualFallbackCard(),
          const SizedBox(height: 10),
          NeonGlassCard(
            radius: 22,
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF22D3EE)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Codes must start with “inv:product:” or be a product UUID.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _manualFallbackCard({bool compact = false}) {
    return NeonGlassCard(
      radius: 22,
      padding: EdgeInsets.all(compact ? 12 : 16),
      borderColor: const Color(0x6622D3EE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Manual Product ID',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          NeonTextField(
            controller: _manualController,
            hint: 'Paste product ID or inv:product:... payload',
            prefixIcon: const Icon(Icons.edit_note_outlined),
            onSubmitted: (_) => _submitManual(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: NeonButton(
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
