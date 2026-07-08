// Widget tests for Marketplace Admin — Phase 2B
//
// Tests cover LoginView rendering, field presence, form validation,
// and controller reactive state.
// Firebase Authentication is NOT tested here (requires integration tests
// with real credentials). LoginController is tested with a mock/stub.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/core/constants/app_strings.dart';
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

// ── Helper ────────────────────────────────────────────────────────────────────

Widget _buildLoginView() {
  // Register stub dependencies before building the view.
  Get.put<AuthRepository>(_StubAuthRepository(), permanent: true);
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
