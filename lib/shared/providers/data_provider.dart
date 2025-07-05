import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class DataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  List<UserModel> _users = [];
  List<ActivityModel> _activities = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<UserModel> get users => _users;
  List<ActivityModel> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load users
  Future<void> loadUsers() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Usar Firestore directamente para cargar usuarios (más rápido y confiable)
      _users = await _firestoreService.getUsers();
      
      if (kDebugMode) {
        print('DataProvider: Users loaded successfully - ${_users.length} users');
      }
    } catch (e) {
      _setError('Error loading users: $e');
      if (kDebugMode) {
        print('DataProvider: Error loading users: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Load activities
  Future<void> loadActivities() async {
    try {
      _setLoading(true);
      _clearError();
      
      // Usar Firestore directamente para cargar actividades
      _activities = await _firestoreService.getActivities();
      
      if (kDebugMode) {
        print('DataProvider: Activities loaded successfully - ${_activities.length} activities');
      }
    } catch (e) {
      _setError('Error loading activities: $e');
      if (kDebugMode) {
        print('DataProvider: Error loading activities: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Create user using Firestore directly
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (kDebugMode) {
        print('DataProvider: Creating user with provisional password...');
      }
      
      // Crear UserModel desde los datos
      final user = UserModel.fromJson(userData);
      final provisionalPassword = userData['provisionalPassword'] as String;
      
      // Usar Firestore directamente para crear usuario
      await _firestoreService.createUser(user, provisionalPassword);
      
      // Recargar la lista de usuarios
      await loadUsers();
      
      if (kDebugMode) {
        print('DataProvider: User created successfully');
      }
    } catch (e) {
      _setError('Error creating user: $e');
      if (kDebugMode) {
        print('DataProvider: Error creating user: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Create activity
  Future<void> createActivity(Map<String, dynamic> activityData) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Crear ActivityModel desde los datos
      final activity = ActivityModel.fromJson(activityData);
      
      // Usar Firestore directamente para crear actividad
      await _firestoreService.createActivity(activity);
      
      // Recargar la lista de actividades
      await loadActivities();
      
      if (kDebugMode) {
        print('DataProvider: Activity created successfully');
      }
    } catch (e) {
      _setError('Error creating activity: $e');
      if (kDebugMode) {
        print('DataProvider: Error creating activity: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Update user using Firestore directly
  Future<void> updateUser(String userId, Map<String, dynamic> userData) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Usar Firestore directamente para actualizar usuario
      await _firestoreService.updateUser(userId, userData);
      
      // Recargar la lista de usuarios
      await loadUsers();
      
      if (kDebugMode) {
        print('DataProvider: User updated successfully');
      }
    } catch (e) {
      _setError('Error updating user: $e');
      if (kDebugMode) {
        print('DataProvider: Error updating user: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Update activity using Firestore directly
  Future<void> updateActivity(String activityId, Map<String, dynamic> activityData) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Usar Firestore directamente para actualizar actividad
      await _firestoreService.updateActivity(activityId, activityData);
      
      // Recargar la lista de actividades
      await loadActivities();
      
      if (kDebugMode) {
        print('DataProvider: Activity updated successfully');
      }
    } catch (e) {
      _setError('Error updating activity: $e');
      if (kDebugMode) {
        print('DataProvider: Error updating activity: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Delete user using Firestore directly
  Future<void> deleteUser(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Usar Firestore directamente para eliminar usuario
      await _firestoreService.deleteUser(userId);
      
      // Recargar la lista de usuarios
      await loadUsers();
      
      if (kDebugMode) {
        print('DataProvider: User deleted successfully');
      }
    } catch (e) {
      _setError('Error deleting user: $e');
      if (kDebugMode) {
        print('DataProvider: Error deleting user: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Update users locally without reloading from Firestore
  void updateUsersLocally(List<UserModel> updatedUsers) {
    _users = updatedUsers;
    notifyListeners();
    if (kDebugMode) {
      print('DataProvider: Users updated locally - ${_users.length} users');
    }
  }

  // Toggle user status using UserService
  Future<void> toggleUserStatus(String userId, bool newStatus) async {
    try {
      _setLoading(true);
      _clearError();
      
      await _userService.toggleUserStatus(userId, newStatus);
      
      // Recargar la lista de usuarios
      await loadUsers();
      
      if (kDebugMode) {
        print('DataProvider: User status toggled successfully');
      }
    } catch (e) {
      _setError('Error toggling user status: $e');
      if (kDebugMode) {
        print('DataProvider: Error toggling user status: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Reset user password using UserService
  Future<String> resetUserPassword(String userId) async {
    try {
      _setLoading(true);
      _clearError();
      
      final newPassword = await _userService.resetUserPassword(userId);
      
      // Recargar la lista de usuarios
      await loadUsers();
      
      if (kDebugMode) {
        print('DataProvider: User password reset successfully');
      }
      
      return newPassword;
    } catch (e) {
      _setError('Error resetting user password: $e');
      if (kDebugMode) {
        print('DataProvider: Error resetting user password: $e');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // Delete activity using Firestore directly
  Future<void> deleteActivity(String activityId) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Usar Firestore directamente para eliminar actividad
      await _firestoreService.deleteActivity(activityId);
      
      // Recargar la lista de actividades
      await loadActivities();
      
      if (kDebugMode) {
        print('DataProvider: Activity deleted successfully');
      }
    } catch (e) {
      _setError('Error deleting activity: $e');
      if (kDebugMode) {
        print('DataProvider: Error deleting activity: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Get user activities
  Future<List<ActivityModel>> getUserActivities(String userId) async {
    print('DataProvider: Starting getUserActivities...');
    try {
      // Por ahora, obtener todas las actividades
      // TODO: Implementar filtrado por usuario cuando se necesite
      final activities = await _firestoreService.getActivities();
      print('DataProvider: Successfully loaded ${activities.length} activities');
      
      _error = null;
      return activities;
    } catch (e) {
      print('DataProvider: Error getting user activities: $e');
      _error = e.toString();
      rethrow; // Re-throw to show error in UI
    }
  }

  // Generate reports using Firestore directly
  Future<List<Map<String, dynamic>>> getReports({int? limit, String? userId}) async {
    try {
      // Por ahora retornamos una lista vacía, se puede implementar más tarde
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('DataProvider: Error getting reports: $e');
      }
      rethrow;
    }
  }

  // Load all data
  Future<void> loadAllData() async {
    print('DataProvider: Starting loadAllData...');
    setLoading(true);
    try {
      print('DataProvider: Loading all data...');
      await Future.wait([
        loadActivities(), // All authenticated users can read activities
        loadUsers(), // Load users (permissions checked in FirestoreService)
      ]);
      print('DataProvider: All data loaded successfully');
      
      _error = null;
    } catch (e) {
      print('DataProvider: Error loading all data: $e');
      _error = e.toString();
      rethrow; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: loadAllData completed');
    }
  }

  // Get dashboard stats
  Map<String, dynamic> get dashboardStats {
    try {
      // All authenticated users can see basic stats
      final activeActivities = _activities.where((a) => a.isActive).length;
      final totalActivities = _activities.length;
      final completedActivities = _activities.where((a) => a.isCompleted).length;
      
      // Only ADMIN/SuperUser can see user stats
      final activeUsers = _users.where((u) => u.isActive).length;
      final totalUsers = _users.length;
      
      return {
        'activeUsers': activeUsers,
        'totalUsers': totalUsers,
        'activeActivities': activeActivities,
        'totalActivities': totalActivities,
        'completedActivities': completedActivities,
        'completionRate': totalActivities > 0 ? (completedActivities / totalActivities * 100).round() : 0,
      };
    } catch (e) {
      print('DataProvider: Error getting dashboard stats: $e');
      return {
        'activeUsers': 0,
        'totalUsers': 0,
        'activeActivities': 0,
        'totalActivities': 0,
        'completedActivities': 0,
        'completionRate': 0,
      };
    }
  }

  // Get user by ID
  UserModel? getUserById(String userId) {
    try {
      // This method should be used carefully as it doesn't check permissions
      // The calling code should ensure proper permissions
      return _users.firstWhere((user) => user.uid == userId);
    } catch (e) {
      print('DataProvider: Error getting user by ID: $e');
      return null;
    }
  }

  // Load specific user by ID from Firestore
  Future<UserModel?> loadUserById(String userId) async {
    try {
      print('DataProvider: Loading user $userId from Firestore...');
      final user = await _firestoreService.getUserById(userId);
      if (user != null) {
        // Add to local cache if not already present
        final existingUser = _users.where((u) => u.uid == userId).firstOrNull;
        if (existingUser == null) {
          _users.add(user);
          notifyListeners();
        }
        print('DataProvider: Successfully loaded user ${user.name}');
      }
      return user;
    } catch (e) {
      print('DataProvider: Error loading user $userId from Firestore: $e');
      return null;
    }
  }



  // Change user status using Firestore directly
  Future<void> changeUserStatus(String userId, bool isActive) async {
    try {
      _setLoading(true);
      _clearError();
      
      // Usar el método updateUser ya implementado
      await updateUser(userId, {'isActive': isActive});
      
      if (kDebugMode) {
        print('DataProvider: User status changed successfully');
      }
    } catch (e) {
      _setError('Error changing user status: $e');
      if (kDebugMode) {
        print('DataProvider: Error changing user status: $e');
      }
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _clearError();
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

  // Filter methods
  List<UserModel> getFilteredUsers({
    String? searchQuery,
    UserType? userType,
    AppRole? appRole,
    bool? isActive,
  }) {
    return _users.where((user) {
      // Search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesSearch = user.firstName.toLowerCase().contains(query) ||
            user.lastName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.documentNumber.contains(query);
        if (!matchesSearch) return false;
      }

      // User type filter
      if (userType != null && user.userType != userType) {
        return false;
      }

      // App role filter
      if (appRole != null && user.appRole != appRole) {
        return false;
      }

      // Active status filter
      if (isActive != null && user.isActive != isActive) {
        return false;
      }

      return true;
    }).toList();
  }

  List<ActivityModel> getFilteredActivities({
    String? searchQuery,
    String? status,
    String? category,
  }) {
    return _activities.where((activity) {
      // Search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesSearch = activity.title.toLowerCase().contains(query) ||
            activity.description.toLowerCase().contains(query);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (status != null && activity.status.name != status) {
        return false;
      }

      // Category filter
      if (category != null && activity.category != category) {
        return false;
      }

      return true;
    }).toList();
  }
} 