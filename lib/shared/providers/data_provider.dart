import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class DataProvider with ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

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
    print('DataProvider: Starting loadUsers...');
    setLoading(true);
    try {
      print('DataProvider: Getting current user model...');
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      print('DataProvider: Current user model: ${currentUserModel?.email ?? "null"}');
      
      // Check permissions according to documentation
      if (currentUserModel == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Only ADMIN/SuperUser can access users according to documentation
      if (!currentUserModel.isAdmin && !currentUserModel.isSuperUser) {
        throw Exception('No tienes permisos para ver la lista de usuarios');
      }
      
      print('DataProvider: Fetching users from Firestore...');
      _users = await _firestoreService.getUsers(currentUser: currentUserModel);
      print('DataProvider: Successfully loaded ${_users.length} users');
      
      _error = null;
    } catch (e) {
      print('DataProvider: Error loading users: $e');
      _error = e.toString();
      _users = [];
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: loadUsers completed');
    }
  }

  // Load activities
  Future<void> loadActivities() async {
    print('DataProvider: Starting loadActivities...');
    setLoading(true);
    try {
      print('DataProvider: Getting current user model...');
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      print('DataProvider: Current user model: ${currentUserModel?.email ?? "null"}');
      
      // Check permissions according to documentation
      if (currentUserModel == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // All authenticated users can read activities according to documentation
      print('DataProvider: Fetching activities from Firestore...');
      _activities = await _firestoreService.getActivities();
      print('DataProvider: Successfully loaded ${_activities.length} activities');
      
      // Load users needed for activity display (responsible users and creators)
      await _loadUsersForActivities();
      
      _error = null;
    } catch (e) {
      print('DataProvider: Error loading activities: $e');
      _error = e.toString();
      _activities = [];
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: loadActivities completed');
    }
  }

  // Load users needed for activities display
  Future<void> _loadUsersForActivities() async {
    try {
      print('DataProvider: Loading users for activities display...');
      
      // Get all unique user IDs from activities (creators and responsible users)
      final Set<String> userIds = {};
      
      for (final activity in _activities) {
        userIds.add(activity.createdBy_uid);
        for (final participant in activity.responsibleUsers) {
          userIds.add(participant.userId);
        }
        for (final participant in activity.participants) {
          userIds.add(participant.userId);
        }
      }
      
      print('DataProvider: Found ${userIds.length} unique user IDs in activities');
      
      // Load each user individually
      final List<UserModel> activityUsers = [];
      for (final userId in userIds) {
        try {
          final user = await _firestoreService.getUserById(userId);
          if (user != null) {
            activityUsers.add(user);
          }
        } catch (e) {
          print('DataProvider: Error loading user $userId: $e');
        }
      }
      
      // Merge with existing users, avoiding duplicates
      final existingUserIds = _users.map((u) => u.uid).toSet();
      for (final user in activityUsers) {
        if (!existingUserIds.contains(user.uid)) {
          _users.add(user);
        }
      }
      
      print('DataProvider: Successfully loaded ${activityUsers.length} users for activities');
    } catch (e) {
      print('DataProvider: Error loading users for activities: $e');
      // Don't throw error here as activities can still be displayed
    }
  }

  // Create user
  Future<void> createUser(UserModel user, String provisionalPassword) async {
    print('DataProvider: Starting createUser...');
    setLoading(true);
    try {
      // Check permissions according to documentation
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Only SuperUser can create users according to documentation
      if (!currentUserModel.isSuperUser) {
        throw Exception('Solo los SuperUsers pueden crear usuarios');
      }
      
      print('DataProvider: Creating user with provisional password...');
      await _firestoreService.createUser(user, provisionalPassword);
      
      print('DataProvider: User created successfully, refreshing list...');
      await loadUsers(); // Refresh the list
      _error = null;
    } catch (e) {
      print('DataProvider: Error creating user: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: createUser completed');
    }
  }

  // Create activity
  Future<void> createActivity(ActivityModel activity) async {
    print('DataProvider: Starting createActivity...');
    setLoading(true);
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) throw Exception('Usuario no autenticado');
      
      // Only ADMIN/SuperUser can create activities according to documentation
      if (!currentUserModel.isAdmin && !currentUserModel.isSuperUser) {
        throw Exception('Solo los Administradores y SuperUsers pueden crear actividades');
      }
      
      print('DataProvider: Creating activity...');
      await _firestoreService.createActivity(activity, currentUserModel);
      await loadActivities(); // Refresh the list
      _error = null;
    } catch (e) {
      print('DataProvider: Error creating activity: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: createActivity completed');
    }
  }

  // Update user
  Future<void> updateUser(String userId, UserModel updatedUser) async {
    print('DataProvider: Starting updateUser...');
    setLoading(true);
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) throw Exception('Usuario no autenticado');
      
      // Check permissions according to documentation
      // SuperUser can edit everything, ADMIN limited, USER can only change password
      if (!currentUserModel.isSuperUser && !currentUserModel.isAdmin) {
        throw Exception('No tienes permisos para editar usuarios');
      }
      
      print('DataProvider: Updating user...');
      await _firestoreService.updateUser(userId, updatedUser, currentUserModel);
      await loadUsers(); // Refresh the list
      _error = null;
    } catch (e) {
      print('DataProvider: Error updating user: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: updateUser completed');
    }
  }

  // Update activity
  Future<void> updateActivity(String activityId, ActivityModel updatedActivity) async {
    setLoading(true);
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) throw Exception('Usuario no autenticado');
      
      await _firestoreService.updateActivity(activityId, updatedActivity, currentUserModel);
      await loadActivities(); // Refresh the list
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      setLoading(false);
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    print('DataProvider: Starting deleteUser...');
    setLoading(true);
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) throw Exception('Usuario no autenticado');
      
      // Only SuperUser can delete users according to documentation
      if (!currentUserModel.isSuperUser) {
        throw Exception('Solo los SuperUsers pueden eliminar usuarios');
      }
      
      print('DataProvider: Deleting user...');
      await _firestoreService.deleteUser(userId, currentUserModel);
      await loadUsers(); // Refresh the list
      _error = null;
    } catch (e) {
      print('DataProvider: Error deleting user: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: deleteUser completed');
    }
  }

  // Delete activity
  Future<void> deleteActivity(String activityId) async {
    print('DataProvider: Starting deleteActivity...');
    setLoading(true);
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) throw Exception('Usuario no autenticado');
      
      // Only SuperUser and creator (ADMIN) can delete activities according to documentation
      if (!currentUserModel.isSuperUser && !currentUserModel.isAdmin) {
        throw Exception('No tienes permisos para eliminar actividades');
      }
      
      print('DataProvider: Deleting activity...');
      await _firestoreService.deleteActivity(activityId, currentUserModel);
      await loadActivities(); // Refresh the list
      _error = null;
    } catch (e) {
      print('DataProvider: Error deleting activity: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: deleteActivity completed');
    }
  }

  // Complete activity session
  Future<void> completeActivitySession(String activityId, int sessionNumber) async {
    print('DataProvider: Starting completeActivitySession...');
    setLoading(true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado');
      
      // Participants and responsible users can complete sessions according to documentation
      print('DataProvider: Completing activity session...');
      await _firestoreService.completeActivitySession(activityId, sessionNumber, currentUser.uid);
      await loadActivities(); // Refresh the list
      _error = null;
    } catch (e) {
      print('DataProvider: Error completing activity session: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: completeActivitySession completed');
    }
  }

  // Approve activity completion
  Future<void> approveActivityCompletion(String activityId, int sessionNumber, String participantUserId) async {
    print('DataProvider: Starting approveActivityCompletion...');
    setLoading(true);
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado');
      
      // Only responsible users can approve completions according to documentation
      print('DataProvider: Approving activity completion...');
      await _firestoreService.approveActivityCompletion(
        activityId, 
        sessionNumber, 
        participantUserId, 
        currentUser.uid
      );
      await loadActivities(); // Refresh the list
      _error = null;
    } catch (e) {
      print('DataProvider: Error approving activity completion: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    } finally {
      setLoading(false);
      print('DataProvider: approveActivityCompletion completed');
    }
  }

  // Get user activities
  Future<List<ActivityModel>> getUserActivities(String userId) async {
    print('DataProvider: Starting getUserActivities...');
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Check permissions according to documentation
      // Users can see their own activities, ADMIN/SuperUser can see all
      if (!currentUserModel.isAdmin && !currentUserModel.isSuperUser && currentUserModel.uid != userId) {
        throw Exception('No tienes permisos para ver las actividades de otros usuarios');
      }
      
      print('DataProvider: Fetching user activities...');
      final activities = await _firestoreService.getUserActivities(userId);
      print('DataProvider: Successfully loaded ${activities.length} user activities');
      
      _error = null;
      return activities;
    } catch (e) {
      print('DataProvider: Error getting user activities: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    }
  }

  // Generate reports
  Future<Map<String, dynamic>> generateUserReport() async {
    print('DataProvider: Starting generateUserReport...');
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Only ADMIN/SuperUser can generate reports according to documentation
      if (!currentUserModel.isAdmin && !currentUserModel.isSuperUser) {
        throw Exception('No tienes permisos para generar reportes');
      }
      
      print('DataProvider: Generating user report...');
      final report = await _firestoreService.generateUserReport();
      print('DataProvider: User report generated successfully');
      
      _error = null;
      return report;
    } catch (e) {
      print('DataProvider: Error generating user report: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    }
  }

  Future<Map<String, dynamic>> generateActivityReport() async {
    print('DataProvider: Starting generateActivityReport...');
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) {
        throw Exception('Usuario no autenticado');
      }
      
      // Only ADMIN/SuperUser can generate reports according to documentation
      if (!currentUserModel.isAdmin && !currentUserModel.isSuperUser) {
        throw Exception('No tienes permisos para generar reportes');
      }
      
      print('DataProvider: Generating activity report...');
      final report = await _firestoreService.generateActivityReport();
      print('DataProvider: Activity report generated successfully');
      
      _error = null;
      return report;
    } catch (e) {
      print('DataProvider: Error generating activity report: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
    }
  }

  // Load all data
  Future<void> loadAllData() async {
    print('DataProvider: Starting loadAllData...');
    setLoading(true);
    try {
      final currentUserModel = await _firestoreService.getCurrentUserModel();
      if (currentUserModel == null) {
        throw Exception('Usuario no autenticado');
      }
      
      print('DataProvider: Loading all data...');
      await Future.wait([
        loadActivities(), // All authenticated users can read activities
        if (currentUserModel.isAdmin || currentUserModel.isSuperUser) loadUsers(), // Only ADMIN/SuperUser can read users
      ]);
      print('DataProvider: All data loaded successfully');
      
      _error = null;
    } catch (e) {
      print('DataProvider: Error loading all data: $e');
      _error = e.toString();
      throw e; // Re-throw to show error in UI
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
    _error = null;
    notifyListeners();
  }
} 