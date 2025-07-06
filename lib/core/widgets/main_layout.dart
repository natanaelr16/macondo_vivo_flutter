import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/auth_provider.dart';
import '../../shared/providers/navigation_provider.dart';
import 'fixed_bottom_navigation.dart';

class MainLayout extends StatelessWidget {
  final Widget child;
  final String route;
  final bool hideBottomNavigation;

  const MainLayout({
    super.key,
    required this.child,
    required this.route,
    this.hideBottomNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Solo mostrar navbar si el usuario está autenticado y no está oculto
        if (!authProvider.isAuthenticated || hideBottomNavigation) {
          return this.child;
        }

        return Scaffold(
          body: this.child,
          bottomNavigationBar: const FixedBottomNavigation(),
        );
      },
    );
  }
} 