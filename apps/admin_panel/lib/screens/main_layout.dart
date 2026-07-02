import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:core/core.dart';
import '../widgets/sidebar.dart';
import '../widgets/topbar.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String currentRoute = GoRouterState.of(context).uri.toString();

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenType = getDeviceScreenType(constraints.maxWidth);
        final isMobile = screenType == DeviceScreenType.mobile;
        final isTablet = screenType == DeviceScreenType.tablet;

        return Scaffold(
          appBar: const TopBar(),
          drawer: isMobile ? Drawer(child: Sidebar(currentRoute: currentRoute)) : null,
          body: Row(
            children: [
              if (!isMobile)
                Sidebar(
                  currentRoute: currentRoute,
                  isCollapsed: isTablet,
                ),
              Expanded(
                child: child,
              ),
            ],
          ),
        );
      },
    );
  }
}
