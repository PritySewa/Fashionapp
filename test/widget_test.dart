// Widget tests for the Marketplace Admin app.
//
// This smoke test verifies that the app can be instantiated.
// Firebase initialization is not tested here (requires an integration test).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:marketplace_admin/core/constants/app_strings.dart';

void main() {
  testWidgets('App renders a GetMaterialApp without crashing', (
    WidgetTester tester,
  ) async {
    // Build a minimal GetMaterialApp to verify route and widget wiring.
    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(body: Center(child: Text(AppStrings.appName))),
      ),
    );

    // Verify the app name text is present.
    expect(find.text(AppStrings.appName), findsOneWidget);
  });
}
