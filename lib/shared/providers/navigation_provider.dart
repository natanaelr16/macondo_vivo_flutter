import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  String _currentRoute = '/dashboard';

  String get currentRoute => _currentRoute;

  void setCurrentRoute(String route) {
    if (_currentRoute != route) {
      _currentRoute = route;
      notifyListeners();
    }
  }

  bool isActiveRoute(String route) {
    return _currentRoute == route;
  }
} 