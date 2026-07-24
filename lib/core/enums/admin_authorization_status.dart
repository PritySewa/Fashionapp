/// Describes the result of checking whether a Firebase-authenticated user
/// exists and is active in the Firestore [admins] collection.
///
/// Used as the [status] field of the record returned by
/// [AdminRepository.checkAuthorization].
enum AdminAuthorizationStatus {
  /// The Firestore [admins] document exists and [AdminModel.isActive] is true.
  /// The user is permitted to access the admin panel.
  authorized,

  /// No Firestore document exists for this Firebase Auth UID.
  /// The authenticated user is not registered as an admin.
  notFound,

  /// A Firestore document exists but [AdminModel.isActive] is false.
  /// The account has been deactivated by an administrator.
  inactive,

  /// An unexpected exception occurred while querying Firestore.
  /// The authorization state could not be determined.
  error,
}
