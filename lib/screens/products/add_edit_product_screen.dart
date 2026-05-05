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
        appBar: NeonAppBar(title: 'Product'),
        body: EmptyStateWidget(
          icon: Icons.lock_outline_rounded,
          title: 'Admins only',
          subtitle:
              'Only administrators can add or edit products in this business.',
        ),
      );
    }

    final saveButton = PremiumButton(
      label: _busy
          ? 'Saving...'
          : (isEdit ? 'Update product' : 'Create product'),
      expand: true,
      icon: _busy ? null : Icons.check_rounded,
      onPressed: _busy ? null : _save,
    );

    return Scaffold(
      appBar: NeonAppBar(
        title: isEdit ? 'Edit product' : 'Add product',
        subtitle: 'Product management',
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: NeonGlassCard(
            radius: 24,
            child: saveButton,
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _busy,
        child: Container(
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
          child: SingleChildScrollView(
            padding: PremiumTokens.pagePadding(context).copyWith(bottom: 110),
            child: Form(
              key: _formKey,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 900;
                  final basicInfoSection = NeonGlassCard(
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Basic Info',
                          subtitle: 'Product name and category',
                          icon: Icons.inventory_2_outlined,
                        ),
                        const SizedBox(height: 10),
                        NeonTextField(
                          controller: _name,
                          label: 'Product name',
                          validator: (v) => Validators.required(v, field: 'Name'),
                        ),
                        const SizedBox(height: 12),
                        NeonTextField(
                          controller: _category,
                          label: 'Category',
                          validator: (v) => Validators.required(v, field: 'Category'),
                        ),
                      ],
                    ),
                  );
                  final pricingSection = NeonGlassCard(
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Pricing',
                          subtitle: 'Buying and selling price',
                          icon: Icons.sell_outlined,
                        ),
                        const SizedBox(height: 10),
                        NeonTextField(
                          controller: _buying,
                          keyboardType: TextInputType.number,
                          label: 'Buying price (BDT)',
                          validator: (v) =>
                              Validators.nonNegativeNumber(v, field: 'Buying price'),
                        ),
                        const SizedBox(height: 12),
                        NeonTextField(
                          controller: _selling,
                          keyboardType: TextInputType.number,
                          label: 'Selling price (BDT)',
                          validator: (v) =>
                              Validators.nonNegativeNumber(v, field: 'Selling price'),
                        ),
                      ],
                    ),
                  );
                  final stockSection = NeonGlassCard(
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionTitle(
                          title: 'Stock',
                          subtitle: 'Current quantity and unit',
                          icon: Icons.warehouse_outlined,
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: NeonTextField(
                                controller: _quantity,
                                keyboardType: TextInputType.number,
                                label: 'Quantity',
                                validator: (v) =>
                                    Validators.positiveInt(v, field: 'Quantity'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: NeonTextField(
                                controller: _unit,
                                label: 'Unit',
                                validator: (v) => Validators.required(v, field: 'Unit'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                  final mediaSection = NeonGlassCard(
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      _SectionTitle(
                        title: 'Image / QR',
                        subtitle: 'Optional image for premium catalog card',
                        icon: Icons.image_outlined,
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: canUploadImage ? _pickImage : null,
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: NeonGlassCard(
                            padding: EdgeInsets.zero,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: _pickedFile != null
                                  ? Image.file(_pickedFile!, fit: BoxFit.cover)
                                  : _existingImageUrl != null
                                      ? Image.network(
                                          _existingImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Center(child: Icon(Icons.image)),
                                        )
                                      : Container(
                                          color: Colors.white.withValues(alpha: 0.08),
                                          child: const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.image_outlined, size: 44),
                                              SizedBox(height: 8),
                                              Text('Tap to pick image (optional)'),
                                            ],
                                          ),
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
                      const SizedBox(height: 12),
                      NeonGlassCard(
                        radius: 20,
                        child: Row(
                          children: [
                            const Icon(Icons.qr_code_2_rounded, color: Color(0xFF22D3EE)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isEdit
                                    ? 'QR label is available after save from Product Details.'
                                    : 'Create product first, then open Product Details for QR.',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    ),
                  );
                  final formSection = Column(
                    children: [
                      basicInfoSection,
                      const SizedBox(height: 12),
                      pricingSection,
                      const SizedBox(height: 12),
                      stockSection,
                    ],
                  );
                  return Column(
                    children: [
                      if (!isWide) ...[
                        formSection,
                        const SizedBox(height: 12),
                        mediaSection,
                      ] else
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: formSection),
                            const SizedBox(width: 12),
                            Expanded(child: mediaSection),
                          ],
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF22D3EE)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
