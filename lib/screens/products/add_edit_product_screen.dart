import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/utils/error_handler.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../main.dart';
import '../../providers/auth_provider.dart';
import '../../services/product_service.dart';
import '../../services/storage_service.dart';

/// Create or update a product with validation + optional image upload.
class AddEditProductScreen extends StatefulWidget {
  const AddEditProductScreen({
    super.key,
    this.productId,
    this.initialName,
    this.initialCategory,
  });

  /// When null, screen is in "add" mode.
  final String? productId;
  final String? initialName;
  final String? initialCategory;

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _category = TextEditingController();
  final _buying = TextEditingController();
  final _selling = TextEditingController();
  final _quantity = TextEditingController();
  final _unit = TextEditingController(text: 'pcs');
  File? _pickedFile;
  bool _busy = false;
  String? _existingImageUrl;

  /// True when editing an existing product (non-empty Firestore document id).
  bool get isEdit =>
      widget.productId != null && widget.productId!.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    } else {
      _name.text = widget.initialName?.trim() ?? '';
      _category.text = widget.initialCategory?.trim() ?? '';
    }
  }

  Future<void> _load() async {
    final svc = context.read<ProductService>();
    final p = await svc.fetchProduct(widget.productId!);
    if (!mounted || p == null) return;
    setState(() {
      _name.text = p.name;
      _category.text = p.category;
      _buying.text = p.buyingPrice.toString();
      _selling.text = p.sellingPrice.toString();
      _quantity.text = p.quantity.toString();
      _unit.text = p.unit;
      _existingImageUrl = p.imageUrl;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _buying.dispose();
    _selling.dispose();
    _quantity.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600);
    if (x == null) return;
    setState(() => _pickedFile = File(x.path));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final uid = auth.activeUid;
    if (uid == null) return;
    if (!auth.isAdmin) {
      ErrorHandler.showSnack(context, Exception('Only admins can save products'));
      return;
    }

    setState(() => _busy = true);
    try {
      final startupState = context.read<AppStartupState>();
      final canUploadImage = startupState.firebaseEnabled;
      final productService = context.read<ProductService>();
      final storage = context.read<StorageService>();
      final buying = double.parse(_buying.text.trim());
      final selling = double.parse(_selling.text.trim());
      final qty = int.parse(_quantity.text.trim());
      if (selling < buying) {
        throw Exception('Selling price should be greater than or equal to buying price.');
      }

      final baseData = <String, dynamic>{
        'name': _name.text.trim(),
        'category': _category.text.trim(),
        'buyingPrice': buying,
        'sellingPrice': selling,
        'quantity': qty,
        'unit': _unit.text.trim(),
      };

      if (isEdit) {
        final id = widget.productId!;
        await productService.updateProduct(id, {
          ...baseData,
          'imageUrl': _existingImageUrl,
        });
        if (_pickedFile != null && canUploadImage) {
          final uploaded = await storage.uploadProductImage(
            productId: id,
            file: _pickedFile!,
          );
          await productService.updateProduct(id, {'imageUrl': uploaded});
        }
      } else {
        final newId = await productService.createProduct(
          data: {...baseData, 'imageUrl': null},
          uid: uid,
        );
        if (_pickedFile != null && canUploadImage) {
          final uploaded = await storage.uploadProductImage(
            productId: newId,
            file: _pickedFile!,
          );
          await productService.updateProduct(newId, {'imageUrl': uploaded});
        }
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ErrorHandler.showSnack(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final canUploadImage = context.watch<AppStartupState>().firebaseEnabled;

    if (!isAdmin) {
      return const Scaffold(
        appBar: PremiumAppBar(title: 'Product'),
        body: EmptyStateWidget(
          icon: Icons.lock_outline_rounded,
          title: 'Admins only',
          subtitle:
              'Only administrators can add or edit products in this business.',
        ),
      );
    }

    return Scaffold(
      appBar: PremiumAppBar(
        title: isEdit ? 'Edit product' : 'Add product',
        subtitle: 'Details & pricing',
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: SingleChildScrollView(
          padding: PremiumTokens.pagePadding(context),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                GestureDetector(
                  onTap: canUploadImage ? _pickImage : null,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ReportCard(
                      padding: EdgeInsets.zero,
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(PremiumTokens.radiusMd),
                        child: _pickedFile != null
                            ? Image.file(_pickedFile!, fit: BoxFit.cover)
                            : _existingImageUrl != null
                                ? Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        const Center(child: Icon(Icons.image)),
                                  )
                                : const Center(
                                    child:
                                        Text('Tap to pick image (optional)'),
                                  ),
                      ),
                    ),
                  ),
                ),
                if (!canUploadImage)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Demo mode: image upload is disabled.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                const SizedBox(height: 16),
                PremiumTextField(
                  controller: _name,
                  label: 'Product name',
                  validator: (v) => Validators.required(v, field: 'Name'),
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: _category,
                  label: 'Category',
                  validator: (v) => Validators.required(v, field: 'Category'),
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: _buying,
                  keyboardType: TextInputType.number,
                  label: 'Buying price (BDT)',
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, field: 'Buying price'),
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: _selling,
                  keyboardType: TextInputType.number,
                  label: 'Selling price (BDT)',
                  validator: (v) =>
                      Validators.nonNegativeNumber(v, field: 'Selling price'),
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: _quantity,
                  keyboardType: TextInputType.number,
                  label: 'Quantity',
                  validator: (v) => Validators.positiveInt(v, field: 'Quantity'),
                ),
                const SizedBox(height: 12),
                PremiumTextField(
                  controller: _unit,
                  label: 'Unit (pcs, kg, box…)',
                  validator: (v) => Validators.required(v, field: 'Unit'),
                ),
                const SizedBox(height: 24),
                PremiumButton(
                  label: _busy
                      ? 'Saving…'
                      : (isEdit ? 'Update product' : 'Create product'),
                  expand: true,
                  icon: _busy ? null : Icons.check_rounded,
                  onPressed: _busy ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
