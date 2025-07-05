import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _firebaseUser;
  UserModel? _userData;
  bool _isLoading = false;
  String? _error;
  bool _isTransitioning = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userData => _userData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _firebaseUser != null;
  bool get isTransitioning => _isTransitioning;

  // Computed properties for easy access
  bool get isSuperUser => _userData?.isSuperUser ?? false;
  bool get isAdmin => _userData?.isAdmin ?? false;
  bool get isTeacher => _userData?.isTeacher ?? false;
  bool get isStudent => _userData?.isStudent ?? false;
  bool get isParent => _userData?.isParent ?? false;
  bool get isAdminStaff => _userData?.isAdminStaff ?? false;
  
  // Permission methods based on Firestore rules
  bool get canManageUsers => isSuperUser || isAdmin;
  bool get canCreateUsers => isSuperUser; // Solo SuperUser puede crear usuarios
  bool get canEditUsers => isSuperUser; // Solo SuperUser puede editar usuarios
  bool get canDeleteUsers => isSuperUser;

  // Backward compatibility getter
  User? get user => _firebaseUser;

  AuthProvider() {
    print('AuthProvider: Initializing...');
    
    // Check current user immediately
    _firebaseUser = _authService.currentUser;
    print('AuthProvider: Current user on init: ${_firebaseUser?.email}');
    
    // Listen to auth state changes
    _authService.authStateChanges.listen((User? user) {
      print('AuthProvider: Auth state changed - User: ${user?.email}');
      _firebaseUser = user;
      
      if (user != null) {
        // Load user data when authenticated
        _loadUserData();
      } else {
        // Clear user data when signed out
        _userData = null;
        notifyListeners();
      }
    });
  }

  Future<bool> signIn(String email, String password) async {
    print('AuthProvider: Attempting sign in for $email');
    _setLoading(true);
    _clearError();

    try {
      await _authService.signInWithEmailAndPassword(email, password);
      
      // User data will be loaded by the auth state listener
      print('AuthProvider: Sign in successful - User: ${_firebaseUser?.email}');
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
      _firebaseUser = null;
      _userData = null;
      print('AuthProvider: Sign out successful');
      notifyListeners();
    } catch (e) {
      print('AuthProvider: Sign out failed - $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load user data from Firestore
  Future<void> _loadUserData() async {
    if (_firebaseUser == null) return;
    
    try {
      final userData = await _authService.getUserData(_firebaseUser!.uid);
      if (userData != null) {
        _userData = userData;
        print('AuthProvider: User data loaded - ${userData.name} (${userData.appRole})');
      } else {
        print('AuthProvider: No user data found for ${_firebaseUser!.uid}');
        _setError('No se encontraron datos del usuario');
      }
    } catch (e) {
      print('AuthProvider: Error loading user data - $e');
      _setError('Error al cargar datos del usuario');
    }
    
    notifyListeners();
  }

  // Refresh user data
  Future<void> refreshUserData() async {
    await _loadUserData();
  }

  // Backward compatibility method
  Future<void> refreshState() async {
    await _loadUserData();
  }

  // Update password
  Future<void> updatePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      await _authService.updatePassword(currentPassword, newPassword);
      print('AuthProvider: Password updated successfully');
      
      // Refresh user data to get updated provisionalPasswordSet status
      await refreshUserData();
    } catch (e) {
      print('AuthProvider: Password update failed - $e');
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get ID token for API calls
  Future<String> getIdToken() async {
    try {
      return await _authService.getIdToken();
    } catch (e) {
      print('AuthProvider: Error getting ID token - $e');
      rethrow;
    }
  }

  // Set transition state
  void setTransitioning(bool transitioning) {
    _isTransitioning = transitioning;
    notifyListeners();
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