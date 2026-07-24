import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../../core/enums/admin_authorization_status.dart';
import '../models/admin_model.dart';

/// Repository responsible for all Firestore operations on the [admins]
/// collection.
///
/// Registered permanently at the application level via [AppBinding] so that
/// [SplashController] and [LoginController] can resolve it via
/// `Get.find<AdminRepository>()` in later phases without re-creating the
/// Firestore handle.
///
/// Architecture:
/// ```
/// Controller
///   ↓
/// AdminRepository
///   ↓
/// Cloud Firestore  admins/{uid}
///   ↓
/// AdminModel + AdminAuthorizationStatus
/// ```
///
/// ## Testing strategy
///
/// Firestore I/O is confined to [checkAuthorization].
/// The authorization decision is extracted into the pure static method
/// [resolveStatus], which accepts only plain Dart values and can therefore
/// be unit-tested without any Firestore stubs, fakes, or extra packages.
class AdminRepository {
  AdminRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'admins';

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Looks up [uid] in the Firestore [admins] collection and returns an
  /// authorization result.
  ///
  /// The returned record always contains a non-null [status].
  /// [admin] is non-null only when [status] is
  /// [AdminAuthorizationStatus.authorized] or
  /// [AdminAuthorizationStatus.inactive].
  ///
  /// This method never throws — all Firestore exceptions are caught and mapped
  /// to [AdminAuthorizationStatus.error].
  Future<({AdminAuthorizationStatus status, AdminModel? admin})>
  checkAuthorization(String uid) async {
    try {
      debugPrint('[AdminRepository] checkAuthorization uid=$uid');

      final snapshot = await _firestore.collection(_collection).doc(uid).get();

      if (!snapshot.exists) {
        debugPrint('[AdminRepository] uid=$uid → notFound');
        return (status: AdminAuthorizationStatus.notFound, admin: null);
      }

      // snapshot is already DocumentSnapshot<Map<String, dynamic>> because
      // collection() returns CollectionReference<Map<String, dynamic>>.
      final admin = AdminModel.fromFirestore(snapshot);

      final status = resolveStatus(documentExists: true, model: admin);
      debugPrint('[AdminRepository] uid=$uid → $status');

      return (status: status, admin: admin);
    } catch (e, st) {
      debugPrint('[AdminRepository] ERROR uid=$uid: $e');
      debugPrint('[AdminRepository] StackTrace: $st');
      return (status: AdminAuthorizationStatus.error, admin: null);
    }
  }

  // ── Pure authorization decision ────────────────────────────────────────────

  /// Determines the [AdminAuthorizationStatus] from document presence and
  /// model data alone.
  ///
  /// This is a **pure function**: it performs no I/O and has no external
  /// dependencies. It exists as a separate static method so that the
  /// authorization decision logic can be unit-tested with plain Dart values —
  /// no Firestore mocks, fakes, or additional test packages required.
  ///
  /// | [documentExists] | [model]        | Result       |
  /// |------------------|----------------|--------------|
  /// | `false`          | `null`         | `notFound`   |
  /// | `true`           | `null`         | `notFound`   |
  /// | `true`           | isActive=false | `inactive`   |
  /// | `true`           | isActive=true  | `authorized` |
  static AdminAuthorizationStatus resolveStatus({
    required bool documentExists,
    required AdminModel? model,
  }) {
    if (!documentExists || model == null) {
      return AdminAuthorizationStatus.notFound;
    }
    if (!model.isActive) {
      return AdminAuthorizationStatus.inactive;
    }
    return AdminAuthorizationStatus.authorized;
  }
}
