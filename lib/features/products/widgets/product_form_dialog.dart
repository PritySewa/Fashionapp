import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/widgets/admin_form_widgets.dart';
import '../../badges/controllers/badge_controller.dart';
import '../../categories/controllers/category_controller.dart';
import '../controllers/product_controller.dart';
import '../models/product_model.dart';

/// Dialog for adding or editing a product.
///
/// Pass [product] = null for "Add Mode"
/// Pass a non-null [ProductModel] for "Edit Mode"
class ProductFormDialog extends StatefulWidget {
  const ProductFormDialog({super.key, this.product});

  final ProductModel? product;

  static Future<void> show(BuildContext context, {ProductModel? product}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ProductFormDialog(product: product),
    );
  }

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _comparePriceCtrl;
  late final TextEditingController _costPriceCtrl;
  late final TextEditingController _skuCtrl;
  late final TextEditingController _stockCtrl;

  String? _selectedCategoryId;
  final List<String> _selectedBadgeIds = [];

  bool _isActive = true;
  bool _isFeatured = false;
  bool _isSubmitting = false;
  String? _localError;

  String _slugPreview = '';
  PickedThumbnail? _thumbnail;
  bool _hadThumbnailOnOpen = false;
  List<PickedProductImage> _images = [];

  bool get _isEditMode => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(
      text: p != null ? p.price.toString() : '',
    );
    _comparePriceCtrl = TextEditingController(
      text: p?.comparePrice != null ? p!.comparePrice.toString() : '',
    );
    _costPriceCtrl = TextEditingController(
      text: p?.costPrice != null ? p!.costPrice.toString() : '',
    );
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _stockCtrl = TextEditingController(
      text: p != null ? p.stock.toString() : '',
    );

    _selectedCategoryId = p?.categoryId;
    if (p != null) {
      _selectedBadgeIds.addAll(p.badgeIds);
      if (p.thumbnailImage != null) {
        _thumbnail = PickedThumbnail.fromUrl(p.thumbnailImage!);
        _hadThumbnailOnOpen = true;
      }
      _images = p.images.map((url) => PickedProductImage.fromUrl(url)).toList();
    }

    _isActive = p?.isActive ?? true;
    _isFeatured = p?.isFeatured ?? false;

    _slugPreview = SlugUtils.toSlug(_nameCtrl.text);
    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _comparePriceCtrl.dispose();
    _costPriceCtrl.dispose();
    _skuCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final preview = SlugUtils.toSlug(_nameCtrl.text);
    if (preview != _slugPreview) {
      setState(() => _slugPreview = preview);
    }
  }

  Future<void> _pickImages() async {
    if (_images.length >= 10) return;

    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: true,
        withData: true,
      );
    } catch (e) {
      debugPrint('[ProductFormDialog] FilePicker error: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final picked = <PickedProductImage>[];
    for (final file in result.files) {
      if (_images.length + picked.length >= 10) {
        Get.snackbar(
          'Limit Reached',
          'Maximum of 10 images are allowed.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.error,
          colorText: Colors.white,
          margin: const EdgeInsets.all(AppDimensions.space4),
        );
        break;
      }

      // Resolve bytes — file_picker populates bytes on web; on desktop
      // we fall back to reading from disk when bytes are missing.
      Uint8List? bytes = file.bytes;
      if (bytes == null && !kIsWeb) {
        try {
          final path = file.path;
          if (path != null) bytes = io.File(path).readAsBytesSync();
        } catch (_) {}
      }
      if (bytes == null || bytes.isEmpty) continue;

      picked.add(
        PickedProductImage.fromFile(bytes: bytes, name: file.name),
      );
    }

    if (picked.isNotEmpty) {
      setState(() => _images.addAll(picked));
    }
  }

  Future<void> _pickThumbnail() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
    } catch (e) {
      debugPrint('[ProductFormDialog] Thumbnail picker error: $e');
      return;
    }

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null && !kIsWeb) {
      try {
        final path = file.path;
        if (path != null) bytes = io.File(path).readAsBytesSync();
      } catch (_) {}
    }
    if (bytes == null || bytes.isEmpty) return;

    setState(() {
      _thumbnail = PickedThumbnail.fromFile(bytes: bytes!, name: file.name);
    });
  }

  Future<void> _submit() async {
    final sw = Stopwatch()..start();
    debugPrint('════════════════════════════════════════════');
    debugPrint('[UI] _submit() ENTER  t=0ms  isEdit=$_isEditMode');
    debugPrint('════════════════════════════════════════════');

    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) {
      debugPrint('[UI] Form validation FAILED  t=${sw.elapsedMilliseconds}ms');
      return;
    }
    debugPrint('[UI] Form validation passed  t=${sw.elapsedMilliseconds}ms');

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim()) ?? 0.0;
    final comparePrice = double.tryParse(_comparePriceCtrl.text.trim());
    final costPrice = double.tryParse(_costPriceCtrl.text.trim());
    final sku = _skuCtrl.text.trim();
    final stock = int.tryParse(_stockCtrl.text.trim()) ?? 0;

    setState(() => _isSubmitting = true);
    debugPrint('[UI] _isSubmitting=true  t=${sw.elapsedMilliseconds}ms');

    try {
      final controller = Get.find<ProductController>();
      debugPrint('[UI] Got controller  t=${sw.elapsedMilliseconds}ms');

      final ({bool success, String? error}) result;

      if (_isEditMode) {
        final deleteThumbnail = _hadThumbnailOnOpen && _thumbnail == null;
        // BUG-03 FIX: Derive clear flags from empty field text so that the
        // repository can issue FieldValue.delete() and actually wipe the field
        // in Firestore — without this, clearing a price on Edit was a no-op.
        final clearComparePrice = _comparePriceCtrl.text.trim().isEmpty;
        final clearCostPrice = _costPriceCtrl.text.trim().isEmpty;
        debugPrint('[UI] await controller.updateProduct START  t=${sw.elapsedMilliseconds}ms');
        result = await controller.updateProduct(
          id: widget.product!.id,
          name: name,
          description: description,
          categoryId: _selectedCategoryId,
          badgeIds: _selectedBadgeIds,
          sku: sku,
          price: price,
          comparePrice: comparePrice,
          clearComparePrice: clearComparePrice,
          costPrice: costPrice,
          clearCostPrice: clearCostPrice,
          stock: stock,
          isActive: _isActive,
          isFeatured: _isFeatured,
          thumbnail: _thumbnail,
          deleteThumbnail: deleteThumbnail,
          images: _images,
        );
        debugPrint('[UI] await controller.updateProduct DONE  t=${sw.elapsedMilliseconds}ms');
      } else {
        debugPrint('[UI] await controller.createProduct START  t=${sw.elapsedMilliseconds}ms');
        result = await controller.createProduct(
          name: name,
          description: description,
          categoryId: _selectedCategoryId!,
          badgeIds: _selectedBadgeIds,
          sku: sku,
          price: price,
          comparePrice: comparePrice,
          costPrice: costPrice,
          stock: stock,
          isActive: _isActive,
          isFeatured: _isFeatured,
          thumbnail: _thumbnail,
          images: _images,
        );
        debugPrint('[UI] await controller.createProduct DONE  t=${sw.elapsedMilliseconds}ms');
      }

      debugPrint('[UI] result.success=${result.success}  t=${sw.elapsedMilliseconds}ms');

      if (!mounted) {
        debugPrint('[UI] NOT MOUNTED — returning  t=${sw.elapsedMilliseconds}ms');
        return;
      }

      if (result.success) {
        debugPrint('[UI] Popping dialog  t=${sw.elapsedMilliseconds}ms');
        Navigator.of(context).pop();
        Get.snackbar(
          _isEditMode ? 'Product Updated' : 'Product Created',
          _isEditMode
              ? '"$name" has been updated successfully.'
              : '"$name" has been created successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: Colors.white,
          duration: const Duration(seconds: 3),
          margin: const EdgeInsets.all(AppDimensions.space4),
        );
      } else {
        debugPrint('[UI] Showing error: ${result.error}  t=${sw.elapsedMilliseconds}ms');
        setState(() => _localError = result.error);
      }
    } catch (e, st) {
      debugPrint('[UI] UNHANDLED EXCEPTION  t=${sw.elapsedMilliseconds}ms: $e');
      debugPrint('[UI] Stack:\n$st');
      if (mounted) {
        setState(() => _localError = 'An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
      debugPrint('════════════════════════════════════════════');
      debugPrint('[UI] _submit() EXIT  t=${sw.elapsedMilliseconds}ms');
      debugPrint('════════════════════════════════════════════');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final isDesktop = Responsive.isDesktop(context);

    return AlertDialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      title: Text(
        _isEditMode ? 'Edit Product' : 'Add Product',
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ────────────────────────────────────────────────────
                AdminFieldLabel('Product Name *'),
                const SizedBox(height: AppDimensions.space2),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Wireless Bluetooth Headphones',
                    counterText: '',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Product name is required.';
                    if (val.length < 2) {
                      return 'Product name must be at least 2 characters.';
                    }
                    if (SlugUtils.toSlug(val).isEmpty) {
                      return 'Product name must contain at least one letter or number.';
                    }
                    return null;
                  },
                ),

                // ── Slug Preview ─────────────────────────────────────────────
                const SizedBox(height: AppDimensions.space3),
                Row(
                  children: [
                    AdminFieldLabel('Slug'),
                    const SizedBox(width: AppDimensions.space2),
                    Text(
                      '(auto-generated)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: secondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space3,
                    vertical: AppDimensions.space3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    _slugPreview.isEmpty ? '—' : _slugPreview,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _slugPreview.isEmpty ? secondaryColor : null,
                      fontFamily: 'monospace',
                      letterSpacing: 0.3,
                    ),
                  ),
                ),

                // ── Description ──────────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                AdminFieldLabel('Description *'),
                const SizedBox(height: AppDimensions.space2),
                TextFormField(
                  controller: _descCtrl,
                  minLines: 2,
                  maxLines: 4,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'Provide a detailed description of the product',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Description is required.';
                    return null;
                  },
                ),

                // ── Category ─────────────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                AdminFieldLabel('Category *'),
                const SizedBox(height: AppDimensions.space2),
                Obx(() {
                  final catCtrl = Get.find<CategoryController>();
                  final activeCategories = catCtrl.categories.where((c) {
                    return c.isActive ||
                        (_isEditMode && c.id == widget.product!.categoryId);
                  }).toList();

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    hint: const Text('Select category'),
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: AppDimensions.space3,
                        vertical: AppDimensions.space2,
                      ),
                    ),
                    items: activeCategories.map((c) {
                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategoryId = val),
                    validator: (v) =>
                        v == null ? 'Category is required.' : null,
                  );
                }),

                // ── Badges ───────────────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                AdminFieldLabel('Badges'),
                const SizedBox(height: AppDimensions.space2),
                Obx(() {
                  final badgeCtrl = Get.find<BadgeController>();
                  final activeBadges = badgeCtrl.badges.where((b) {
                    return b.isActive ||
                        (_isEditMode &&
                            widget.product!.badgeIds.contains(b.id));
                  }).toList();

                  if (activeBadges.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppDimensions.space1,
                      ),
                      child: Text(
                        'No badges available.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: secondaryColor,
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: AppDimensions.space2,
                    runSpacing: AppDimensions.space2,
                    children: activeBadges.map((badge) {
                      final isSelected = _selectedBadgeIds.contains(badge.id);
                      return FilterChip(
                        label: Text(badge.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedBadgeIds.add(badge.id);
                            } else {
                              _selectedBadgeIds.remove(badge.id);
                            }
                          });
                        },
                      );
                    }).toList(),
                  );
                }),

                // ── Pricing Section ──────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                const Divider(),
                const SizedBox(height: AppDimensions.space3),
                Text('Pricing', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppDimensions.space3),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildPriceField()),
                      const SizedBox(width: AppDimensions.space3),
                      Expanded(child: _buildComparePriceField()),
                      const SizedBox(width: AppDimensions.space3),
                      Expanded(child: _buildCostPriceField()),
                    ],
                  )
                else ...[
                  _buildPriceField(),
                  const SizedBox(height: AppDimensions.space3),
                  _buildComparePriceField(),
                  const SizedBox(height: AppDimensions.space3),
                  _buildCostPriceField(),
                ],

                // ── Inventory Section ────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                const Divider(),
                const SizedBox(height: AppDimensions.space3),
                Text('Inventory', style: theme.textTheme.titleMedium),
                const SizedBox(height: AppDimensions.space3),
                if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSkuField()),
                      const SizedBox(width: AppDimensions.space3),
                      Expanded(child: _buildStockField()),
                    ],
                  )
                else ...[
                  _buildSkuField(),
                  const SizedBox(height: AppDimensions.space3),
                  _buildStockField(),
                ],
                // ── Thumbnail Section ──────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                const Divider(),
                const SizedBox(height: AppDimensions.space3),
                AdminFieldLabel('Thumbnail Image'),
                const SizedBox(height: AppDimensions.space2),
                _buildThumbnailSection(isDark, theme, secondaryColor),

                // ── Gallery Images Section ────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                const Divider(),
                const SizedBox(height: AppDimensions.space3),
                Row(
                  children: [
                    AdminFieldLabel('Product Images'),
                    const SizedBox(width: AppDimensions.space2),
                    Text(
                      '${_images.length} / 10',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _images.length >= 10
                            ? AppColors.error
                            : secondaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space2),
                _buildImageGallery(isDark, theme, secondaryColor),

                // ── Variants Section Placeholder ──────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                const Divider(),
                const SizedBox(height: AppDimensions.space3),
                AdminFieldLabel('Variants'),
                const SizedBox(height: AppDimensions.space2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDimensions.space3,
                    vertical: AppDimensions.space3,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.surfaceVariantDark
                        : AppColors.surfaceVariantLight,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                    border: Border.all(
                      color: isDark
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Text(
                    'Variants will be implemented in Phase 3.4E.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: secondaryColor,
                    ),
                  ),
                ),

                // ── Visibility & Promotion Switches ──────────────────────────
                const SizedBox(height: AppDimensions.space4),
                const Divider(),
                const SizedBox(height: AppDimensions.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Active', style: theme.textTheme.bodyMedium),
                        Text(
                          'Visible to customers in the app',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isActive,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Featured', style: theme.textTheme.bodyMedium),
                        Text(
                          'Highlight in marketing banners and lists',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isFeatured,
                      activeThumbColor: AppColors.primary,
                      onChanged: (v) => setState(() => _isFeatured = v),
                    ),
                  ],
                ),

                // ── Inline Submission Error ──────────────────────────────────
                if (_localError != null) ...[
                  const SizedBox(height: AppDimensions.space4),
                  AdminInlineError(_localError!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
          ),
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(_isEditMode ? 'Save Changes' : 'Create Product'),
        ),
      ],
    );
  }

  // ── Pricing Widget Builders ────────────────────────────────────────────────

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel('Price (Rs.) *'),
        const SizedBox(height: AppDimensions.space2),
        TextFormField(
          controller: _priceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: '0.00'),
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return 'Price is required.';
            final p = double.tryParse(val);
            if (p == null || p < 0) return 'Must be >= 0.';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildComparePriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel('Compare Price (Rs.)'),
        const SizedBox(height: AppDimensions.space2),
        TextFormField(
          controller: _comparePriceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Optional — e.g. 1299'),
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return null;
            final cp = double.tryParse(val);
            if (cp == null || cp < 0) return 'Must be >= 0.';
            final priceVal = double.tryParse(_priceCtrl.text.trim());
            if (priceVal != null && cp < priceVal) {
              return 'Must be >= selling price.';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildCostPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel('Cost Price (Rs.)'),
        const SizedBox(height: AppDimensions.space2),
        TextFormField(
          controller: _costPriceCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'Optional — e.g. 500'),
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return null;
            final cp = double.tryParse(val);
            if (cp == null || cp < 0) return 'Must be >= 0.';
            return null;
          },
        ),
      ],
    );
  }

  // ── Inventory Widget Builders ──────────────────────────────────────────────

  Widget _buildSkuField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel('SKU *'),
        const SizedBox(height: AppDimensions.space2),
        TextFormField(
          controller: _skuCtrl,
          textInputAction: TextInputAction.next,
          maxLength: 40,
          decoration: const InputDecoration(
            hintText: 'e.g. WH-1000XM4',
            counterText: '',
          ),
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return 'SKU is required.';
            final ctrl = Get.find<ProductController>();
            final skuExists = ctrl.products.any((p) {
              return p.sku.toLowerCase() == val.toLowerCase() &&
                  p.id != widget.product?.id;
            });
            if (skuExists) return 'SKU must be unique.';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildStockField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminFieldLabel('Stock *'),
        const SizedBox(height: AppDimensions.space2),
        TextFormField(
          controller: _stockCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: '0'),
          validator: (v) {
            final val = v?.trim() ?? '';
            if (val.isEmpty) return 'Stock is required.';
            final s = int.tryParse(val);
            if (s == null || s < 0) return 'Must be a valid integer >= 0.';
            return null;
          },
        ),
      ],
    );
  }

  // ── Thumbnail Builder ──────────────────────────────────────────────────────

  Widget _buildThumbnailSection(
    bool isDark,
    ThemeData theme,
    Color secondaryColor,
  ) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    // ── Empty state ──────────────────────────────────────────────────────────
    if (_thumbnail == null) {
      return InkWell(
        onTap: _pickThumbnail,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.image_outlined,
                size: 36,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Thumbnail',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'JPG, PNG, WEBP • 1 image only',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Thumbnail preview ────────────────────────────────────────────────────
    final thumb = _thumbnail!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Preview
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
          child: thumb.isRemote
              ? Image.network(
                  thumb.url!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: secondaryColor,
                      size: 36,
                    ),
                  ),
                )
              : Image.memory(
                  thumb.bytes!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image_outlined,
                      color: secondaryColor,
                      size: 36,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: AppDimensions.space3),

        // Actions
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              onPressed: _pickThumbnail,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Replace'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space3,
                  vertical: AppDimensions.space2,
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space2),
            OutlinedButton.icon(
              onPressed: () => setState(() => _thumbnail = null),
              icon: const Icon(Icons.delete_outline, size: 16),
              label: const Text('Remove'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppDimensions.space3,
                  vertical: AppDimensions.space2,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Image Gallery Builder ──────────────────────────────────────────────────

  Widget _buildImageGallery(bool isDark, ThemeData theme, Color secondaryColor) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    // ── Empty state ──────────────────────────────────────────────────────────
    if (_images.isEmpty) {
      return InkWell(
        onTap: _pickImages,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_photo_alternate_outlined,
                size: 36,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'Upload Images',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Supports JPG, PNG, WEBP (Max 10)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ── Gallery with thumbnails ──────────────────────────────────────────────
    return Wrap(
      spacing: AppDimensions.space3,
      runSpacing: AppDimensions.space3,
      children: [
        // Existing image cards
        for (int index = 0; index < _images.length; index++)
          _buildImageCard(index, isDark, theme, borderColor, surfaceVariant,
              secondaryColor),

        // "+ Add Image" card
        if (_images.length < 10)
          GestureDetector(
            onTap: _pickImages,
            child: Container(
              width: 120,
              height: 150,
              decoration: BoxDecoration(
                color: surfaceVariant,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add Image',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${_images.length}/10',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: secondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImageCard(
    int index,
    bool isDark,
    ThemeData theme,
    Color borderColor,
    Color surfaceVariant,
    Color secondaryColor,
  ) {
    final img = _images[index];

    return Container(
      width: 120,
      height: 150,
      decoration: BoxDecoration(
        color: surfaceVariant,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // ── Thumbnail ──────────────────────────────────────────────────────
          Positioned.fill(
            bottom: 30,
            child: img.isRemote
                ? Image.network(
                    img.url!,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: secondaryColor,
                      ),
                    ),
                  )
                : Image.memory(
                    img.bytes!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        color: secondaryColor,
                      ),
                    ),
                  ),
          ),

          // ── COVER badge (first image) ──────────────────────────────────────
          if (index == 0)
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
                ),
                child: const Text(
                  'COVER',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

          // ── Delete button ──────────────────────────────────────────────────
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => setState(() => _images.removeAt(index)),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(153),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          // ── Reorder controls ───────────────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 30,
            child: Container(
              color: isDark ? Colors.black26 : Colors.black12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_back_rounded,
                      size: 16,
                      color: index > 0
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : Colors.grey,
                    ),
                    onPressed: index > 0
                        ? () {
                            setState(() {
                              final temp = _images[index];
                              _images[index] = _images[index - 1];
                              _images[index - 1] = temp;
                            });
                          }
                        : null,
                  ),
                  Text(
                    '${index + 1}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: index < _images.length - 1
                          ? (isDark ? Colors.white70 : Colors.black87)
                          : Colors.grey,
                    ),
                    onPressed: index < _images.length - 1
                        ? () {
                            setState(() {
                              final temp = _images[index];
                              _images[index] = _images[index + 1];
                              _images[index + 1] = temp;
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
