import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../models/product.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';
import '../../services/ai/product_recognizer.dart';

/// AI-ready product recognition flow (mock today, replaceable with real ML later).
class AIProductRecognitionScreen extends StatefulWidget {
  const AIProductRecognitionScreen({super.key});

  @override
  State<AIProductRecognitionScreen> createState() =>
      _AIProductRecognitionScreenState();
}

class _AIProductRecognitionScreenState extends State<AIProductRecognitionScreen> {
  final _picker = ImagePicker();
  final _mockHint = TextEditingController();
  final ProductRecognizer _recognizer = const MockProductRecognizer();

  XFile? _image;
  ProductRecognitionResult? _result;
  bool _busy = false;
  String _status = 'Open camera and capture a product image.';

  Product? _findExistingProduct(List<Product> products, String detectedName) {
    final n = detectedName.trim().toLowerCase();
    for (final p in products) {
      final pn = p.name.trim().toLowerCase();
      if (pn == n || pn.contains(n) || n.contains(pn)) {
        return p;
      }
    }
    return null;
  }

  Widget _imagePreview() {
    if (_image == null) return const Center(child: Text('No image yet'));
    return FutureBuilder<Uint8List>(
      future: _image!.readAsBytes(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (!snap.hasData || snap.data == null) {
          if (kIsWeb) {
            return Image.network(_image!.path, fit: BoxFit.cover);
          }
          return const Center(child: Text('Could not preview image'));
        }
        return Image.memory(snap.data!, fit: BoxFit.cover);
      },
    );
  }

  Future<void> _analyze(XFile image) async {
    setState(() {
      _busy = true;
      _status = 'Analyzing image with mock AI...';
      _result = null;
    });
    try {
      final result = await _recognizer.recognize(
        image,
        mockHint: _mockHint.text.trim().isEmpty ? null : _mockHint.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _result = result;
        _status = 'Detected: ${result.productName}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _status = 'Could not analyze image. Try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _capture() async {
    if (!kIsWeb) {
      var status = await Permission.camera.status;
      if (status.isDenied) {
        status = await Permission.camera.request();
      }
      if (!status.isGranted) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status.isPermanentlyDenied
                  ? 'Camera permission blocked. Open settings to allow it.'
                  : 'Camera permission is required to capture product images.',
            ),
            action: status.isPermanentlyDenied
                ? const SnackBarAction(
                    label: 'Settings',
                    onPressed: openAppSettings,
                  )
                : null,
          ),
        );
        return;
      }
    }

    final x = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
    );
    if (x == null) return;
    setState(() {
      _image = x;
      _status = 'Image captured. Starting recognition...';
    });
    await _analyze(x);
  }

  Future<void> _pickFromGallery() async {
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (x == null) return;
    setState(() {
      _image = x;
      _status = 'Image selected. Starting recognition...';
    });
    await _analyze(x);
  }

  @override
  void dispose() {
    _mockHint.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final detectedName = _result?.productName;
    final matched = detectedName == null
        ? null
        : _findExistingProduct(products, detectedName);

    return Scaffold(
      appBar: AppBar(title: const Text('AI product recognition')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(_status, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 12),
            if (_result != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: Text(_result!.productName),
                  subtitle: Text(
                    'Confidence ${(100 * _result!.confidence).toStringAsFixed(0)}% · '
                    '${_result!.source}',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: _imagePreview(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mockHint,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.psychology_alt_outlined),
                labelText: 'Mock AI hint (optional)',
                hintText: 'alu / peyaj / chal / dal / oil / sugar',
              ),
              onSubmitted: (_) {
                if (_image != null) _analyze(_image!);
              },
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final hint in const [
                  'alu',
                  'peyaj',
                  'chal',
                  'dal',
                  'oil',
                  'sugar',
                ])
                  ActionChip(
                    label: Text(hint),
                    onPressed: () {
                      _mockHint.text = hint;
                      if (_image != null) _analyze(_image!);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : _capture,
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Open camera'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Tip: set a mock hint, then capture/select image.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            if (_image != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _busy ? null : () => _analyze(_image!),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-analyze'),
                ),
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              if (matched != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Matched existing product',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(matched.name),
                        Text(
                          '${matched.quantity} ${matched.unit} · '
                          '${BdtFormatter.format(matched.sellingPrice)}',
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.stockIn,
                                  arguments: matched.id,
                                ),
                                icon: const Icon(Icons.add_box_outlined),
                                label: const Text('Add stock'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRoutes.sell,
                                  arguments: matched.id,
                                ),
                                icon: const Icon(Icons.shopping_cart_outlined),
                                label: const Text('Sell'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'No existing product found for "${_result!.productName}"',
                        ),
                        const SizedBox(height: 10),
                        FilledButton.icon(
                          onPressed: () => Navigator.pushNamed(
                            context,
                            AppRoutes.productAdd,
                            arguments: <String, String>{
                              'initialName': _result!.productName,
                              'initialCategory': 'Vegetable',
                            },
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add as new product'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
