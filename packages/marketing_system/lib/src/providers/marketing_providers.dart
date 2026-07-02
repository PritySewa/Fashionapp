import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/marketing_repository.dart';
import '../models/coupon.dart';

final marketingRepositoryProvider = Provider<MarketingRepository>((ref) {
  return FirebaseMarketingRepository();
});

final couponsProvider = StreamProvider<List<Coupon>>((ref) {
  return ref.watch(marketingRepositoryProvider).watchCoupons();
});
