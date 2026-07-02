import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';

abstract class MarketingRepository {
  Stream<List<Coupon>> watchCoupons();
  Future<void> createCoupon(Coupon coupon);
  Future<bool> validateCoupon(String code, double orderTotal);
}

class FirebaseMarketingRepository implements MarketingRepository {
  final FirebaseFirestore _firestore;

  FirebaseMarketingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Coupon>> watchCoupons() {
    return _firestore.collection('coupons').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Coupon.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  @override
  Future<void> createCoupon(Coupon coupon) async {
    final data = coupon.toJson();
    data.remove('id');
    await _firestore.collection('coupons').doc(coupon.id).set(data);
  }

  @override
  Future<bool> validateCoupon(String code, double orderTotal) async {
    final doc = await _firestore.collection('coupons').doc(code).get();
    if (!doc.exists || doc.data() == null) return false;
    final coupon = Coupon.fromJson({'id': doc.id, ...doc.data()!});
    
    if (!coupon.isActive) return false;
    if (coupon.expiryDate.isBefore(DateTime.now())) return false;
    if (coupon.maxUses != null && coupon.timesUsed >= coupon.maxUses!) return false;
    if (coupon.minOrderValue != null && orderTotal < coupon.minOrderValue!) return false;
    
    return true;
  }
}
