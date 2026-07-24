import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/enums/admin_authorization_status.dart';
import '../../../features/auth/controllers/login_controller.dart';
import '../../../features/auth/repositories/auth_repository.dart';
import '../../../features/admin/repositories/admin_repository.dart';
import '../../../routes/app_routes.dart';

/// GetX controller for the Splash screen.
///
/// Checks Firebase Authentication state in [onReady], then validates admin
/// authorization via [AdminRepository] before deciding which route to load.
///
/// ## Startup flow
///
/// ```
/// App starts
///   → Check Firebase currentUser
///
///   No user  → Navigate to Login
///
///   User exists
///     → AdminRepository.checkAuthorization(uid)
///
///     authorized → Navigate to Dashboard
///
///     notFound   → Sign out → Navigate to Login
///                  (message: "You are not authorized…")
///
///     inactive   → Sign out → Navigate to Login
///                  (message: "Your admin account is inactive.")
///
///     error      → Sign out → Navigate to Login
///                  (message: "Unable to verify admin access…")
/// ```
///
/// ## Dependency resolution
///
/// Both [AuthRepository] and [AdminRepository] are registered permanently at
/// the application level by [AppBinding] and resolved here via [Get.find].
/// [SplashBinding] only registers [SplashController] — it does NOT touch either
/// repository.
///
/// ## Error message delivery
///
/// After navigating to `/login`, [LoginBinding] runs synchronously and puts
/// [LoginController] into the GetX container before the first frame builds.
/// This allows [SplashController] to call [Get.find<LoginController>()] and
/// set [LoginController.authError] immediately after the navigation call,
/// without modifying [LoginController] or [LoginView].
///
/// ## Defensive behaviour
///
/// The outer try/catch preserves the Phase 2A guarantee that the app never
/// remains permanently on SplashView — any unexpected exception falls back
/// safely to [AppRoutes.login].
class SplashController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    debugPrint('[SplashController] onReady() fired');
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      debugPrint('[SplashController] looking up AuthRepository...');
      final auth = Get.find<AuthRepository>();
      debugPrint('[SplashController] AuthRepository found: $auth');

      final user = auth.currentUser;
      debugPrint('[SplashController] currentUser = $user');

      if (user == null) {
        debugPrint('[SplashController] no session — navigating to login');
        Get.offAllNamed(AppRoutes.login);
        return;
      }

      // ── Authenticated user: check admin authorization ───────────────────────
      debugPrint('[SplashController] user found — checking authorization...');
      final adminRepo = Get.find<AdminRepository>();
      final result = await adminRepo.checkAuthorization(user.uid);
      debugPrint('[SplashController] authorization result: ${result.status}');

      switch (result.status) {
        case AdminAuthorizationStatus.authorized:
          debugPrint('[SplashController] authorized — navigating to dashboard');
          Get.offAllNamed(AppRoutes.dashboard);

        case AdminAuthorizationStatus.notFound:
          debugPrint(
            '[SplashController] notFound — signing out and navigating to login',
          );
          await auth.signOut();
          Get.offAllNamed(AppRoutes.login);
          _setLoginError(AppStrings.authStartupNotFound);

        case AdminAuthorizationStatus.inactive:
          debugPrint(
            '[SplashController] inactive — signing out and navigating to login',
          );
          await auth.signOut();
          Get.offAllNamed(AppRoutes.login);
          _setLoginError(AppStrings.authStartupInactive);

        case AdminAuthorizationStatus.error:
          // Security: never grant Dashboard access when authorization state is
          // unknown. Sign out so the session is clean and the user can retry.
          // Rationale: keeping the user signed in while showing Login would
          // leave a live Firebase session with no confirmed admin record —
          // that session could be exploited if other routes are added later.
          debugPrint(
            '[SplashController] error — signing out and navigating to login',
          );
          await auth.signOut();
          Get.offAllNamed(AppRoutes.login);
          _setLoginError(AppStrings.authStartupError);
      }
    } catch (e, st) {
      // Log the full exception in debug builds so the root cause is visible
      // in the Chrome DevTools / IDE console.
      debugPrint('[SplashController] ERROR in _checkAuthAndNavigate: $e');
      debugPrint('[SplashController] StackTrace: $st');

      // Fail-safe: never leave the app permanently on SplashView.
      Get.offAllNamed(AppRoutes.login);
    }
  }

  // ── Private helpers ─────────────────────────────────────────────────────────

  /// Forwards [message] to [LoginController.authError] so the Login screen
  /// immediately displays the startup authorization failure reason.
  ///
  /// [LoginBinding] puts [LoginController] into the GetX container synchronously
  /// when [Get.offAllNamed(AppRoutes.login)] resolves, so [Get.find] is safe
  /// to call immediately after the navigation statement.
  ///
  /// Wrapped in a try/catch so a missing controller (e.g. in tests where
  /// LoginBinding has not run) never prevents the navigation from completing.
  void _setLoginError(String message) {
    try {
      Get.find<LoginController>().authError.value = message;
      debugPrint('[SplashController] authError set: $message');
    } catch (_) {
      // LoginController not yet registered — message delivery skipped.
      // Navigation has already completed; the user is on Login.
      debugPrint(
        '[SplashController] LoginController not found — skipping authError',
      );
    }
  }
}
