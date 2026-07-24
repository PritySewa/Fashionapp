import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/widgets/admin_form_widgets.dart';
import '../../categories/controllers/category_controller.dart';
import '../../products/controllers/product_controller.dart';
import '../controllers/banner_controller.dart';
import '../models/banner_model.dart';

class BannerFormDialog extends StatefulWidget {
  const BannerFormDialog({super.key, this.banner});

  final BannerModel? banner;

  bool get isEdit => banner != null;

  static Future<void> show(BuildContext context, {BannerModel? banner}) {
    if (Responsive.isDesktop(context)) {
      return showDialog(
        context: context,
        builder: (_) => BannerFormDialog(banner: banner),
      );
    }
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => BannerFormSheet(
          banner: banner,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _subtitleCtrl;
  late TextEditingController _displayOrderCtrl;
  late TextEditingController _externalUrlCtrl;

  late BannerTargetType _targetType;
  String? _selectedTargetId;
  late bool _isActive;
  PickedBannerImage? _pickedImage;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _subtitleCtrl = TextEditingController(text: b?.subtitle ?? '');
    _displayOrderCtrl = TextEditingController(
      text: (b?.displayOrder ?? 0).toString(),
    );
    _externalUrlCtrl = TextEditingController(text: b?.externalUrl ?? '');

    _targetType = b?.targetType ?? BannerTargetType.product;
    _selectedTargetId = b?.targetId;
    _isActive = b?.isActive ?? true;

    if (b != null && b.imageUrl.isNotEmpty) {
      _pickedImage = PickedBannerImage.fromUrl(b.imageUrl);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _displayOrderCtrl.dispose();
    _externalUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(() {
            _pickedImage = PickedBannerImage.fromBytes(
              bytes: file.bytes,
              name: file.name,
            );
          });
        }
      }
    } catch (e) {
      debugPrint('[BannerFormDialog] pickImage error: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      Get.snackbar(
        'Image Required',
        'Please select a banner image.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final controller = Get.find<BannerController>();

    final title = _titleCtrl.text.trim();
    final subtitle = _subtitleCtrl.text.trim();
    final displayOrder = int.tryParse(_displayOrderCtrl.text.trim()) ?? 0;

    String? targetId;
    String? externalUrl;

    if (_targetType == BannerTargetType.product ||
        _targetType == BannerTargetType.category) {
      targetId = _selectedTargetId;
    } else if (_targetType == BannerTargetType.external) {
      externalUrl = _externalUrlCtrl.text.trim();
    }

    final ({String? error, bool success}) result;

    if (widget.isEdit) {
      result = await controller.updateBanner(
        id: widget.banner!.id,
        title: title,
        subtitle: subtitle,
        image: _pickedImage,
        targetType: _targetType,
        targetId: targetId,
        clearTargetId: targetId == null,
        externalUrl: externalUrl,
        clearExternalUrl: externalUrl == null,
        displayOrder: displayOrder,
        isActive: _isActive,
      );
    } else {
      result = await controller.createBanner(
        title: title,
        subtitle: subtitle,
        image: _pickedImage!,
        targetType: _targetType,
        targetId: targetId,
        externalUrl: externalUrl,
        displayOrder: displayOrder,
        isActive: _isActive,
      );
    }

    setState(() => _isSubmitting = false);

    if (result.success) {
      if (mounted) Navigator.of(context).pop();
      Get.snackbar(
        'Success',
        widget.isEdit
            ? 'Banner updated successfully.'
            : 'Banner created successfully.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
      );
    } else {
      Get.snackbar(
        'Error',
        result.error ?? 'An error occurred.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error,
        colorText: Colors.white,
        margin: const EdgeInsets.all(AppDimensions.space4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Container(
        width: 580,
        constraints: const BoxConstraints(maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Bar
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
                    child: Text(
                      widget.isEdit ? 'Edit Banner' : 'Add Banner',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppDimensions.space6),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image Picker Card
                      _ImagePickerSection(
                        pickedImage: _pickedImage,
                        onPick: _pickImage,
                        onRemove: () => setState(() => _pickedImage = null),
                      ),
                      const SizedBox(height: AppDimensions.space5),

                      // Title
                      const AdminFieldLabel('Title *'),
                      const SizedBox(height: AppDimensions.space1),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Summer Sale 50% Off',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Title is required'
                            : null,
                      ),
                      const SizedBox(height: AppDimensions.space4),

                      // Subtitle
                      const AdminFieldLabel('Subtitle'),
                      const SizedBox(height: AppDimensions.space1),
                      TextFormField(
                        controller: _subtitleCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Limited time offer on selected items',
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),

                      // Target Type Selector
                      const AdminFieldLabel('Target Type'),
                      const SizedBox(height: AppDimensions.space1),
                      DropdownButtonFormField<BannerTargetType>(
                        initialValue: _targetType,
                        items: BannerTargetType.values
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.label),
                              ),
                            )
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _targetType = val;
                              _selectedTargetId = null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: AppDimensions.space4),

                      // Conditional Target Selector Field
                      if (_targetType == BannerTargetType.product) ...[
                        const AdminFieldLabel('Select Product *'),
                        const SizedBox(height: AppDimensions.space1),
                        GetBuilder<ProductController>(
                          builder: (productCtrl) {
                            final products = productCtrl.products;
                            return DropdownButtonFormField<String>(
                              initialValue: products.any((p) => p.id == _selectedTargetId)
                                  ? _selectedTargetId
                                  : null,
                              items: products
                                  .map(
                                    (p) => DropdownMenuItem(
                                      value: p.id,
                                      child: Text(p.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedTargetId = val),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Please select a product'
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.space4),
                      ] else if (_targetType == BannerTargetType.category) ...[
                        const AdminFieldLabel('Select Category *'),
                        const SizedBox(height: AppDimensions.space1),
                        GetBuilder<CategoryController>(
                          builder: (catCtrl) {
                            final categories = catCtrl.categories;
                            return DropdownButtonFormField<String>(
                              initialValue: categories.any((c) => c.id == _selectedTargetId)
                                  ? _selectedTargetId
                                  : null,
                              items: categories
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _selectedTargetId = val),
                              validator: (val) => val == null || val.isEmpty
                                  ? 'Please select a category'
                                  : null,
                            );
                          },
                        ),
                        const SizedBox(height: AppDimensions.space4),
                      ] else if (_targetType == BannerTargetType.external) ...[
                        const AdminFieldLabel('External URL *'),
                        const SizedBox(height: AppDimensions.space1),
                        TextFormField(
                          controller: _externalUrlCtrl,
                          decoration: const InputDecoration(
                            hintText: 'https://example.com/promo',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'URL is required';
                            }
                            final uri = Uri.tryParse(v.trim());
                            if (uri == null || !uri.hasAbsolutePath) {
                              return 'Enter a valid URL (e.g. https://...)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: AppDimensions.space4),
                      ],

                      // Display Order & Active Switch
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AdminFieldLabel('Display Order'),
                                const SizedBox(height: AppDimensions.space1),
                                TextFormField(
                                  controller: _displayOrderCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                  ),
                                  validator: (v) {
                                    if (v != null && v.isNotEmpty) {
                                      if (int.tryParse(v.trim()) == null) {
                                        return 'Must be an integer';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppDimensions.space4),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AdminFieldLabel('Active Status'),
                                SwitchListTile(
                                  title: const Text('Active', style: TextStyle(fontSize: 13)),
                                  subtitle: const Text('Visible in app', style: TextStyle(fontSize: 11)),
                                  value: _isActive,
                                  activeThumbColor: AppColors.success,
                                  onChanged: (v) => setState(() => _isActive = v),
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Divider(height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.all(AppDimensions.space4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: AppDimensions.space3),
                  ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(widget.isEdit ? 'Save Changes' : 'Create Banner'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mobile Bottom Sheet ───────────────────────────────────────────────────────

class BannerFormSheet extends StatelessWidget {
  const BannerFormSheet({
    super.key,
    this.banner,
    required this.scrollController,
  });

  final BannerModel? banner;
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
      child: BannerFormDialog(banner: banner),
    );
  }
}

// ── Image Picker Section Widget ───────────────────────────────────────────────

class _ImagePickerSection extends StatelessWidget {
  const _ImagePickerSection({
    required this.pickedImage,
    required this.onPick,
    required this.onRemove,
  });

  final PickedBannerImage? pickedImage;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Banner Image *',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.space2),
        Container(
          height: 160,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.surfaceVariantDark
                : AppColors.surfaceVariantLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
          ),
          child: pickedImage != null
              ? Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMd),
                        child: pickedImage!.isLocal
                            ? Image.memory(
                                pickedImage!.bytes!,
                                fit: BoxFit.cover,
                              )
                            : Image.network(
                                pickedImage!.url!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                            ),
                            icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                            onPressed: onPick,
                          ),
                          const SizedBox(width: 4),
                          IconButton.filled(
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.error,
                            ),
                            icon: const Icon(Icons.delete, size: 16, color: Colors.white),
                            onPressed: onRemove,
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : InkWell(
                  onTap: onPick,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_rounded,
                        size: 40,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                      const SizedBox(height: AppDimensions.space2),
                      Text(
                        'Click to upload banner image',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Supports PNG, JPG, WebP',
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
        ),
      ],
    );
  }
}
