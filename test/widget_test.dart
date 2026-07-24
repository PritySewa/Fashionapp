// Widget tests for Marketplace Admin — Phase 2B / 2C.3
//
// Tests cover LoginView rendering, field presence, form validation,
// and controller reactive state.
//
// Firebase Authentication is NOT tested here (requires integration tests
// with real credentials). LoginController is tested with stubs for both
// AuthRepository and AdminRepository.
//
// ## Phase 2C.3 note
//
// LoginController now calls Get.find<AdminRepository>() at field-initializer
// time (controller construction). A _StubAdminRepository is therefore
// registered before LoginController in _buildLoginView(). The stub's
// checkAuthorization() always returns notFound, which is irrelevant to the
// existing UI/form tests because those tests never successfully complete a
// Firebase sign-in — the stub FirebaseAuth always throws invalid-credential.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/core/constants/app_strings.dart';
import 'package:marketplace_admin/core/enums/admin_authorization_status.dart';
import 'package:marketplace_admin/features/admin/models/admin_model.dart';
import 'package:marketplace_admin/features/admin/repositories/admin_repository.dart';
import 'package:marketplace_admin/features/auth/controllers/login_controller.dart';
import 'package:marketplace_admin/features/auth/repositories/auth_repository.dart';
import 'package:marketplace_admin/features/auth/views/login_view.dart';

// ── Stub AuthRepository ───────────────────────────────────────────────────────
// Avoids real Firebase calls in widget tests.

class _StubAuthRepository extends AuthRepository {
  _StubAuthRepository() : super(auth: _stubAuth);

  static final _stubAuth = _FakeFirebaseAuth();
}

// Minimal FirebaseAuth stand-in that never calls Firebase servers.
class _FakeFirebaseAuth extends Fake implements FirebaseAuth {
  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    throw FirebaseAuthException(code: 'invalid-credential');
  }

  @override
  Future<void> signOut() async {}
}

// ── Stub AdminRepository ──────────────────────────────────────────────────────
// Required because LoginController now resolves AdminRepository via Get.find
// at construction time. This stub never calls Firestore.
//
// checkAuthorization always returns notFound — which is safe for all existing
// widget tests because they never reach a successful Firebase sign-in
// (the FakeFirebaseAuth always throws invalid-credential).

class _StubAdminRepository extends AdminRepository {
  _StubAdminRepository() : super(firestore: _FakeFirestore());

  @override
  Future<({AdminAuthorizationStatus status, AdminModel? admin})>
  checkAuthorization(String uid) async {
    // Stub: always returns notFound. Not reached in existing widget tests
    // because Firebase sign-in always fails first.
    return (status: AdminAuthorizationStatus.notFound, admin: null);
  }
}

// Minimal Firestore stand-in — only exists to satisfy the AdminRepository
// constructor; its methods are never called via the stub override above.
class _FakeFirestore extends Fake implements FirebaseFirestore {}

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildLoginView() {
  // Register stub dependencies before building the view.
  // Order matters: AuthRepository and AdminRepository must be registered
  // before LoginController, which resolves both via Get.find at init time.
  Get.put<AuthRepository>(_StubAuthRepository(), permanent: true);
  Get.put<AdminRepository>(_StubAdminRepository(), permanent: true);
  Get.put<LoginController>(LoginController());

  return const GetMaterialApp(home: LoginView());
}

void setUp() {
  // Reset GetX between tests.
  Get.reset();
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  tearDown(() => Get.reset());

  // ── Smoke test ─────────────────────────────────────────────────────────────
  testWidgets('App renders GetMaterialApp without crashing', (tester) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: Center(child: Text(AppStrings.appName))),
      ),
    );
    expect(find.text(AppStrings.appName), findsOneWidget);
  });

  // ── LoginView rendering ────────────────────────────────────────────────────
  testWidgets('LoginView renders without crashing', (tester) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();
    // View should be on screen
    expect(find.byType(LoginView), findsOneWidget);
  });

  testWidgets('LoginView contains email field', (tester) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('emailField')), findsOneWidget);
  });

  testWidgets('LoginView contains password field', (tester) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
  });

  testWidgets('LoginView contains login button', (tester) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });

  testWidgets('LoginView shows app name and heading', (tester) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.appName), findsOneWidget);
    expect(find.text(AppStrings.loginHeading), findsOneWidget);
  });

  // ── Form validation ────────────────────────────────────────────────────────
  testWidgets('Empty form shows email and password validation errors', (
    tester,
  ) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();

    // Tap login with empty fields
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    // Both validation errors should appear
    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Invalid email format shows validation error', (tester) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();

    // Enter invalid email
    await tester.enterText(find.byKey(const Key('emailField')), 'notanemail');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  // ── Password visibility ────────────────────────────────────────────────────
  testWidgets('Password visibility toggle changes obscurePassword state', (
    tester,
  ) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();

    final controller = Get.find<LoginController>();

    // Initially obscured
    expect(controller.obscurePassword.value, isTrue);

    // Tap the visibility icon
    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    // Now visible
    expect(controller.obscurePassword.value, isFalse);

    // Tap again to hide
    await tester.tap(find.byIcon(Icons.visibility_off_outlined));
    await tester.pumpAndSettle();

    expect(controller.obscurePassword.value, isTrue);
  });

  // ── Remember Me ────────────────────────────────────────────────────────────
  testWidgets('Remember Me checkbox toggles state', (tester) async {
    await tester.pumpWidget(_buildLoginView());
    await tester.pumpAndSettle();

    final controller = Get.find<LoginController>();
    expect(controller.rememberMe.value, isFalse);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(controller.rememberMe.value, isTrue);
  });
}
