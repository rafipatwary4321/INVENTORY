import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/empty_state.dart';
import '../../core/utils/bdt_formatter.dart';
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
  String _selectedCategory = 'All';

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
    final categories = <String>{
      'All',
      ...products
          .map((e) => e.category.trim())
          .where((c) => c.isNotEmpty),
    }.toList()
      ..sort((a, b) {
        if (a == 'All') return -1;
        if (b == 'All') return 1;
        return a.toLowerCase().compareTo(b.toLowerCase());
      });

    final filtered = products.where((p) {
      final byCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      final byQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query);
      return byCategory && byQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.productAdd),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search by name or category',
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (categories.length > 1)
            SizedBox(
              height: 54,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final category = categories[i];
                  final selected = category == _selectedCategory;
                  return ChoiceChip(
                    label: Text(category),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: categories.length,
              ),
            ),
          Expanded(
            child: products.isEmpty
                ? const EmptyState(
                    title: 'No products yet',
                    subtitle: 'Add your first product to start tracking stock.',
                  )
                : filtered.isEmpty
                    ? const EmptyState(
                        title: 'No matching products',
                        subtitle: 'Try a different search or category filter.',
                        icon: Icons.filter_alt_off_outlined,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = filtered[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                                ),
                              ),
                              title: Text(p.name),
                              subtitle: Text(
                                '${p.category} · Qty ${p.quantity} ${p.unit}\n'
                                'Buy ${BdtFormatter.format(p.buyingPrice)} · '
                                'Sell ${BdtFormatter.format(p.sellingPrice)}',
                              ),
                              isThreeLine: true,
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRoutes.productDetails,
                                arguments: p.id,
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
