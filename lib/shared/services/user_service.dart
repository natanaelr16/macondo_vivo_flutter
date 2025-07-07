import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../utils/permissions.dart';

import 'firestore_service.dart';
import 'api_service.dart';




class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  // ==================== USER MANAGEMENT ====================

  // Get all users with filtering and search
  Future<List<UserModel>> getAllUsers({
    String? searchTerm,
    UserType? userType,
    AppRole? appRole,
    bool? isActive,
  }) async {
    try {
      print('UserService: Getting all users with filters...');
      
      // Use FirestoreService to get users
      final users = await _firestoreService.getUsers();
      
      // Apply filters
      var filteredUsers = users;
      
      // Search filter
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final searchLower = searchTerm.toLowerCase();
        filteredUsers = filteredUsers.where((user) {
          return user.firstName.toLowerCase().contains(searchLower) ||
                 user.lastName.toLowerCase().contains(searchLower) ||
                 user.email.toLowerCase().contains(searchLower) ||
                 user.documentNumber.contains(searchTerm);
        }).toList();
      }
      
      // User type filter
      if (userType != null) {
        filteredUsers = filteredUsers.where((user) => user.userType == userType).toList();
      }
      
      // App role filter
      if (appRole != null) {
        filteredUsers = filteredUsers.where((user) => user.appRole == appRole).toList();
      }
      
      // Active status filter
      if (isActive != null) {
        filteredUsers = filteredUsers.where((user) => user.isActive == isActive).toList();
      }
      
      print('UserService: Returning ${filteredUsers.length} filtered users');
      return filteredUsers;
      
    } catch (e) {
      print('UserService: Error getting users: $e');
      rethrow;
    }
  }

  // Get user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      return await _firestoreService.getUserById(uid);
    } catch (e) {
      print('UserService: Error getting user by ID: $e');
      return null;
    }
  }

  // Create new user using Web API (Admin SDK)
  Future<UserCreationResult> createUser(UserModel userData) async {
    try {
      print('UserService: Creating new user via Web API...');
      
      // Get current user token for authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }
      
      final token = await currentUser.getIdToken();
      print('UserService: Got authentication token');
      
      // Prepare user data for API
      final apiUserData = {
        'email': userData.email,
        'firstName': userData.firstName,
        'lastName': userData.lastName,
        'documentType': userData.documentType.name,
        'documentNumber': userData.documentNumber,
        'phone': userData.phone,
        'userType': userData.userType.name,
        'appRole': userData.appRole.name,
        'typeSpecificData': userData.typeSpecificData?.toMap() ?? {},
      };
      
      print('UserService: Sending user data to API: ${apiUserData['email']}');
      
      // Call the web API to create user
      final response = await ApiService.createUser(apiUserData);
      
      if (response['success'] == true) {
        print('UserService: ✅ User created successfully via API');
        
        // Get the created user data
        final createdUserData = response['user'];
        final provisionalPassword = response['provisionalPassword'];
        
                 // Create UserModel from API response
         final createdUser = UserModel(
           uid: createdUserData['uid'],
           email: createdUserData['email'],
           firstName: createdUserData['firstName'],
           lastName: createdUserData['lastName'],
           documentType: DocumentType.values.firstWhere(
             (e) => e.name == createdUserData['documentType'],
             orElse: () => DocumentType.CC,
           ),
           documentNumber: createdUserData['documentNumber'],
           phone: createdUserData['phone'],
           userType: UserType.values.firstWhere(
             (e) => e.name == createdUserData['userType'],
             orElse: () => UserType.ADMIN_STAFF,
           ),
           appRole: AppRole.values.firstWhere(
             (e) => e.name == createdUserData['appRole'],
             orElse: () => AppRole.USER,
           ),
           status: UserStatus.values.firstWhere(
             (e) => e.name == createdUserData['status'],
             orElse: () => UserStatus.PENDING,
           ),
           isActive: createdUserData['isActive'] ?? true,
           provisionalPasswordSet: createdUserData['provisionalPasswordSet'] ?? true,
           typeSpecificData: createdUserData['typeSpecificData'] != null 
               ? TypeSpecificData.fromMap(createdUserData['typeSpecificData'])
               : null,
           createdAt: DateTime.parse(createdUserData['createdAt']),
           updatedAt: DateTime.parse(createdUserData['updatedAt']),
         );
        
        print('UserService: ✅ User created with UID: ${createdUser.uid}');
        print('UserService: ✅ Provisional password: $provisionalPassword');
        
        return UserCreationResult(
          user: createdUser,
          provisionalPassword: provisionalPassword ?? '',
        );
        
      } else {
        final errorMessage = response['message'] ?? 'Unknown error';
        print('UserService: ❌ API Error: $errorMessage');
        throw Exception(errorMessage);
      }
      
    } catch (e) {
      print('UserService: Error creating user via API: $e');
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(String uid, Map<String, dynamic> updates) async {
    try {
      print('UserService: Updating user $uid...');
      print('UserService: Updates recibidos: $updates');
      print('UserService: isActive en updates: ${updates['isActive']}');
      
      // Update user using FirestoreService
      await _firestoreService.updateUser(uid, updates);
      
      print('UserService: ✅ User updated successfully via FirestoreService');
      
    } catch (e) {
      print('UserService: Error updating user: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String uid) async {
    try {
      print('UserService: Deleting user $uid...');
      
      // Get current user token for authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }
      
      print('UserService: Current user: ${currentUser.email} (${currentUser.uid})');
      
      try {
        // Try the web API first to delete from Firebase Auth
        print('UserService: Trying web API to delete user from Firebase Auth...');
        await ApiService.deleteUser(uid);
        
        print('UserService: ✅ User deleted successfully via API (Firebase Auth + Firestore)');
        
      } catch (apiError) {
        print('UserService: API failed with error: $apiError');
        
        // Check if it's an authorization error
        if (apiError.toString().contains('No autorizado') || 
            apiError.toString().contains('No authorized') ||
            apiError.toString().contains('403')) {
          print('UserService: ❌ Authorization error - User may not have permission to delete users');
          print('UserService: ❌ This user can only delete from Firestore, not from Firebase Auth');
          print('UserService: ❌ Please use the web app to delete users from Firebase Auth');
          
          // Still delete from Firestore for consistency
          print('UserService: Proceeding with Firestore deletion only...');
          await _firestoreService.deleteUser(uid);
          
          throw Exception('No tienes permisos para eliminar usuarios de Firebase Auth. El usuario fue eliminado solo de Firestore. Usa la aplicación web para eliminación completa.');
        }
        
        // Other API errors - use Firestore fallback
        print('UserService: Using Firestore fallback (Firebase Auth deletion required manually)...');
        await _firestoreService.deleteUser(uid);
        
        print('UserService: ⚠️ User deleted from Firestore only. Firebase Auth deletion required manually.');
        print('UserService: ⚠️ Please delete the user from Firebase Auth console or use the web app.');
      }
      
    } catch (e) {
      print('UserService: Error deleting user: $e');
      rethrow;
    }
  }

  // Toggle user active status
  Future<void> toggleUserStatus(String uid, bool newStatus) async {
    try {
      print('UserService: Toggling user status for $uid to ${newStatus ? 'active' : 'inactive'}');
      
      // Get current user token for authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }
      
      final token = await currentUser.getIdToken();
      
      try {
        // Try the web API first
        print('UserService: Trying web API...');
        final response = await ApiService.toggleUserStatus(uid, newStatus);
        
        print('UserService: API Response: $response');
        print('UserService: Response type: ${response.runtimeType}');
        print('UserService: Response keys: ${response.keys.toList()}');
        
        if (response['success'] == true) {
          print('UserService: ✅ User status updated successfully via API');
          return;
        } else {
          final errorMessage = response['message'] ?? 'Unknown error';
          print('UserService: ❌ API Error: $errorMessage');
          throw Exception(errorMessage);
        }
      } catch (apiError) {
        print('UserService: API failed, trying Firestore fallback: $apiError');
        
        // Fallback: Update directly in Firestore
        print('UserService: Using Firestore fallback...');
        await _firestore.collection('users').doc(uid).update({
          'isActive': newStatus,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        print('UserService: ✅ User status updated successfully via Firestore fallback');
      }
      
    } catch (e) {
      print('UserService: Error toggling user status: $e');
      rethrow;
    }
  }

  // Reset user password
  Future<String> resetUserPassword(String uid) async {
    try {
      print('UserService: Resetting password for user $uid...');
      
      // Get current user token for authentication
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('No authenticated user found');
      }
      
      final token = await currentUser.getIdToken();
      
      // Call the web API to reset password
      final response = await ApiService.resetUserPassword(uid);
      
      if (response['success'] == true) {
        final provisionalPassword = response['provisionalPassword'] ?? '';
        print('UserService: ✅ Password reset successfully via API');
        print('UserService: ✅ New provisional password: $provisionalPassword');
        return provisionalPassword;
      } else {
        final errorMessage = response['message'] ?? 'Unknown error';
        print('UserService: ❌ API Error: $errorMessage');
        throw Exception(errorMessage);
      }
      
    } catch (e) {
      print('UserService: Error resetting user password: $e');
      rethrow;
    }
  }



  // Change user status
  Future<void> changeUserStatus(String uid, UserStatus newStatus) async {
    try {
      print('UserService: Changing status for user $uid to ${newStatus.name}...');
      
      // Change user status using FirestoreService
      await _firestoreService.changeUserStatus(uid, newStatus);
      
      print('UserService: ✅ User status changed successfully');
      
    } catch (e) {
      print('UserService: Error changing user status: $e');
      rethrow;
    }
  }

  // ==================== VALIDATION METHODS ====================

  // Check if email already exists
  Future<bool> emailExists(String email) async {
    try {
      print('UserService: Checking if email exists: $email');
      
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      
      final exists = query.docs.isNotEmpty;
      print('UserService: Email exists: $exists');
      
      return exists;
    } catch (e) {
      print('UserService: Error checking email: $e');
      return false;
    }
  }

  // Check if document number already exists
  Future<bool> documentExists(String documentNumber) async {
    try {
      print('UserService: Checking if document exists: $documentNumber');
      
      final query = await _firestore
          .collection('users')
          .where('documentNumber', isEqualTo: documentNumber.trim())
          .limit(1)
          .get();
      
      final exists = query.docs.isNotEmpty;
      print('UserService: Document exists: $exists');
      
      return exists;
    } catch (e) {
      print('UserService: Error checking document: $e');
      return false;
    }
  }

  // Debug method to test user creation
  Future<void> debugUserCreation() async {
    try {
      print('UserService: Debug - Testing user creation permissions...');
      
      final currentUser = _auth.currentUser;
      print('UserService: Debug - Current user: ${currentUser?.email}');
      print('UserService: Debug - Current user UID: ${currentUser?.uid}');
      print('UserService: Debug - Is user null: ${currentUser == null}');
      
      if (currentUser != null) {
        print('UserService: Debug - User is authenticated');
        
        // Try to get user data
        try {
          final userData = await _firestoreService.getUserById(currentUser.uid);
          print('UserService: Debug - Current user data: ${userData?.toJson()}');
          
          if (userData != null) {
            final canCreate = PermissionManager.canCreateUsers(userData);
            print('UserService: Debug - Can create users: $canCreate');
            print('UserService: Debug - User role: ${userData.appRole}');
            print('UserService: Debug - Is SuperUser: ${userData.isSuperUser}');
            print('UserService: Debug - Is Admin: ${userData.isAdmin}');
            print('UserService: Debug - User type: ${userData.userType}');
            print('UserService: Debug - App role enum: ${userData.appRole}');
            print('UserService: Debug - App role name: ${userData.appRole.name}');
          } else {
            print('UserService: Debug - No user data found in Firestore');
          }
        } catch (e) {
          print('UserService: Debug - Error getting user data: $e');
        }
      } else {
        print('UserService: Debug - No authenticated user found');
      }
      
      // Test direct Firestore query to see what's in the database
      try {
        print('UserService: Debug - Testing direct Firestore query...');
        final userDoc = await _firestore.collection('users').doc(currentUser?.uid).get();
        if (userDoc.exists) {
          print('UserService: Debug - Raw Firestore data: ${userDoc.data()}');
        } else {
          print('UserService: Debug - User document does not exist in Firestore');
        }
      } catch (e) {
        print('UserService: Debug - Error in direct Firestore query: $e');
      }
      
    } catch (e) {
      print('UserService: Debug - Error: $e');
    }
  }

  // Validate user permissions for operations
  Future<bool> canCreateUsers() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final userData = await _firestoreService.getUserById(currentUser.uid);
      if (userData == null) return false;
      
      return userData.isSuperUser || userData.isAdmin;
    } catch (e) {
      print('UserService: Error checking create permissions: $e');
      return false;
    }
  }

  // Check if user can edit another user
  Future<bool> canEditUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final currentUserData = await _firestoreService.getUserById(currentUser.uid);
      final targetUserData = await _firestoreService.getUserById(targetUserId);
      
      if (currentUserData == null || targetUserData == null) return false;
      
      // SuperUser can edit anyone
      if (currentUserData.isSuperUser) return true;
      
      // Admin can edit non-SuperUser users
      if (currentUserData.isAdmin && !targetUserData.isSuperUser) return true;
      
      // Users can edit themselves
      if (currentUser.uid == targetUserId) return true;
      
      return false;
    } catch (e) {
      print('UserService: Error checking edit permissions: $e');
      return false;
    }
  }

  // Check if user can delete another user
  Future<bool> canDeleteUser(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return false;
      
      final currentUserData = await _firestoreService.getUserById(currentUser.uid);
      if (currentUserData == null) return false;
      
      // Only SuperUser can delete users
      return currentUserData.isSuperUser;
    } catch (e) {
      print('UserService: Error checking delete permissions: $e');
      return false;
    }
  }

  // Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final allUsers = await getAllUsers();
      
      return {
        'total': allUsers.length,
        'active': allUsers.where((u) => u.isActive).length,
        'inactive': allUsers.where((u) => !u.isActive).length,
        'teachers': allUsers.where((u) => u.userType == UserType.DOCENTE).length,
        'students': allUsers.where((u) => u.userType == UserType.ESTUDIANTE).length,
        'parents': allUsers.where((u) => u.userType == UserType.ACUDIENTE).length,
        'adminStaff': allUsers.where((u) => u.userType == UserType.ADMIN_STAFF).length,
        'superUsers': allUsers.where((u) => u.appRole == AppRole.SuperUser).length,
        'admins': allUsers.where((u) => u.appRole == AppRole.ADMIN).length,
        'users': allUsers.where((u) => u.appRole == AppRole.USER).length,
      };
    } catch (e) {
      print('Error getting user statistics: $e');
      rethrow;
    }
  }

  // Validate user data
  String? validateUserData(Map<String, dynamic> userData) {
    final requiredFields = [
      'email', 'firstName', 'lastName', 'documentType', 
      'documentNumber', 'userType', 'appRole'
    ];

    for (final field in requiredFields) {
      if (userData[field] == null || userData[field].toString().isEmpty) {
        return 'El campo $field es requerido';
      }
    }

    // Validate email format
    final email = userData['email'].toString();
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return 'El formato del email no es válido';
    }

    // Validate document number
    final documentNumber = userData['documentNumber'].toString();
    if (documentNumber.length < 6) {
      return 'El número de documento debe tener al menos 6 caracteres';
    }

    return null;
  }

} 