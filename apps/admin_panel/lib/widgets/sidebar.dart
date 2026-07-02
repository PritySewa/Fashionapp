import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:authentication/authentication.dart';

class Sidebar extends ConsumerWidget {
  final String currentRoute;
  final bool isCollapsed;

  const Sidebar({super.key, required this.currentRoute, this.isCollapsed = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: isCollapsed ? 80 : 250,
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_bag, color: Colors.white, size: 28),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                const Text(
                  'Enterprise',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ]
            ],
          ),
          const SizedBox(height: 48),
          _NavItem(
            icon: Icons.dashboard,
            label: 'Dashboard',
            isSelected: currentRoute == '/',
            isCollapsed: isCollapsed,
            onTap: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go('/');
            },
          ),
          _NavItem(
            icon: Icons.inventory_2,
            label: 'Products',
            isSelected: currentRoute.startsWith('/products'),
            isCollapsed: isCollapsed,
            onTap: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go('/products');
            },
          ),
          _NavItem(
            icon: Icons.shopping_cart,
            label: 'Orders',
            isSelected: currentRoute.startsWith('/orders'),
            isCollapsed: isCollapsed,
            onTap: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go('/orders');
            },
          ),
          _NavItem(
            icon: Icons.campaign,
            label: 'Marketing',
            isSelected: currentRoute.startsWith('/marketing'),
            isCollapsed: isCollapsed,
            onTap: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go('/marketing');
            },
          ),
          _NavItem(
            icon: Icons.category,
            label: 'Categories',
            isSelected: currentRoute.startsWith('/categories'),
            isCollapsed: isCollapsed,
            onTap: () {
              if (Scaffold.of(context).hasDrawer && Scaffold.of(context).isDrawerOpen) {
                Navigator.of(context).pop();
              }
              context.go('/categories');
            },
          ),
          const Spacer(),
          _NavItem(
            icon: Icons.logout,
            label: 'Sign Out',
            isSelected: false,
            isCollapsed: isCollapsed,
            onTap: () async {
              await ref.read(authRepositoryProvider).signOut();
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? Colors.white : Colors.white54;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 24, vertical: 16),
        alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            if (!isCollapsed) ...[
              const SizedBox(width: 16),
              Text(
                label,
                style: TextStyle(color: color, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
