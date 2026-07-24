import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../controllers/order_controller.dart';
import '../models/order_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// OrdersView
// ─────────────────────────────────────────────────────────────────────────────

/// Orders list screen mounted at sidebar index 3.
class OrdersView extends GetView<OrderController> {
  const OrdersView({super.key});

  @override
  Widget build(BuildContext context) {
    return _OrdersBody(controller: controller);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body (StatefulWidget for local search + filter state)
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersBody extends StatefulWidget {
  const _OrdersBody({required this.controller});
  final OrderController controller;

  @override
  State<_OrdersBody> createState() => _OrdersBodyState();
}

class _OrdersBodyState extends State<_OrdersBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  OrderStatus? _statusFilter; // null = All

  OrderController get _ctrl => widget.controller;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onQueryChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q != _query) setState(() => _query = q);
  }

  List<OrderModel> _filtered(List<OrderModel> all) {
    var list = all;
    if (_statusFilter != null) {
      list = list.where((o) => o.status == _statusFilter).toList();
    }
    if (_query.isEmpty) return list;
    return list.where((o) {
      return o.id.toLowerCase().contains(_query) ||
          o.customerName.toLowerCase().contains(_query) ||
          o.customerEmail.toLowerCase().contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDesktop = Responsive.isDesktop(context);
    final isMobile = Responsive.isMobile(context);
    final padding = isMobile ? AppDimensions.space4 : AppDimensions.pagePadding;

    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ─────────────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Orders', style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 2),
                    Text(
                      'Manage and track customer orders',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space6),

          // ── Search + Filter ─────────────────────────────────────────────────
          _SearchFilterRow(
            searchCtrl: _searchCtrl,
            statusFilter: _statusFilter,
            onStatusChanged: (v) => setState(() => _statusFilter = v),
            isDesktop: isDesktop,
          ),
          const SizedBox(height: AppDimensions.space4),

          // ── Content ─────────────────────────────────────────────────────────
          Obx(() {
            if (_ctrl.errorMessage.value != null) {
              return AppError(
                message: _ctrl.errorMessage.value!,
                onRetry: _ctrl.refresh,
              );
            }
            final filtered = _filtered(_ctrl.orders);
            if (_ctrl.orders.isEmpty && !_ctrl.isLoading.value) {
              return _EmptyOrders();
            }
            if (_ctrl.orders.isEmpty) {
              return const AppLoading();
            }
            if (filtered.isEmpty) {
              return _NoResults(query: _query);
            }
            if (isDesktop) {
              return _OrdersTable(orders: filtered, controller: _ctrl);
            }
            return _OrdersCardList(orders: filtered, controller: _ctrl);
          }),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search + Filter Row
// ─────────────────────────────────────────────────────────────────────────────

class _SearchFilterRow extends StatelessWidget {
  const _SearchFilterRow({
    required this.searchCtrl,
    required this.statusFilter,
    required this.onStatusChanged,
    required this.isDesktop,
  });

  final TextEditingController searchCtrl;
  final OrderStatus? statusFilter;
  final ValueChanged<OrderStatus?> onStatusChanged;
  final bool isDesktop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final searchBox = SizedBox(
      height: 40,
      child: TextField(
        controller: searchCtrl,
        decoration: InputDecoration(
          hintText: 'Search by order ID, customer name or email…',
          prefixIcon: const Icon(Icons.search, size: 18),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space3,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            borderSide: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
        ),
        style: theme.textTheme.bodyMedium,
      ),
    );

    final chips = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'All',
            selected: statusFilter == null,
            onTap: () => onStatusChanged(null),
          ),
          ...OrderStatus.values.map(
            (s) => _FilterChip(
              label: s.label,
              selected: statusFilter == s,
              color: _orderStatusColor(s),
              onTap: () => onStatusChanged(statusFilter == s ? null : s),
            ),
          ),
        ],
      ),
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 2, child: searchBox),
          const SizedBox(width: AppDimensions.space4),
          Expanded(flex: 3, child: chips),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        searchBox,
        const SizedBox(height: AppDimensions.space3),
        chips,
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(right: AppDimensions.space2),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? c.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
            border: Border.all(
              color: selected ? c : AppColors.borderLight,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: selected ? c : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Table
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersTable extends StatelessWidget {
  const _OrdersTable({required this.orders, required this.controller});

  final List<OrderModel> orders;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final headerStyle = theme.textTheme.labelSmall?.copyWith(
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space4,
              vertical: AppDimensions.space3,
            ),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text('ORDER ID', style: headerStyle)),
                Expanded(flex: 3, child: Text('CUSTOMER', style: headerStyle)),
                Expanded(flex: 2, child: Text('DATE', style: headerStyle)),
                Expanded(flex: 2, child: Text('AMOUNT', style: headerStyle)),
                Expanded(flex: 2, child: Text('STATUS', style: headerStyle)),
                Expanded(flex: 2, child: Text('PAYMENT', style: headerStyle)),
                const SizedBox(width: 40),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // Rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: orders.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            itemBuilder: (context, index) =>
                _OrderTableRow(order: orders[index], controller: controller),
          ),
        ],
      ),
    );
  }
}

class _OrderTableRow extends StatelessWidget {
  const _OrderTableRow({required this.order, required this.controller});

  final OrderModel order;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = DateFormat('dd MMM yyyy');

    return InkWell(
      onTap: () => _showOrderDetail(context, order, controller),
      hoverColor: isDark
          ? Colors.white.withValues(alpha: 0.03)
          : Colors.black.withValues(alpha: 0.02),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space4,
          vertical: AppDimensions.space3,
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                '#${order.id.substring(0, 8).toUpperCase()}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    order.customerEmail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                fmt.format(order.createdAt),
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: _OrderStatusBadge(status: order.status),
            ),
            Expanded(
              flex: 2,
              child: _PaymentStatusBadge(status: order.paymentStatus),
            ),
            SizedBox(
              width: 40,
              child: IconButton(
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                tooltip: 'View details',
                onPressed: () =>
                    _showOrderDetail(context, order, controller),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Card List
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersCardList extends StatelessWidget {
  const _OrdersCardList({required this.orders, required this.controller});

  final List<OrderModel> orders;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.space2),
      itemBuilder: (context, index) =>
          _OrderCard(order: orders[index], controller: controller),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.controller});

  final OrderModel order;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fmt = DateFormat('dd MMM yyyy');

    return GestureDetector(
      onTap: () => _showOrderDetail(context, order, controller),
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                _OrderStatusBadge(status: order.status),
              ],
            ),
            const SizedBox(height: AppDimensions.space2),
            Text(
              order.customerName,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              order.customerEmail,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.space3),
            Row(
              children: [
                Text(
                  'Rs. ${order.totalAmount.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                _PaymentStatusBadge(status: order.paymentStatus),
              ],
            ),
            const SizedBox(height: AppDimensions.space1),
            Text(
              fmt.format(order.createdAt),
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order Detail Dialog / Bottom Sheet
// ─────────────────────────────────────────────────────────────────────────────

void _showOrderDetail(
  BuildContext context,
  OrderModel order,
  OrderController controller,
) {
  if (Responsive.isDesktop(context)) {
    showDialog(
      context: context,
      builder: (_) => _OrderDetailDialog(order: order, controller: controller),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => _OrderDetailSheet(
          order: order,
          controller: controller,
          scrollController: scrollController,
        ),
      ),
    );
  }
}

// ── Desktop Dialog ──────────────────────────────────────────────────────────

class _OrderDetailDialog extends StatelessWidget {
  const _OrderDetailDialog({required this.order, required this.controller});

  final OrderModel order;
  final OrderController controller;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: SizedBox(
        width: 640,
        child: _OrderDetailContent(
          order: order,
          controller: controller,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

// ── Mobile Bottom Sheet ─────────────────────────────────────────────────────

class _OrderDetailSheet extends StatelessWidget {
  const _OrderDetailSheet({
    required this.order,
    required this.controller,
    required this.scrollController,
  });

  final OrderModel order;
  final OrderController controller;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimensions.radiusLg),
        ),
      ),
      child: _OrderDetailContent(
        order: order,
        controller: controller,
        onClose: () => Navigator.of(context).pop(),
        scrollController: scrollController,
      ),
    );
  }
}

// ── Shared Detail Content ───────────────────────────────────────────────────

class _OrderDetailContent extends StatefulWidget {
  const _OrderDetailContent({
    required this.order,
    required this.controller,
    required this.onClose,
    this.scrollController,
  });

  final OrderModel order;
  final OrderController controller;
  final VoidCallback onClose;
  final ScrollController? scrollController;

  @override
  State<_OrderDetailContent> createState() => _OrderDetailContentState();
}

class _OrderDetailContentState extends State<_OrderDetailContent> {
  late OrderStatus _selectedStatus;
  late PaymentStatus _selectedPaymentStatus;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status;
    _selectedPaymentStatus = widget.order.paymentStatus;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    bool success = true;

    if (_selectedStatus != widget.order.status) {
      final result = await widget.controller.updateOrderStatus(
        widget.order.id,
        _selectedStatus,
      );
      if (!result.success) success = false;
    }
    if (_selectedPaymentStatus != widget.order.paymentStatus) {
      final result = await widget.controller.updatePaymentStatus(
        widget.order.id,
        _selectedPaymentStatus,
      );
      if (!result.success) success = false;
    }

    setState(() => _saving = false);

    if (mounted) {
      Get.snackbar(
        success ? 'Success' : 'Error',
        success ? 'Order updated successfully.' : 'Failed to update order.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: success ? AppColors.success : AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
        borderRadius: AppDimensions.radiusSm,
        duration: const Duration(seconds: 2),
      );
      if (success) widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final o = widget.order;
    final fmt = DateFormat('dd MMM yyyy, hh:mm a');
    final secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title bar ────────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.space6,
            AppDimensions.space5,
            AppDimensions.space4,
            0,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Details', style: theme.textTheme.titleLarge),
                    Text(
                      '#${o.id.substring(0, 8).toUpperCase()}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: secColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: widget.onClose,
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),

        // ── Scrollable body ──────────────────────────────────────────────────
        Flexible(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(AppDimensions.space6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Customer info
                _DetailSection(title: 'Customer', children: [
                  _DetailRow(label: 'Name', value: o.customerName),
                  _DetailRow(label: 'Email', value: o.customerEmail),
                ]),
                const SizedBox(height: AppDimensions.space4),

                // Address
                _DetailSection(title: 'Shipping Address', children: [
                  _DetailRow(label: 'Contact', value: o.address.name),
                  _DetailRow(label: 'Phone', value: o.address.phone),
                  _DetailRow(
                    label: 'Address',
                    value: o.address.formatted,
                  ),
                ]),
                const SizedBox(height: AppDimensions.space4),

                // Items
                _DetailSection(
                  title: 'Items (${o.itemCount})',
                  children: o.items
                      .map(
                        (item) => _DetailRow(
                          label: item.name,
                          value:
                              'Rs. ${item.price.toStringAsFixed(0)} × ${item.qty}  =  Rs. ${item.lineTotal.toStringAsFixed(0)}',
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: AppDimensions.space2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total:  Rs. ${o.totalAmount.toStringAsFixed(0)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space4),

                // Timestamps
                _DetailSection(title: 'Timeline', children: [
                  _DetailRow(label: 'Ordered', value: fmt.format(o.createdAt)),
                  _DetailRow(label: 'Updated', value: fmt.format(o.updatedAt)),
                  if (o.paymentMethod.isNotEmpty)
                    _DetailRow(
                      label: 'Payment Method',
                      value: o.paymentMethod,
                    ),
                  if (o.notes != null && o.notes!.isNotEmpty)
                    _DetailRow(label: 'Notes', value: o.notes!),
                ]),
                const SizedBox(height: AppDimensions.space5),

                // Status selectors
                Text('Update Status', style: theme.textTheme.titleSmall),
                const SizedBox(height: AppDimensions.space3),
                Row(
                  children: [
                    Expanded(
                      child: _StatusSelector<OrderStatus>(
                        label: 'Order Status',
                        value: _selectedStatus,
                        items: OrderStatus.values,
                        labelOf: (s) => s.label,
                        colorOf: _orderStatusColor,
                        onChanged: (s) => setState(() => _selectedStatus = s),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space3),
                    Expanded(
                      child: _StatusSelector<PaymentStatus>(
                        label: 'Payment Status',
                        value: _selectedPaymentStatus,
                        items: PaymentStatus.values,
                        labelOf: (s) => s.label,
                        colorOf: _paymentStatusColor,
                        onChanged: (s) =>
                            setState(() => _selectedPaymentStatus = s),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space6),
              ],
            ),
          ),
        ),

        // ── Footer buttons ───────────────────────────────────────────────────
        Divider(
          height: 1,
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        Padding(
          padding: const EdgeInsets.all(AppDimensions.space4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: widget.onClose,
                child: const Text('Close'),
              ),
              const SizedBox(width: AppDimensions.space3),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Save Changes'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Detail helpers
// ─────────────────────────────────────────────────────────────────────────────

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: AppDimensions.space3),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _StatusSelector<T> extends StatelessWidget {
  const _StatusSelector({
    required this.label,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.colorOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T) labelOf;
  final Color Function(T) colorOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppDimensions.space1),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.space3,
              vertical: AppDimensions.space2,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            isDense: true,
          ),
          items: items
              .map(
                (s) => DropdownMenuItem<T>(
                  value: s,
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorOf(s),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(labelOf(s), style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status badges
// ─────────────────────────────────────────────────────────────────────────────

class _OrderStatusBadge extends StatelessWidget {
  const _OrderStatusBadge({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _orderStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  const _PaymentStatusBadge({required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _paymentStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Color helpers
// ─────────────────────────────────────────────────────────────────────────────

Color _orderStatusColor(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return AppColors.warning;
    case OrderStatus.processing:
      return AppColors.info;
    case OrderStatus.shipped:
      return AppColors.accent;
    case OrderStatus.delivered:
      return AppColors.success;
    case OrderStatus.cancelled:
      return AppColors.error;
  }
}

Color _paymentStatusColor(PaymentStatus s) {
  switch (s) {
    case PaymentStatus.unpaid:
      return AppColors.warning;
    case PaymentStatus.paid:
      return AppColors.success;
    case PaymentStatus.refunded:
      return AppColors.info;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / No-results states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyOrders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceVariantLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 28,
                color: secColor,
              ),
            ),
            const SizedBox(height: AppDimensions.space4),
            Text('No orders yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.space1),
            Text(
              'Customer orders will appear here.',
              style: theme.textTheme.bodySmall?.copyWith(color: secColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 40,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppDimensions.space3),
            Text(
              'No orders match "$query"',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
