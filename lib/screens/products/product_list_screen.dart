import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/premium/premium_ui.dart';
import '../../providers/auth_provider.dart';
import '../../providers/products_provider.dart';
import '../../routes/app_router.dart';

/// Browse products; admin can add/edit; everyone can open details / QR.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final _search = TextEditingController();
  String? _selectedCategory;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductsProvider>().products;
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final query = _search.text.trim().toLowerCase();
    final categories = products
        .map((p) => p.category.trim())
        .where((c) => c.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final filtered = products.where((p) {
      final matchQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      final matchCategory = _selectedCategory == null || p.category == _selectedCategory;
      return matchQuery && matchCategory;
    }).toList();
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    return Scaffold(
      appBar: const PremiumAppBar(
        title: 'Products',
        subtitle: 'Inventory',
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.productAdd),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add product'),
            )
          : null,
      body: products.isEmpty
          ? Center(
              child: Padding(
                padding: PremiumTokens.pagePadding(context),
                child: EmptyStateWidget(
                  icon: Icons.inventory_2_rounded,
                  title: 'No products yet',
                  subtitle:
                      'Add your first product to start tracking stock and generating QR labels.',
                  actionLabel: isAdmin ? 'Add product' : null,
                  onAction: isAdmin
                      ? () => Navigator.pushNamed(context, AppRoutes.productAdd)
                      : null,
                ),
              ),
            )
          : ListView(
              padding: PremiumTokens.pagePadding(context),
              children: [
                FeatureHeaderCard(
                  title: 'Product Catalog',
                  subtitle: '${filtered.length} of ${products.length} product(s) in your inventory workspace.',
                  icon: Icons.inventory_2_rounded,
                  trailingIcon: Icons.storefront_rounded,
                ),
                ReportCard(
                  child: Column(
                    children: [
                      TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          hintText: 'Search by product name or category',
                          prefixIcon: Icon(Icons.search_rounded),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      if (categories.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 34,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  selected: _selectedCategory == null,
                                  label: const Text('All'),
                                  onSelected: (_) => setState(() => _selectedCategory = null),
                                ),
                              ),
                              ...categories.map(
                                (c) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: FilterChip(
                                    selected: _selectedCategory == c,
                                    label: Text(c),
                                    onSelected: (_) => setState(() {
                                      _selectedCategory = _selectedCategory == c ? null : c;
                                    }),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (filtered.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.search_off_rounded,
                    title: 'No products match filters',
                    subtitle: 'Try another keyword or clear category filter.',
                  )
                else if (!isWide)
                  ...List.generate(filtered.length, (i) {
                    final p = filtered[i];
                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 220 + (i * 12).clamp(0, 180)),
                      tween: Tween(begin: 0, end: 1),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, (1 - value) * 8),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ProductCard(
                          product: p,
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.productDetails,
                            arguments: p.id,
                          ),
                        ),
                      ),
                    );
                  })
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 2.5,
                    ),
                    itemBuilder: (context, i) {
                      final p = filtered[i];
                      return ProductCard(
                        product: p,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.productDetails,
                          arguments: p.id,
                        ),
                      );
                    },
                  ),
              ],
            ),
    );
  }
}
