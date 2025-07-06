import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../shared/providers/auth_provider.dart';
import 'fixed_bottom_navigation.dart';

class ActivitiesLayout extends StatefulWidget {
  final Widget child;

  const ActivitiesLayout({
    super.key,
    required this.child,
  });

  @override
  State<ActivitiesLayout> createState() => _ActivitiesLayoutState();
}

class _ActivitiesLayoutState extends State<ActivitiesLayout>
    with SingleTickerProviderStateMixin {
  bool _isCalendarView = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    // Iniciar la animación cuando se monta el widget
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // Solo mostrar navbar si el usuario está autenticado y no está en vista de calendario
        if (!authProvider.isAuthenticated || _isCalendarView) {
          return FadeTransition(
            opacity: _fadeAnimation,
            child: this.widget.child,
          );
        }

        return Scaffold(
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: this.widget.child,
          ),
          bottomNavigationBar: const FixedBottomNavigation(),
        );
      },
    );
  }

  void setCalendarView(bool isCalendarView) {
    setState(() {
      _isCalendarView = isCalendarView;
    });
  }
} 