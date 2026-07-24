import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class StorageEmulatorConfig {
  const StorageEmulatorConfig({required this.host, required this.port});

  final String host;
  final int port;
}

class AppFirebaseInitializer {
  static const int _storageEmulatorPort = 9199;

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    final emulatorConfig = resolveStorageEmulatorConfig(
      isDebug: kDebugMode,
      isWeb: kIsWeb,
      baseHost: _resolveHost(),
    );

    if (emulatorConfig != null) {
      await FirebaseStorage.instance.useStorageEmulator(
        emulatorConfig.host,
        emulatorConfig.port,
      );
      // NOTE: Firestore emulator is intentionally NOT used here so that
      // production data and admin authorization rules remain active.
    }
  }

  static StorageEmulatorConfig? resolveStorageEmulatorConfig({
    required bool isDebug,
    required bool isWeb,
    required String baseHost,
  }) {
    if (!isDebug || !isWeb) {
      return null;
    }

    final normalizedHost = baseHost.toLowerCase();
    if (!normalizedHost.contains('localhost') &&
        !normalizedHost.contains('127.0.0.1')) {
      return null;
    }

    return const StorageEmulatorConfig(
      host: 'localhost',
      port: _storageEmulatorPort,
    );
  }

  static String _resolveHost() {
    if (kIsWeb) {
      return Uri.base.host;
    }

    if (Platform.isAndroid ||
        Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      return 'localhost';
    }

    return 'localhost';
  }
}
