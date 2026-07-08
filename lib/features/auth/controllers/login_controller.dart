import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../routes/app_routes.dart';
import '../repositories/auth_repository.dart';

/// GetX controller for the Admin Login screen.
///
/// Manages form state, password visibility, loading, and authentication.
/// Retrieves [AuthRepository] from the app-level GetX container —
/// does NOT create a new instance.
///
/// Architecture:
///   LoginView → LoginController → AuthRepository → FirebaseAuth
class LoginController extends GetxController {
  // ── Dependencies ───────────────────────────────────────────────────────────

  final AuthRepository _auth = Get.find<AuthRepository>();

  // ── Form ───────────────────────────────────────────────────────────────────

  final formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // ── Reactive state ─────────────────────────────────────────────────────────

  /// Whether the authentication request is in-flight.
  /// Drives button loading indicator and prevents duplicate submissions.
  final RxBool isLoading = false.obs;

  /// Whether the password field text is obscured.
  final RxBool obscurePassword = true.obs;

  /// UI-only: Remember Me checkbox state.
  /// Persistent credential storage is NOT implemented in Phase 2B.
  final RxBool rememberMe = false.obs;

  /// Inline Firebase authentication error shown below the form.
  /// `null` means no error is currently displayed.
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

  /// Validates the form and calls Firebase sign-in.
  ///
  /// Guards against duplicate submission via [isLoading].
  /// Maps [FirebaseAuthException] codes to user-friendly messages.
  Future<void> login() async {
    // Clear any previous auth error.
    authError.value = null;

    // Prevent duplicate submissions.
    if (isLoading.value) return;

    // Validate all fields; stop if invalid.
    if (!formKey.currentState!.validate()) return;

    isLoading.value = true;

    try {
      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      // Replace the entire navigation stack — LoginView is removed from history.
      Get.offAllNamed(AppRoutes.dashboard);
    } on FirebaseAuthException catch (e) {
      authError.value = _mapFirebaseError(e.code);
    } catch (_) {
      authError.value = AppStrings.authErrorUnexpected;
    } finally {
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
