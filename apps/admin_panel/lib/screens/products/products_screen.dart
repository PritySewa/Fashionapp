import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:product_catalog/product_catalog.dart';
import 'package:shared_widgets/shared_widgets.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Products',
              description: 'Manage your product catalog and variants.',
              action: ElevatedButton.icon(
                onPressed: () => context.go('/products/new'),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ),
            CardContainer(
              width: double.infinity,
              padding: EdgeInsets.zero,
              child: productsAsync.when(
                data: (products) {
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(
                        child: Text('No products found. Create one!'),
                      ),
                    );
                  }
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Title')),
                      DataColumn(label: Text('Base Price')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: products.map((product) {
                      return DataRow(
                        cells: [
                          DataCell(Text(product.title)),
                          DataCell(Text('\$${product.basePrice.toStringAsFixed(2)}')),
                          DataCell(Chip(label: Text(product.status))),
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, size: 20),
                                onPressed: () {},
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                onPressed: () {},
                              ),
                            ],
                          )),
                        ],
                      );
                    }).toList(),
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(48.0),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, stack) => Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
