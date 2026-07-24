import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/widgets/admin_form_widgets.dart';
import '../controllers/category_controller.dart';
import '../models/category_model.dart';

/// Dialog for creating a new category or editing an existing one.
///
/// Pass [category] = null to open in "Add" mode.
/// Pass a non-null [CategoryModel] to open in "Edit" mode.
///
/// ## Responsibilities
///
/// - Own local form state (TextEditingControllers, isSubmitting, localError).
/// - Derive and display the slug preview automatically from the name field.
/// - Delegate all Firestore mutations to [CategoryController].
/// - Show inline error messages on validation or controller failures.
/// - Pop itself and show a success snackbar on success.
///
/// The slug is auto-generated from the name and shown as a read-only preview.
/// The admin does NOT type the slug manually.
class CategoryFormDialog extends StatefulWidget {
  const CategoryFormDialog({super.key, this.category});

  /// Null = create mode. Non-null = edit mode.
  final CategoryModel? category;

  /// Convenience static method — show the dialog with the correct transition.
  static Future<void> show(BuildContext context, {CategoryModel? category}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CategoryFormDialog(category: category),
    );
  }

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _sortCtrl;

  bool _isActive = true;
  bool _isSubmitting = false;
  String? _localError;

  /// The slug preview, re-derived whenever name changes.
  String _slugPreview = '';

  /// Category image state.
  PickedCategoryImage? _image;
  bool _hadImageOnOpen = false;

  bool get _isEditMode => widget.category != null;

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameCtrl = TextEditingController(text: cat?.name ?? '');
    _descCtrl = TextEditingController(text: cat?.description ?? '');
    _sortCtrl = TextEditingController(text: (cat?.sortOrder ?? 0).toString());
    _isActive = cat?.isActive ?? true;
    _slugPreview = SlugUtils.toSlug(_nameCtrl.text);

    if (cat != null && cat.imageUrl.isNotEmpty) {
      _image = PickedCategoryImage.fromUrl(cat.imageUrl);
      _hadImageOnOpen = true;
    }

    _nameCtrl.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final preview = SlugUtils.toSlug(_nameCtrl.text);
    if (preview != _slugPreview) {
      setState(() => _slugPreview = preview);
    }
  }

  Future<void> _submit() async {
    // Clear any previous inline error.
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final sortOrder = int.tryParse(_sortCtrl.text.trim()) ?? 0;

    setState(() => _isSubmitting = true);

    final controller = Get.find<CategoryController>();
    final ({bool success, String? error}) result;

    if (_isEditMode) {
      final deleteImage = _hadImageOnOpen && _image == null;
      result = await controller.updateCategory(
        id: widget.category!.id,
        name: name,
        description: description,
        isActive: _isActive,
        sortOrder: sortOrder,
        image: _image,
        deleteImage: deleteImage,
      );
    } else {
      result = await controller.createCategory(
        name: name,
        description: description,
        isActive: _isActive,
        sortOrder: sortOrder,
        image: _image,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.of(context).pop();
      Get.snackbar(
        _isEditMode ? 'Category Updated' : 'Category Created',
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
      setState(() => _localError = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

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
        _isEditMode ? 'Edit Category' : 'Add Category',
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Name ──────────────────────────────────────────────────────
              AdminFieldLabel('Name *'),
              const SizedBox(height: AppDimensions.space2),
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                maxLength: 80,
                decoration: const InputDecoration(
                  hintText: 'e.g. Electronics',
                  counterText: '',
                ),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Name is required.';
                  if (val.length < 2) {
                    return 'Name must be at least 2 characters.';
                  }
                  if (SlugUtils.toSlug(val).isEmpty) {
                    return 'Name must contain at least one letter or number.';
                  }
                  return null;
                },
              ),

              // ── Slug preview ──────────────────────────────────────────────
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
                    color: _slugPreview.isEmpty
                        ? secondaryColor
                        : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight),
                    fontFamily: 'monospace',
                    letterSpacing: 0.3,
                  ),
                ),
              ),

              // ── Description ───────────────────────────────────────────────
              const SizedBox(height: AppDimensions.space4),
              AdminFieldLabel('Description'),
              const SizedBox(height: AppDimensions.space2),
              TextFormField(
                controller: _descCtrl,
                minLines: 2,
                maxLines: 3,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  hintText: 'Optional — describe this category',
                ),
              ),

              // ── Category Image ─────────────────────────────────────────
              const SizedBox(height: AppDimensions.space4),
              AdminFieldLabel('Category Image'),
              const SizedBox(height: AppDimensions.space2),
              _buildCategoryImageSection(isDark, theme, secondaryColor),

              // ── Sort Order ────────────────────────────────────────────────
              const SizedBox(height: AppDimensions.space4),
              AdminFieldLabel('Sort Order'),
              const SizedBox(height: AppDimensions.space2),
              TextFormField(
                controller: _sortCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(hintText: '0'),
                validator: (v) {
                  final val = v?.trim() ?? '';
                  if (val.isEmpty) return 'Sort order is required.';
                  final n = int.tryParse(val);
                  if (n == null || n < 0) {
                    return 'Must be a non-negative whole number.';
                  }
                  return null;
                },
              ),

              // ── Active status ─────────────────────────────────────────────
              const SizedBox(height: AppDimensions.space4),
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

              // ── Inline error ──────────────────────────────────────────────
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
              : Text(_isEditMode ? 'Save Changes' : 'Create Category'),
        ),
      ],
    );
  }

  // ── Image Picker ─────────────────────────────────────────────────────────

  Future<void> _pickCategoryImage() async {
    final FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
    } catch (e) {
      debugPrint('[CategoryFormDialog] Image picker error: $e');
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
      _image = PickedCategoryImage.fromFile(bytes: bytes!, name: file.name);
    });
  }

  // ── Image Section Builder ────────────────────────────────────────────────

  Widget _buildCategoryImageSection(
    bool isDark,
    ThemeData theme,
    Color secondaryColor,
  ) {
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final surfaceVariant = isDark
        ? AppColors.surfaceVariantDark
        : AppColors.surfaceVariantLight;

    // Empty state
    if (_image == null) {
      return InkWell(
        onTap: _pickCategoryImage,
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
                'Upload Image',
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

    // Image preview
    final img = _image!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            color: surfaceVariant,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: borderColor),
          ),
          clipBehavior: Clip.antiAlias,
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
                      size: 36,
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
              onPressed: _pickCategoryImage,
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
              onPressed: () => setState(() => _image = null),
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
}

// Shared form helpers (AdminFieldLabel, AdminInlineError) are provided by
// core/widgets/admin_form_widgets.dart — imported above.
