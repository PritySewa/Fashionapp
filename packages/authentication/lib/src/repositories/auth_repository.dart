import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';

abstract class AuthRepository {
  Stream<User?> get authStateChanges;
  User? get currentUser;
  Future<AppUser?> getAppUser(String uid);
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signOut();
}

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Future<AppUser?> getAppUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return AppUser.fromJson({'uid': uid, ...doc.data()!});
      }
      
      final fbUser = _auth.currentUser;
      if (fbUser != null && fbUser.uid == uid) {
          final idTokenResult = await fbUser.getIdTokenResult(true);
          final role = idTokenResult.claims?['role'] as String? ?? 'customer';
          return AppUser(
            uid: uid, 
            email: fbUser.email ?? '', 
            displayName: fbUser.displayName,
            photoUrl: fbUser.photoURL,
            role: role,
          );
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
