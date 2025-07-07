import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/navigation_provider.dart';

class FixedBottomNavigation extends StatefulWidget {
  const FixedBottomNavigation({super.key});

  @override
  State<FixedBottomNavigation> createState() => _FixedBottomNavigationState();
}

class _FixedBottomNavigationState extends State<FixedBottomNavigation> {
  @override
  void initState() {
    super.initState();
    // Sincronizar el estado del provider con la ruta actual
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentRoute = GoRouterState.of(context).matchedLocation;
      context.read<NavigationProvider>().forceUpdateState(currentRoute);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, NavigationProvider>(
      builder: (context, authProvider, navigationProvider, child) {
        final canManageUsers = authProvider.canManageUsers;
        // Obtener la ruta actual del router
        final currentRoute = GoRouterState.of(context).matchedLocation;
        final isMinimized = navigationProvider.isMinimized;
        final isTransitioning = navigationProvider.isTransitioning;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 864),
          curve: Curves.easeInOutCubic,
          height: isMinimized ? 48 : 62,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isMinimized ? 4 : 6,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavigationItem(
                    icon: Icons.dashboard_rounded,
                    label: 'Dashboard',
                    isActive: currentRoute == '/dashboard',
                    isMinimized: isMinimized,
                    isTransitioning: isTransitioning,
                    onTap: () => _navigateTo('/dashboard', context),
                  ),
                  if (canManageUsers)
                    _NavigationItem(
                      icon: Icons.people_rounded,
                      label: 'Usuarios',
                      isActive: currentRoute == '/users',
                      isMinimized: isMinimized,
                      isTransitioning: isTransitioning,
                      onTap: () => _navigateTo('/users', context),
                    ),
                  _NavigationItem(
                    icon: Icons.school_rounded,
                    label: 'Actividades',
                    isActive: currentRoute == '/activities',
                    isMinimized: isMinimized,
                    isTransitioning: isTransitioning,
                    onTap: () => _navigateTo('/activities', context),
                  ),
                  _NavigationItem(
                    icon: Icons.analytics_rounded,
                    label: 'Reportes',
                    isActive: currentRoute == '/reports',
                    isMinimized: isMinimized,
                    isTransitioning: isTransitioning,
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
    final navigationProvider = context.read<NavigationProvider>();
    
    // Solo navegar si no estamos ya en esa ruta
    if (navigationProvider.currentRoute != route) {
      // Iniciar transición en el provider
      navigationProvider.navigateTo(route);
      
      // Navegar con delay para permitir la animación
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted && context.mounted) {
          context.go(route);
        }
      });
    }
  }
}

class _NavigationItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isMinimized;
  final bool isTransitioning;
  final VoidCallback onTap;

  const _NavigationItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.isMinimized,
    required this.isTransitioning,
    required this.onTap,
  });

  @override
  State<_NavigationItem> createState() => _NavigationItemState();
}

class _NavigationItemState extends State<_NavigationItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 144),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) => _animationController.reverse(),
      onTapCancel: () => _animationController.reverse(),
      onTap: () {
        // Ejecutar la navegación
        widget.onTap();
      },
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 864),
              curve: Curves.easeInOutCubic,
              padding: EdgeInsets.symmetric(
                horizontal: widget.isMinimized ? 8 : 10,
                vertical: widget.isMinimized ? 6 : 4,
              ),
              decoration: BoxDecoration(
                color: widget.isActive 
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Colors.transparent,
                borderRadius: BorderRadius.circular(widget.isMinimized ? 12 : 16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icono con animación de escala suave
                  AnimatedScale(
                    duration: const Duration(milliseconds: 864),
                    curve: Curves.easeInOutCubic,
                    scale: widget.isMinimized ? 1.2 : 1.0,
                    child: Icon(
                      widget.icon,
                      size: 22,
                      color: widget.isActive 
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  
                  // Texto con animación suave
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 864),
                    curve: Curves.easeInOutCubic,
                    height: widget.isMinimized ? 0 : 16,
                    child: widget.isMinimized 
                      ? const SizedBox.shrink()
                      : AnimatedOpacity(
                          duration: const Duration(milliseconds: 576),
                          curve: Curves.easeInOutCubic,
                          opacity: 1.0,
                          child: Text(
                            widget.label,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
                              color: widget.isActive 
                                ? Theme.of(context).colorScheme.onPrimaryContainer
                                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
} 