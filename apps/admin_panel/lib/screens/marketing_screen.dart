import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketing_system/marketing_system.dart';
import 'package:shared_widgets/shared_widgets.dart';

class MarketingScreen extends ConsumerWidget {
  const MarketingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final couponsAsync = ref.watch(couponsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Marketing & Promotions',
              description: 'Manage discount codes and flash sales.',
              action: ElevatedButton.icon(
                onPressed: () {
                  // show generate coupon dialog
                },
                icon: const Icon(Icons.add),
                label: const Text('New Coupon'),
              ),
            ),
            CardContainer(
              width: double.infinity,
              padding: EdgeInsets.zero,
              child: couponsAsync.when(
                data: (coupons) {
                  if (coupons.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(
                        child: Text('No active coupons.'),
                      ),
                    );
                  }
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Code')),
                      DataColumn(label: Text('Discount')),
                      DataColumn(label: Text('Usage')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Expiry')),
                    ],
                    rows: coupons.map((coupon) {
                      final discountStr = coupon.type == DiscountType.percentage 
                          ? '${coupon.value}%' 
                          : '\$${coupon.value.toStringAsFixed(2)}';
                      final usageStr = coupon.maxUses == null ? '${coupon.timesUsed}/∞' : '${coupon.timesUsed}/${coupon.maxUses}';
                      return DataRow(
                        cells: [
                          DataCell(Text(coupon.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                          DataCell(Text(discountStr)),
                          DataCell(Text(usageStr)),
                          DataCell(Chip(
                            label: Text(coupon.isActive ? 'Active' : 'Inactive'),
                            backgroundColor: coupon.isActive ? Colors.green.shade100 : Colors.red.shade100,
                          )),
                          DataCell(Text(coupon.expiryDate.toString().split(' ')[0])),
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
