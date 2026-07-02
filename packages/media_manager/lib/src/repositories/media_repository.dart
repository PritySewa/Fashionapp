import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

abstract class MediaRepository {
  Future<String> uploadProductMedia(String productId, String fileName, Uint8List bytes);
}

class FirebaseMediaRepository implements MediaRepository {
  final FirebaseStorage _storage;

  FirebaseMediaRepository({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  @override
  Future<String> uploadProductMedia(String productId, String fileName, Uint8List bytes) async {
    final ref = _storage.ref().child('products').child(productId).child(fileName);
    
    final metadata = SettableMetadata(
      contentType: _getContentType(fileName),
    );
    
    final uploadTask = await ref.putData(bytes, metadata);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
  
  String _getContentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}
