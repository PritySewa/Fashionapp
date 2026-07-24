import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/app_error.dart';
import '../../../core/widgets/app_loading.dart';
import '../../../core/widgets/status_badge.dart';
import '../../categories/controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';
import '../widgets/product_form_dialog.dart';

// ── ProductsView ──────────────────────────────────────────────────────────────

/// Products list and management screen.
class ProductsView extends GetView<ProductController> {
  const ProductsView({super.key});

  @override
  Widget build(BuildContext context) {
    return _ProductsBody(controller: controller);
  }
}

// ── Body (StatefulWidget for local search state) ───────────────────────────────

class _ProductsBody extends StatefulWidget {
  const _ProductsBody({required this.controller});
  final ProductController controller;

  @override
  State<_ProductsBody> createState() => _ProductsBodyState();
}

class _ProductsBodyState extends State<_ProductsBody> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  ProductController get _ctrl => widget.controller;

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

  List<ProductModel> _filteredList(List<ProductModel> all) {
    if (_query.isEmpty) return all;
    return all.where((p) {
      final nameMatch = p.name.toLowerCase().contains(_query);
      final skuMatch = p.sku.toLowerCase().contains(_query);
      final slugMatch = p.slug.toLowerCase().contains(_query);
      return nameMatch || skuMatch || slugMatch;
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
          // ── Page Header ────────────────────────────────────────────────────
          _PageHeader(isDark: isDark, theme: theme),
          const SizedBox(height: AppDimensions.space6),

          // ── Reactive content ───────────────────────────────────────────────
          Obx(() {
            final allProducts = _ctrl.products.toList();
            final error = _ctrl.errorMessage.value;
            final loading = _ctrl.isLoading.value;

            // Loading + no data yet
            if (loading && allProducts.isEmpty) {
              return const SizedBox(
                height: 320,
                child: AppLoading(message: 'Loading products…'),
              );
            }

            // Stream error + no data in memory
            if (error != null && allProducts.isEmpty) {
              return SizedBox(
                height: 320,
                child: AppError(message: error, onRetry: _ctrl.refresh),
              );
            }

            final filtered = _filteredList(allProducts);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Toolbar(
                  searchCtrl: _searchCtrl,
                  totalCount: allProducts.length,
                  isDark: isDark,
                  theme: theme,
                  onRefresh: _ctrl.refresh,
                ),
                const SizedBox(height: AppDimensions.space5),

                // Empty: no products at all
                if (allProducts.isEmpty)
                  _EmptyState(theme: theme, isDark: isDark)
                // Empty: search returned nothing
                else if (filtered.isEmpty)
                  _EmptySearch(query: _searchCtrl.text.trim())
                // Data table (desktop) or card list (mobile/tablet)
                else if (isDesktop)
                  _ProductsTable(
                    products: filtered,
                    isDark: isDark,
                    theme: theme,
                  )
                else
                  _ProductCardList(
                    products: filtered,
                    isDark: isDark,
                    theme: theme,
                  ),
              ],
            );
          }),

          const SizedBox(height: AppDimensions.space8),
        ],
      ),
    );
  }
}

// ── Page Header ────────────────────────────────────────────────────────────────

class _PageHeader extends StatelessWidget {
  const _PageHeader({required this.isDark, required this.theme});
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final isMobile = Responsive.isMobile(context);

    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Products', style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppDimensions.space1),
        Text(
          'Manage store items, pricing, inventory and badges.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: secondaryColor,
          ),
        ),
      ],
    );

    final addButton = FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        ),
      ),
      onPressed: () => ProductFormDialog.show(context, product: null),
      icon: const Icon(Icons.add_rounded, size: AppDimensions.iconMd),
      label: const Text('Add Product'),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleColumn,
          const SizedBox(height: AppDimensions.space4),
          SizedBox(width: double.infinity, child: addButton),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: titleColumn),
        const SizedBox(width: AppDimensions.space4),
        addButton,
      ],
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchCtrl,
    required this.totalCount,
    required this.isDark,
    required this.theme,
    required this.onRefresh,
  });

  final TextEditingController searchCtrl;
  final int totalCount;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Search field
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TextFormField(
              controller: searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search by name, SKU or slug…',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: AppDimensions.iconMd,
                ),
                suffixIcon: searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: searchCtrl.clear,
                        tooltip: 'Clear search',
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space4,
                  vertical: AppDimensions.space3,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.space3),
        // Refresh button
        Tooltip(
          message: 'Refresh products',
          child: IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: onRefresh,
          ),
        ),
        const SizedBox(width: AppDimensions.space3),
        // Count chip
        _CountChip(count: totalCount, isDark: isDark, theme: theme),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.count,
    required this.isDark,
    required this.theme,
  });
  final int count;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space3,
        vertical: AppDimensions.space1,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        '$count ${count == 1 ? 'product' : 'products'}',
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Featured Badge ─────────────────────────────────────────────────────────────

class FeaturedBadge extends StatelessWidget {
  const FeaturedBadge({super.key, required this.isFeatured});
  final bool isFeatured;

  @override
  Widget build(BuildContext context) {
    if (!isFeatured) {
      return const Text('—');
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space2,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 10, color: AppColors.warning),
          SizedBox(width: 2),
          Text(
            'Featured',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.warning,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Buttons ─────────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({required this.product, required this.isDark});
  final ProductModel product;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductController>();
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Toggle Active
        Tooltip(
          message: product.isActive ? 'Deactivate' : 'Activate',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              product.isActive
                  ? Icons.toggle_on_rounded
                  : Icons.toggle_off_rounded,
              color: product.isActive ? AppColors.success : secondaryColor,
              size: 26,
            ),
            onPressed: () async {
              final result = await ctrl.toggleProductActive(product);
              if (!result.success) {
                Get.snackbar(
                  'Error',
                  result.error ?? 'Could not update status.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(AppDimensions.space4),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // Toggle Featured
        Tooltip(
          message: product.isFeatured ? 'Unfeature' : 'Feature',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              product.isFeatured
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              color: product.isFeatured ? AppColors.warning : secondaryColor,
              size: 20,
            ),
            onPressed: () async {
              final result = await ctrl.toggleProductFeatured(product);
              if (!result.success) {
                Get.snackbar(
                  'Error',
                  result.error ?? 'Could not update featured status.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.error,
                  colorText: Colors.white,
                  margin: const EdgeInsets.all(AppDimensions.space4),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 8),

        // Edit
        Tooltip(
          message: 'Edit',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(Icons.edit_outlined, size: 20, color: secondaryColor),
            onPressed: () => ProductFormDialog.show(context, product: product),
          ),
        ),
        const SizedBox(width: 8),

        // Delete
        Tooltip(
          message: 'Delete',
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.error,
            ),
            onPressed: () => ProductDeleteDialog.show(context, product),
          ),
        ),
      ],
    );
  }
}

// ── Desktop Table ──────────────────────────────────────────────────────────────

class _ProductsTable extends StatelessWidget {
  const _ProductsTable({
    required this.products,
    required this.isDark,
    required this.theme,
  });
  final List<ProductModel> products;
  final bool isDark;
  final ThemeData theme;

  String _getCategoryName(String categoryId) {
    if (!Get.isRegistered<CategoryController>()) return '—';
    final cat = Get.find<CategoryController>().categories.firstWhereOrNull(
      (c) => c.id == categoryId,
    );
    return cat?.name ?? '—';
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final headerColor = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > 1100
            ? constraints.maxWidth
            : 1100.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                border: Border.all(color: borderColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Header Row ──────────────────────────────────────────────────
                  Container(
                    color: headerColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppDimensions.space4,
                      vertical: AppDimensions.space3,
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            'Image',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: AppDimensions.space3),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'Product',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 100,
                          child: Text(
                            'SKU',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Category',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Price',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Stock',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Status',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Featured',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 95,
                          child: Text(
                            'Updated',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(
                          width: 150,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Actions',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  ...products.map((product) {
                    final categoryName = _getCategoryName(product.categoryId);

                    return Container(
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: borderColor)),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space4,
                        vertical: AppDimensions.space3,
                      ),
                      child: Row(
                        children: [
                          // Image Preview / Placeholder
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceVariantDark
                                  : AppColors.surfaceVariantLight,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusSm,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight,
                                width: 0.5,
                              ),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: product.displayImageUrl != null
                                ? Image.network(
                                    product.displayImageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                          debugPrint('[PRODUCT_READ] Step 3 Image load ERROR  id=${product.id}  url=${product.displayImageUrl}  error=$error');
                                          return Icon(
                                            Icons.shopping_bag_outlined,
                                            color: secondaryColor,
                                            size: 22,
                                          );
                                        },
                                  )
                                : Icon(
                                    Icons.shopping_bag_outlined,
                                    color: secondaryColor,
                                    size: 22,
                                  ),
                          ),
                          const SizedBox(width: AppDimensions.space3),

                          // Name & Slug
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  product.slug,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: secondaryColor,
                                    fontFamily: 'monospace',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // SKU
                          SizedBox(
                            width: 100,
                            child: Text(
                              product.sku,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: secondaryColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Category
                          Expanded(
                            flex: 2,
                            child: Text(
                              categoryName,
                              style: theme.textTheme.bodyMedium,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          // Price
                          SizedBox(
                            width: 90,
                            child: Text(
                              'Rs. ${product.price.toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),

                          // Stock
                          SizedBox(
                            width: 80,
                            child: Text(
                              product.stock.toString(),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: product.stock == 0
                                    ? AppColors.error
                                    : null,
                              ),
                            ),
                          ),

                          // Status
                          SizedBox(
                            width: 80,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: StatusBadge(isActive: product.isActive),
                            ),
                          ),

                          // Featured
                          SizedBox(
                            width: 90,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: FeaturedBadge(
                                isFeatured: product.isFeatured,
                              ),
                            ),
                          ),

                          // Updated
                          SizedBox(
                            width: 95,
                            child: Text(
                              _formatDate(product.updatedAt),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: secondaryColor,
                              ),
                            ),
                          ),

                          // Actions
                          SizedBox(
                            width: 150,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: _ActionButtons(
                                product: product,
                                isDark: isDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ── Mobile / Tablet Card List ──────────────────────────────────────────────────

class _ProductCardList extends StatelessWidget {
  const _ProductCardList({
    required this.products,
    required this.isDark,
    required this.theme,
  });
  final List<ProductModel> products;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      separatorBuilder: (_, i) => const SizedBox(height: AppDimensions.space3),
      itemBuilder: (context, i) =>
          _ProductCard(product: products[i], isDark: isDark, theme: theme),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.isDark,
    required this.theme,
  });
  final ProductModel product;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceColor = isDark
        ? AppColors.surfaceDark
        : AppColors.surfaceLight;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    String categoryName = '—';
    if (Get.isRegistered<CategoryController>()) {
      final cat = Get.find<CategoryController>().categories.firstWhereOrNull(
        (c) => c.id == product.categoryId,
      );
      categoryName = cat?.name ?? '—';
    }

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(AppDimensions.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Preview / placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceVariantDark
                      : AppColors.surfaceVariantLight,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                  border: Border.all(
                    color: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    width: 0.5,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: product.displayImageUrl != null
                    ? Image.network(
                        product.displayImageUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('[PRODUCT_READ] Step 3 Card image load ERROR  id=${product.id}  error=$error');
                          return Icon(
                            Icons.shopping_bag_outlined,
                            color: secondaryColor,
                            size: 24,
                          );
                        },
                      )
                    : Icon(
                        Icons.shopping_bag_outlined,
                        color: secondaryColor,
                        size: 24,
                      ),
              ),
              const SizedBox(width: AppDimensions.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      product.sku,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Category: $categoryName',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rs. ${product.price.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              Text(
                'Stock: ${product.stock}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: product.stock == 0 ? AppColors.error : secondaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space3),
          Row(
            children: [
              StatusBadge(isActive: product.isActive),
              const SizedBox(width: AppDimensions.space2),
              FeaturedBadge(isFeatured: product.isFeatured),
            ],
          ),
          Divider(height: AppDimensions.space4, color: borderColor),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [_ActionButtons(product: product, isDark: isDark)],
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme, required this.isDark});
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppDimensions.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.space4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              'No products yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.space1),
            Text(
              'Add items to display them in the catalog.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppDimensions.space6),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                ),
              ),
              onPressed: () => ProductFormDialog.show(context, product: null),
              icon: const Icon(Icons.add_rounded, size: AppDimensions.iconMd),
              label: const Text('Add Product'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty Search ───────────────────────────────────────────────────────────────

class _EmptySearch extends StatelessWidget {
  const _EmptySearch({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              'No search results',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppDimensions.space1),
            Text(
              'No products matched "$query".',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Delete Confirmation Dialog ─────────────────────────────────────────────────

class ProductDeleteDialog extends StatelessWidget {
  const ProductDeleteDialog({super.key, required this.product});
  final ProductModel product;

  static void show(BuildContext context, ProductModel product) {
    showDialog(
      context: context,
      builder: (context) => ProductDeleteDialog(product: product),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<ProductController>();
    return AlertDialog(
      title: const Text('Delete Product'),
      content: Text('Are you sure you want to delete "${product.name}"?'),
      actions: [
        TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: () async {
            Get.back(); // close dialog
            final result = await ctrl.deleteProduct(product.id);
            if (!result.success) {
              Get.snackbar(
                'Error',
                result.error ?? 'Could not delete product.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.error,
                colorText: Colors.white,
                margin: const EdgeInsets.all(AppDimensions.space4),
              );
            } else {
              Get.snackbar(
                'Success',
                'Product deleted successfully.',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.success,
                colorText: Colors.white,
                margin: const EdgeInsets.all(AppDimensions.space4),
              );
            }
          },
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

// ── Product Placeholder Dialog ─────────────────────────────────────────────────

class ProductPlaceholderDialog extends StatelessWidget {
  const ProductPlaceholderDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ProductPlaceholderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Product Editor'),
      content: const Text('Product editor will be implemented in Phase 3.4C.'),
      actions: [
        FilledButton(onPressed: () => Get.back(), child: const Text('OK')),
      ],
    );
  }
}

// ── Date Formatter Helper ──────────────────────────────────────────────────────

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year;
  return '$d/$m/$y';
}
