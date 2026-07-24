import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/slug_utils.dart';
import '../../../../core/widgets/admin_form_widgets.dart';
import '../controllers/badge_controller.dart';
import '../models/badge_model.dart';

/// Predefined list of standard color hexes for quick selection.
const List<({String name, String hex})> _colorPresets = [
  (name: 'Green', hex: '#22C55E'),
  (name: 'Red', hex: '#EF4444'),
  (name: 'Blue', hex: '#3B82F6'),
  (name: 'Orange', hex: '#F97316'),
  (name: 'Purple', hex: '#A855F7'),
  (name: 'Gold', hex: '#EAB308'),
];

/// Predefined list of standard icon names for quick selection.
const List<({String name, IconData icon})> _iconPresets = [
  (name: 'workspace_premium', icon: Icons.workspace_premium),
  (name: 'local_fire_department', icon: Icons.local_fire_department),
  (name: 'new_releases', icon: Icons.new_releases),
  (name: 'local_offer', icon: Icons.local_offer),
  (name: 'star', icon: Icons.star),
  (name: 'verified', icon: Icons.verified),
];

/// Resolves a string icon name to [IconData].
IconData getBadgeIconData(String iconName) {
  switch (iconName.trim()) {
    case 'workspace_premium':
      return Icons.workspace_premium;
    case 'local_fire_department':
      return Icons.local_fire_department;
    case 'new_releases':
      return Icons.new_releases;
    case 'local_offer':
      return Icons.local_offer;
    case 'star':
      return Icons.star;
    case 'verified':
      return Icons.verified;
    case 'trending_up':
      return Icons.trending_up;
    case 'sell':
      return Icons.sell;
    case 'percent':
      return Icons.percent;
    case 'favorite':
      return Icons.favorite;
    case 'flash_on':
      return Icons.flash_on;
    case 'loyalty':
      return Icons.loyalty;
    case 'card_membership':
      return Icons.card_membership;
    case 'military_tech':
      return Icons.military_tech;
    case 'thumb_up':
      return Icons.thumb_up;
    case 'celebration':
      return Icons.celebration;
    case 'redeem':
      return Icons.redeem;
    default:
      return Icons.help_outline_rounded;
  }
}

/// Parses a hex color string into a Flutter [Color].
Color parseHexColor(String hex) {
  var hexStr = hex.trim().replaceAll('#', '');
  if (hexStr.length == 6) {
    hexStr = 'FF$hexStr';
  } else if (hexStr.length == 8) {
    // already has alpha
  } else {
    return Colors.transparent;
  }
  final val = int.tryParse(hexStr, radix: 16);
  if (val != null) {
    return Color(val);
  }
  return Colors.transparent;
}

/// Dialog for creating a new badge or editing an existing one.
///
/// Pass [badge] = null to open in "Add" mode.
/// Pass a non-null [BadgeModel] to open in "Edit" mode.
class BadgeFormDialog extends StatefulWidget {
  const BadgeFormDialog({super.key, this.badge});

  /// Null = create mode. Non-null = edit mode.
  final BadgeModel? badge;

  /// Convenience static method — show the dialog with the correct transition.
  static Future<void> show(BuildContext context, {BadgeModel? badge}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BadgeFormDialog(badge: badge),
    );
  }

  @override
  State<BadgeFormDialog> createState() => _BadgeFormDialogState();
}

class _BadgeFormDialogState extends State<BadgeFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _sortCtrl;

  bool _isActive = true;
  bool _isSubmitting = false;
  String? _localError;

  /// The slug preview, re-derived whenever name changes.
  String _slugPreview = '';

  bool get _isEditMode => widget.badge != null;

  @override
  void initState() {
    super.initState();
    final badge = widget.badge;
    _nameCtrl = TextEditingController(text: badge?.name ?? '');
    _colorCtrl = TextEditingController(text: badge?.color ?? '#22C55E');
    _iconCtrl = TextEditingController(text: badge?.icon ?? 'workspace_premium');
    _sortCtrl = TextEditingController(text: (badge?.sortOrder ?? 0).toString());
    _isActive = badge?.isActive ?? true;
    _slugPreview = SlugUtils.toSlug(_nameCtrl.text);

    _nameCtrl.addListener(_onNameChanged);
    _colorCtrl.addListener(_onColorOrIconChanged);
    _iconCtrl.addListener(_onColorOrIconChanged);
  }

  @override
  void dispose() {
    _nameCtrl.removeListener(_onNameChanged);
    _colorCtrl.removeListener(_onColorOrIconChanged);
    _iconCtrl.removeListener(_onColorOrIconChanged);

    _nameCtrl.dispose();
    _colorCtrl.dispose();
    _iconCtrl.dispose();
    _sortCtrl.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    final preview = SlugUtils.toSlug(_nameCtrl.text);
    if (preview != _slugPreview) {
      setState(() => _slugPreview = preview);
    }
  }

  void _onColorOrIconChanged() {
    setState(() {}); // Redraw preview fields
  }

  Future<void> _submit() async {
    setState(() => _localError = null);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final name = _nameCtrl.text.trim();
    final color = _colorCtrl.text.trim();
    final icon = _iconCtrl.text.trim();
    final sortOrder = int.tryParse(_sortCtrl.text.trim()) ?? 0;

    setState(() => _isSubmitting = true);

    final controller = Get.find<BadgeController>();
    final ({bool success, String? error}) result;

    if (_isEditMode) {
      result = await controller.updateBadge(
        id: widget.badge!.id,
        name: name,
        color: color,
        icon: icon,
        isActive: _isActive,
        sortOrder: sortOrder,
      );
    } else {
      result = await controller.createBadge(
        name: name,
        color: color,
        icon: icon,
        isActive: _isActive,
        sortOrder: sortOrder,
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (result.success) {
      Navigator.of(context).pop();
      Get.snackbar(
        _isEditMode ? 'Badge Updated' : 'Badge Created',
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

    final parsedColor = parseHexColor(_colorCtrl.text);

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
        _isEditMode ? 'Edit Badge' : 'Add Badge',
        style: theme.textTheme.titleLarge,
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Name ──────────────────────────────────────────────────────
                const AdminFieldLabel('Name *'),
                const SizedBox(height: AppDimensions.space2),
                TextFormField(
                  controller: _nameCtrl,
                  textInputAction: TextInputAction.next,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Best Seller',
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
                    const AdminFieldLabel('Slug'),
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

                // ── Color ─────────────────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                Row(
                  children: [
                    const AdminFieldLabel('Color (Hex code) *'),
                    const SizedBox(width: AppDimensions.space2),
                    if (parsedColor != Colors.transparent)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: parsedColor,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            width: 1,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space2),
                TextFormField(
                  controller: _colorCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(hintText: 'e.g. #22C55E'),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Color hex code is required.';
                    final c = parseHexColor(val);
                    if (c == Colors.transparent) {
                      return 'Invalid hex code format (use #RRGGBB).';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space2),
                // Color quick select presets
                Wrap(
                  spacing: AppDimensions.space2,
                  runSpacing: AppDimensions.space2,
                  children: _colorPresets.map((preset) {
                    final color = parseHexColor(preset.hex);
                    return ActionChip(
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: CircleAvatar(backgroundColor: color, radius: 7),
                      label: Text(preset.name),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                      onPressed: () {
                        _colorCtrl.text = preset.hex;
                      },
                    );
                  }).toList(),
                ),

                // ── Icon ──────────────────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                Row(
                  children: [
                    const AdminFieldLabel('Icon *'),
                    const SizedBox(width: AppDimensions.space2),
                    Icon(
                      getBadgeIconData(_iconCtrl.text),
                      size: 16,
                      color: parsedColor != Colors.transparent
                          ? parsedColor
                          : secondaryColor,
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space2),
                TextFormField(
                  controller: _iconCtrl,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    hintText: 'e.g. workspace_premium',
                  ),
                  validator: (v) {
                    final val = v?.trim() ?? '';
                    if (val.isEmpty) return 'Icon name is required.';
                    return null;
                  },
                ),
                const SizedBox(height: AppDimensions.space2),
                // Icon presets
                Wrap(
                  spacing: AppDimensions.space2,
                  runSpacing: AppDimensions.space2,
                  children: _iconPresets.map((preset) {
                    return ActionChip(
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      avatar: Icon(preset.icon, size: 12),
                      label: Text(preset.name),
                      labelStyle: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                      ),
                      onPressed: () {
                        _iconCtrl.text = preset.name;
                      },
                    );
                  }).toList(),
                ),

                // ── Sort Order ────────────────────────────────────────────────
                const SizedBox(height: AppDimensions.space4),
                const AdminFieldLabel('Sort Order'),
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
              : Text(_isEditMode ? 'Save Changes' : 'Create Badge'),
        ),
      ],
    );
  }
}
