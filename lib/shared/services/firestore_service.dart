import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/activity_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collections
  static const String usersCollection = 'users';
  static const String activitiesCollection = 'activities';
  static const String sessionsCollection = 'sessions';

  /// Get current user model from Firestore
  Future<UserModel?> getCurrentUserModel() async {
    try {
      print('FirestoreService: Getting current user...');
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('FirestoreService: No current user in Firebase Auth');
        return null;
      }
      
      print('FirestoreService: Current user UID: ${currentUser.uid}');
      print('FirestoreService: Current user email: ${currentUser.email}');
      print('FirestoreService: Fetching user document from Firestore...');
      
      final doc = await _firestore.collection(usersCollection).doc(currentUser.uid).get();
      if (doc.exists) {
        print('FirestoreService: User document found, converting to UserModel...');
        final userModel = UserModel.fromFirestore(doc);
        print('FirestoreService: UserModel created: ${userModel.email}');
        print('FirestoreService: User role: ${userModel.appRole.name}');
        print('FirestoreService: User type: ${userModel.userType.name}');
        print('FirestoreService: User active: ${userModel.isActive}');
        return userModel;
      } else {
        print('FirestoreService: User document does not exist in Firestore');
        print('FirestoreService: This means the user exists in Firebase Auth but not in Firestore');
        print('FirestoreService: This could be a data inconsistency issue');
        return null;
      }
    } catch (e) {
      print('FirestoreService: Error getting current user model: $e');
      print('FirestoreService: Error type: ${e.runtimeType}');
      return null;
    }
  }

  // User Management Methods

  /// Get all users with permission filtering
  Future<List<UserModel>> getUsers({UserModel? currentUser}) async {
    try {
      print('FirestoreService: Starting getUsers...');
      print('FirestoreService: Current user: ${currentUser?.email ?? "null"}');
      
      // Check if user is authenticated
      final authUser = _auth.currentUser;
      if (authUser == null) {
        print('FirestoreService: No authenticated user');
        throw Exception('Usuario no autenticado');
      }
      
      print('FirestoreService: Querying users collection...');
      final snapshot = await _firestore.collection(usersCollection).get();
      print('FirestoreService: Received ${snapshot.docs.length} user documents');
      
      if (snapshot.docs.isEmpty) {
        print('FirestoreService: No user documents found in Firestore');
        return [];
      }
      
      print('FirestoreService: Converting documents to UserModel objects...');
      final users = <UserModel>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        try {
          final doc = snapshot.docs[i];
          print('FirestoreService: Processing document ${i + 1}/${snapshot.docs.length}: ${doc.id}');
          final user = UserModel.fromFirestore(doc);
          users.add(user);
          print('FirestoreService: Successfully converted user: ${user.email}');
        } catch (e) {
          print('FirestoreService: Error converting document ${snapshot.docs[i].id}: $e');
        }
      }

      print('FirestoreService: Successfully converted ${users.length} users');

      // Apply permission filtering according to documentation
      if (currentUser != null) {
        final isFullAccess = currentUser.isAdmin || currentUser.isSuperUser;
        print('FirestoreService: Applying permission filtering, isFullAccess: $isFullAccess');
        
        if (!isFullAccess) {
          // USER role only sees basic information (according to documentation)
          final filteredUsers = users.map((user) => UserModel(
            uid: user.uid,
            email: user.email,
            firstName: user.firstName,
            lastName: user.lastName,
            documentType: user.documentType,
            documentNumber: user.documentNumber,
            phone: user.phone,
            userType: user.userType,
            appRole: user.appRole,
            status: user.status,
            isActive: user.isActive,
            provisionalPasswordSet: user.provisionalPasswordSet,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            typeSpecificData: null, // Hide sensitive data for USER role
          )).toList();
          print('FirestoreService: Applied USER role filtering');
          return filteredUsers;
        }
      }

      print('FirestoreService: Returning ${users.length} users without filtering');
      return users;
    } catch (e) {
      print('FirestoreService: Error in getUsers: $e');
      print('FirestoreService: Error type: ${e.runtimeType}');
      throw Exception('Error fetching users: $e');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(usersCollection).doc(userId).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  /// Create new user with validation
  Future<UserModel> createUser(UserModel user, String provisionalPassword) async {
    try {
      // Validate required fields
      final validationError = _validateRequiredUserFields(user);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Validate unique document
      final isDocumentUnique = await _validateUniqueDocument(user.documentNumber);
      if (!isDocumentUnique) {
        throw Exception('El número de documento ya está registrado');
      }

      // Validate unique email (except for students/parents)
      final isEmailUnique = await _validateUniqueEmail(user.email, user.userType);
      if (!isEmailUnique) {
        throw Exception('El email ya está registrado');
      }

      // Validate SuperUser limit
      if (user.appRole == AppRole.SuperUser) {
        final canCreateSuperUser = await _validateSuperUserLimit();
        if (!canCreateSuperUser) {
          throw Exception('No se pueden crear más de 2 SuperUsers');
        }
      }

      // Create user in Firebase Auth
      final userRecord = await _auth.createUserWithEmailAndPassword(
        email: user.email,
        password: provisionalPassword,
      );

      // Update display name
      await userRecord.user?.updateDisplayName('${user.firstName} ${user.lastName}');

      // Create user document in Firestore
      final newUser = user.copyWith(
        uid: userRecord.user!.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        provisionalPasswordSet: true,
      );

      await _firestore
          .collection(usersCollection)
          .doc(userRecord.user!.uid)
          .set(newUser.toFirestore());

      return newUser;
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  /// Update user with permission validation
  Future<void> updateUser(String userId, UserModel updatedUser, UserModel currentUser) async {
    try {
      // Check permissions
      final canEdit = currentUser.isSuperUser || 
          (currentUser.isAdmin && updatedUser.appRole != AppRole.SuperUser);

      if (!canEdit) {
        throw Exception('No tienes permisos para editar este usuario');
      }

      // Additional validation for ADMIN role
      if (currentUser.appRole == AppRole.ADMIN && updatedUser.appRole == AppRole.SuperUser) {
        throw Exception('No puedes asignar rol SuperUser');
      }

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .update(updatedUser.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  /// Delete user (SuperUser only)
  Future<void> deleteUser(String userId, UserModel currentUser) async {
    try {
      if (!currentUser.isSuperUser) {
        throw Exception('No tienes permisos para eliminar usuarios');
      }

      // Delete from Firebase Auth
      await _auth.currentUser?.delete();

      // Delete from Firestore
      await _firestore.collection(usersCollection).doc(userId).delete();
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }

  /// Reset user password
  Future<void> resetUserPassword(String userId, String newPassword, UserModel currentUser) async {
    try {
      final canReset = currentUser.isSuperUser || currentUser.uid == userId;
      if (!canReset) {
        throw Exception('No tienes permisos para resetear esta contraseña');
      }

      // Update password in Firebase Auth
      await _auth.currentUser?.updatePassword(newPassword);

      // Update user document
      await _firestore.collection(usersCollection).doc(userId).update({
        'provisionalPasswordSet': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error resetting password: $e');
    }
  }

  /// Get user activities
  Future<List<ActivityModel>> getUserActivities(String userId) async {
    try {
      final allActivitiesSnapshot = await _firestore.collection(activitiesCollection).get();
      
      final userActivities = allActivitiesSnapshot.docs
          .where((doc) {
            final activityData = doc.data();
            
            final isParticipant = (activityData['participants'] as List<dynamic>?)
                ?.any((p) => p['userId'] == userId) ?? false;
            
            final isResponsible = (activityData['responsibleUsers'] as List<dynamic>?)
                ?.any((r) => r['userId'] == userId) ?? false;
            
            return isParticipant || isResponsible;
          })
          .map((doc) => ActivityModel.fromFirestore(doc))
          .toList();

      return userActivities;
    } catch (e) {
      throw Exception('Error fetching user activities: $e');
    }
  }

  // Activity Management Methods

  /// Get all activities
  Future<List<ActivityModel>> getActivities() async {
    try {
      print('FirestoreService: Starting getActivities...');
      
      print('FirestoreService: Querying activities collection...');
      final snapshot = await _firestore
          .collection(activitiesCollection)
          .orderBy('createdAt', descending: true)
          .get();

      print('FirestoreService: Received ${snapshot.docs.length} activity documents');
      
      if (snapshot.docs.isEmpty) {
        print('FirestoreService: No activity documents found in Firestore');
        return [];
      }

      print('FirestoreService: Converting documents to ActivityModel objects...');
      final activities = <ActivityModel>[];
      for (int i = 0; i < snapshot.docs.length; i++) {
        try {
          final doc = snapshot.docs[i];
          print('FirestoreService: Processing activity document ${i + 1}/${snapshot.docs.length}: ${doc.id}');
          final activity = ActivityModel.fromFirestore(doc);
          activities.add(activity);
          print('FirestoreService: Successfully converted activity: ${activity.title}');
        } catch (e) {
          print('FirestoreService: Error converting activity document ${snapshot.docs[i].id}: $e');
        }
      }

      print('FirestoreService: Successfully converted ${activities.length} activities');
      return activities;
    } catch (e) {
      print('FirestoreService: Error in getActivities: $e');
      print('FirestoreService: Error type: ${e.runtimeType}');
      throw Exception('Error fetching activities: $e');
    }
  }

  /// Get activity by ID
  Future<ActivityModel?> getActivityById(String activityId) async {
    try {
      final doc = await _firestore.collection(activitiesCollection).doc(activityId).get();
      if (doc.exists) {
        return ActivityModel.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Error fetching activity: $e');
    }
  }

  /// Create new activity with validation
  Future<ActivityModel> createActivity(ActivityModel activity, UserModel currentUser) async {
    try {
      // Check permissions
      if (!currentUser.isAdmin) {
        throw Exception('No tienes permisos para crear actividades');
      }

      // Validate required fields
      final validationError = _validateRequiredActivityFields(activity);
      if (validationError != null) {
        throw Exception(validationError);
      }

      // Validate at least one responsible user
      if (activity.responsibleUsers.isEmpty) {
        throw Exception('Debe asignar al menos un responsable');
      }

      // Validate session dates
      final sortedDates = List<SessionDate>.from(activity.sessionDates)
        ..sort((a, b) => a.date.compareTo(b.date));

      final newActivity = activity.copyWith(
        activityId: '', // Will be set by Firestore
        status: ActivityStatus.ACTIVA,
        adminCanEdit: true,
        createdBy_uid: currentUser.uid,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        sessionDates: sortedDates,
      );

      final docRef = await _firestore.collection(activitiesCollection).add(newActivity.toFirestore());
      
      return newActivity.copyWith(activityId: docRef.id);
    } catch (e) {
      throw Exception('Error creating activity: $e');
    }
  }

  /// Update activity with permission validation
  Future<void> updateActivity(String activityId, ActivityModel updatedActivity, UserModel currentUser) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) {
        throw Exception('Actividad no encontrada');
      }

      // Check permissions
      if (!activity.canUserEdit(currentUser.uid, currentUser.appRole.name)) {
        throw Exception('No tienes permisos para editar esta actividad');
      }

      await _firestore
          .collection(activitiesCollection)
          .doc(activityId)
          .update(updatedActivity.copyWith(updatedAt: DateTime.now()).toFirestore());
    } catch (e) {
      throw Exception('Error updating activity: $e');
    }
  }

  /// Delete activity with permission validation
  Future<void> deleteActivity(String activityId, UserModel currentUser) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) {
        throw Exception('Actividad no encontrada');
      }

      // Check permissions
      if (!activity.canUserDelete(currentUser.uid, currentUser.appRole.name)) {
        throw Exception('No tienes permisos para eliminar esta actividad');
      }

      await _firestore.collection(activitiesCollection).doc(activityId).delete();
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }

  /// Complete activity session
  Future<void> completeActivitySession(String activityId, int sessionNumber, String userId) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) {
        throw Exception('Actividad no encontrada');
      }

      // Check if user is participant or responsible
      final isParticipant = activity.isUserParticipant(userId);
      final isResponsible = activity.isUserResponsible(userId);

      if (!isParticipant && !isResponsible) {
        throw Exception('No tienes permisos para completar esta actividad');
      }

      // Create session completion
      final sessionCompletion = SessionCompletion(
        sessionNumber: sessionNumber,
        userId: userId,
        completedAt: DateTime.now(),
        isResponsible: isResponsible,
        status: CompletionStatus.PENDING_APPROVAL,
      );

      // Update activity
      final updatedCompletions = List<SessionCompletion>.from(activity.sessionCompletions)
        ..add(sessionCompletion);

      await _firestore.collection(activitiesCollection).doc(activityId).update({
        'sessionCompletions': updatedCompletions.map((sc) => sc.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error completing activity session: $e');
    }
  }

  /// Approve activity completion
  Future<void> approveActivityCompletion(
    String activityId, 
    int sessionNumber, 
    String participantUserId, 
    String approvingUserId
  ) async {
    try {
      final activity = await getActivityById(activityId);
      if (activity == null) {
        throw Exception('Actividad no encontrada');
      }

      // Check if approver is responsible
      if (!activity.isUserResponsible(approvingUserId)) {
        throw Exception('Solo los responsables pueden aprobar completaciones');
      }

      // Update completion status
      final updatedCompletions = activity.sessionCompletions.map((completion) {
        if (completion.sessionNumber == sessionNumber && completion.userId == participantUserId) {
          return completion.copyWith(
            status: CompletionStatus.APPROVED,
            approvedBy: approvingUserId,
            approvedAt: DateTime.now(),
          );
        }
        return completion;
      }).toList();

      await _firestore.collection(activitiesCollection).doc(activityId).update({
        'sessionCompletions': updatedCompletions.map((sc) => sc.toMap()).toList(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Error approving activity completion: $e');
    }
  }

  // Session Management Methods

  /// Create user session
  Future<String> createUserSession(String userId, Map<String, dynamic> deviceInfo) async {
    try {
      final sessionId = _generateSessionId();
      final session = {
        'sessionId': sessionId,
        'userId': userId,
        'deviceInfo': deviceInfo,
        'ipAddress': await _getIPAddress(),
        'userAgent': 'Flutter Mobile App',
        'createdAt': Timestamp.now(),
        'lastActivity': Timestamp.now(),
        'isActive': true,
        'timeoutMinutes': 30,
      };

      await _firestore.collection(sessionsCollection).doc(sessionId).set(session);
      return sessionId;
    } catch (e) {
      throw Exception('Error creating session: $e');
    }
  }

  /// Validate user session
  Future<bool> validateUserSession(String sessionId, String userId) async {
    try {
      final doc = await _firestore.collection(sessionsCollection).doc(sessionId).get();
      
      if (!doc.exists) return false;
      
      final session = doc.data()!;
      
      // Check if session belongs to user
      if (session['userId'] != userId) return false;
      
      // Check if session is active
      if (!session['isActive']) return false;
      
      // Check timeout
      final lastActivity = (session['lastActivity'] as Timestamp).toDate();
      final now = DateTime.now();
      final timeoutMs = (session['timeoutMinutes'] ?? 30) * 60 * 1000;
      
      if (now.difference(lastActivity).inMilliseconds > timeoutMs) {
        await _terminateSession(sessionId);
        return false;
      }
      
      // Update last activity
      await _firestore.collection(sessionsCollection).doc(sessionId).update({
        'lastActivity': Timestamp.now(),
      });
      
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Terminate user session
  Future<void> terminateUserSession(String sessionId) async {
    await _terminateSession(sessionId);
  }

  /// Get user active sessions
  Future<List<Map<String, dynamic>>> getUserActiveSessions(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(sessionsCollection)
          .where('userId', isEqualTo: userId)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      throw Exception('Error fetching user sessions: $e');
    }
  }

  // Report Methods

  /// Generate user report
  Future<Map<String, dynamic>> generateUserReport() async {
    try {
      final users = await getUsers();
      
      return {
        'totalUsers': users.length,
        'activeUsers': users.where((u) => u.isActive).length,
        'inactiveUsers': users.where((u) => !u.isActive).length,
        'byUserType': {
          'DOCENTE': users.where((u) => u.userType == UserType.DOCENTE).length,
          'ESTUDIANTE': users.where((u) => u.userType == UserType.ESTUDIANTE).length,
          'ACUDIENTE': users.where((u) => u.userType == UserType.ACUDIENTE).length,
          'ADMIN_STAFF': users.where((u) => u.userType == UserType.ADMIN_STAFF).length,
        },
        'byAppRole': {
          'SuperUser': users.where((u) => u.appRole == AppRole.SuperUser).length,
          'ADMIN': users.where((u) => u.appRole == AppRole.ADMIN).length,
          'USER': users.where((u) => u.appRole == AppRole.USER).length,
        }
      };
    } catch (e) {
      throw Exception('Error generating user report: $e');
    }
  }

  /// Generate activity report
  Future<Map<String, dynamic>> generateActivityReport() async {
    try {
      final activities = await getActivities();
      
      return {
        'totalActivities': activities.length,
        'activeActivities': activities.where((a) => a.isActive).length,
        'completedActivities': activities.where((a) => a.isCompleted).length,
        'inactiveActivities': activities.where((a) => a.isInactive).length,
        'averageCompletionRate': activities.isEmpty 
            ? 0.0 
            : activities.map((a) => a.completionPercentage ?? 0.0).reduce((a, b) => a + b) / activities.length,
        'byCategory': activities.fold<Map<String, int>>({}, (acc, activity) {
          final category = activity.category ?? 'Sin categoría';
          acc[category] = (acc[category] ?? 0) + 1;
          return acc;
        })
      };
    } catch (e) {
      throw Exception('Error generating activity report: $e');
    }
  }

  // Private Helper Methods

  String? _validateRequiredUserFields(UserModel user) {
    final requiredFields = {
      'general': ['email', 'firstName', 'lastName', 'documentType', 'documentNumber', 'phone', 'userType', 'appRole'],
      'DOCENTE': ['areaOfStudy', 'assignedToGradeLevel', 'educationLevel', 'schoolPosition'],
      'ESTUDIANTE': ['schoolGrade'],
      'ACUDIENTE': ['representedChildrenCount']
    };

    // Check general required fields
    if (user.email.isEmpty || user.firstName.isEmpty || user.lastName.isEmpty) {
      return 'Faltan campos requeridos básicos';
    }

    // Check type-specific required fields
    final typeFields = requiredFields[user.userType.name] ?? [];
    for (final field in typeFields) {
      switch (field) {
        case 'areaOfStudy':
          if (user.typeSpecificData?.areaOfStudy?.isEmpty ?? true) {
            return 'El área de estudio es requerida para docentes';
          }
          break;
        case 'assignedToGradeLevel':
          if (user.typeSpecificData?.assignedToGradeLevel == null) {
            return 'El nivel de grado asignado es requerido para docentes';
          }
          break;
        case 'educationLevel':
          if (user.typeSpecificData?.educationLevel == null) {
            return 'El nivel de educación es requerido para docentes';
          }
          break;
        case 'schoolPosition':
          if (user.typeSpecificData?.schoolPosition == null) {
            return 'La posición escolar es requerida para docentes';
          }
          break;
        case 'schoolGrade':
          if (user.typeSpecificData?.schoolGrade == null) {
            return 'El grado escolar es requerido para estudiantes';
          }
          break;
        case 'representedChildrenCount':
          if (user.typeSpecificData?.representedChildrenCount == null) {
            return 'El número de hijos representados es requerido para acudientes';
          }
          break;
      }
    }

    return null;
  }

  String? _validateRequiredActivityFields(ActivityModel activity) {
    if (activity.title.isEmpty || activity.description.isEmpty || activity.numberOfSessions <= 0) {
      return 'Faltan datos requeridos de la actividad';
    }

    if (activity.sessionDates.isEmpty) {
      return 'Debe especificar al menos una fecha de sesión';
    }

    if (activity.responsibleUsers.isEmpty) {
      return 'Debe asignar al menos un responsable';
    }

    return null;
  }

  Future<bool> _validateUniqueDocument(String documentNumber) async {
    final snapshot = await _firestore
        .collection(usersCollection)
        .where('documentNumber', isEqualTo: documentNumber)
        .get();
    return snapshot.docs.isEmpty;
  }

  Future<bool> _validateUniqueEmail(String email, UserType userType) async {
    if (userType == UserType.ESTUDIANTE || userType == UserType.ACUDIENTE) {
      return true; // Allow duplicate emails for students/parents
    }
    
    final snapshot = await _firestore
        .collection(usersCollection)
        .where('email', isEqualTo: email)
        .where('userType', whereNotIn: ['ESTUDIANTE', 'ACUDIENTE'])
        .get();
    return snapshot.docs.isEmpty;
  }

  Future<bool> _validateSuperUserLimit() async {
    final snapshot = await _firestore
        .collection(usersCollection)
        .where('appRole', isEqualTo: AppRole.SuperUser.name)
        .get();
    return snapshot.docs.length < 2;
  }

  String _generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           (1000 + DateTime.now().microsecond).toString();
  }

  Future<String> _getIPAddress() async {
    // In a real implementation, you would get the actual IP
    // For now, return a placeholder
    return '192.168.1.1';
  }

  Future<void> _terminateSession(String sessionId) async {
    await _firestore.collection(sessionsCollection).doc(sessionId).update({
      'isActive': false,
      'lastActivity': Timestamp.now(),
    });
  }

  /// Debug function to check Firestore data
  Future<void> debugFirestoreData() async {
    try {
      print('=== DEBUG FIRESTORE DATA ===');
      
      // Check users collection
      print('\n--- USERS COLLECTION ---');
      final usersSnapshot = await _firestore.collection(usersCollection).get();
      print('Total users found: ${usersSnapshot.docs.length}');
      
      for (int i = 0; i < usersSnapshot.docs.length; i++) {
        final doc = usersSnapshot.docs[i];
        print('User ${i + 1}:');
        print('  ID: ${doc.id}');
        print('  Data: ${doc.data()}');
        print('  Exists: ${doc.exists}');
        print('---');
      }
      
      // Check activities collection
      print('\n--- ACTIVITIES COLLECTION ---');
      final activitiesSnapshot = await _firestore.collection(activitiesCollection).get();
      print('Total activities found: ${activitiesSnapshot.docs.length}');
      
      for (int i = 0; i < activitiesSnapshot.docs.length; i++) {
        final doc = activitiesSnapshot.docs[i];
        print('Activity ${i + 1}:');
        print('  ID: ${doc.id}');
        print('  Data: ${doc.data()}');
        print('  Exists: ${doc.exists}');
        print('---');
      }
      
      print('=== END DEBUG ===');
    } catch (e) {
      print('Debug error: $e');
    }
  }

  /// Create test data for debugging
  Future<void> createTestData() async {
    try {
      print('=== CREATING TEST DATA ===');
      
      // Create test users
      final testUsers = [
        {
          'uid': 'test_superuser_1',
          'email': 'superuser@macondo.test',
          'firstName': 'Super',
          'lastName': 'User',
          'documentType': 'CC',
          'documentNumber': '12345678',
          'phone': '555-0001',
          'userType': 'ADMIN_STAFF',
          'appRole': 'SuperUser',
          'status': 'VERIFIED',
          'isActive': true,
          'provisionalPasswordSet': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'uid': 'test_admin_1',
          'email': 'admin@macondo.test',
          'firstName': 'Admin',
          'lastName': 'User',
          'documentType': 'CC',
          'documentNumber': '87654321',
          'phone': '555-0002',
          'userType': 'ADMIN_STAFF',
          'appRole': 'ADMIN',
          'status': 'VERIFIED',
          'isActive': true,
          'provisionalPasswordSet': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
        {
          'uid': 'test_teacher_1',
          'email': 'teacher@macondo.test',
          'firstName': 'Teacher',
          'lastName': 'One',
          'documentType': 'CC',
          'documentNumber': '11111111',
          'phone': '555-0003',
          'userType': 'DOCENTE',
          'appRole': 'USER',
          'status': 'VERIFIED',
          'isActive': true,
          'provisionalPasswordSet': false,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'typeSpecificData': {
            'areaOfStudy': 'Matemáticas',
            'assignedToGradeLevel': 'PRIMARIA',
            'educationLevel': 'PROFESIONAL',
            'schoolPosition': 'DOCENTE',
          }
        },
      ];
      
      // Create users
      for (final userData in testUsers) {
        await _firestore.collection(usersCollection).doc(userData['uid'] as String).set(userData);
        print('Created user: ${userData['email']}');
      }
      
      // Create test activities
      final testActivities = [
        {
          'activityId': 'test_activity_1',
          'title': 'Taller de Matemáticas',
          'description': 'Taller práctico de resolución de problemas matemáticos para estudiantes de primaria.',
          'numberOfSessions': 3,
          'sessionDates': [
            {
              'sessionNumber': 1,
              'date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'startTime': '09:00',
              'endTime': '11:00',
              'location': 'Aula 101',
            },
            {
              'sessionNumber': 2,
              'date': DateTime.now().add(const Duration(days: 14)).toIso8601String(),
              'startTime': '14:00',
              'endTime': '16:00',
              'location': 'Aula 102',
            },
            {
              'sessionNumber': 3,
              'date': DateTime.now().add(const Duration(days: 21)).toIso8601String(),
              'startTime': '09:00',
              'endTime': '11:00',
              'location': 'Aula 103',
            },
          ],
          'materials': ['Calculadora', 'Papel cuadriculado', 'Lápices'],
          'objectives': ['Mejorar habilidades matemáticas', 'Desarrollar pensamiento lógico'],
          'responsibleUsers': [
            {
              'userId': 'test_teacher_1',
              'status': 'COMPLETADA',
            }
          ],
          'participants': [
            {
              'userId': 'test_teacher_1',
              'status': 'PENDIENTE',
            }
          ],
          'status': 'ACTIVA',
          'adminCanEdit': true,
          'createdBy_uid': 'test_admin_1',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'sessionCompletions': [],
        },
        {
          'activityId': 'test_activity_2',
          'title': 'Sesión de Lectura',
          'description': 'Sesión de lectura comprensiva con actividades interactivas.',
          'numberOfSessions': 2,
          'sessionDates': [
            {
              'sessionNumber': 1,
              'date': DateTime.now().add(const Duration(days: 5)).toIso8601String(),
              'startTime': '10:00',
              'endTime': '12:00',
              'location': 'Biblioteca',
            },
            {
              'sessionNumber': 2,
              'date': DateTime.now().add(const Duration(days: 12)).toIso8601String(),
              'startTime': '10:00',
              'endTime': '12:00',
              'location': 'Biblioteca',
            },
          ],
          'materials': ['Libros', 'Cuadernos', 'Marcadores'],
          'objectives': ['Mejorar comprensión lectora', 'Fomentar el amor por la lectura'],
          'responsibleUsers': [
            {
              'userId': 'test_teacher_1',
              'status': 'COMPLETADA',
            }
          ],
          'participants': [
            {
              'userId': 'test_teacher_1',
              'status': 'PENDIENTE',
            }
          ],
          'status': 'COMPLETADA',
          'adminCanEdit': true,
          'createdBy_uid': 'test_admin_1',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'sessionCompletions': [
            {
              'sessionNumber': 1,
              'userId': 'test_teacher_1',
              'completedAt': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
              'isResponsible': false,
              'status': 'COMPLETED',
            },
            {
              'sessionNumber': 2,
              'userId': 'test_teacher_1',
              'completedAt': DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
              'isResponsible': false,
              'status': 'COMPLETED',
            }
          ],
        },
      ];
      
      // Create activities
      for (final activityData in testActivities) {
        await _firestore.collection(activitiesCollection).doc(activityData['activityId'] as String).set(activityData);
        print('Created activity: ${activityData['title']}');
      }
      
      print('=== TEST DATA CREATED SUCCESSFULLY ===');
    } catch (e) {
      print('Error creating test data: $e');
      throw Exception('Error creating test data: $e');
    }
  }
} 