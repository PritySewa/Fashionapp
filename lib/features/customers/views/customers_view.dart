import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../controllers/customer_controller.dart';
import '../models/customer_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CustomersView
// ─────────────────────────────────────────────────────────────────────────────

/// Customers list screen mounted at sidebar index 4.
class CustomersView extends GetView<CustomerController> {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    return _CustomersBody(controller: controller);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Body
// ─────────────────────────────────────────────────────────────────────────────

class _CustomersBody extends StatefulWidget {
  const _CustomersBody({required this.controller});
  final CustomerController controller;

  @override
  State<_CustomersBody> createState() => _CustomersBodyState();
}

class _CustomersBodyState extends State<_CustomersBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool? _activeFilter; // null = All

  CustomerController get _ctrl => widget.controller;

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

  List<CustomerModel> _filtered(List<CustomerModel> all) {
    var list = all;
    if (_activeFilter != null) {
      list = list.where((c) => c.isActive == _activeFilter).toList();
    }
    if (_query.isEmpty) return list;
    return list.where((c) {
      return c.name.toLowerCase().contains(_query) ||
          c.email.toLowerCase().contains(_query) ||
          (c.phone?.contains(_query) ?? false);
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
          Text('Customers', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 2),
          Text(
            'View and manage your customer accounts',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: AppDimensions.space6),

          // ── Search + Filter ─────────────────────────────────────────────────
          _SearchFilterRow(
            searchCtrl: _searchCtrl,
            activeFilter: _activeFilter,
            onFilterChanged: (v) => setState(() => _activeFilter = v),
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
            if (_ctrl.customers.isEmpty && !_ctrl.isLoading.value) {
              return _EmptyCustomers();
            }
            if (_ctrl.customers.isEmpty) {
              return const AppLoading();
            }
            final filtered = _filtered(_ctrl.customers);
            if (filtered.isEmpty) {
              return _NoResults(query: _query);
            }
            if (isDesktop) {
              return _CustomersTable(
                customers: filtered,
                controller: _ctrl,
              );
            }
            return _CustomerCardList(
              customers: filtered,
              controller: _ctrl,
            );
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
    required this.activeFilter,
    required this.onFilterChanged,
    required this.isDesktop,
  });

  final TextEditingController searchCtrl;
  final bool? activeFilter;
  final ValueChanged<bool?> onFilterChanged;
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
          hintText: 'Search by name, email or phone…',
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

    Widget chip(String label, bool? value) {
      final selected = activeFilter == value;
      final color = value == true
          ? AppColors.success
          : (value == false ? AppColors.error : AppColors.primary);
      return Padding(
        padding: const EdgeInsets.only(right: AppDimensions.space2),
        child: GestureDetector(
          onTap: () => onFilterChanged(selected ? null : value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              border: Border.all(
                color: selected ? color : AppColors.borderLight,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : AppColors.textSecondaryLight,
              ),
            ),
          ),
        ),
      );
    }

    final chips = Row(
      children: [
        chip('All', null),
        chip('Active', true),
        chip('Inactive', false),
      ],
    );

    if (isDesktop) {
      return Row(
        children: [
          Expanded(flex: 2, child: searchBox),
          const SizedBox(width: AppDimensions.space4),
          chips,
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

// ─────────────────────────────────────────────────────────────────────────────
// Desktop Table
// ─────────────────────────────────────────────────────────────────────────────

class _CustomersTable extends StatelessWidget {
  const _CustomersTable({required this.customers, required this.controller});

  final List<CustomerModel> customers;
  final CustomerController controller;

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
                const SizedBox(width: 44),
                Expanded(flex: 3, child: Text('CUSTOMER', style: headerStyle)),
                Expanded(flex: 2, child: Text('JOINED', style: headerStyle)),
                Expanded(flex: 1, child: Text('ORDERS', style: headerStyle)),
                Expanded(flex: 2, child: Text('SPENT', style: headerStyle)),
                Expanded(flex: 1, child: Text('STATUS', style: headerStyle)),
                const SizedBox(width: 60),
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
            itemCount: customers.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            itemBuilder: (context, index) => _CustomerTableRow(
              customer: customers[index],
              controller: controller,
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomerTableRow extends StatelessWidget {
  const _CustomerTableRow({
    required this.customer,
    required this.controller,
  });

  final CustomerModel customer;
  final CustomerController controller;

  Future<void> _onToggle(BuildContext context) async {
    final result = await controller.toggleActive(customer);
    if (!result.success) {
      Get.snackbar(
        'Error',
        result.error ?? 'Failed to update status.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
        borderRadius: AppDimensions.radiusSm,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = customer;
    final fmt = DateFormat('dd MMM yyyy');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space4,
        vertical: AppDimensions.space3,
      ),
      child: Row(
        children: [
          // Avatar
          _CustomerAvatar(customer: c, size: 32),
          const SizedBox(width: 12),
          // Name + Email
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  c.email,
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
              fmt.format(c.createdAt),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${c.totalOrders}',
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'Rs. ${c.totalSpent.toStringAsFixed(0)}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(flex: 1, child: StatusBadge(isActive: c.isActive)),
          SizedBox(
            width: 60,
            child: Switch(
              value: c.isActive,
              onChanged: (_) => _onToggle(context),
              activeThumbColor: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mobile Card List
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerCardList extends StatelessWidget {
  const _CustomerCardList({required this.customers, required this.controller});

  final List<CustomerModel> customers;
  final CustomerController controller;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (context, index) =>
          const SizedBox(height: AppDimensions.space2),
      itemBuilder: (context, index) => _CustomerCard(
        customer: customers[index],
        controller: controller,
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.controller});

  final CustomerModel customer;
  final CustomerController controller;

  Future<void> _onToggle(BuildContext context) async {
    final result = await controller.toggleActive(customer);
    if (!result.success) {
      Get.snackbar(
        'Error',
        result.error ?? 'Failed to update status.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
        borderRadius: AppDimensions.radiusSm,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final c = customer;
    final fmt = DateFormat('dd MMM yyyy');

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _CustomerAvatar(customer: c, size: 44),
          const SizedBox(width: AppDimensions.space3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  c.email,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: AppDimensions.space1),
                Row(
                  children: [
                    Text(
                      '${c.totalOrders} orders',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space2),
                    Text(
                      '·',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space2),
                    Text(
                      'Rs. ${c.totalSpent.toStringAsFixed(0)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Joined ${fmt.format(c.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              StatusBadge(isActive: c.isActive),
              const SizedBox(height: AppDimensions.space2),
              Switch(
                value: c.isActive,
                onChanged: (_) => _onToggle(context),
                activeThumbColor: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Customer Avatar
// ─────────────────────────────────────────────────────────────────────────────

class _CustomerAvatar extends StatelessWidget {
  const _CustomerAvatar({required this.customer, required this.size});

  final CustomerModel customer;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (customer.avatarUrl != null && customer.avatarUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(customer.avatarUrl!),
      );
    }
    // Initials fallback
    final seed = customer.name.codeUnits.fold(0, (a, b) => a + b);
    final colors = [
      AppColors.primary,
      AppColors.warning,
      AppColors.accent,
      AppColors.success,
      AppColors.info,
    ];
    final bg = colors[seed % colors.length];

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: bg.withValues(alpha: 0.15),
      child: Text(
        customer.initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: bg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / No-result states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCustomers extends StatelessWidget {
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
                Icons.people_outline_rounded,
                size: 28,
                color: secColor,
              ),
            ),
            const SizedBox(height: AppDimensions.space4),
            Text('No customers yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppDimensions.space1),
            Text(
              'Registered customers will appear here.',
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
              'No customers match "$_query"',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  String get _query => query;
}
