import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:order_system/order_system.dart';
import 'package:shared_widgets/shared_widgets.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersProvider);
    final orderRepo = ref.watch(orderRepositoryProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Orders',
              description: 'Manage customer orders and fulfillments.',
            ),
            CardContainer(
              width: double.infinity,
              padding: EdgeInsets.zero,
              child: ordersAsync.when(
                data: (orders) {
                  if (orders.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(48.0),
                      child: Center(
                        child: Text('No orders yet.'),
                      ),
                    );
                  }
                  return DataTable(
                    columns: const [
                      DataColumn(label: Text('Order ID')),
                      DataColumn(label: Text('Date')),
                      DataColumn(label: Text('Total')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: orders.map((order) {
                      return DataRow(
                        cells: [
                          DataCell(Text(order.id.substring(0, 8).toUpperCase())),
                          DataCell(Text(order.createdAt.toString().split(' ')[0])),
                          DataCell(Text('\$${order.totalAmount.toStringAsFixed(2)}')),
                          DataCell(
                            DropdownButton<OrderStatus>(
                              value: order.status,
                              items: OrderStatus.values.map((s) {
                                return DropdownMenuItem(
                                  value: s,
                                  child: Text(s.name.toUpperCase()),
                                );
                              }).toList(),
                              onChanged: (newStatus) {
                                if (newStatus != null) {
                                  orderRepo.updateOrderStatus(order.id, newStatus);
                                }
                              },
                            )
                          ),
                          DataCell(
                            IconButton(
                              icon: const Icon(Icons.visibility, color: Colors.blue),
                              onPressed: () {
                                // show order details dialog
                              },
                            ),
                          ),
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
