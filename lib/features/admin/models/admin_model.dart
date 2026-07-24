import 'package:cloud_firestore/cloud_firestore.dart';

/// Immutable snapshot of a single document from the Firestore [admins]
/// collection.
///
/// Firestore document structure:
/// ```
/// admins/{firebaseAuthUid}   ← document ID = Firebase Auth UID
///   email:       String
///   displayName: String
///   role:        String      (e.g. 'admin')
///   isActive:    bool
///   createdAt:   Timestamp
/// ```
///
/// The Firebase Auth UID is the Firestore document ID and is stored in [uid]
/// via [DocumentSnapshot.id]. It is NOT stored as a separate field inside the
/// document body, and [toMap] therefore excludes it.
class AdminModel {
  const AdminModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  /// The Firebase Auth UID — matches the Firestore document ID.
  final String uid;

  /// The admin's email address.
  final String email;

  /// The admin's display name.
  final String displayName;

  /// The admin's role string (e.g. `'admin'`).
  /// Additional role types may be defined in later phases.
  final String role;

  /// Whether the admin account is currently active.
  /// Inactive accounts are rejected by [AdminRepository.checkAuthorization].
  final bool isActive;

  /// When this admin document was created.
  final DateTime createdAt;

  // ── Serialization ───────────────────────────────────────────────────────────

  /// Creates an [AdminModel] from a Firestore document snapshot.
  ///
  /// [snapshot] must exist and must contain valid data; callers (i.e.
  /// [AdminRepository]) are responsible for checking [DocumentSnapshot.exists]
  /// before calling this factory.
  ///
  /// Missing or wrongly-typed fields fall back to safe defaults so that a
  /// partially-written document does not cause a runtime crash.
  factory AdminModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    return AdminModel(
      uid: snapshot.id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? '',
      role: data['role'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// Converts this model to a plain map suitable for Firestore writes.
  ///
  /// [uid] is intentionally excluded because it is stored as the document ID,
  /// not as a field inside the document body.
  Map<String, dynamic> toMap() => {
    'email': email,
    'displayName': displayName,
    'role': role,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };

  @override
  String toString() =>
      'AdminModel(uid: $uid, email: $email, role: $role, isActive: $isActive)';
}
