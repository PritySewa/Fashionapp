import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/review_model.dart';

/// Repository for Firestore operations on the [reviews] collection.
class ReviewRepository {
  ReviewRepository({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'reviews';

  CollectionReference<Map<String, dynamic>> get _ref =>
      _firestore.collection(_collection);

  /// Streams all customer reviews ordered by creation date (newest first).
  Stream<List<ReviewModel>> watchReviews() {
    return _ref.orderBy('createdAt', descending: true).snapshots().map((snap) {
      final list = snap.docs.map(ReviewModel.fromFirestore).toList();
      debugPrint('[ReviewRepository] watchReviews emitted ${list.length} reviews');
      return list;
    });
  }

  /// Updates the moderation [status] of review [id].
  Future<void> updateReviewStatus(String id, ReviewStatus status) async {
    debugPrint('[ReviewRepository] updateReviewStatus id=$id status=${status.value}');
    await _ref.doc(id).update({
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Permanently deletes review document [id].
  Future<void> deleteReview(String id) async {
    debugPrint('[ReviewRepository] deleteReview id=$id');
    await _ref.doc(id).delete();
  }
}
