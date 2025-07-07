import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  String _currentRoute = '/dashboard';
  bool _isMinimized = false;
  bool _isTransitioning = false;
  String _previousRoute = '/dashboard';

  String get currentRoute => _currentRoute;
  bool get isMinimized => _isMinimized;
  bool get isTransitioning => _isTransitioning;
  String get previousRoute => _previousRoute;

  void setCurrentRoute(String route) {
    // Evitar actualizaciones innecesarias
    if (_currentRoute == route) return;
    
    _previousRoute = _currentRoute;
    _currentRoute = route;
    
    // Iniciar transición suave
    _startTransition();
    
    // Actualizar estado minimizado después de un delay (10% más rápido)
    Future.delayed(const Duration(milliseconds: 270), () { // 300 * 0.9
      _isMinimized = route != '/dashboard';
      _isTransitioning = false;
      notifyListeners();
    });
  }

  void _startTransition() {
    _isTransitioning = true;
    notifyListeners();
  }

  void toggleMinimized() {
    if (!_isTransitioning) {
      _isMinimized = !_isMinimized;
      notifyListeners();
    }
  }

  void setMinimized(bool minimized) {
    if (!_isTransitioning && _isMinimized != minimized) {
      _isMinimized = minimized;
      notifyListeners();
    }
  }

  bool isActiveRoute(String route) {
    return _currentRoute == route;
  }

  // Método para navegación suave
  void navigateTo(String route) {
    if (_currentRoute == route) return;
    
    _startTransition();
    _previousRoute = _currentRoute;
    _currentRoute = route;
    
    // Actualizar estado minimizado con delay (10% más rápido)
    Future.delayed(const Duration(milliseconds: 360), () { // 400 * 0.9
      _isMinimized = route != '/dashboard';
      _isTransitioning = false;
      notifyListeners();
    });
  }

  // Método para forzar la actualización del estado sin transición
  void forceUpdateState(String route) {
    _currentRoute = route;
    _isMinimized = route != '/dashboard';
    _isTransitioning = false;
    notifyListeners();
  }
} 