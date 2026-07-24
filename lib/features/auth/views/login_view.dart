import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/validators.dart';
import '../controllers/login_controller.dart';

/// Professional Admin Login screen for the Marketplace Admin Panel.
///
/// Fully responsive: desktop card layout → tablet card → mobile full-width.
/// Uses [LoginController] for form state, authentication, and reactive UI.
/// Reuses existing [AppColors], [AppDimensions], [AppValidators], and [Responsive].
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = Responsive.isDesktop(context);
            final isTablet = Responsive.isTablet(context);

            // Card max-width adapts to screen size
            final horizontalPadding = Responsive.value<double>(
              context,
              desktop: 0,
              tablet: 0,
              mobile: AppDimensions.space5,
            );

            // Card max-width adapts to screen size.
            // On mobile we subtract padding×2 so the card never overflows
            // the viewport when the ScrollView applies horizontal insets.
            final cardWidth = isDesktop
                ? 440.0
                : isTablet
                ? 400.0
                : constraints.maxWidth - (horizontalPadding * 2);

            return Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppDimensions.space8,
                ),
                child: SizedBox(
                  width: cardWidth.clamp(0.0, double.infinity),
                  child: _LoginCard(isDark: isDark, theme: theme),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Login Card ────────────────────────────────────────────────────────────────

class _LoginCard extends GetView<LoginController> {
  const _LoginCard({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Branding header ──────────────────────────────────────────────
          _BrandHeader(isDark: isDark, theme: theme),
          const SizedBox(height: AppDimensions.space8),

          // ── Form ────────────────────────────────────────────────────────
          _LoginForm(isDark: isDark, theme: theme),
        ],
      ),
    );
  }
}

// ── Brand Header ──────────────────────────────────────────────────────────────

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo mark
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: const Icon(
            Icons.storefront_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(height: AppDimensions.space5),

        // App name
        Text(
          AppStrings.appName,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.space1),

        // Heading
        Text(
          AppStrings.loginHeading,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: AppDimensions.space2),

        // Welcome message
        Text(
          AppStrings.loginWelcome,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
    );
  }
}

// ── Login Form ────────────────────────────────────────────────────────────────

class _LoginForm extends GetView<LoginController> {
  const _LoginForm({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Email field ────────────────────────────────────────────────
          _FieldLabel(
            label: AppStrings.loginEmail,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: AppDimensions.space2),
          _EmailField(isDark: isDark),
          const SizedBox(height: AppDimensions.space5),

          // ── Password field ─────────────────────────────────────────────
          _FieldLabel(
            label: AppStrings.loginPassword,
            isDark: isDark,
            theme: theme,
          ),
          const SizedBox(height: AppDimensions.space2),
          _PasswordField(isDark: isDark),
          const SizedBox(height: AppDimensions.space4),

          // ── Remember me + Forgot password ─────────────────────────────
          _RememberForgotRow(isDark: isDark, theme: theme),
          const SizedBox(height: AppDimensions.space5),

          // ── Firebase auth error ────────────────────────────────────────
          _AuthErrorMessage(theme: theme),

          // ── Submit button ──────────────────────────────────────────────
          _LoginButton(theme: theme),
        ],
      ),
    );
  }
}

// ── Field Label ───────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.label,
    required this.isDark,
    required this.theme,
  });

  final String label;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      ),
    );
  }
}

// ── Email Field ───────────────────────────────────────────────────────────────

class _EmailField extends GetView<LoginController> {
  const _EmailField({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: const Key('emailField'),
      controller: controller.emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      autocorrect: false,
      onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
      decoration: const InputDecoration(
        hintText: 'you@example.com',
        prefixIcon: Icon(Icons.mail_outline_rounded),
      ),
      validator: AppValidators.email,
    );
  }
}

// ── Password Field ────────────────────────────────────────────────────────────

class _PasswordField extends GetView<LoginController> {
  const _PasswordField({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => TextFormField(
        key: const Key('passwordField'),
        controller: controller.passwordController,
        obscureText: controller.obscurePassword.value,
        textInputAction: TextInputAction.done,
        autofillHints: const [AutofillHints.password],
        // Allow pressing Enter to submit on web
        onFieldSubmitted: (_) => controller.login(),
        onEditingComplete: () {},
        decoration: InputDecoration(
          hintText: '••••••••',
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip: controller.obscurePassword.value
                ? 'Show password'
                : 'Hide password',
            icon: Icon(
              controller.obscurePassword.value
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
            ),
            onPressed: controller.togglePasswordVisibility,
          ),
        ),
        validator: (v) => AppValidators.required(v, label: 'Password'),
      ),
    );
  }
}

// ── Remember Me + Forgot Password Row ─────────────────────────────────────────

class _RememberForgotRow extends GetView<LoginController> {
  const _RememberForgotRow({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Remember Me
        Obx(
          () => SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: controller.rememberMe.value,
              onChanged: (_) => controller.toggleRememberMe(),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusXs),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDimensions.space2),
        GestureDetector(
          onTap: controller.toggleRememberMe,
          child: Text(
            AppStrings.loginRememberMe,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),

        const Spacer(),

        // Forgot Password
        Flexible(
          child: TextButton(
            onPressed: controller.onForgotPasswordTapped,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space2,
                vertical: AppDimensions.space1,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              AppStrings.loginForgotPassword,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Firebase Auth Error Message ───────────────────────────────────────────────

class _AuthErrorMessage extends GetView<LoginController> {
  const _AuthErrorMessage({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final error = controller.authError.value;
      if (error == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(bottom: AppDimensions.space4),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.space4,
            vertical: AppDimensions.space3,
          ),
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: AppDimensions.iconMd,
                color: AppColors.error,
              ),
              const SizedBox(width: AppDimensions.space2),
              Expanded(
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Login Submit Button ───────────────────────────────────────────────────────

class _LoginButton extends GetView<LoginController> {
  const _LoginButton({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.enter) {
            controller.login();
          }
        },
        child: SizedBox(
          height: 48,
          child: ElevatedButton(
            key: const Key('loginButton'),
            // Disable button while loading to prevent duplicate submissions
            onPressed: controller.isLoading.value ? null : controller.login,
            child: controller.isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    AppStrings.loginButton,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
