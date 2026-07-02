import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/media_repository.dart';

final mediaRepositoryProvider = Provider<MediaRepository>((ref) {
  return FirebaseMediaRepository();
});
