import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_admin/core/firebase/firebase_init.dart';

void main() {
  group('AppFirebaseInitializer.resolveStorageEmulatorConfig', () {
    test('returns config for local web debug runs', () {
      final config = AppFirebaseInitializer.resolveStorageEmulatorConfig(
        isDebug: true,
        isWeb: true,
        baseHost: 'localhost',
      );

      expect(config, isNotNull);
      expect(config!.host, 'localhost');
      expect(config.port, 9199);
    });

    test('returns null for non-localhost web debug runs', () {
      final config = AppFirebaseInitializer.resolveStorageEmulatorConfig(
        isDebug: true,
        isWeb: true,
        baseHost: 'example.com',
      );

      expect(config, isNull);
    });

    test('returns null outside debug mode', () {
      final config = AppFirebaseInitializer.resolveStorageEmulatorConfig(
        isDebug: false,
        isWeb: true,
        baseHost: 'localhost',
      );

      expect(config, isNull);
    });
  });
}
