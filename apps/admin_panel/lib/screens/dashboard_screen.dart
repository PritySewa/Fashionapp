import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:shared_widgets/shared_widgets.dart';
import '../providers/dashboard_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final revAsync = ref.watch(totalRevenueProvider);
    final activeOrdersAsync = ref.watch(activeOrdersCountProvider);
    final productsAsync = ref.watch(totalProductsCountProvider);
    final recentOrdersAsync = ref.watch(recentOrdersProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Dashboard',
              description: 'Welcome back! Here is what is happening today.',
            ),
            
            // Top Stats Row
            Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Revenue',
                    value: revAsync.when(
                      data: (val) => '\$${val.toStringAsFixed(2)}',
                      loading: () => '...',
                      error: (_, _) => 'Err',
                    ),
                    icon: Icons.attach_money,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Active Orders',
                    value: activeOrdersAsync.when(
                      data: (val) => val.toString(),
                      loading: () => '...',
                      error: (_, _) => 'Err',
                    ),
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _StatCard(
                    title: 'Total Products',
                    value: productsAsync.when(
                      data: (val) => val.toString(),
                      loading: () => '...',
                      error: (_, _) => 'Err',
                    ),
                    icon: Icons.inventory_2,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Main Content Area
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Revenue Overview', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 300,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: 2000,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (double value, TitleMeta meta) {
                                      final style = const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14);
                                      String text;
                                      switch (value.toInt()) {
                                        case 0: text = 'Mon'; break;
                                        case 1: text = 'Tue'; break;
                                        case 2: text = 'Wed'; break;
                                        case 3: text = 'Thu'; break;
                                        case 4: text = 'Fri'; break;
                                        case 5: text = 'Sat'; break;
                                        case 6: text = 'Sun'; break;
                                        default: text = ''; break;
                                      }
                                      return SideTitleWidget(meta: meta, space: 16, child: Text(text, style: style));
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: [
                                BarChartGroupData(x: 0, barRods: [BarChartRodData(toY: 800, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                                BarChartGroupData(x: 1, barRods: [BarChartRodData(toY: 1000, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                                BarChartGroupData(x: 2, barRods: [BarChartRodData(toY: 1400, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                                BarChartGroupData(x: 3, barRods: [BarChartRodData(toY: 1500, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                                BarChartGroupData(x: 4, barRods: [BarChartRodData(toY: 1300, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                                BarChartGroupData(x: 5, barRods: [BarChartRodData(toY: 1000, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                                BarChartGroupData(x: 6, barRods: [BarChartRodData(toY: 900, color: Colors.blue, width: 22, borderRadius: BorderRadius.circular(4))]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 1,
                  child: CardContainer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Recent Orders', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 16),
                        recentOrdersAsync.when(
                          data: (orders) {
                            if (orders.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Text('No orders yet.'),
                              );
                            }
                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orders.length,
                              separatorBuilder: (_, _) => const Divider(),
                              itemBuilder: (context, index) {
                                final order = orders[index];
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text('Order #${order.id.substring(0, 5).toUpperCase()}'),
                                  subtitle: Text(order.createdAt.toString().split(' ')[0]),
                                  trailing: Text('\$${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                );
                              },
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (e, s) => Text('Error: $e'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return CardContainer(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
