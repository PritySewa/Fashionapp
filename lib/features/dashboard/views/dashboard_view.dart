import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/dashboard_controller.dart';
import '../widgets/admin_shell.dart';

/// Top-level view for the /dashboard route.
///
/// Delegates entirely to [AdminShell] for layout. All navigation state is
/// driven by [DashboardController.selectedIndex].
class DashboardView extends GetView<DashboardController> {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminShell();
  }
}
