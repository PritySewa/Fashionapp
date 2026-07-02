import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/product_repository.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return FirebaseProductRepository();
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  return ref.watch(productRepositoryProvider).watchProducts();
});

final productVariantsProvider = StreamProvider.family<List<ProductVariant>, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).watchVariants(productId);
});
