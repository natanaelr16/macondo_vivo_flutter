import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    print('AuthProvider: Initializing...');
    
    // Check current user immediately
    _user = _authService.currentUser;
    print('AuthProvider: Current user on init: ${_user?.email}');
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      print('AuthProvider: Auth state changed - User: ${user?.email}');
      _user = user;
      notifyListeners();
    });
  }

  Future<bool> signIn(String email, String password) async {
    print('AuthProvider: Attempting sign in for $email');
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      
      // Force refresh the user state
      await _refreshUserState();
      
      print('AuthProvider: Sign in successful - User: ${_user?.email}');
      print('AuthProvider: isAuthenticated: $isAuthenticated');
      
      _setLoading(false);
      return true;
    } catch (e) {
      print('AuthProvider: Sign in failed - $e');
      _setError(e.toString());
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    print('AuthProvider: Signing out');
    _setLoading(true);
    try {
      await _authService.signOut();
      _user = null; // Clear user immediately
      print('AuthProvider: Sign out successful');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Sign out failed - $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Force refresh user state
  Future<void> _refreshUserState() async {
    _user = _authService.currentUser;
    print('AuthProvider: Refreshed user state - User: ${_user?.email}');
    notifyListeners();
    
    // Add a small delay to ensure state is propagated
    await Future.delayed(const Duration(milliseconds: 100));
    notifyListeners();
  }

  // Public method to refresh state
  Future<void> refreshState() async {
    await _refreshUserState();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }
} 