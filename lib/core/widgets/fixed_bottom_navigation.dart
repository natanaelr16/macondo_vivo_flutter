import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/navigation_provider.dart';

class FixedBottomNavigation extends StatelessWidget {
  const FixedBottomNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, NavigationProvider>(
      builder: (context, authProvider, navigationProvider, child) {
        final canManageUsers = authProvider.canManageUsers;
        final currentRoute = navigationProvider.currentRoute;
        
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavigationItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: currentRoute == '/dashboard',
                    onTap: () => _navigateTo('/dashboard', context),
                  ),
                  if (canManageUsers)
                    _NavigationItem(
                      icon: Icons.people_rounded,
                      label: 'Usuarios',
                      isActive: currentRoute == '/users',
                      onTap: () => _navigateTo('/users', context),
                    ),
                  _NavigationItem(
                    icon: Icons.school_rounded,
                    label: 'Actividades',
                    isActive: currentRoute == '/activities',
                    onTap: () => _navigateTo('/activities', context),
                  ),
                  _NavigationItem(
                    icon: Icons.analytics_rounded,
                    label: 'Reportes',
                    isActive: currentRoute == '/reports',
                    onTap: () => _navigateTo('/reports', context),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateTo(String route, BuildContext context) {
    // Actualizar el provider y navegar
    context.read<NavigationProvider>().setCurrentRoute(route);
    context.go(route);
  }
}

class _NavigationItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive 
            ? Theme.of(context).colorScheme.primaryContainer
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive 
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive 
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 