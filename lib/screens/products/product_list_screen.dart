import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/bdt_formatter.dart';
import '../../core/widgets/premium/premium_ui.dart';
import '../../models/product.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';
import '../../services/product_service.dart';

/// Browse products; admin can add/edit; everyone can open details / QR.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  _ProductFilter _selectedFilter = _ProductFilter.all;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final query = _search.text.trim().toLowerCase();
    final filtered = products.where((p) {
      final matchQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      final matchFilter = switch (_selectedFilter) {
        _ProductFilter.all => true,
        _ProductFilter.active => p.quantity > 0,
        _ProductFilter.lowStock => p.quantity > 0 && p.quantity < 10,
        _ProductFilter.outOfStock => p.quantity <= 0,
      };
      return matchQuery && matchFilter;
    }).toList();
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 900;
    final gridColumns = width >= 1250
        ? 3
        : width >= 900
            ? 2
            : 1;
    final lowStockCount = filtered.where((p) => p.isLowStock).length;

    return Scaffold(
      body: Container(
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
            _ProductsTopSection(
              isAdmin: isAdmin,
              searchController: _search,
              searchFocus: _searchFocus,
              selectedFilter: _selectedFilter,
              onFilterChanged: (next) => setState(() => _selectedFilter = next),
              onSearchChanged: () => setState(() {}),
            ),
            const SizedBox(height: 16),
            if (lowStockCount > 0)
              _LowStockStrip(lowStockCount: lowStockCount),
            if (lowStockCount > 0) const SizedBox(height: 12),
            if (products.isEmpty)
              EmptyStatePremium(
                icon: Icons.inventory_2_rounded,
                title: 'No products yet',
                subtitle: 'Add your first product to start tracking inventory.',
                actionLabel: isAdmin ? 'Add Product' : null,
                onAction: isAdmin
                    ? () => Navigator.pushNamed(context, AppRoutes.productAdd)
                    : null,
              )
            else if (filtered.isEmpty)
              const EmptyStatePremium(
                icon: Icons.search_off_rounded,
                title: 'No products found',
                subtitle: 'Try changing search or stock filter.',
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.65 : 1.28,
                ),
                itemBuilder: (context, i) {
                  final p = filtered[i];
                  return _LiquidProductCard(
                    product: p,
                    isAdmin: isAdmin,
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.productDetails,
                      arguments: p.id,
                    ),
                    onEdit: isAdmin
                        ? () => Navigator.pushNamed(
                              context,
                              AppRoutes.productEdit,
                              arguments: p.id,
                            )
                        : null,
                    onDelete: isAdmin ? () => _confirmDelete(p) : null,
                    onQrOrView: () => Navigator.pushNamed(
                      context,
                      AppRoutes.qrGenerate,
                      arguments: p.id,
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text('This will remove "${product.name}" from inventory.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await context.read<ProductService>().deleteProduct(product.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${product.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }
}

enum _ProductFilter { all, active, lowStock, outOfStock }

class _ProductsTopSection extends StatelessWidget {
  const _ProductsTopSection({
    required this.isAdmin,
    required this.searchController,
    required this.searchFocus,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onSearchChanged,
  });

  final bool isAdmin;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final _ProductFilter selectedFilter;
  final ValueChanged<_ProductFilter> onFilterChanged;
  final VoidCallback onSearchChanged;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    return NeonGlassCard(
      radius: 26,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Products',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (isAdmin)
                FilledButton.icon(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.productAdd),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(isWide ? 'Add Product' : 'Add'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: searchFocus.hasFocus
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.28),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: TextField(
              controller: searchController,
              focusNode: searchFocus,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search products...',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0x55111F35),
              ),
              onChanged: (_) => onSearchChanged(),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(
                label: 'All',
                selected: selectedFilter == _ProductFilter.all,
                onTap: () => onFilterChanged(_ProductFilter.all),
              ),
              _FilterChip(
                label: 'Active',
                selected: selectedFilter == _ProductFilter.active,
                onTap: () => onFilterChanged(_ProductFilter.active),
              ),
              _FilterChip(
                label: 'Low Stock',
                selected: selectedFilter == _ProductFilter.lowStock,
                onTap: () => onFilterChanged(_ProductFilter.lowStock),
              ),
              _FilterChip(
                label: 'Out of Stock',
                selected: selectedFilter == _ProductFilter.outOfStock,
                onTap: () => onFilterChanged(_ProductFilter.outOfStock),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF22D3EE), Color(0xFFA855F7)],
                )
              : null,
          color: selected ? null : Colors.white.withValues(alpha: 0.08),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.16),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _LowStockStrip extends StatelessWidget {
  const _LowStockStrip({required this.lowStockCount});

  final int lowStockCount;

  @override
  Widget build(BuildContext context) {
    return NeonGlassCard(
      borderColor: const Color(0x66F97316),
      radius: 22,
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFF97316)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$lowStockCount product(s) are low stock.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiquidProductCard extends StatefulWidget {
  const _LiquidProductCard({
    required this.product,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onQrOrView,
  });

  final Product product;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onQrOrView;

  @override
  State<_LiquidProductCard> createState() => _LiquidProductCardState();
}

class _LiquidProductCardState extends State<_LiquidProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final outOfStock = p.quantity <= 0;
    final lowStock = p.quantity > 0 && p.quantity < 10;
    final status = outOfStock ? 'Out of Stock' : (lowStock ? 'Low Stock' : 'In Stock');
    final statusColor = outOfStock
        ? const Color(0xFFF97316)
        : (lowStock ? Colors.orangeAccent : const Color(0xFF22D3EE));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.98, end: _hovered ? 1.0 : 0.995),
        duration: const Duration(milliseconds: 180),
        builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xAA111827),
                  const Color(0xAA1F2937),
                ],
              ),
              border: Border.all(
                color: (_hovered ? const Color(0xFF22D3EE) : const Color(0xFF6A4CFF))
                    .withValues(alpha: 0.45),
              ),
              boxShadow: [
                BoxShadow(
                  color: (_hovered ? const Color(0xFF22D3EE) : const Color(0xFFA855F7))
                      .withValues(alpha: 0.22),
                  blurRadius: 18,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF22D3EE), Color(0xFF3B82F6)],
                        ),
                      ),
                      child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p.category,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    _StatusBadge(label: status, color: statusColor),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Stock: ${p.quantity} ${p.unit}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    if (lowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0x33F97316),
                          border: Border.all(color: const Color(0x66F97316)),
                        ),
                        child: Text(
                          'Low Stock',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: const Color(0xFFF97316),
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Buy: ${BdtFormatter.format(p.buyingPrice)} | Sell: ${BdtFormatter.format(p.sellingPrice)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Row(
                  children: [
                    _MiniActionBtn(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      onTap: widget.onEdit,
                    ),
                    const SizedBox(width: 8),
                    _MiniActionBtn(
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                      onTap: widget.onDelete,
                      danger: true,
                    ),
                    const SizedBox(width: 8),
                    _MiniActionBtn(
                      icon: Icons.qr_code_2_rounded,
                      label: 'QR / View',
                      onTap: widget.onQrOrView,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MiniActionBtn extends StatelessWidget {
  const _MiniActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? const Color(0xFFF97316) : Colors.white;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: onTap == null ? Colors.white38 : fg),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: onTap == null ? Colors.white38 : fg,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
