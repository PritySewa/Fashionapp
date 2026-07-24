import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/admin_authorization_status.dart';
import '../../../features/admin/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';
import '../repositories/auth_repository.dart';

/// GetX controller for the Admin Login screen.
///
/// Manages form state, password visibility, loading, and the two-step
/// authentication + authorization flow:
///
/// ```
/// Validate form
///   → Firebase Email/Password sign-in
///   → AdminRepository.checkAuthorization(uid)
///
///   authorized  → Navigate to Dashboard
///
///   notFound    → Sign out → Stay on Login
///                 authError = "You are not authorized…"
///
///   inactive    → Sign out → Stay on Login
///                 authError = "Your admin account is inactive."
///
///   error       → Sign out → Stay on Login
///                 authError = "Unable to verify admin access…"
/// ```
///
/// ## Security guarantee
///
/// Firebase Authentication success alone **never** navigates to Dashboard.
/// Navigation to `/dashboard` only occurs when [AdminRepository.checkAuthorization]
/// returns [AdminAuthorizationStatus.authorized].
///
/// ## Dependency resolution
///
/// Both [AuthRepository] and [AdminRepository] are resolved via [Get.find]
/// — they are registered permanently at the application level by [AppBinding]
/// and are NOT re-registered here.
///
/// Architecture:
///   LoginView → LoginController → AuthRepository   → FirebaseAuth
///                               → AdminRepository  → Cloud Firestore
class LoginController extends GetxController {
  // ── Dependencies ───────────────────────────────────────────────────────────

  final AuthRepository _auth = Get.find<AuthRepository>();
  final AdminRepository _adminRepo = Get.find<AdminRepository>();

  // ── Form ───────────────────────────────────────────────────────────────────

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ── Reactive state ─────────────────────────────────────────────────────────

  /// Whether the authentication + authorization request is in-flight.
  /// Drives button loading indicator and prevents duplicate submissions.
  final RxBool isLoading = false.obs;

  /// Whether the password field text is obscured.
  final RxBool obscurePassword = true.obs;

  /// UI-only: Remember Me checkbox state.
  /// Persistent credential storage is NOT implemented in Phase 2B.
  final RxBool rememberMe = false.obs;

  /// Inline error shown below the form.
  ///
  /// Set for both Firebase authentication failures and Firestore authorization
  /// failures. `null` means no error is currently displayed.
  final RxnString authError = RxnString();

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Toggles password field visibility.
  void togglePasswordVisibility() =>
      obscurePassword.value = !obscurePassword.value;

  /// Toggles the Remember Me checkbox.
  void toggleRememberMe() => rememberMe.value = !rememberMe.value;

  /// Displays the Forgot Password temporary message via a GetX snackbar.
  void onForgotPasswordTapped() {
    Get.snackbar(
      'Forgot Password',
      AppStrings.loginForgotPasswordMessage,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
    );
  }

  /// Validates the form, signs in with Firebase, then checks admin
  /// authorization before navigating.
  ///
  /// ## Loading state
  ///
  /// [isLoading] is set to `true` at the start of the async work and
  /// reset to `false` in a `finally` block, so it always resets — even
  /// when authorization fails or an unexpected exception is thrown.
  /// This ensures the button re-enables and the user can retry.
  ///
  /// ## Error handling
  ///
  /// - [FirebaseAuthException] → mapped to user-friendly message
  /// - Authorization failure  → sign out + mapped message
  /// - Unexpected exception   → generic fallback message
  Future<void> login() async {
    // Clear any previous error.
    authError.value = null;

    // Prevent duplicate submissions.
    if (isLoading.value) return;

    // Validate all fields; stop if invalid.
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      // ── Step 1: Firebase Authentication ──────────────────────────────────
      final credential = await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final uid = credential.user!.uid;
      debugPrint('[LoginController] Firebase auth OK — uid=$uid');

      // ── Step 2: Admin authorization check ────────────────────────────────
      final result = await _adminRepo.checkAuthorization(uid);
      debugPrint('[LoginController] authorization result: ${result.status}');

      switch (result.status) {
        case AdminAuthorizationStatus.authorized:
          // Only reachable path to Dashboard.
          debugPrint('[LoginController] authorized — navigating to dashboard');
          Get.offAllNamed(AppRoutes.dashboard);

        case AdminAuthorizationStatus.notFound:
          debugPrint('[LoginController] notFound — signing out');
          await _auth.signOut();
          authError.value = AppStrings.authStartupNotFound;

        case AdminAuthorizationStatus.inactive:
          debugPrint('[LoginController] inactive — signing out');
          await _auth.signOut();
          authError.value = AppStrings.authStartupInactive;

        case AdminAuthorizationStatus.error:
          // Never allow Dashboard access when authorization is indeterminate.
          // Sign out to discard the live Firebase session.
          debugPrint('[LoginController] error — signing out');
          await _auth.signOut();
          authError.value = AppStrings.authStartupError;
      }
    } on FirebaseAuthException catch (e) {
      authError.value = _mapFirebaseError(e.code);
    } catch (_) {
      authError.value = AppStrings.authErrorUnexpected;
    } finally {
      // Always reset loading so the button re-enables and the user can retry.
      isLoading.value = false;
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  /// Maps a [FirebaseAuthException] error code to a user-readable message.
  String _mapFirebaseError(String code) {
    switch (code) {
      case 'invalid-email':
        return AppStrings.authErrorInvalidEmail;
      case 'user-disabled':
        return AppStrings.authErrorUserDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AppStrings.authErrorInvalidCredentials;
      case 'too-many-requests':
        return AppStrings.authErrorTooManyRequests;
      case 'network-request-failed':
        return AppStrings.authErrorNetwork;
      default:
        return AppStrings.authErrorUnexpected;
    }
  }
}
