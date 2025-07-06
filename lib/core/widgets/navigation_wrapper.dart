import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/navigation_provider.dart';

class NavigationWrapper extends StatefulWidget {
  final Widget child;
  final String route;

  const NavigationWrapper({
    super.key,
    required this.child,
    required this.route,
  });

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  @override
  void initState() {
    super.initState();
    // Actualizar la ruta actual cuando se inicializa el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().setCurrentRoute(widget.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
} 