import 'package:firebase_auth/firebase_auth.dart';

/// Repository that wraps [FirebaseAuth] as the single source of truth
/// for all authentication operations.
///
/// Registered once at the application level via [AppBinding] with
/// `permanent: true`, so it survives route replacements and is available
/// everywhere via `Get.find<AuthRepository>()`.
///
/// Architecture:
///   UI → GetX Controller → AuthRepository → FirebaseAuth
///
/// Phase 2A exposes:
///   - [currentUser]        — synchronous snapshot of the signed-in user
///   - [authStateChanges]   — stream of auth-state events
///   - [signInWithEmailAndPassword] — email/password sign-in
///   - [signOut]            — sign-out
class AuthRepository {
  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  // ── Read ───────────────────────────────────────────────────────────────────

  /// Synchronous snapshot of the currently signed-in [User], or `null`
  /// if no user is authenticated.
  User? get currentUser => _auth.currentUser;

  /// A stream that emits a [User] whenever the auth state changes
  /// (sign-in, sign-out, token refresh).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Write ──────────────────────────────────────────────────────────────────

  /// Signs in with [email] and [password].
  ///
  /// Throws a [FirebaseAuthException] on failure; callers should handle it.
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) => _auth.signInWithEmailAndPassword(email: email, password: password);

  /// Signs out the currently authenticated user.
  Future<void> signOut() => _auth.signOut();
}
