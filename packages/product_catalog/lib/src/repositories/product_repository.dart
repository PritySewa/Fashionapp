import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

abstract class ProductRepository {
  Stream<List<Product>> watchProducts();
  Future<Product?> getProduct(String id);
  Future<void> saveProduct(Product product);
  
  Stream<List<ProductVariant>> watchVariants(String productId);
  Future<void> saveVariant(String productId, ProductVariant variant);
  Future<void> deleteVariant(String productId, String variantId);
}

class FirebaseProductRepository implements ProductRepository {
  final FirebaseFirestore _firestore;

  FirebaseProductRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<List<Product>> watchProducts() {
    return _firestore.collection('products').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Product.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  @override
  Future<Product?> getProduct(String id) async {
    final doc = await _firestore.collection('products').doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return Product.fromJson({'id': doc.id, ...doc.data()!});
  }

  @override
  Future<void> saveProduct(Product product) async {
    final data = product.toJson();
    data.remove('id'); // ID is the document key, not stored in data payload if possible, but keeping it is fine. Here we remove it for cleaner db.
    await _firestore.collection('products').doc(product.id).set(data, SetOptions(merge: true));
  }

  @override
  Stream<List<ProductVariant>> watchVariants(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProductVariant.fromJson({'id': doc.id, ...doc.data()}))
          .toList();
    });
  }

  @override
  Future<void> saveVariant(String productId, ProductVariant variant) async {
    final data = variant.toJson();
    data.remove('id');
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .doc(variant.id)
        .set(data, SetOptions(merge: true));
  }

  @override
  Future<void> deleteVariant(String productId, String variantId) async {
    await _firestore
        .collection('products')
        .doc(productId)
        .collection('variants')
        .doc(variantId)
        .delete();
  }
}
