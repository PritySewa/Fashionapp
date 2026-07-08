import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_binding.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase is already connected — do NOT modify these two lines.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MarketplaceAdminApp());
}

/// Root application widget.
///
/// [initialBinding] runs [AppBinding] before any route is built, registering
/// application-level dependencies (e.g. [AuthRepository]) permanently so they
/// survive [Get.offAllNamed()] calls and remain available app-wide.
class MarketplaceAdminApp extends StatelessWidget {
  const MarketplaceAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Marketplace Admin',
      debugShowCheckedModeBanner: false,

      // ── App-level dependencies ──────────────────────────────────────────────
      initialBinding: AppBinding(),

      // ── Themes ──────────────────────────────────────────────────────────────
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ── Routing ─────────────────────────────────────────────────────────────
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,

      // ── Default transition ───────────────────────────────────────────────────
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 250),
    );
  }
}
